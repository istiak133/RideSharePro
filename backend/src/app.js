// ============================================
// RideShare AI Pro — Express App Entry Point
// All 39 features served from here
// ============================================

require('dotenv').config();

const express = require('express');
const cors = require('cors');
const helmet = require('helmet');
const morgan = require('morgan');
const errorHandler = require('./middleware/errorHandler');

// Import all route modules
const authRoutes = require('./modules/auth/auth.routes');
const usersRoutes = require('./modules/users/users.routes');
const ridesRoutes = require('./modules/rides/rides.routes');
const paymentsRoutes = require('./modules/payments/payments.routes');
const ratingsRoutes = require('./modules/ratings/ratings.routes');
const notificationsRoutes = require('./modules/notifications/notifications.routes');
const adminRoutes = require('./modules/admin/admin.routes');

const app = express();
const PORT = process.env.PORT || 5000;

// ── Middleware ─────────────────────────────────
app.use(helmet());
app.use(cors());
app.use(express.json({ limit: '10mb' }));
if (process.env.NODE_ENV === 'development') app.use(morgan('dev'));

// ── Health Check ──────────────────────────────
app.get('/api/health', (req, res) => {
  res.json({ success: true, message: '🚀 RideShare AI Pro API running!', env: process.env.NODE_ENV });
});

// ── API Routes ────────────────────────────────
app.use('/api/auth', authRoutes);           // F1, F19
app.use('/api/users', usersRoutes);         // F2, F20, F21
app.use('/api/rides', ridesRoutes);         // F3-F11, F22-F29, F31
app.use('/api/payments', paymentsRoutes);   // F13, F14, F30
app.use('/api/ratings', ratingsRoutes);     // F16
app.use('/api/notifications', notificationsRoutes); // F17
app.use('/api/admin', adminRoutes);         // F33-F38, F42-F44

// ── 404 ───────────────────────────────────────
app.use((req, res, next) => {
  res.status(404).json({ success: false, message: `Route ${req.originalUrl} not found` });
});

// ── Error Handler ─────────────────────────────
app.use(errorHandler);

// ── Start ─────────────────────────────────────
app.listen(PORT, () => {
  console.log(`\n🚀 RideShare AI Pro API | Port ${PORT} | ${process.env.NODE_ENV}\n`);
  console.log('Endpoints:');
  console.log('  POST /api/auth/request-otp');
  console.log('  POST /api/auth/verify-otp');
  console.log('  GET  /api/auth/me');
  console.log('  PUT  /api/users/profile');
  console.log('  POST /api/users/driver/documents');
  console.log('  POST /api/rides');
  console.log('  POST /api/rides/fare-estimate');
  console.log('  POST /api/rides/:id/accept');
  console.log('  POST /api/rides/:id/verify-otp');
  console.log('  PUT  /api/rides/:id/start');
  console.log('  PUT  /api/rides/:id/complete');
  console.log('  POST /api/payments/cash');
  console.log('  POST /api/ratings');
  console.log('  POST /api/admin/login');
  console.log('  GET  /api/admin/dashboard');
  console.log('  ...and more\n');
});

module.exports = app;
