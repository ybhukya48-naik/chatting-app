require('dotenv').config();
const express = require('express');
const http = require('http');
const { Server } = require('socket.io');
const cors = require('cors');
const { Pool } = require('pg');

const app = express();
app.use(cors());

// Health check route
app.get('/', (req, res) => {
  res.json({
    status: 'online',
    database: dbConnected ? 'connected' : 'limited_mode',
    time: new Date().toISOString(),
    message: 'WebSocket Server is running'
  });
});

const server = http.createServer(app);
const io = new Server(server, {
  cors: {
    origin: "*",
    methods: ["GET", "POST"]
  }
});

// Neon DB Connection
const pool = new Pool({
  connectionString: process.env.DATABASE_URL,
  ssl: {
    rejectUnauthorized: false
  }
});

let dbConnected = false;
const inMemoryMessages = {}; // Fallback storage

// Initialize Database Schema
async function initDb() {
  try {
    const client = await pool.connect();
    dbConnected = true;
    console.log('Successfully connected to Neon DB');
    
    await client.query(`
      CREATE TABLE IF NOT EXISTS users (
        id TEXT PRIMARY KEY,
        name TEXT,
        phone TEXT,
        last_seen BIGINT
      );

      CREATE TABLE IF NOT EXISTS messages (
        id TEXT PRIMARY KEY,
        chat_id TEXT NOT NULL,
        sender_id TEXT NOT NULL,
        text TEXT NOT NULL,
        timestamp BIGINT NOT NULL,
        type INTEGER DEFAULT 0,
        is_encrypted BOOLEAN DEFAULT FALSE,
        is_read BOOLEAN DEFAULT FALSE
      );
      
      CREATE INDEX IF NOT EXISTS idx_chat_id ON messages(chat_id);
      CREATE INDEX IF NOT EXISTS idx_user_phone ON users(phone);
    `);
    client.release();
    console.log('Neon DB schema initialized');
  } catch (err) {
    dbConnected = false;
    console.error('Neon DB Connection Failed:', err.message);
    console.log('System will operate in limited mode using in-memory storage.');
  }
}

initDb();

io.on('connection', (socket) => {
  console.log('User connected:', socket.id);

  // Sync user profile
  socket.on('sync_profile', async (userData) => {
    const { id, name, phone } = userData;
    console.log(`Syncing profile for user: ${name} (${id})`);
    
    if (dbConnected) {
      try {
        await pool.query(
          'INSERT INTO users (id, name, phone, last_seen) VALUES ($1, $2, $3, $4) ON CONFLICT (id) DO UPDATE SET name = $2, phone = $3, last_seen = $4',
          [id, name, phone, Date.now()]
        );
      } catch (err) {
        console.error('Error syncing user to Neon:', err.message);
      }
    }
  });

  socket.on('join_chat', async (chatId) => {
    socket.join(chatId);
    console.log(`User joined chat: ${chatId}`);
    
    if (dbConnected) {
      try {
        const result = await pool.query(
          'SELECT * FROM messages WHERE chat_id = $1 ORDER BY timestamp ASC',
          [chatId]
        );
        
        const messages = result.rows.map(row => ({
          id: row.id,
          senderId: row.sender_id,
          text: row.text,
          timestamp: parseInt(row.timestamp),
          type: row.type,
          isEncrypted: row.is_encrypted,
          isRead: row.is_read
        }));
        
        socket.emit('previous_messages', messages);
      } catch (err) {
        console.error('Error fetching messages from Neon:', err.message);
        socket.emit('previous_messages', []);
      }
    } else {
      // Fallback to in-memory for this session
      socket.emit('previous_messages', inMemoryMessages[chatId] || []);
    }
  });

  socket.on('send_message', async (data) => {
    const { chatId, message } = data;
    
    if (dbConnected) {
      try {
        await pool.query(
          'INSERT INTO messages (id, chat_id, sender_id, text, timestamp, type, is_encrypted, is_read) VALUES ($1, $2, $3, $4, $5, $6, $7, $8)',
          [
            message.id,
            chatId,
            message.senderId,
            message.text,
            message.timestamp,
            message.type || 0,
            message.isEncrypted || false,
            message.isRead || false
          ]
        );
      } catch (err) {
        console.error('Error persisting to Neon:', err.message);
      }
    } else {
      // Store in memory if DB is down
      if (!inMemoryMessages[chatId]) inMemoryMessages[chatId] = [];
      inMemoryMessages[chatId].push(message);
    }
    
    io.to(chatId).emit('receive_message', message);
  });

  socket.on('disconnect', () => {
    console.log('User disconnected:', socket.id);
  });
});

const PORT = process.env.PORT || 3000;
server.listen(PORT, '0.0.0.0', () => {
  console.log(`----------------------------------------`);
  console.log(`SERVER RUNNING ON PORT: ${PORT}`);
  console.log(`LOCAL ACCESS: http://localhost:${PORT}`);
  console.log(`NETWORK ACCESS: http://192.168.7.4:${PORT}`);
  console.log(`----------------------------------------`);
});
