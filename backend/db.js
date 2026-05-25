// db.js (Mock In-Memory Database)

let db = {
  users: [],
  wallet: [],
  wallet_transactions: [],
  bookings: [],
  passengers: []
};

async function initializeDatabase() {
  console.log('Using IN-MEMORY Mock Database. Data will be lost on restart.');
}

async function executeQuery(sql, params = []) {
  sql = sql.trim().replace(/\s+/g, ' ');
  
  if (sql.includes('SELECT email FROM users WHERE email = ?')) {
    return db.users.filter(u => u.email === params[0]);
  }
  if (sql.includes('INSERT INTO users')) {
    db.users.push({ email: params[0], name: params[1], pin: params[2], aadhaar: params[3], mobile: params[4], created_at: new Date() });
    return [];
  }
  if (sql.includes('INSERT INTO wallet (user_email, balance)')) {
    db.wallet.push({ user_email: params[0], balance: params[1] });
    return [];
  }
  if (sql.includes('INSERT INTO wallet_transactions')) {
    db.wallet_transactions.push({ id: params[0], user_email: params[1], amount: params[2], type: params[3], description: params[4], date: new Date() });
    return [];
  }
  if (sql.includes('SELECT * FROM users WHERE pin = ?')) {
    return db.users.filter(u => u.pin === params[0]);
  }
  if (sql.includes('SELECT * FROM users WHERE email = ? AND pin = ?')) {
    return db.users.filter(u => u.email === params[0] && u.pin === params[1]);
  }
  if (sql.includes('SELECT * FROM users WHERE email = ?')) {
    return db.users.filter(u => u.email === params[0]);
  }
  if (sql.includes('UPDATE users SET mobile')) {
    const user = db.users.find(u => u.email === params[1]);
    if (user) user.mobile = params[0];
    return [];
  }
  if (sql.includes('UPDATE users SET aadhaar')) {
    const user = db.users.find(u => u.email === params[1]);
    if (user) user.aadhaar = params[0];
    return [];
  }
  if (sql.includes('SELECT COUNT(*) as count FROM users')) {
    return [{ count: db.users.length }];
  }
  if (sql.includes('ORDER BY created_at DESC LIMIT 1')) {
    if (db.users.length === 0) return [];
    return [db.users[db.users.length - 1]];
  }
  if (sql.includes('SELECT balance FROM wallet WHERE user_email = ?')) {
    return db.wallet.filter(w => w.user_email === params[0]);
  }
  if (sql.includes('SELECT * FROM wallet_transactions')) {
    return db.wallet_transactions.filter(t => t.user_email === params[0]).reverse();
  }
  if (sql.includes('UPDATE wallet SET balance = balance + ?')) {
    const w = db.wallet.find(w => w.user_email === params[1]);
    if (w) w.balance = parseFloat(w.balance) + parseFloat(params[0]);
    return [];
  }
  if (sql.includes('UPDATE wallet SET balance = balance - ?')) {
    const w = db.wallet.find(w => w.user_email === params[1]);
    if (w) w.balance = parseFloat(w.balance) - parseFloat(params[0]);
    return [];
  }
  if (sql.includes('SELECT * FROM bookings WHERE user_email = ?')) {
    return db.bookings.filter(b => b.user_email === params[0]).reverse();
  }
  if (sql.includes('SELECT * FROM passengers WHERE booking_pnr = ?')) {
    return db.passengers.filter(p => p.booking_pnr === params[0]);
  }
  if (sql.includes('INSERT INTO bookings')) {
    db.bookings.push({
      pnr: params[0], train_number: params[1], train_name: params[2], source: params[3], destination: params[4],
      departure_time: params[5], arrival_time: params[6], journey_date: params[7], status: params[8], total_amount: params[9],
      payment_mode: params[10], transaction_id: params[11], user_email: params[12], booking_date: new Date()
    });
    return [];
  }
  if (sql.includes('INSERT INTO passengers')) {
    db.passengers.push({
      id: db.passengers.length + 1, booking_pnr: params[0], name: params[1], age: params[2], gender: params[3],
      berth_preference: params[4], coach: params[5], seat_number: params[6]
    });
    return [];
  }
  if (sql.includes('SELECT * FROM bookings WHERE pnr = ?')) {
    return db.bookings.filter(b => b.pnr === params[0]);
  }
  if (sql.includes('UPDATE bookings SET status = ? WHERE pnr = ?')) {
    const b = db.bookings.find(b => b.pnr === params[1]);
    if (b) b.status = params[0];
    return [];
  }
  if (sql.includes('SELECT id FROM passengers WHERE booking_pnr = ?')) {
    return db.passengers.filter(p => p.booking_pnr === params[0]);
  }

  console.log('UNHANDLED QUERY:', sql);
  return [];
}

async function query(sql, params) {
  return executeQuery(sql, params);
}

const mockPool = {
  getConnection: async () => ({
    query: async (sql, params) => {
      const res = await executeQuery(sql, params);
      return [res, []];
    },
    beginTransaction: async () => {},
    commit: async () => {},
    rollback: async () => {},
    release: () => {}
  })
};

module.exports = {
  initializeDatabase,
  query,
  getPool: () => mockPool
};
