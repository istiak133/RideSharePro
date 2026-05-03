// ============================================
// RideShare AI Pro — Global Error Handler
// Catches all errors and sends formatted response
// ============================================

const { AppError } = require('../utils/errors');

const errorHandler = (err, req, res, next) => {
  // Log error in development
  if (process.env.NODE_ENV === 'development') {
    console.error('❌ Error:', {
      message: err.message,
      status: err.statusCode || 500,
      stack: err.stack?.split('\n').slice(0, 3).join('\n'),
    });
  }

  // Known operational errors (our custom errors)
  if (err instanceof AppError) {
    return res.status(err.statusCode).json({
      success: false,
      message: err.message,
    });
  }

  // PostgreSQL unique constraint violation
  if (err.code === '23505') {
    return res.status(409).json({
      success: false,
      message: 'Duplicate entry. This record already exists.',
    });
  }

  // PostgreSQL foreign key violation
  if (err.code === '23503') {
    return res.status(400).json({
      success: false,
      message: 'Referenced record does not exist.',
    });
  }

  // JWT errors
  if (err.name === 'JsonWebTokenError') {
    return res.status(401).json({
      success: false,
      message: 'Invalid token.',
    });
  }

  // Unknown errors — don't leak details in production
  const statusCode = err.statusCode || 500;
  const message = process.env.NODE_ENV === 'development'
    ? err.message
    : 'Internal server error';

  return res.status(statusCode).json({
    success: false,
    message,
  });
};

module.exports = errorHandler;
