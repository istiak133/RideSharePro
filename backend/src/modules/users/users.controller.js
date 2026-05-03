// ============================================
// RideShare AI Pro — Users Controller
// ============================================

const usersService = require('./users.service');
const { successResponse } = require('../../utils/helpers');

/**
 * PUT /api/users/profile
 */
const updateProfile = async (req, res, next) => {
  try {
    const user = await usersService.updateProfile(req.user.id, req.body);
    return successResponse(res, { user }, 'Profile updated successfully');
  } catch (error) {
    next(error);
  }
};

/**
 * PUT /api/users/profile/photo
 */
const updateProfilePhoto = async (req, res, next) => {
  try {
    // TODO: Implement actual file upload to Supabase Storage
    // For now, accept photo_url directly
    const { photo_url } = req.body;
    const result = await usersService.updateProfilePhoto(req.user.id, photo_url);
    return successResponse(res, result, 'Photo updated');
  } catch (error) {
    next(error);
  }
};

/**
 * POST /api/users/driver/documents
 */
const submitDriverDocuments = async (req, res, next) => {
  try {
    const result = await usersService.submitDriverDocuments(req.user.id, req.body);
    return successResponse(res, result, 'Documents submitted for verification', 201);
  } catch (error) {
    next(error);
  }
};

/**
 * GET /api/users/driver/verification-status
 */
const getVerificationStatus = async (req, res, next) => {
  try {
    const result = await usersService.getVerificationStatus(req.user.id);
    return successResponse(res, result, 'Verification status fetched');
  } catch (error) {
    next(error);
  }
};

module.exports = {
  updateProfile,
  updateProfilePhoto,
  submitDriverDocuments,
  getVerificationStatus,
};
