const { Kafka } = require('kafkajs');
require('dotenv').config();

const kafka = new Kafka({
  clientId: 'irctc-backend',
  brokers: [process.env.KAFKA_BROKER],
  ssl: true,
  sasl: {
    mechanism: 'scram-sha-256', // Aiven defaults to scram-sha-256 or scram-sha-512, sometimes plain. scram-sha-256 is safest starting point.
    username: process.env.KAFKA_USERNAME,
    password: process.env.KAFKA_PASSWORD,
  },
  connectionTimeout: 10000,
});

const producer = kafka.producer();
const consumer = kafka.consumer({ groupId: 'irctc-group' });

async function initKafka() {
  try {
    await producer.connect();
    console.log('✅ Connected to Aiven Kafka Producer successfully');
    
    // Example: Connecting consumer (can be removed if not consuming here)
    await consumer.connect();
    console.log('✅ Connected to Aiven Kafka Consumer successfully');
  } catch (error) {
    console.error('❌ Error connecting to Kafka:', error);
  }
}

async function sendBookingEvent(bookingDetails) {
  try {
    await producer.send({
      topic: 'train-bookings', // Make sure to create this topic in Aiven Console
      messages: [
        { value: JSON.stringify(bookingDetails) },
      ],
    });
    console.log(`✅ Sent booking event to Kafka for PNR: ${bookingDetails.pnr}`);
  } catch (error) {
    console.error(`❌ Failed to send booking event to Kafka for PNR: ${bookingDetails.pnr}`, error);
  }
}

module.exports = {
  kafka,
  producer,
  consumer,
  initKafka,
  sendBookingEvent,
};
