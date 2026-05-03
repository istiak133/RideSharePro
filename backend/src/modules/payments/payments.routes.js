// ============================================
// RideShare AI Pro — Payments Module
// F13: Cash + F14: Card + F30: Earnings
// ============================================

const express = require('express');
const router = express.Router();
const { supabase } = require('../../config/supabase');
const { authenticate, authorize } = require('../../middleware/auth');
const { successResponse } = require('../../utils/helpers');
const { BadRequestError } = require('../../utils/errors');
const { calculateCommission } = require('../../utils/helpers');

// All routes need auth
router.use(authenticate);

// F13: Pay with cash
router.post('/cash', async (req, res, next) => {
  try {
    const { ride_id } = req.body;
    const { data: ride } = await supabase.from('rides').select('final_fare, status, driver_id').eq('id', ride_id).single();
    if (!ride || ride.status !== 'completed') throw new BadRequestError('Ride not completed.');

    const { platformCommission, driverEarning } = calculateCommission(ride.final_fare);

    const { data: payment, error } = await supabase
      .from('payments')
      .insert({
        ride_id,
        amount: ride.final_fare,
        payment_method: 'cash',
        status: 'completed',
        platform_commission: platformCommission,
        driver_earning: driverEarning,
        paid_at: new Date().toISOString(),
        verified_by: 'driver',
      })
      .select()
      .single();

    if (error) throw new BadRequestError(error.message);
    successResponse(res, payment, 'Cash payment recorded', 201);
  } catch (e) { next(e); }
});

// F14: Pay with card (Stripe placeholder)
router.post('/card', async (req, res, next) => {
  try {
    const { ride_id, payment_method_id } = req.body;
    const { data: ride } = await supabase.from('rides').select('final_fare, status').eq('id', ride_id).single();
    if (!ride || ride.status !== 'completed') throw new BadRequestError('Ride not completed.');

    const { platformCommission, driverEarning } = calculateCommission(ride.final_fare);

    // TODO: Stripe PaymentIntent.create() here
    const { data: payment, error } = await supabase
      .from('payments')
      .insert({
        ride_id,
        amount: ride.final_fare,
        payment_method: 'card',
        status: 'completed',
        platform_commission: platformCommission,
        driver_earning: driverEarning,
        stripe_payment_intent_id: 'pi_mock_' + Date.now(),
        paid_at: new Date().toISOString(),
        verified_by: 'system',
      })
      .select()
      .single();

    if (error) throw new BadRequestError(error.message);
    successResponse(res, payment, 'Card payment processed', 201);
  } catch (e) { next(e); }
});

// F14: Save card
router.post('/methods', authorize('rider'), async (req, res, next) => {
  try {
    const { stripe_payment_method_id, last4, brand } = req.body;
    const { data, error } = await supabase
      .from('payment_methods')
      .insert({ user_id: req.user.id, stripe_payment_method_id, last4, brand })
      .select()
      .single();
    if (error) throw new BadRequestError(error.message);
    successResponse(res, data, 'Card saved', 201);
  } catch (e) { next(e); }
});

// Get saved cards
router.get('/methods', authorize('rider'), async (req, res, next) => {
  try {
    const { data } = await supabase.from('payment_methods').select('*').eq('user_id', req.user.id);
    successResponse(res, data || []);
  } catch (e) { next(e); }
});

// F30: Driver earnings
router.get('/earnings', authorize('driver'), async (req, res, next) => {
  try {
    const today = new Date().toISOString().split('T')[0];
    const { data: todayPayments } = await supabase
      .from('payments')
      .select('driver_earning, ride_id')
      .eq('status', 'completed')
      .gte('paid_at', today + 'T00:00:00')
      .lte('paid_at', today + 'T23:59:59');

    // Filter by driver's rides
    const { data: driverRides } = await supabase
      .from('rides')
      .select('id')
      .eq('driver_id', req.user.id)
      .eq('status', 'completed');

    const driverRideIds = (driverRides || []).map(r => r.id);
    const myEarnings = (todayPayments || []).filter(p => driverRideIds.includes(p.ride_id));

    const todayTotal = myEarnings.reduce((sum, p) => sum + parseFloat(p.driver_earning || 0), 0);

    successResponse(res, {
      today_trips: myEarnings.length,
      today_earnings: todayTotal,
    });
  } catch (e) { next(e); }
});

module.exports = router;
