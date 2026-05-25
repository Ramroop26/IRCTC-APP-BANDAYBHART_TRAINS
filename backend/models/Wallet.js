const mongoose = require('mongoose');

const walletSchema = new mongoose.Schema({
  user_email: { type: String, required: true, unique: true, lowercase: true },
  balance: { type: Number, required: true, default: 0 }
});

module.exports = mongoose.model('Wallet', walletSchema);
