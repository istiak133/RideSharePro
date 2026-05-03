// ============================================
// RideShare AI Pro — Rides Controller + Routes
// ============================================

const express = require('express');
const router = express.Router();
const ridesService = require('./rides.service');
const { authenticate, authorize } = require('../../middleware/auth');
const { successResponse } = require('../../utils/helpers');
const { BadRequestError } = require('../../utils/errors');

// All routes need auth
router.use(authenticate);

// F5: Fare estimate
router.post('/fare-estimate', async (req, res, next) => {
  try {
    const { distance, duration, vehicle_type } = req.body;
    if (!distance || !duration) throw new BadRequestError('Distance and duration required.');
    const result = await ridesService.getFareEstimate(distance, duration, vehicle_type);
    successResponse(res, result, 'Fare estimated');
  } catch (e) { next(e); }
});

// F6: Create ride
router.post('/', authorize('rider'), async (req, res, next) => {
  try {
    const ride = await ridesService.createRide(req.user.id, req.body);
    successResponse(res, ride, 'Ride created', 201);
  } catch (e) { next(e); }
});

// Get ride by ID
router.get('/:id', async (req, res, next) => {
  try {
    const ride = await ridesService.getRide(req.params.id);
    successResponse(res, ride);
  } catch (e) { next(e); }
});

// Ride history
router.get('/history/me', async (req, res, next) => {
  try {
    const { page } = req.query;
    const result = await ridesService.getRideHistory(req.user.id, req.user.role, parseInt(page) || 1);
    successResponse(res, result);
  } catch (e) { next(e); }
});

// Cancel ride
router.put('/:id/cancel', async (req, res, next) => {
  try {
    const ride = await ridesService.cancelRide(req.params.id, req.user.id, req.body.reason);
    successResponse(res, ride, 'Ride cancelled');
  } catch (e) { next(e); }
});

// F8: Find nearby drivers
router.post('/:id/find-drivers', authorize('rider'), async (req, res, next) => {
  try {
    const { pickup_lat, pickup_lng } = req.body;
    const drivers = await ridesService.findNearbyDrivers(req.params.id, pickup_lat, pickup_lng);
    successResponse(res, { drivers, count: drivers.length });
  } catch (e) { next(e); }
});

// F24: Accept ride
router.post('/:id/accept', authorize('driver'), async (req, res, next) => {
  try {
    const ride = await ridesService.acceptRide(req.params.id, req.user.id);
    successResponse(res, ride, 'Ride accepted');
  } catch (e) { next(e); }
});

// F24: Decline ride
router.post('/:id/decline', authorize('driver'), async (req, res, next) => {
  try {
    const result = await ridesService.declineRide(req.params.id, req.user.id);
    successResponse(res, result);
  } catch (e) { next(e); }
});

// F10: Verify pickup OTP
router.post('/:id/verify-otp', authorize('driver'), async (req, res, next) => {
  try {
    const { otp } = req.body;
    if (!otp) throw new BadRequestError('OTP required.');
    const result = await ridesService.verifyPickupOTP(req.params.id, req.user.id, otp);
    successResponse(res, result);
  } catch (e) { next(e); }
});

// F27: Start ride
router.put('/:id/start', authorize('driver'), async (req, res, next) => {
  try {
    const ride = await ridesService.startRide(req.params.id, req.user.id);
    successResponse(res, ride, 'Ride started');
  } catch (e) { next(e); }
});

// F29: Complete ride
router.put('/:id/complete', authorize('driver'), async (req, res, next) => {
  try {
    const { actual_distance, actual_duration } = req.body;
    const ride = await ridesService.completeRide(req.params.id, req.user.id, actual_distance, actual_duration);
    successResponse(res, ride, 'Ride completed');
  } catch (e) { next(e); }
});

// F11: Record route point
router.post('/:id/route-point', authorize('driver'), async (req, res, next) => {
  try {
    const { lat, lng, speed, heading } = req.body;
    const result = await ridesService.recordRoutePoint(req.params.id, lat, lng, speed, heading);
    successResponse(res, result);
  } catch (e) { next(e); }
});

// F22: Toggle driver status
router.put('/driver/toggle', authorize('driver'), async (req, res, next) => {
  try {
    const { status, lat, lng } = req.body;
    const result = await ridesService.toggleDriverStatus(req.user.id, status, lat, lng);
    successResponse(res, result);
  } catch (e) { next(e); }
});

// Update driver location
router.put('/driver/location', authorize('driver'), async (req, res, next) => {
  try {
    const { lat, lng } = req.body;
    const result = await ridesService.updateDriverLocation(req.user.id, lat, lng);
    successResponse(res, result);
  } catch (e) { next(e); }
});

module.exports = router;
