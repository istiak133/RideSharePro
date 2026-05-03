// ============================================
// RideShare AI Pro — Auth Routes
// ============================================

const express = require('express');
const router = express.Router();
const authController = require('./auth.controller');
const { authenticate } = require('../../middleware/auth');

// Public routes (no auth needed)
router.post('/request-otp', authController.requestOTP);
router.post('/verify-otp', authController.verifyOTP);

// Protected routes (need JWT token)
router.get('/me', authenticate, authController.getMe);

module.exports = router;
