// ============================================
// RideShare AI Pro — Auth Middleware (Supabase)
// ============================================

const { verifyToken } = require('../utils/helpers');
const { UnauthorizedError, ForbiddenError } = require('../utils/errors');
const { supabase } = require('../config/supabase');

/**
 * Authenticate user via JWT token
 */
const authenticate = async (req, res, next) => {
  try {
    const authHeader = req.headers.authorization;
    if (!authHeader || !authHeader.startsWith('Bearer ')) {
      throw new UnauthorizedError('No token provided.');
    }

    const token = authHeader.split(' ')[1];
    let decoded;
    try {
      decoded = verifyToken(token);
    } catch (err) {
      throw new UnauthorizedError(err.name === 'TokenExpiredError' ? 'Token expired.' : 'Invalid token.');
    }

    // Bypass DB check for hardcoded MVP admin
    if (decoded.role === 'admin' && decoded.id === 'admin-123') {
      req.user = { id: 'admin-123', role: 'admin', username: decoded.username };
      return next();
    }

    const { data: user } = await supabase
      .from('users')
      .select('id, phone, role, status')
      .eq('id', decoded.userId || decoded.id)
      .single();

    if (!user) throw new UnauthorizedError('User not found.');
    if (user.status === 'blocked') throw new ForbiddenError('Account blocked.');

    req.user = user;
    next();
  } catch (error) {
    next(error);
  }
};

/**
 * Role-based authorization
 */
const authorize = (...roles) => {
  return (req, res, next) => {
    if (!req.user) return next(new UnauthorizedError('Login required.'));
    if (!roles.includes(req.user.role)) return next(new ForbiddenError('Access denied.'));
    next();
  };
};

module.exports = { authenticate, authorize };
