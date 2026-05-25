const express = require('express');
const cors = require('cors');
const path = require('path');
require('dotenv').config();
const db = require('./db');

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
    // Check if email already registered
    const existing = await db.query('SELECT email FROM users WHERE email = ?', [normalizedEmail]);
    if (existing.length > 0) {
      return res.status(400).json({ success: false, message: 'Email is already registered.' });
    }

    // Insert user
    await db.query(
      'INSERT INTO users (email, name, pin, aadhaar, mobile) VALUES (?, ?, ?, ?, ?)',
      [normalizedEmail, name.trim(), pin, aadhaar, mobile]
    );

    // Initialize wallet with default ₹5000.00
    await db.query('INSERT INTO wallet (user_email, balance) VALUES (?, ?)', [normalizedEmail, 5000.00]);

    // Log initial activation credit transaction
    const txnId = `TXN${Date.now()}`;
    await db.query(
      'INSERT INTO wallet_transactions (id, user_email, amount, type, description) VALUES (?, ?, ?, ?, ?)',
      [txnId, normalizedEmail, 5000.00, 'credit', 'Initial eWallet Activation Credit']
    );

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
    const users = await db.query('SELECT * FROM users WHERE pin = ?', [pin]);
    if (users.length === 0) {
      return res.status(401).json({ success: false, message: 'Invalid PIN.' });
    }

    // Return the matched user
    const user = users[0];
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
    const users = await db.query('SELECT * FROM users WHERE email = ? AND pin = ?', [normalizedEmail, pin]);
    if (users.length === 0) {
      return res.status(401).json({ success: false, message: 'Invalid credentials.' });
    }

    const user = users[0];
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
    const users = await db.query('SELECT * FROM users WHERE email = ?', [email.toLowerCase().trim()]);
    if (users.length === 0) {
      return res.status(404).json({ success: false, message: 'User not found.' });
    }

    const user = users[0];
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
    if (mobile !== undefined) {
      await db.query('UPDATE users SET mobile = ? WHERE email = ?', [mobile, email.toLowerCase().trim()]);
    }
    if (aadhaar !== undefined) {
      await db.query('UPDATE users SET aadhaar = ? WHERE email = ?', [aadhaar, email.toLowerCase().trim()]);
    }

    return res.json({ success: true, message: 'Profile updated successfully.' });
  } catch (error) {
    console.error('Profile update error:', error);
    return res.status(500).json({ success: false, message: 'Internal server error.' });
  }
});

// Check if there are any registered users
app.get('/api/auth/has-users', async (req, res) => {
  try {
    const result = await db.query('SELECT COUNT(*) as count FROM users');
    const count = result[0].count;
    return res.json({ success: true, hasUsers: count > 0 });
  } catch (error) {
    console.error('Has-users check error:', error);
    return res.status(500).json({ success: false, hasUsers: false });
  }
});

// Get the last registered user
app.get('/api/auth/last-user', async (req, res) => {
  try {
    const result = await db.query('SELECT * FROM users ORDER BY created_at DESC LIMIT 1');
    if (result.length === 0) {
      return res.status(404).json({ success: false, message: 'No registered users found.' });
    }
    const user = result[0];
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
    const wallets = await db.query('SELECT balance FROM wallet WHERE user_email = ?', [normalizedEmail]);
    if (wallets.length === 0) {
      return res.status(404).json({ success: false, message: 'Wallet not found.' });
    }

    const transactions = await db.query(
      'SELECT * FROM wallet_transactions WHERE user_email = ? ORDER BY date DESC',
      [normalizedEmail]
    );

    return res.json({
      success: true,
      balance: parseFloat(wallets[0].balance),
      transactions: transactions.map(t => ({
        id: t.id,
        amount: parseFloat(t.amount),
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
    // Add to balance
    await db.query('UPDATE wallet SET balance = balance + ? WHERE user_email = ?', [amount, normalizedEmail]);

    // Log transaction
    const txnId = `TXN${Date.now()}`;
    await db.query(
      'INSERT INTO wallet_transactions (id, user_email, amount, type, description) VALUES (?, ?, ?, ?, ?)',
      [txnId, normalizedEmail, amount, 'credit', 'Add Money to eWallet']
    );

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
    // Check balance
    const wallets = await db.query('SELECT balance FROM wallet WHERE user_email = ?', [normalizedEmail]);
    if (wallets.length === 0) {
      return res.status(404).json({ success: false, message: 'Wallet not found.' });
    }

    const currentBalance = parseFloat(wallets[0].balance);
    if (currentBalance < amount) {
      return res.status(400).json({ success: false, message: 'Insufficient funds.' });
    }

    // Deduct
    await db.query('UPDATE wallet SET balance = balance - ? WHERE user_email = ?', [amount, normalizedEmail]);

    // Log transaction
    const txnId = `TXN${Date.now()}`;
    await db.query(
      'INSERT INTO wallet_transactions (id, user_email, amount, type, description) VALUES (?, ?, ?, ?, ?)',
      [txnId, normalizedEmail, amount, 'debit', `Withdrawal to Bank: ${bankDetails}`]
    );

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
    // 1. Fetch bookings
    const bookings = await db.query(
      'SELECT * FROM bookings WHERE user_email = ? ORDER BY booking_date DESC',
      [normalizedEmail]
    );

    // 2. Fetch passengers for each booking
    const results = [];
    for (const b of bookings) {
      const passengers = await db.query('SELECT * FROM passengers WHERE booking_pnr = ?', [b.pnr]);
      results.push({
        pnr: b.pnr,
        train: {
          number: b.train_number,
          name: b.train_name,
          source: b.source,
          destination: b.destination,
          departureTime: b.departure_time,
          arrivalTime: b.arrival_time,
          classes: ['CC', 'EC', 'GEN', '3A', '2A', '1A'] // Mock classes schema support
        },
        journeyDate: b.journey_date,
        passengers: passengers.map(p => ({
          name: p.name,
          age: p.age,
          gender: p.gender,
          berthPreference: p.berth_preference,
          coach: p.coach,
          seatNumber: p.seat_number
        })),
        status: b.status,
        totalAmount: parseFloat(b.total_amount),
        paymentMode: b.payment_mode,
        transactionId: b.transaction_id,
        bookingDate: b.booking_date,
        bookedSource: b.source,
        bookedDestination: b.destination
      });
    }

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
  const conn = await db.getPool().getConnection();

  try {
    await conn.beginTransaction();

    // 1. If payment mode is eWallet, check balance and deduct
    if (paymentMode === 'IRCTC eWallet') {
      const [wallets] = await conn.query('SELECT balance FROM wallet WHERE user_email = ?', [normalizedEmail]);
      if (wallets.length === 0) {
        throw new Error('Wallet not found.');
      }
      const balance = parseFloat(wallets[0].balance);
      if (balance < totalAmount) {
        return res.status(400).json({ success: false, message: 'Insufficient wallet balance.' });
      }

      // Deduct
      await conn.query('UPDATE wallet SET balance = balance - ? WHERE user_email = ?', [totalAmount, normalizedEmail]);

      // Log transaction
      const txnId = `TXN${Date.now()}`;
      await conn.query(
        'INSERT INTO wallet_transactions (id, user_email, amount, type, description) VALUES (?, ?, ?, ?, ?)',
        [txnId, normalizedEmail, totalAmount, 'debit', `Ticket Booking: PNR Generation (${trainNumber})`]
      );
    }

    // 2. Generate PNR and booking fields
    const pnr = generatePnr();
    const transactionId = `TXN${Date.now()}`;

    // 3. Insert booking
    await conn.query(
      'INSERT INTO bookings (pnr, train_number, train_name, source, destination, departure_time, arrival_time, journey_date, status, total_amount, payment_mode, transaction_id, user_email) VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?)',
      [pnr, trainNumber, trainName, source, destination, departureTime, arrivalTime, journeyDate, 'CONFIRMED', totalAmount, paymentMode, transactionId, normalizedEmail]
    );

    // 4. Assign mock coach/seat numbers and insert passengers
    const coachPrefix = trainName.includes('VANDE') || trainName.includes('SHATABDI') ? 'C' : 'S';
    const coachNum = Math.floor(Math.random() * 6) + 1;
    const coach = `${coachPrefix}${coachNum}`;

    for (const p of passengers) {
      const seatNumber = (Math.floor(Math.random() * 72) + 1).toString();
      await conn.query(
        'INSERT INTO passengers (booking_pnr, name, age, gender, berth_preference, coach, seat_number) VALUES (?, ?, ?, ?, ?, ?, ?)',
        [pnr, p.name, p.age, p.gender, p.berthPreference, coach, seatNumber]
      );
    }

    await conn.commit();
    conn.release();

    return res.json({ success: true, pnr, message: 'Booking created successfully!' });
  } catch (error) {
    await conn.rollback();
    conn.release();
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

  const conn = await db.getPool().getConnection();

  try {
    await conn.beginTransaction();

    // 1. Fetch booking details
    const [bookings] = await conn.query('SELECT * FROM bookings WHERE pnr = ?', [pnr]);
    if (bookings.length === 0) {
      return res.status(404).json({ success: false, message: 'Booking not found.' });
    }

    const booking = bookings[0];
    if (booking.status === 'CANCELLED') {
      return res.status(400).json({ success: false, message: 'Ticket is already cancelled.' });
    }

    // 2. Update booking status
    await conn.query('UPDATE bookings SET status = ? WHERE pnr = ?', ['CANCELLED', pnr]);

    // 3. Count passengers to calculate fee (₹120 per passenger)
    const [passengers] = await conn.query('SELECT id FROM passengers WHERE booking_pnr = ?', [pnr]);
    const passengersCount = passengers.length;
    const cancellationFee = passengersCount * 120.00;
    const totalAmount = parseFloat(booking.total_amount);
    const refundAmount = Math.max(0.0, totalAmount - cancellationFee);

    // 4. If paid via eWallet, refund
    if (booking.payment_mode === 'IRCTC eWallet' && refundAmount > 0) {
      await conn.query('UPDATE wallet SET balance = balance + ? WHERE user_email = ?', [refundAmount, booking.user_email]);

      // Log transaction
      const txnId = `TXN${Date.now()}`;
      await conn.query(
        'INSERT INTO wallet_transactions (id, user_email, amount, type, description) VALUES (?, ?, ?, ?, ?)',
        [txnId, booking.user_email, refundAmount, 'credit', `Cancellation Refund for PNR ${pnr}`]
      );
    }

    await conn.commit();
    conn.release();

    return res.json({ success: true, message: 'Booking cancelled. Refund processed.' });
  } catch (error) {
    await conn.rollback();
    conn.release();
    console.error('Booking cancellation error:', error);
    return res.status(500).json({ success: false, message: 'Internal server error.' });
  }
});


// Catch-all route to serve the frontend index.html for any other requests (for client-side routing)
app.get('*', (req, res) => {
  res.sendFile(path.join(__dirname, 'public', 'index.html'));
});

// Start server after database initialization
const PORT = process.env.PORT || 3000;
db.initializeDatabase().then(() => {
  app.listen(PORT, () => {
    console.log(`IRCTC Backend Server listening on port ${PORT}`);
  });
});
