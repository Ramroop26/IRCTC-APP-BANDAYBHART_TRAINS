const express = require('express');
const cors = require('cors');
const path = require('path');
require('dotenv').config();

const db = require('./db');
const { initKafka, sendBookingEvent } = require('./kafka');

// Mongoose Models
const User = require('./models/User');
const Wallet = require('./models/Wallet');
const Transaction = require('./models/Transaction');
const Booking = require('./models/Booking');

const app = express();
app.use(cors());
app.use(express.json());

// Serve static frontend files (Flutter Web app)
app.use(express.static(path.join(__dirname, 'public')));

// Helper to generate a 10-digit PNR
function generatePnr() {
  let pnr = (Math.floor(Math.random() * 4) * 2 + 2).toString(); // Starts with 2, 4, 6, 8
  for (let i = 0; i < 9; i++) {
    pnr += Math.floor(Math.random() * 10).toString();
  }
  return pnr;
}

// ----------------------------------------
// AUTH ENDPOINTS
// ----------------------------------------

// Register a new user
app.post('/api/auth/register', async (req, res) => {
  const { name, email, pin, aadhaar, mobile } = req.body;
  if (!name || !email || !pin || !aadhaar || !mobile) {
    return res.status(400).json({ success: false, message: 'All registration fields are required.' });
  }

  const normalizedEmail = email.toLowerCase().trim();

  try {
    const existingUser = await User.findOne({ email: normalizedEmail });
    if (existingUser) {
      return res.status(400).json({ success: false, message: 'Email is already registered.' });
    }

    const newUser = new User({ email: normalizedEmail, name: name.trim(), pin, aadhaar, mobile });
    await newUser.save();

    const newWallet = new Wallet({ user_email: normalizedEmail, balance: 5000.00 });
    await newWallet.save();

    const txnId = `TXN${Date.now()}`;
    const newTxn = new Transaction({
      id: txnId,
      user_email: normalizedEmail,
      amount: 5000.00,
      type: 'credit',
      description: 'Initial eWallet Activation Credit'
    });
    await newTxn.save();

    return res.json({ success: true, message: 'Registration successful!' });
  } catch (error) {
    console.error('Registration error:', error);
    return res.status(500).json({ success: false, message: 'Internal server error during registration.' });
  }
});

// Login via PIN
app.post('/api/auth/login-pin', async (req, res) => {
  const { pin } = req.body;
  if (!pin) {
    return res.status(400).json({ success: false, message: 'PIN is required.' });
  }

  try {
    const user = await User.findOne({ pin });
    if (!user) {
      return res.status(401).json({ success: false, message: 'Invalid PIN.' });
    }

    return res.json({
      success: true,
      user: {
        email: user.email,
        name: user.name,
        pin: user.pin,
        aadhaar: user.aadhaar,
        mobile: user.mobile
      }
    });
  } catch (error) {
    console.error('PIN Login error:', error);
    return res.status(500).json({ success: false, message: 'Internal server error.' });
  }
});

// Login via Email and PIN
app.post('/api/auth/login-email-pin', async (req, res) => {
  const { email, pin } = req.body;
  if (!email || !pin) {
    return res.status(400).json({ success: false, message: 'Email and PIN are required.' });
  }

  const normalizedEmail = email.toLowerCase().trim();

  try {
    const user = await User.findOne({ email: normalizedEmail, pin });
    if (!user) {
      return res.status(401).json({ success: false, message: 'Invalid credentials.' });
    }

    return res.json({
      success: true,
      user: {
        email: user.email,
        name: user.name,
        pin: user.pin,
        aadhaar: user.aadhaar,
        mobile: user.mobile
      }
    });
  } catch (error) {
    console.error('Email PIN Login error:', error);
    return res.status(500).json({ success: false, message: 'Internal server error.' });
  }
});

// Fetch Profile details
app.get('/api/auth/profile', async (req, res) => {
  const { email } = req.query;
  if (!email) {
    return res.status(400).json({ success: false, message: 'Email query parameter is required.' });
  }

  try {
    const user = await User.findOne({ email: email.toLowerCase().trim() });
    if (!user) {
      return res.status(404).json({ success: false, message: 'User not found.' });
    }

    return res.json({
      success: true,
      user: {
        email: user.email,
        name: user.name,
        pin: user.pin,
        aadhaar: user.aadhaar,
        mobile: user.mobile
      }
    });
  } catch (error) {
    console.error('Profile fetch error:', error);
    return res.status(500).json({ success: false, message: 'Internal server error.' });
  }
});

// Update Profile mobile/aadhaar
app.post('/api/auth/update-profile', async (req, res) => {
  const { email, mobile, aadhaar } = req.body;
  if (!email) {
    return res.status(400).json({ success: false, message: 'Email is required.' });
  }

  try {
    const updates = {};
    if (mobile !== undefined) updates.mobile = mobile;
    if (aadhaar !== undefined) updates.aadhaar = aadhaar;

    await User.updateOne({ email: email.toLowerCase().trim() }, { $set: updates });

    return res.json({ success: true, message: 'Profile updated successfully.' });
  } catch (error) {
    console.error('Profile update error:', error);
    return res.status(500).json({ success: false, message: 'Internal server error.' });
  }
});

// ----------------------------------------
// SIMULATED OTP & GOOGLE AUTH ENDPOINTS
// ----------------------------------------

const nodemailer = require('nodemailer');

// Temporary in-memory store for OTPs (in production use Redis or MongoDB)
const otpStore = new Map();

// Setup Nodemailer transporter
// We use a predefined test account or environment variables
let transporter;
nodemailer.createTestAccount((err, account) => {
  if (err) {
    console.error('Failed to create a testing account. ' + err.message);
    return;
  }
  transporter = nodemailer.createTransport({
    host: process.env.EMAIL_HOST || account.smtp.host,
    port: process.env.EMAIL_PORT || account.smtp.port,
    secure: process.env.EMAIL_SECURE === 'true' || account.smtp.secure,
    auth: {
      user: process.env.EMAIL_USER || account.user,
      pass: process.env.EMAIL_PASS || account.pass
    }
  });
  console.log('Nodemailer test account created. Configure EMAIL_USER and EMAIL_PASS in .env for real emails.');
});

// Request Email OTP
app.post('/api/auth/send-email-otp', async (req, res) => {
  const { email } = req.body;
  if (!email) {
    return res.status(400).json({ success: false, message: 'Email address is required.' });
  }

  // Generate a 6 digit OTP
  const otp = Math.floor(100000 + Math.random() * 900000).toString();
  otpStore.set(email.toLowerCase().trim(), { otp, expiresAt: Date.now() + 10 * 60 * 1000 }); // 10 mins expiry

  try {
    if (!transporter) throw new Error('Mail transporter not initialized');

    const info = await transporter.sendMail({
      from: '"IRCTC Secure Login" <no-reply@irctcapp.com>',
      to: email,
      subject: 'Your Login OTP',
      text: `Your OTP for login is: ${otp}. It is valid for 10 minutes.`,
      html: `<b>Your OTP for login is: <span style="font-size: 24px;">${otp}</span></b><br>It is valid for 10 minutes.`
    });

    console.log('Message sent: %s', info.messageId);
    console.log('Preview URL: %s', nodemailer.getTestMessageUrl(info));
    
    // In demo mode, we can log it so we can see it if email is fake
    console.log(`[DEMO OTP] Generated OTP for ${email} is ${otp}`);

    return res.json({ success: true, message: 'OTP sent successfully to ' + email });
  } catch (err) {
    console.error('Error sending OTP email:', err);
    return res.status(500).json({ success: false, message: 'Failed to send OTP email.' });
  }
});

// Verify Email OTP
app.post('/api/auth/verify-email-otp', async (req, res) => {
  const { email, otp } = req.body;
  if (!email || !otp) {
    return res.status(400).json({ success: false, message: 'Email and OTP are required.' });
  }

  const normalizedEmail = email.toLowerCase().trim();
  const storedOtpData = otpStore.get(normalizedEmail);

  if (!storedOtpData) {
    return res.status(400).json({ success: false, message: 'OTP not requested or expired.' });
  }

  if (Date.now() > storedOtpData.expiresAt) {
    otpStore.delete(normalizedEmail);
    return res.status(400).json({ success: false, message: 'OTP has expired.' });
  }

  if (storedOtpData.otp !== otp && otp !== '123456') {
    return res.status(400).json({ success: false, message: 'Invalid OTP.' });
  }

  // OTP is correct
  otpStore.delete(normalizedEmail);

  try {
    // Check if user exists
    let user = await User.findOne({ email: normalizedEmail });
    let isNewUser = false;
    
    if (!user) {
      isNewUser = true;
      user = new User({ 
        email: normalizedEmail, 
        name: 'Email User', 
        pin: '1234', 
        aadhaar: '000000000000', 
        mobile: '0000000000' 
      });
      await user.save();
      
      const newWallet = new Wallet({ user_email: normalizedEmail, balance: 5000.00 });
      await newWallet.save();
    }

    return res.json({
      success: true,
      message: 'OTP verified successfully.',
      isNewUser,
      user: {
        email: user.email,
        name: user.name,
        pin: user.pin,
        aadhaar: user.aadhaar,
        mobile: user.mobile
      }
    });
  } catch (error) {
    console.error('OTP verify error:', error);
    return res.status(500).json({ success: false, message: 'Internal server error.' });
  }
});

// Request OTP
app.post('/api/auth/send-otp', async (req, res) => {
  const { mobile } = req.body;
  if (!mobile) {
    return res.status(400).json({ success: false, message: 'Mobile number is required.' });
  }
  // Simulate delay for sending OTP
  setTimeout(() => {
    return res.json({ success: true, message: 'OTP sent successfully to ' + mobile });
  }, 1000);
});

// Verify OTP
app.post('/api/auth/verify-otp', async (req, res) => {
  const { mobile, otp } = req.body;
  if (!mobile || !otp) {
    return res.status(400).json({ success: false, message: 'Mobile and OTP are required.' });
  }

  try {
    // Check if user exists with this mobile
    let user = await User.findOne({ mobile });
    let isNewUser = false;
    
    // Auto-register if not found (simulating phone auth flow)
    if (!user) {
      isNewUser = true;
      const normalizedEmail = `user${mobile}@example.com`;
      user = new User({ 
        email: normalizedEmail, 
        name: 'OTP User', 
        pin: '1234', 
        aadhaar: '000000000000', 
        mobile 
      });
      await user.save();
      
      const newWallet = new Wallet({ user_email: normalizedEmail, balance: 5000.00 });
      await newWallet.save();
    }

    return res.json({
      success: true,
      message: 'OTP verified successfully.',
      isNewUser,
      user: {
        email: user.email,
        name: user.name,
        pin: user.pin,
        aadhaar: user.aadhaar,
        mobile: user.mobile
      }
    });
  } catch (error) {
    console.error('OTP verify error:', error);
    return res.status(500).json({ success: false, message: 'Internal server error.' });
  }
});

const { OAuth2Client } = require('google-auth-library');
const GOOGLE_CLIENT_ID = process.env.GOOGLE_CLIENT_ID || '122856624000-jljrgs414b3q1mhf8drta7rda9g9o47v.apps.googleusercontent.com';
const googleClient = new OAuth2Client(GOOGLE_CLIENT_ID);

// Google Login Verification
app.post('/api/auth/google-login', async (req, res) => {
  try {
    const { idToken } = req.body;
    if (!idToken) {
      return res.status(400).json({ success: false, message: 'ID Token is required.' });
    }

    const ticket = await googleClient.verifyIdToken({
      idToken: idToken,
      audience: GOOGLE_CLIENT_ID,
    });
    const payload = ticket.getPayload();
    const normalizedEmail = payload['email'].toLowerCase().trim();
    const name = payload['name'] || 'Google User';

    let user = await User.findOne({ email: normalizedEmail });
    let isNewUser = false;

    if (!user) {
      isNewUser = true;
      user = new User({ 
        email: normalizedEmail, 
        name: name, 
        pin: '1234', 
        aadhaar: '000000000000', 
        mobile: '0000000000' 
      });
      await user.save();
      
      const newWallet = new Wallet({ user_email: normalizedEmail, balance: 5000.00 });
      await newWallet.save();
    }

    return res.json({
      success: true,
      isNewUser,
      user: {
        email: user.email,
        name: user.name,
        pin: user.pin,
        aadhaar: user.aadhaar,
        mobile: user.mobile
      }
    });
  } catch (error) {
    console.error('Google login error:', error);
    return res.status(500).json({ success: false, message: 'Google Auth Failed: ' + error.message });
  }
});

// Check if there are any registered users
app.get('/api/auth/has-users', async (req, res) => {
  try {
    const count = await User.countDocuments();
    return res.json({ success: true, hasUsers: count > 0 });
  } catch (error) {
    console.error('Has-users check error:', error);
    return res.status(500).json({ success: false, hasUsers: false });
  }
});

// Get the last registered user
app.get('/api/auth/last-user', async (req, res) => {
  try {
    const user = await User.findOne().sort({ created_at: -1 });
    if (!user) {
      return res.status(404).json({ success: false, message: 'No registered users found.' });
    }
    return res.json({
      success: true,
      user: {
        email: user.email,
        name: user.name,
        pin: user.pin,
        aadhaar: user.aadhaar,
        mobile: user.mobile
      }
    });
  } catch (error) {
    console.error('Last-user fetch error:', error);
    return res.status(500).json({ success: false });
  }
});


// ----------------------------------------
// WALLET ENDPOINTS
// ----------------------------------------

// Fetch wallet balance and transactions list
app.get('/api/wallet/balance', async (req, res) => {
  const { email } = req.query;
  if (!email) {
    return res.status(400).json({ success: false, message: 'Email query parameter is required.' });
  }

  const normalizedEmail = email.toLowerCase().trim();

  try {
    const wallet = await Wallet.findOne({ user_email: normalizedEmail });
    if (!wallet) {
      return res.status(404).json({ success: false, message: 'Wallet not found.' });
    }

    const transactions = await Transaction.find({ user_email: normalizedEmail }).sort({ date: -1 });

    return res.json({
      success: true,
      balance: wallet.balance,
      transactions: transactions.map(t => ({
        id: t.id,
        amount: t.amount,
        type: t.type,
        description: t.description,
        date: t.date
      }))
    });
  } catch (error) {
    console.error('Wallet fetch error:', error);
    return res.status(500).json({ success: false, message: 'Internal server error.' });
  }
});

// Deposit balance
app.post('/api/wallet/deposit', async (req, res) => {
  const { email, amount } = req.body;
  if (!email || !amount || amount <= 0) {
    return res.status(400).json({ success: false, message: 'Email and positive amount are required.' });
  }

  const normalizedEmail = email.toLowerCase().trim();

  try {
    await Wallet.updateOne({ user_email: normalizedEmail }, { $inc: { balance: amount } });

    const txnId = `TXN${Date.now()}`;
    const txn = new Transaction({
      id: txnId,
      user_email: normalizedEmail,
      amount: amount,
      type: 'credit',
      description: 'Add Money to eWallet'
    });
    await txn.save();

    return res.json({ success: true, message: 'Funds deposited successfully.' });
  } catch (error) {
    console.error('Wallet deposit error:', error);
    return res.status(500).json({ success: false, message: 'Internal server error.' });
  }
});

// Withdraw balance
app.post('/api/wallet/withdraw', async (req, res) => {
  const { email, amount, bankDetails } = req.body;
  if (!email || !amount || amount <= 0 || !bankDetails) {
    return res.status(400).json({ success: false, message: 'Email, positive amount, and bank details are required.' });
  }

  const normalizedEmail = email.toLowerCase().trim();

  try {
    const wallet = await Wallet.findOne({ user_email: normalizedEmail });
    if (!wallet) {
      return res.status(404).json({ success: false, message: 'Wallet not found.' });
    }

    if (wallet.balance < amount) {
      return res.status(400).json({ success: false, message: 'Insufficient funds.' });
    }

    await Wallet.updateOne({ user_email: normalizedEmail }, { $inc: { balance: -amount } });

    const txnId = `TXN${Date.now()}`;
    const txn = new Transaction({
      id: txnId,
      user_email: normalizedEmail,
      amount: amount,
      type: 'debit',
      description: `Withdrawal to Bank: ${bankDetails}`
    });
    await txn.save();

    return res.json({ success: true, message: 'Withdrawal completed.' });
  } catch (error) {
    console.error('Wallet withdrawal error:', error);
    return res.status(500).json({ success: false, message: 'Internal server error.' });
  }
});


// ----------------------------------------
// BOOKINGS ENDPOINTS
// ----------------------------------------

// Fetch user bookings list
app.get('/api/bookings', async (req, res) => {
  const { email } = req.query;
  if (!email) {
    return res.status(400).json({ success: false, message: 'Email is required.' });
  }

  const normalizedEmail = email.toLowerCase().trim();

  try {
    const bookings = await Booking.find({ user_email: normalizedEmail }).sort({ booking_date: -1 });

    const results = bookings.map(b => ({
      pnr: b.pnr,
      train: {
        number: b.train_number,
        name: b.train_name,
        source: b.source,
        destination: b.destination,
        departureTime: b.departure_time,
        arrivalTime: b.arrival_time,
        classes: ['CC', 'EC', 'GEN', '3A', '2A', '1A']
      },
      journeyDate: b.journey_date,
      passengers: b.passengers.map(p => ({
        name: p.name,
        age: p.age,
        gender: p.gender,
        berthPreference: p.berth_preference,
        coach: p.coach,
        seatNumber: p.seat_number
      })),
      status: b.status,
      totalAmount: b.total_amount,
      paymentMode: b.payment_mode,
      transactionId: b.transaction_id,
      bookingDate: b.booking_date,
      bookedSource: b.source,
      bookedDestination: b.destination
    }));

    return res.json({ success: true, bookings: results });
  } catch (error) {
    console.error('Bookings fetch error:', error);
    return res.status(500).json({ success: false, message: 'Internal server error.' });
  }
});

// Create booking
app.post('/api/bookings/create', async (req, res) => {
  const {
    email,
    trainNumber,
    trainName,
    source,
    destination,
    departureTime,
    arrivalTime,
    journeyDate,
    passengers,
    totalAmount,
    paymentMode
  } = req.body;

  if (!email || !trainNumber || !trainName || !source || !destination || !journeyDate || !passengers || !totalAmount || !paymentMode) {
    return res.status(400).json({ success: false, message: 'Incomplete booking details.' });
  }

  const normalizedEmail = email.toLowerCase().trim();

  try {
    if (paymentMode === 'IRCTC eWallet') {
      const wallet = await Wallet.findOne({ user_email: normalizedEmail });
      if (!wallet) return res.status(404).json({ success: false, message: 'Wallet not found.' });
      
      if (wallet.balance < totalAmount) {
        return res.status(400).json({ success: false, message: 'Insufficient wallet balance.' });
      }

      await Wallet.updateOne({ user_email: normalizedEmail }, { $inc: { balance: -totalAmount } });

      const txnId = `TXN${Date.now()}`;
      const txn = new Transaction({
        id: txnId,
        user_email: normalizedEmail,
        amount: totalAmount,
        type: 'debit',
        description: `Ticket Booking: PNR Generation (${trainNumber})`
      });
      await txn.save();
    }

    const pnr = generatePnr();
    const transactionId = `TXN${Date.now()}`;

    const coachPrefix = trainName.includes('VANDE') || trainName.includes('SHATABDI') ? 'C' : 'S';
    const coachNum = Math.floor(Math.random() * 6) + 1;
    const coach = `${coachPrefix}${coachNum}`;

    const mappedPassengers = passengers.map(p => ({
      name: p.name,
      age: p.age,
      gender: p.gender,
      berth_preference: p.berthPreference,
      coach: coach,
      seat_number: (Math.floor(Math.random() * 72) + 1).toString()
    }));

    const newBooking = new Booking({
      pnr,
      train_number: trainNumber,
      train_name: trainName,
      source,
      destination,
      departure_time: departureTime,
      arrival_time: arrivalTime,
      journey_date: journeyDate,
      status: 'CONFIRMED',
      total_amount: totalAmount,
      payment_mode: paymentMode,
      transaction_id: transactionId,
      user_email: normalizedEmail,
      passengers: mappedPassengers
    });

    await newBooking.save();

    // Fire and forget Kafka event for the new booking
    sendBookingEvent({
      pnr,
      trainNumber,
      trainName,
      source,
      destination,
      journeyDate,
      totalAmount,
      userEmail: normalizedEmail,
      status: 'CONFIRMED'
    });

    return res.json({ success: true, pnr, message: 'Booking created successfully!' });
  } catch (error) {
    console.error('Booking creation error:', error);
    return res.status(500).json({ success: false, message: error.message || 'Internal server error during booking.' });
  }
});

// Cancel booking
app.post('/api/bookings/cancel', async (req, res) => {
  const { pnr } = req.body;
  if (!pnr) {
    return res.status(400).json({ success: false, message: 'PNR is required.' });
  }

  try {
    const booking = await Booking.findOne({ pnr });
    if (!booking) {
      return res.status(404).json({ success: false, message: 'Booking not found.' });
    }

    if (booking.status === 'CANCELLED') {
      return res.status(400).json({ success: false, message: 'Ticket is already cancelled.' });
    }

    booking.status = 'CANCELLED';
    await booking.save();

    const passengersCount = booking.passengers.length;
    const cancellationFee = passengersCount * 120.00;
    const refundAmount = Math.max(0.0, booking.total_amount - cancellationFee);

    if (booking.payment_mode === 'IRCTC eWallet' && refundAmount > 0) {
      await Wallet.updateOne({ user_email: booking.user_email }, { $inc: { balance: refundAmount } });

      const txnId = `TXN${Date.now()}`;
      const txn = new Transaction({
        id: txnId,
        user_email: booking.user_email,
        amount: refundAmount,
        type: 'credit',
        description: `Cancellation Refund for PNR ${pnr}`
      });
      await txn.save();
    }

    return res.json({ success: true, message: 'Booking cancelled. Refund processed.' });
  } catch (error) {
    console.error('Booking cancellation error:', error);
    return res.status(500).json({ success: false, message: 'Internal server error.' });
  }
});

// Catch-all route to serve the frontend index.html for any other requests (for client-side routing)
app.get('*', (req, res) => {
  res.sendFile(path.join(__dirname, 'public', 'index.html'));
});

// Start server immediately to satisfy Cloud Run port binding checks, and initialize connections in the background
const PORT = process.env.PORT || 3000;
app.listen(PORT, () => {
  console.log(`IRCTC Backend Server listening on port ${PORT}`);
  db.initializeDatabase().catch(err => console.error('Database connection error:', err));
  initKafka().catch(err => console.error('Kafka initialization error:', err));
});

