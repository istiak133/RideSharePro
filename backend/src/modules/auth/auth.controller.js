// ============================================
// RideShare AI Pro — Auth Controller
// HTTP request handlers for auth routes
// ============================================

const authService = require('./auth.service');
const { isValidBDPhone } = require('../../utils/helpers');
const { successResponse, errorResponse } = require('../../utils/helpers');
const { BadRequestError } = require('../../utils/errors');
const { ROLES } = require('../../utils/constants');

/**
 * POST /api/auth/request-otp
 * Body: { phone: "01XXXXXXXXX" }
 */
const requestOTP = async (req, res, next) => {
  try {
    const { phone } = req.body;

    // Validate phone
    if (!phone) {
      throw new BadRequestError('Phone number is required.');
    }
    if (!isValidBDPhone(phone)) {
      throw new BadRequestError('Invalid phone number. Must be 11 digits starting with 01.');
    }

    const result = await authService.requestOTP(phone);
    return successResponse(res, result, 'OTP sent successfully');
  } catch (error) {
    next(error);
  }
};

/**
 * POST /api/auth/verify-otp
 * Body: { phone: "01XXXXXXXXX", otp: "123456", role: "rider"|"driver" }
 */
const verifyOTP = async (req, res, next) => {
  try {
    const { phone, otp, role } = req.body;

    // Validate inputs
    if (!phone || !otp) {
      throw new BadRequestError('Phone and OTP are required.');
    }
    if (!isValidBDPhone(phone)) {
      throw new BadRequestError('Invalid phone number.');
    }
    if (otp.length !== 6 || !/^\d+$/.test(otp)) {
      throw new BadRequestError('OTP must be 6 digits.');
    }

    // Validate role if provided
    const validRole = role && Object.values(ROLES).includes(role) ? role : ROLES.RIDER;

    const result = await authService.verifyOTP(phone, otp, validRole);
    return successResponse(res, result, result.user.isNewUser ? 'Account created successfully' : 'Login successful');
  } catch (error) {
    next(error);
  }
};

/**
 * GET /api/auth/me
 * Header: Authorization: Bearer <token>
 */
const getMe = async (req, res, next) => {
  try {
    const user = await authService.getCurrentUser(req.user.id);
    return successResponse(res, { user }, 'Profile fetched');
  } catch (error) {
    next(error);
  }
};

module.exports = {
  requestOTP,
  verifyOTP,
  getMe,
};
