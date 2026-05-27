const mongoose = require('mongoose');

async function initializeDatabase() {
  const uri = process.env.MONGODB_URI || 'mongodb://localhost:27017/irctc';
  
  mongoose.connection.on('connected', () => console.log('✅ Mongoose connected to DB'));
  mongoose.connection.on('error', (err) => console.error('❌ Mongoose connection error:', err));
  mongoose.connection.on('disconnected', () => console.log('⚠️ Mongoose disconnected'));

  try {
    await mongoose.connect(uri, {
      serverSelectionTimeoutMS: 15000, // Increased for Cloud Run cold starts
      socketTimeoutMS: 45000,
    });
    console.log('✅ Connected to MongoDB successfully.');
  } catch (error) {
    console.error('❌ MongoDB Initial Connection Error:', error);
  }
}

// Keeping this so existing imports don't crash, but it won't be used
const mockPool = {
  getConnection: async () => ({
    query: async () => [[]],
    beginTransaction: async () => {},
    commit: async () => {},
    rollback: async () => {},
    release: () => {}
  })
};

module.exports = {
  initializeDatabase,
  getPool: () => mockPool
};
