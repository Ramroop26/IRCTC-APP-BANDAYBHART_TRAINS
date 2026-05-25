const mysql = require('mysql2/promise');

async function testConnection() {
  try {
    console.log('Attempting to connect...');
    const connection = await mysql.createConnection({
      host: 'kafka-393f72a7-ramroopp26-4f33.l.aivencloud.com',
      port: 16429,
      user: 'avnadmin',
      password: 'YOUR_PASSWORD',
      ssl: { rejectUnauthorized: false }
    });
    console.log('SUCCESS! Connected to MySQL database.');
    await connection.end();
  } catch (error) {
    console.error('FAILED to connect:', error.message);
  }
}

testConnection();
