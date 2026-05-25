const mongoose = require('mongoose');

const passengerSchema = new mongoose.Schema({
  name: { type: String, required: true },
  age: { type: String, required: true },
  gender: { type: String, required: true },
  berth_preference: { type: String, required: true },
  coach: { type: String, required: true },
  seat_number: { type: String, required: true }
});

const bookingSchema = new mongoose.Schema({
  pnr: { type: String, required: true, unique: true },
  train_number: { type: String, required: true },
  train_name: { type: String, required: true },
  source: { type: String, required: true },
  destination: { type: String, required: true },
  departure_time: { type: String, required: true },
  arrival_time: { type: String, required: true },
  journey_date: { type: String, required: true },
  status: { type: String, required: true, default: 'CONFIRMED' },
  total_amount: { type: Number, required: true },
  payment_mode: { type: String, required: true },
  transaction_id: { type: String, required: true },
  user_email: { type: String, required: true, lowercase: true },
  booking_date: { type: Date, default: Date.now },
  passengers: [passengerSchema]
});

module.exports = mongoose.model('Booking', bookingSchema);
