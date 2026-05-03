// ============================================
// RideShare AI Pro — Users Service
// Business logic for profile management
// Feature 2: User Profile Management
// Feature 20: Document Upload & Verification
// ============================================

const { query } = require('../../config/database');
const { BadRequestError, NotFoundError } = require('../../utils/errors');
const { isValidEmail, isOver18 } = require('../../utils/helpers');
const { ROLES, VERIFICATION_STATUS } = require('../../utils/constants');

/**
 * Update user profile (rider or driver basic info)
 */
const updateProfile = async (userId, profileData) => {
  const { full_name, date_of_birth, email, emergency_contact_name, emergency_contact_phone, language_preference } = profileData;

  // Validation
  if (full_name && full_name.trim().length < 3) {
    throw new BadRequestError('Name must be at least 3 characters.');
  }
  if (date_of_birth && !isOver18(date_of_birth)) {
    throw new BadRequestError('You must be at least 18 years old.');
  }
  if (email && !isValidEmail(email)) {
    throw new BadRequestError('Invalid email format.');
  }

  // Build dynamic UPDATE query
  const fields = [];
  const values = [];
  let paramIndex = 1;

  if (full_name) { fields.push(`full_name = $${paramIndex++}`); values.push(full_name.trim()); }
  if (date_of_birth) { fields.push(`date_of_birth = $${paramIndex++}`); values.push(date_of_birth); }
  if (email !== undefined) { fields.push(`email = $${paramIndex++}`); values.push(email); }
  if (emergency_contact_name !== undefined) { fields.push(`emergency_contact_name = $${paramIndex++}`); values.push(emergency_contact_name); }
  if (emergency_contact_phone !== undefined) { fields.push(`emergency_contact_phone = $${paramIndex++}`); values.push(emergency_contact_phone); }
  if (language_preference) { fields.push(`language_preference = $${paramIndex++}`); values.push(language_preference); }

  if (fields.length === 0) {
    throw new BadRequestError('No fields to update.');
  }

  fields.push(`updated_at = NOW()`);
  values.push(userId);

  const result = await query(
    `UPDATE users SET ${fields.join(', ')} WHERE id = $${paramIndex} RETURNING 
     id, phone, role, status, full_name, photo_url, date_of_birth, email,
     emergency_contact_name, emergency_contact_phone, language_preference, updated_at`,
    values
  );

  if (result.rows.length === 0) {
    throw new NotFoundError('User not found.');
  }

  return result.rows[0];
};

/**
 * Update profile photo URL
 */
const updateProfilePhoto = async (userId, photoUrl) => {
  const result = await query(
    `UPDATE users SET photo_url = $1, updated_at = NOW() WHERE id = $2 
     RETURNING id, photo_url`,
    [photoUrl, userId]
  );

  if (result.rows.length === 0) {
    throw new NotFoundError('User not found.');
  }

  return result.rows[0];
};

/**
 * Submit driver documents (NID, license, vehicle, bank)
 */
const submitDriverDocuments = async (userId, docData) => {
  const {
    nid_front_url, nid_back_url, license_url,
    vehicle_type, vehicle_model, vehicle_year, registration_number, vehicle_photo_url,
    account_holder_name, account_number, bank_name, branch_name, routing_number,
  } = docData;

  // Verify user is a driver
  const userResult = await query('SELECT role FROM users WHERE id = $1', [userId]);
  if (userResult.rows.length === 0) throw new NotFoundError('User not found.');
  if (userResult.rows[0].role !== ROLES.DRIVER) {
    throw new BadRequestError('Only drivers can submit documents.');
  }

  // Upsert driver_profiles (insert or update if exists)
  const existingDoc = await query('SELECT id FROM driver_profiles WHERE user_id = $1', [userId]);

  let result;
  if (existingDoc.rows.length > 0) {
    // Update existing — increment resubmission count
    result = await query(
      `UPDATE driver_profiles SET
        nid_front_url = COALESCE($1, nid_front_url),
        nid_back_url = COALESCE($2, nid_back_url),
        license_url = COALESCE($3, license_url),
        vehicle_type = COALESCE($4, vehicle_type),
        vehicle_model = COALESCE($5, vehicle_model),
        vehicle_year = COALESCE($6, vehicle_year),
        registration_number = COALESCE($7, registration_number),
        vehicle_photo_url = COALESCE($8, vehicle_photo_url),
        account_holder_name = COALESCE($9, account_holder_name),
        account_number = COALESCE($10, account_number),
        bank_name = COALESCE($11, bank_name),
        branch_name = COALESCE($12, branch_name),
        routing_number = COALESCE($13, routing_number),
        verification_status = $14,
        resubmission_count = resubmission_count + 1
       WHERE user_id = $15
       RETURNING *`,
      [nid_front_url, nid_back_url, license_url,
       vehicle_type || 'car', vehicle_model, vehicle_year, registration_number, vehicle_photo_url,
       account_holder_name, account_number, bank_name, branch_name, routing_number,
       VERIFICATION_STATUS.PENDING, userId]
    );
  } else {
    // Insert new
    result = await query(
      `INSERT INTO driver_profiles 
        (user_id, nid_front_url, nid_back_url, license_url,
         vehicle_type, vehicle_model, vehicle_year, registration_number, vehicle_photo_url,
         account_holder_name, account_number, bank_name, branch_name, routing_number,
         verification_status)
       VALUES ($1,$2,$3,$4,$5,$6,$7,$8,$9,$10,$11,$12,$13,$14,$15)
       RETURNING *`,
      [userId, nid_front_url, nid_back_url, license_url,
       vehicle_type || 'car', vehicle_model, vehicle_year, registration_number, vehicle_photo_url,
       account_holder_name, account_number, bank_name, branch_name, routing_number,
       VERIFICATION_STATUS.PENDING]
    );
  }

  return result.rows[0];
};

/**
 * Get driver verification status
 */
const getVerificationStatus = async (userId) => {
  const result = await query(
    `SELECT verification_status, rejection_reason, resubmission_count, verified_at
     FROM driver_profiles WHERE user_id = $1`,
    [userId]
  );

  if (result.rows.length === 0) {
    return { verification_status: 'not_submitted', message: 'Please submit your documents.' };
  }

  return result.rows[0];
};

module.exports = {
  updateProfile,
  updateProfilePhoto,
  submitDriverDocuments,
  getVerificationStatus,
};
