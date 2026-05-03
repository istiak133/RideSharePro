// ============================================
// RideShare AI Pro — Auth Middleware
// Verifies JWT token on protected routes
// ============================================

const { verifyToken } = require('../utils/helpers');
const { UnauthorizedError, ForbiddenError } = require('../utils/errors');
const { query } = require('../config/database');

/**
 * Authenticate user via JWT token
 * Attaches user object to req.user
 */
const authenticate = async (req, res, next) => {
  try {
    // Get token from header
    const authHeader = req.headers.authorization;
    if (!authHeader || !authHeader.startsWith('Bearer ')) {
      throw new UnauthorizedError('No token provided. Please login.');
    }

    const token = authHeader.split(' ')[1];

    // Verify token
    let decoded;
    try {
      decoded = verifyToken(token);
    } catch (err) {
      if (err.name === 'TokenExpiredError') {
        throw new UnauthorizedError('Token expired. Please login again.');
      }
      throw new UnauthorizedError('Invalid token.');
    }

    // Check if user exists and is active
    const result = await query(
      'SELECT id, phone, role, status FROM users WHERE id = $1',
      [decoded.userId]
    );

    if (result.rows.length === 0) {
      throw new UnauthorizedError('User not found.');
    }

    const user = result.rows[0];

    if (user.status === 'blocked') {
      throw new ForbiddenError('Your account has been blocked. Contact support.');
    }

    // Attach user to request
    req.user = {
      id: user.id,
      phone: user.phone,
      role: user.role,
      status: user.status,
    };

    next();
  } catch (error) {
    next(error);
  }
};

/**
 * Restrict access to specific roles
 * Usage: authorize('rider') or authorize('driver') or authorize('rider', 'driver')
 */
const authorize = (...roles) => {
  return (req, res, next) => {
    if (!req.user) {
      return next(new UnauthorizedError('Please login first.'));
    }
    if (!roles.includes(req.user.role)) {
      return next(new ForbiddenError(`Access denied. Required role: ${roles.join(' or ')}`));
    }
    next();
  };
};

module.exports = { authenticate, authorize };
