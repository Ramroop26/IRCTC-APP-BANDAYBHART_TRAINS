const mysql = require('mysql2/promise');
require('dotenv').config();

// Create connection configuration
const connectionConfig = {
  host: process.env.DB_HOST || 'localhost',
  user: process.env.DB_USER || 'root',
  password: process.env.DB_PASSWORD || '1234',
  port: parseInt(process.env.DB_PORT || '3306'),
};

let pool;

async function initializeDatabase() {
  try {
    const dbName = process.env.DB_NAME || 'irctc_db';
    const isLocalhost = connectionConfig.host === 'localhost' || connectionConfig.host === '127.0.0.1';

    if (isLocalhost) {
      // 1. Create a temporary connection to create database if not exists
      const tempConnection = await mysql.createConnection(connectionConfig);
      await tempConnection.query(`CREATE DATABASE IF NOT EXISTS \`${dbName}\`;`);
      await tempConnection.end();
      console.log(`Database '${dbName}' verified/created.`);
    }

    // 2. Create the connection pool with the database specified
    pool = mysql.createPool({
      ...connectionConfig,
      database: dbName,
      waitForConnections: true,
      connectionLimit: 10,
      queueLimit: 0,
      ssl: process.env.DB_SSL === 'true' ? { rejectUnauthorized: false } : undefined
    });

    // 3. Create tables
    await createTables();
  } catch (error) {
    console.error('Error during database initialization:', error);
    process.exit(1);
  }
}

async function createTables() {
  const queries = [
    // Users table
    `CREATE TABLE IF NOT EXISTS users (
      email VARCHAR(255) PRIMARY KEY,
      name VARCHAR(255) NOT NULL,
      pin VARCHAR(10) NOT NULL,
      aadhaar VARCHAR(20) NOT NULL,
      mobile VARCHAR(20) NOT NULL,
      created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
    );`,

    // Bookings table
    `CREATE TABLE IF NOT EXISTS bookings (
      pnr VARCHAR(20) PRIMARY KEY,
      train_number VARCHAR(20) NOT NULL,
      train_name VARCHAR(255) NOT NULL,
      source VARCHAR(255) NOT NULL,
      destination VARCHAR(255) NOT NULL,
      departure_time VARCHAR(20) NOT NULL,
      arrival_time VARCHAR(20) NOT NULL,
      journey_date VARCHAR(20) NOT NULL,
      status VARCHAR(50) NOT NULL DEFAULT 'CONFIRMED',
      total_amount DECIMAL(10, 2) NOT NULL,
      payment_mode VARCHAR(100) NOT NULL,
      transaction_id VARCHAR(255) NOT NULL,
      booking_date TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
      user_email VARCHAR(255) NOT NULL,
      FOREIGN KEY (user_email) REFERENCES users(email) ON DELETE CASCADE
    );`,

    // Passengers table
    `CREATE TABLE IF NOT EXISTS passengers (
      id INT AUTO_INCREMENT PRIMARY KEY,
      booking_pnr VARCHAR(20) NOT NULL,
      name VARCHAR(255) NOT NULL,
      age INT NOT NULL,
      gender VARCHAR(20) NOT NULL,
      berth_preference VARCHAR(50) NOT NULL,
      coach VARCHAR(20),
      seat_number VARCHAR(20),
      FOREIGN KEY (booking_pnr) REFERENCES bookings(pnr) ON DELETE CASCADE
    );`,

    // Wallet table
    `CREATE TABLE IF NOT EXISTS wallet (
      user_email VARCHAR(255) PRIMARY KEY,
      balance DECIMAL(10, 2) NOT NULL DEFAULT 5000.00,
      FOREIGN KEY (user_email) REFERENCES users(email) ON DELETE CASCADE
    );`,

    // Wallet transactions table
    `CREATE TABLE IF NOT EXISTS wallet_transactions (
      id VARCHAR(255) PRIMARY KEY,
      user_email VARCHAR(255) NOT NULL,
      amount DECIMAL(10, 2) NOT NULL,
      type VARCHAR(20) NOT NULL,
      description VARCHAR(255) NOT NULL,
      date TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
      FOREIGN KEY (user_email) REFERENCES users(email) ON DELETE CASCADE
    );`
  ];

  for (const query of queries) {
    await pool.query(query);
  }

  console.log('Database tables successfully verified/created.');
}

// Helper query function
async function query(sql, params) {
  if (!pool) {
    throw new Error('Database pool not initialized. Call initializeDatabase first.');
  }
  const [results] = await pool.execute(sql, params);
  return results;
}

module.exports = {
  initializeDatabase,
  query,
  getPool: () => pool
};
