const mongoose = require('mongoose');
require('dotenv').config();

async function updatePin() {
  const uri = process.env.MONGODB_URI;
  try {
    await mongoose.connect(uri);
    console.log('Connected to DB');
    
    const User = require('./models/User');
    const result = await User.updateOne(
      { email: 'ramroopp26@gmail.com' },
      { $set: { pin: '1234', name: 'Ramroop Prajapati' } }
    );
    
    console.log('Update result:', result);
  } catch (error) {
    console.error('Error:', error);
  } finally {
    await mongoose.disconnect();
    console.log('Disconnected from DB');
  }
}

updatePin();
