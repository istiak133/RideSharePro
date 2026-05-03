// ============================================
// RideShare AI Pro — Helper Utilities
// ============================================

const bcrypt = require('bcryptjs');
const jwt = require('jsonwebtoken');
const { v4: uuidv4 } = require('uuid');

/**
 * Generate a random numeric OTP
 * @param {number} length - Number of digits (4 or 6)
 * @returns {string} OTP string
 */
const generateOTP = (length = 6) => {
  const min = Math.pow(10, length - 1);
  const max = Math.pow(10, length) - 1;
  return String(Math.floor(min + Math.random() * (max - min + 1)));
};

/**
 * Hash a string (OTP, password) using bcrypt
 * @param {string} plainText
 * @returns {Promise<string>} Hashed string
 */
const hashString = async (plainText) => {
  const salt = await bcrypt.genSalt(10);
  return bcrypt.hash(plainText, salt);
};

/**
 * Compare plain text with bcrypt hash
 * @param {string} plainText
 * @param {string} hash
 * @returns {Promise<boolean>}
 */
const compareHash = async (plainText, hash) => {
  return bcrypt.compare(plainText, hash);
};

/**
 * Generate JWT token
 * @param {Object} payload - Data to encode in token
 * @param {string} expiresIn - Token expiry (default from env)
 * @returns {string} JWT token
 */
const generateToken = (payload, expiresIn = process.env.JWT_EXPIRES_IN || '7d') => {
  return jwt.sign(payload, process.env.JWT_SECRET, { expiresIn });
};

/**
 * Verify JWT token
 * @param {string} token
 * @returns {Object} Decoded payload
 */
const verifyToken = (token) => {
  return jwt.verify(token, process.env.JWT_SECRET);
};

/**
 * Generate UUID
 * @returns {string} UUID v4
 */
const generateUUID = () => uuidv4();

/**
 * Validate Bangladeshi phone number
 * Must be 11 digits, starting with 01
 * @param {string} phone
 * @returns {boolean}
 */
const isValidBDPhone = (phone) => {
  if (!phone || typeof phone !== 'string') return false;
  const regex = /^01[3-9]\d{8}$/;
  return regex.test(phone);
};

/**
 * Validate email format
 * @param {string} email
 * @returns {boolean}
 */
const isValidEmail = (email) => {
  if (!email) return true; // email is optional
  const regex = /^[^\s@]+@[^\s@]+\.[^\s@]+$/;
  return regex.test(email);
};

/**
 * Check if user is 18+ years old
 * @param {string} dateOfBirth - YYYY-MM-DD format
 * @returns {boolean}
 */
const isOver18 = (dateOfBirth) => {
  const dob = new Date(dateOfBirth);
  const today = new Date();
  let age = today.getFullYear() - dob.getFullYear();
  const monthDiff = today.getMonth() - dob.getMonth();
  if (monthDiff < 0 || (monthDiff === 0 && today.getDate() < dob.getDate())) {
    age--;
  }
  return age >= 18;
};

/**
 * Round to nearest 5 (for fare calculation)
 * @param {number} num
 * @returns {number}
 */
const roundToNearest5 = (num) => {
  return Math.round(num / 5) * 5;
};

/**
 * Calculate platform commission and driver earning
 * @param {number} totalFare
 * @returns {{ platformCommission: number, driverEarning: number }}
 */
const calculateCommission = (totalFare) => {
  const platformCommission = parseFloat((totalFare * 0.25).toFixed(2));
  const driverEarning = parseFloat((totalFare * 0.75).toFixed(2));
  return { platformCommission, driverEarning };
};

/**
 * Format API success response
 */
const successResponse = (res, data, message = 'Success', statusCode = 200) => {
  return res.status(statusCode).json({
    success: true,
    message,
    data,
  });
};

/**
 * Format API error response
 */
const errorResponse = (res, message = 'Something went wrong', statusCode = 500, errors = null) => {
  const response = {
    success: false,
    message,
  };
  if (errors) response.errors = errors;
  return res.status(statusCode).json(response);
};

module.exports = {
  generateOTP,
  hashString,
  compareHash,
  generateToken,
  verifyToken,
  generateUUID,
  isValidBDPhone,
  isValidEmail,
  isOver18,
  roundToNearest5,
  calculateCommission,
  successResponse,
  errorResponse,
};
