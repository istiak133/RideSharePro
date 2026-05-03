// ============================================
// RideShare AI Pro — Auth Service (Supabase)
// F1: Phone Registration + F19: Driver Registration
// ============================================

const { supabase } = require('../../config/supabase');
const { generateOTP, hashString, compareHash, generateToken } = require('../../utils/helpers');
const { BadRequestError, TooManyRequestsError } = require('../../utils/errors');
const { OTP, ROLES } = require('../../utils/constants');

/**
 * Request OTP
 */
const requestOTP = async (phone) => {
  // Rate limit check
  const { count } = await supabase
    .from('otp_verifications')
    .select('*', { count: 'exact', head: true })
    .eq('phone', phone)
    .gte('created_at', new Date(Date.now() - 3600000).toISOString());

  if (count >= OTP.RATE_LIMIT_PER_HOUR) {
    throw new TooManyRequestsError('Too many OTP requests. Try after 1 hour.');
  }

  // Generate & hash OTP
  const otp = generateOTP(OTP.REGISTRATION_LENGTH);
  const otpHash = await hashString(otp);

  // Delete old OTPs for this phone
  await supabase.from('otp_verifications').delete().eq('phone', phone);

  // Store new OTP
  await supabase.from('otp_verifications').insert({
    phone,
    otp_code: otpHash,
    expires_at: new Date(Date.now() + OTP.EXPIRY_MINUTES * 60000).toISOString(),
  });

  // Dev mode: return OTP (no SMS cost)
  console.log(`📱 [DEV] OTP for ${phone}: ${otp}`);
  return { message: 'OTP sent successfully', devOTP: otp };
};

/**
 * Verify OTP & login/register
 */
const verifyOTP = async (phone, otpCode, role = ROLES.RIDER) => {
  // Get stored OTP
  const { data: otpRecords } = await supabase
    .from('otp_verifications')
    .select('*')
    .eq('phone', phone)
    .order('created_at', { ascending: false })
    .limit(1);

  if (!otpRecords || otpRecords.length === 0) {
    throw new BadRequestError('No OTP found. Request a new one.');
  }

  const otpRecord = otpRecords[0];

  // Check expiry
  if (new Date(otpRecord.expires_at) < new Date()) {
    await supabase.from('otp_verifications').delete().eq('phone', phone);
    throw new BadRequestError('OTP expired. Request a new one.');
  }

  // Check max attempts
  if (otpRecord.attempts >= OTP.MAX_ATTEMPTS) {
    await supabase.from('otp_verifications').delete().eq('phone', phone);
    throw new TooManyRequestsError('Too many wrong attempts. Request a new OTP.');
  }

  // Verify OTP
  const isValid = await compareHash(otpCode, otpRecord.otp_code);

  if (!isValid) {
    await supabase
      .from('otp_verifications')
      .update({ attempts: otpRecord.attempts + 1 })
      .eq('id', otpRecord.id);
    const remaining = OTP.MAX_ATTEMPTS - otpRecord.attempts - 1;
    throw new BadRequestError(`Wrong OTP. ${remaining} attempt(s) remaining.`);
  }

  // OTP correct — delete it
  await supabase.from('otp_verifications').delete().eq('phone', phone);

  // Check if user exists
  const { data: existingUsers } = await supabase
    .from('users')
    .select('*')
    .eq('phone', phone)
    .limit(1);

  let user;
  let isNewUser = false;

  if (existingUsers && existingUsers.length > 0) {
    user = existingUsers[0];
  } else {
    // Create new user
    const { data: newUser, error } = await supabase
      .from('users')
      .insert({ phone, role })
      .select()
      .single();

    if (error) throw new BadRequestError('Failed to create user: ' + error.message);
    user = newUser;
    isNewUser = true;

    // If driver, create driver record
    if (role === ROLES.DRIVER) {
      await supabase.from('drivers').insert({ user_id: user.id });
    }
  }

  // Generate JWT
  const token = generateToken({ userId: user.id, phone: user.phone, role: user.role });

  return {
    token,
    user: { id: user.id, phone: user.phone, role: user.role, status: user.status, isNewUser },
  };
};

/**
 * Get current user profile
 */
const getCurrentUser = async (userId) => {
  const { data: user, error } = await supabase
    .from('users')
    .select('*')
    .eq('id', userId)
    .single();

  if (error || !user) throw new BadRequestError('User not found');

  // If driver, get extra info
  if (user.role === ROLES.DRIVER) {
    const { data: profile } = await supabase
      .from('driver_profiles')
      .select('verification_status, vehicle_type, vehicle_model, registration_number')
      .eq('user_id', userId)
      .single();

    const { data: driverStatus } = await supabase
      .from('drivers')
      .select('status, is_verified, acceptance_rate, total_rides')
      .eq('user_id', userId)
      .single();

    user.driverProfile = profile || null;
    user.driverStatus = driverStatus || null;
  }

  return user;
};

module.exports = { requestOTP, verifyOTP, getCurrentUser };
