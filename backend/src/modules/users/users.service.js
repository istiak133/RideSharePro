// ============================================
// RideShare AI Pro — Users Service (Supabase)
// F2: Profile + F20: Documents + F21: Verification
// ============================================

const { supabase } = require('../../config/supabase');
const { BadRequestError, NotFoundError } = require('../../utils/errors');
const { isValidEmail, isOver18 } = require('../../utils/helpers');
const { ROLES, VERIFICATION_STATUS } = require('../../utils/constants');

/**
 * Update user profile
 */
const updateProfile = async (userId, profileData) => {
  const { full_name, date_of_birth, email, emergency_contact_name, emergency_contact_phone, language_preference } = profileData;

  if (full_name && full_name.trim().length < 3) throw new BadRequestError('Name must be at least 3 characters.');
  if (date_of_birth && !isOver18(date_of_birth)) throw new BadRequestError('Must be 18+.');
  if (email && !isValidEmail(email)) throw new BadRequestError('Invalid email.');

  const updateData = {};
  if (full_name) updateData.full_name = full_name.trim();
  if (date_of_birth) updateData.date_of_birth = date_of_birth;
  if (email !== undefined) updateData.email = email;
  if (emergency_contact_name !== undefined) updateData.emergency_contact_name = emergency_contact_name;
  if (emergency_contact_phone !== undefined) updateData.emergency_contact_phone = emergency_contact_phone;
  if (language_preference) updateData.language_preference = language_preference;
  updateData.updated_at = new Date().toISOString();

  const { data, error } = await supabase
    .from('users')
    .update(updateData)
    .eq('id', userId)
    .select()
    .single();

  if (error) throw new BadRequestError('Update failed: ' + error.message);
  return data;
};

/**
 * Update profile photo
 */
const updateProfilePhoto = async (userId, photoUrl) => {
  const { data, error } = await supabase
    .from('users')
    .update({ photo_url: photoUrl, updated_at: new Date().toISOString() })
    .eq('id', userId)
    .select('id, photo_url')
    .single();

  if (error) throw new NotFoundError('User not found.');
  return data;
};

/**
 * Upload file to Supabase Storage
 */
const uploadFile = async (bucket, filePath, fileBuffer, mimeType) => {
  const { data, error } = await supabase.storage
    .from(bucket)
    .upload(filePath, fileBuffer, { contentType: mimeType, upsert: true });

  if (error) throw new BadRequestError('Upload failed: ' + error.message);

  const { data: urlData } = supabase.storage.from(bucket).getPublicUrl(filePath);
  return urlData.publicUrl;
};

/**
 * Submit driver documents
 */
const submitDriverDocuments = async (userId, docData) => {
  // Verify user is driver
  const { data: user } = await supabase.from('users').select('role').eq('id', userId).single();
  if (!user || user.role !== ROLES.DRIVER) throw new BadRequestError('Only drivers can submit documents.');

  // Check if profile exists
  const { data: existing } = await supabase.from('driver_profiles').select('id').eq('user_id', userId).single();

  if (existing) {
    // Update
    const { data, error } = await supabase
      .from('driver_profiles')
      .update({ ...docData, verification_status: VERIFICATION_STATUS.PENDING })
      .eq('user_id', userId)
      .select()
      .single();
    if (error) throw new BadRequestError(error.message);
    return data;
  } else {
    // Insert
    const { data, error } = await supabase
      .from('driver_profiles')
      .insert({ user_id: userId, ...docData })
      .select()
      .single();
    if (error) throw new BadRequestError(error.message);
    return data;
  }
};

/**
 * Get verification status
 */
const getVerificationStatus = async (userId) => {
  const { data } = await supabase
    .from('driver_profiles')
    .select('verification_status, rejection_reason, resubmission_count, verified_at')
    .eq('user_id', userId)
    .single();

  if (!data) return { verification_status: 'not_submitted' };
  return data;
};

module.exports = { updateProfile, updateProfilePhoto, uploadFile, submitDriverDocuments, getVerificationStatus };
