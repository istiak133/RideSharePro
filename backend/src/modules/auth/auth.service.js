// ============================================
// RideShare AI Pro — Auth Service
// Business logic for OTP registration/login
// Feature 1: Phone-Based Registration
// Feature 19: Driver Registration
// ============================================

const { query } = require('../../config/database');
const { generateOTP, hashString, compareHash, generateToken } = require('../../utils/helpers');
const { BadRequestError, TooManyRequestsError, UnauthorizedError } = require('../../utils/errors');
const { OTP, ROLES } = require('../../utils/constants');

/**
 * Request OTP — sends OTP to phone number
 * In development: returns OTP in response (no SMS)
 * In production: sends via Twilio
 */
const requestOTP = async (phone) => {
  // Check rate limit: max 5 OTP requests per phone per hour
  const rateLimitCheck = await query(
    `SELECT COUNT(*) as count FROM otp_verifications 
     WHERE phone = $1 AND created_at > NOW() - INTERVAL '1 hour'`,
    [phone]
  );

  if (parseInt(rateLimitCheck.rows[0].count) >= OTP.RATE_LIMIT_PER_HOUR) {
    throw new TooManyRequestsError('Too many OTP requests. Please try again after 1 hour.');
  }

  // Generate 6-digit OTP
  const otp = generateOTP(OTP.REGISTRATION_LENGTH);
  const otpHash = await hashString(otp);

  // Delete any existing OTP for this phone
  await query('DELETE FROM otp_verifications WHERE phone = $1', [phone]);

  // Store hashed OTP with expiry
  await query(
    `INSERT INTO otp_verifications (phone, otp_code, expires_at)
     VALUES ($1, $2, NOW() + INTERVAL '${OTP.EXPIRY_MINUTES} minutes')`,
    [phone, otpHash]
  );

  // In development: return OTP directly (no SMS cost)
  // In production: send via Twilio
  if (process.env.NODE_ENV === 'development') {
    console.log(`📱 [DEV] OTP for ${phone}: ${otp}`);
    return { message: 'OTP sent successfully', devOTP: otp };
  }

  // TODO: Twilio SMS sending for production
  // await twilioClient.messages.create({ body: `Your RideShare code: ${otp}`, to: phone, from: TWILIO_NUMBER });

  return { message: 'OTP sent successfully' };
};

/**
 * Verify OTP — creates account if new, logs in if existing
 * Returns JWT token
 */
const verifyOTP = async (phone, otpCode, role = ROLES.RIDER) => {
  // Get stored OTP
  const otpResult = await query(
    `SELECT * FROM otp_verifications 
     WHERE phone = $1 ORDER BY created_at DESC LIMIT 1`,
    [phone]
  );

  if (otpResult.rows.length === 0) {
    throw new BadRequestError('No OTP found. Please request a new one.');
  }

  const otpRecord = otpResult.rows[0];

  // Check if OTP expired
  if (new Date(otpRecord.expires_at) < new Date()) {
    await query('DELETE FROM otp_verifications WHERE phone = $1', [phone]);
    throw new BadRequestError('OTP expired. Please request a new one.');
  }

  // Check max attempts
  if (otpRecord.attempts >= OTP.MAX_ATTEMPTS) {
    await query('DELETE FROM otp_verifications WHERE phone = $1', [phone]);
    throw new TooManyRequestsError('Too many wrong attempts. Please request a new OTP.');
  }

  // Verify OTP
  const isValid = await compareHash(otpCode, otpRecord.otp_code);

  if (!isValid) {
    // Increment attempt count
    await query(
      'UPDATE otp_verifications SET attempts = attempts + 1 WHERE id = $1',
      [otpRecord.id]
    );
    const remaining = OTP.MAX_ATTEMPTS - otpRecord.attempts - 1;
    throw new BadRequestError(`Wrong OTP. ${remaining} attempt(s) remaining.`);
  }

  // OTP is correct — delete it
  await query('DELETE FROM otp_verifications WHERE phone = $1', [phone]);

  // Check if user already exists
  let userResult = await query('SELECT * FROM users WHERE phone = $1', [phone]);
  let user;
  let isNewUser = false;

  if (userResult.rows.length === 0) {
    // Create new user
    const newUser = await query(
      `INSERT INTO users (phone, role) VALUES ($1, $2) RETURNING *`,
      [phone, role]
    );
    user = newUser.rows[0];
    isNewUser = true;

    // If driver, create driver record too
    if (role === ROLES.DRIVER) {
      await query(
        `INSERT INTO drivers (user_id) VALUES ($1)`,
        [user.id]
      );
    }
  } else {
    user = userResult.rows[0];
  }

  // Generate JWT token
  const token = generateToken({
    userId: user.id,
    phone: user.phone,
    role: user.role,
  });

  return {
    token,
    user: {
      id: user.id,
      phone: user.phone,
      role: user.role,
      status: user.status,
      isNewUser,
    },
  };
};

/**
 * Get current user's full profile
 */
const getCurrentUser = async (userId) => {
  const result = await query(
    `SELECT u.id, u.phone, u.role, u.status, u.full_name, u.photo_url,
            u.date_of_birth, u.email, u.emergency_contact_name,
            u.emergency_contact_phone, u.language_preference,
            u.average_rating, u.total_ratings, u.created_at
     FROM users u WHERE u.id = $1`,
    [userId]
  );

  if (result.rows.length === 0) {
    throw new BadRequestError('User not found');
  }

  const user = result.rows[0];

  // If driver, get verification status too
  if (user.role === ROLES.DRIVER) {
    const driverProfile = await query(
      `SELECT verification_status, vehicle_type, vehicle_model, registration_number
       FROM driver_profiles WHERE user_id = $1`,
      [userId]
    );

    const driverStatus = await query(
      `SELECT status, is_verified, acceptance_rate, total_rides
       FROM drivers WHERE user_id = $1`,
      [userId]
    );

    user.driverProfile = driverProfile.rows[0] || null;
    user.driverStatus = driverStatus.rows[0] || null;
  }

  return user;
};

module.exports = {
  requestOTP,
  verifyOTP,
  getCurrentUser,
};
