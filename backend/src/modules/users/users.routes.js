// ============================================
// RideShare AI Pro — Users Routes
// ============================================

const express = require('express');
const router = express.Router();
const usersController = require('./users.controller');
const { authenticate, authorize } = require('../../middleware/auth');

// All routes need authentication
router.use(authenticate);

// Profile routes (both rider & driver)
router.put('/profile', usersController.updateProfile);
router.put('/profile/photo', usersController.updateProfilePhoto);

// Driver-specific routes
router.post('/driver/documents', authorize('driver'), usersController.submitDriverDocuments);
router.get('/driver/verification-status', authorize('driver'), usersController.getVerificationStatus);

module.exports = router;
