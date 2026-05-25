const mongoose = require('mongoose');

async function initializeDatabase() {
  try {
    const uri = process.env.MONGODB_URI || 'mongodb://localhost:27017/irctc';
    await mongoose.connect(uri);
    console.log('✅ Connected to MongoDB successfully.');
  } catch (error) {
    console.error('❌ MongoDB Connection Error:', error);
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
