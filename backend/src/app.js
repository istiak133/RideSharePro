// ============================================
// RideShare AI Pro — Express App Entry Point
// ============================================

require('dotenv').config();

const express = require('express');
const cors = require('cors');
const helmet = require('helmet');
const morgan = require('morgan');

const errorHandler = require('./middleware/errorHandler');
const { testConnection } = require('./config/database');

// Import route modules
const authRoutes = require('./modules/auth/auth.routes');
const usersRoutes = require('./modules/users/users.routes');

const app = express();
const PORT = process.env.PORT || 5000;

// ── Middleware ─────────────────────────────────
app.use(helmet());                        // Security headers
app.use(cors());                          // Allow cross-origin requests
app.use(express.json({ limit: '10mb' })); // Parse JSON bodies
app.use(express.urlencoded({ extended: true }));

// Request logging (dev only)
if (process.env.NODE_ENV === 'development') {
  app.use(morgan('dev'));
}

// ── Health Check ──────────────────────────────
app.get('/api/health', (req, res) => {
  res.json({
    success: true,
    message: '🚀 RideShare AI Pro API is running!',
    version: '1.0.0',
    environment: process.env.NODE_ENV,
    timestamp: new Date().toISOString(),
  });
});

// ── API Routes ────────────────────────────────
app.use('/api/auth', authRoutes);
app.use('/api/users', usersRoutes);

// Future route modules (uncomment when implemented):
// app.use('/api/rides', ridesRoutes);
// app.use('/api/payments', paymentsRoutes);
// app.use('/api/ratings', ratingsRoutes);
// app.use('/api/notifications', notificationsRoutes);
// app.use('/api/admin', adminRoutes);

// ── 404 Handler ───────────────────────────────
app.use('*', (req, res) => {
  res.status(404).json({
    success: false,
    message: `Route ${req.originalUrl} not found`,
  });
});

// ── Global Error Handler ──────────────────────
app.use(errorHandler);

// ── Start Server ──────────────────────────────
const startServer = async () => {
  // Test database connection first
  const dbConnected = await testConnection();

  if (!dbConnected) {
    console.error('❌ Cannot start server without database connection.');
    console.log('💡 Make sure PostgreSQL is running and DATABASE_URL is correct in .env');
    process.exit(1);
  }

  app.listen(PORT, () => {
    console.log(`
╔═══════════════════════════════════════════════╗
║   🚀 RideShare AI Pro API Server             ║
║   Port: ${PORT}                                ║
║   Env:  ${process.env.NODE_ENV || 'development'}                        ║
║   DB:   Connected ✅                          ║
╚═══════════════════════════════════════════════╝
    `);
    console.log('📌 Available endpoints:');
    console.log('   GET  /api/health');
    console.log('   POST /api/auth/request-otp');
    console.log('   POST /api/auth/verify-otp');
    console.log('   GET  /api/auth/me');
    console.log('   PUT  /api/users/profile');
    console.log('   PUT  /api/users/profile/photo');
    console.log('   POST /api/users/driver/documents');
    console.log('   GET  /api/users/driver/verification-status');
    console.log('');
  });
};

startServer();

module.exports = app;
