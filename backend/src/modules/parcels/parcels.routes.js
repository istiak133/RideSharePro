// ============================================
// RideShare AI Pro — Parcel Delivery Module
// F45-F51: Full Parcel Delivery System
// ============================================

const express = require('express');
const router = express.Router();
const { supabase } = require('../../config/supabase');
const { authenticate } = require('../../middleware/auth');
const { successResponse, generateOTP, hashString, compareHash, calculateCommission } = require('../../utils/helpers');
const { BadRequestError, NotFoundError } = require('../../utils/errors');

router.use(authenticate);

// ── F46: Get Parcel Categories (size/weight options) ──
router.get('/categories', async (req, res, next) => {
  try {
    const { data } = await supabase
      .from('parcel_categories')
      .select('*')
      .eq('is_active', true)
      .order('max_weight_kg', { ascending: true });
    successResponse(res, data || []);
  } catch (e) { next(e); }
});

// ── F47: Parcel Fare Estimate ──
router.post('/fare-estimate', async (req, res, next) => {
  try {
    const { distance, category_id, weight_kg, is_fragile } = req.body;
    if (!distance || !category_id) throw new BadRequestError('distance and category_id required.');

    const { data: cat } = await supabase
      .from('parcel_categories')
      .select('*')
      .eq('id', category_id)
      .single();

    if (!cat) throw new NotFoundError('Category not found.');
    if (weight_kg && weight_kg > cat.max_weight_kg) {
      throw new BadRequestError(`Max weight for ${cat.name} is ${cat.max_weight_kg}kg.`);
    }

    const distanceFare = distance * cat.per_km_rate;
    const weightExtra = weight_kg > 1 ? (weight_kg - 1) * cat.weight_surcharge : 0;
    const fragileFee = is_fragile ? cat.fragile_surcharge : 0;
    const total = Math.ceil(cat.base_fare + distanceFare + weightExtra + fragileFee);

    successResponse(res, {
      estimated_fare: total,
      breakdown: {
        base_fare: cat.base_fare,
        distance_fare: parseFloat(distanceFare.toFixed(2)),
        weight_surcharge: parseFloat(weightExtra.toFixed(2)),
        fragile_surcharge: fragileFee,
        total,
      },
      category: cat.name,
    });
  } catch (e) { next(e); }
});

// ── F45: Create Parcel Booking ──
router.post('/', async (req, res, next) => {
  try {
    const {
      category_id, parcel_description, weight_kg, is_fragile, special_instructions,
      pickup_lat, pickup_lng, pickup_address, pickup_contact_name, pickup_contact_phone,
      drop_lat, drop_lng, drop_address, receiver_name, receiver_phone,
      estimated_fare, estimated_distance, estimated_duration, fare_breakdown,
      payment_method, scheduled_at,
    } = req.body;

    if (!pickup_lat || !drop_lat || !receiver_name || !receiver_phone) {
      throw new BadRequestError('Pickup, drop, receiver details required.');
    }

    // Generate pickup & delivery OTPs
    const pickupOtp = generateOTP(4);
    const deliveryOtp = generateOTP(4);

    const { data, error } = await supabase.from('parcels').insert({
      sender_id: req.user.id,
      category_id, parcel_description, weight_kg, is_fragile, special_instructions,
      pickup_lat, pickup_lng, pickup_address,
      pickup_contact_name: pickup_contact_name || req.user.full_name || 'Sender',
      pickup_contact_phone: pickup_contact_phone || req.user.phone,
      drop_lat, drop_lng, drop_address, receiver_name, receiver_phone,
      estimated_fare, estimated_distance, estimated_duration, fare_breakdown,
      payment_method: payment_method || 'cash',
      pickup_otp_hash: await hashString(pickupOtp),
      delivery_otp_hash: await hashString(deliveryOtp),
      status: scheduled_at ? 'scheduled' : 'pending',
      scheduled_at,
    }).select().single();

    if (error) throw new BadRequestError(error.message);

    successResponse(res, {
      ...data,
      pickup_otp: pickupOtp,
      delivery_otp: deliveryOtp,
    }, 'Parcel booked', 201);
  } catch (e) { next(e); }
});

// ── F45: Get parcel details ──
router.get('/:id', async (req, res, next) => {
  try {
    const { data } = await supabase
      .from('parcels')
      .select('*, sender:users!parcels_sender_id_fkey(full_name, phone), driver:users!parcels_driver_id_fkey(full_name, phone, photo_url)')
      .eq('id', req.params.id)
      .single();
    if (!data) throw new NotFoundError('Parcel not found.');
    successResponse(res, data);
  } catch (e) { next(e); }
});

// ── F45: My parcels (sent) ──
router.get('/history/sent', async (req, res, next) => {
  try {
    const { data } = await supabase
      .from('parcels')
      .select('*')
      .eq('sender_id', req.user.id)
      .order('created_at', { ascending: false });
    successResponse(res, data || []);
  } catch (e) { next(e); }
});

// ── F45: My parcels (driver deliveries) ──
router.get('/history/deliveries', async (req, res, next) => {
  try {
    const { data } = await supabase
      .from('parcels')
      .select('*')
      .eq('driver_id', req.user.id)
      .order('created_at', { ascending: false });
    successResponse(res, data || []);
  } catch (e) { next(e); }
});

// ── F48: Driver accepts parcel ──
router.post('/:id/accept', async (req, res, next) => {
  try {
    const { data: parcel } = await supabase.from('parcels').select('status').eq('id', req.params.id).single();
    if (!parcel || parcel.status !== 'pending') throw new BadRequestError('Parcel not available.');

    const { data, error } = await supabase.from('parcels')
      .update({ driver_id: req.user.id, status: 'driver_assigned' })
      .eq('id', req.params.id)
      .eq('status', 'pending')
      .select().single();

    if (error || !data) throw new BadRequestError('Parcel already taken.');
    successResponse(res, data, 'Parcel accepted');
  } catch (e) { next(e); }
});

// ── F48: Driver arrived at pickup ──
router.put('/:id/pickup-arrived', async (req, res, next) => {
  try {
    const { data, error } = await supabase.from('parcels')
      .update({ status: 'pickup_arrived' })
      .eq('id', req.params.id)
      .eq('driver_id', req.user.id)
      .select().single();
    if (error || !data) throw new BadRequestError('Cannot update status.');
    successResponse(res, data);
  } catch (e) { next(e); }
});

// ── F48: Verify pickup OTP + photo proof ──
router.post('/:id/verify-pickup', async (req, res, next) => {
  try {
    const { otp, photo_url } = req.body;
    if (!otp) throw new BadRequestError('OTP required.');

    const { data: parcel } = await supabase.from('parcels')
      .select('pickup_otp_hash, driver_id')
      .eq('id', req.params.id).single();

    if (!parcel) throw new NotFoundError('Parcel not found.');
    if (parcel.driver_id !== req.user.id) throw new BadRequestError('Not your delivery.');

    const valid = await compareHash(otp, parcel.pickup_otp_hash);
    if (!valid) throw new BadRequestError('Wrong OTP.');

    const { data } = await supabase.from('parcels')
      .update({
        pickup_verified: true,
        pickup_photo_url: photo_url || null,
        status: 'picked_up',
        picked_up_at: new Date().toISOString(),
      })
      .eq('id', req.params.id)
      .select().single();

    successResponse(res, data, 'Pickup verified, parcel collected');
  } catch (e) { next(e); }
});

// ── F49: Start transit (driver heading to receiver) ──
router.put('/:id/in-transit', async (req, res, next) => {
  try {
    const { data } = await supabase.from('parcels')
      .update({ status: 'in_transit' })
      .eq('id', req.params.id)
      .eq('driver_id', req.user.id)
      .select().single();
    if (!data) throw new BadRequestError('Cannot update.');
    successResponse(res, data);
  } catch (e) { next(e); }
});

// ── F49: Track parcel (add GPS point) ──
router.post('/:id/track', async (req, res, next) => {
  try {
    const { lat, lng, status_update, note } = req.body;
    await supabase.from('parcel_tracking').insert({
      parcel_id: req.params.id, lat, lng, status_update, note,
    });
    successResponse(res, { message: 'Tracking point added' });
  } catch (e) { next(e); }
});

// ── F49: Get tracking history ──
router.get('/:id/tracking', async (req, res, next) => {
  try {
    const { data } = await supabase
      .from('parcel_tracking')
      .select('*')
      .eq('parcel_id', req.params.id)
      .order('recorded_at', { ascending: true });
    successResponse(res, data || []);
  } catch (e) { next(e); }
});

// ── F50: Verify delivery OTP + photo proof ──
router.post('/:id/verify-delivery', async (req, res, next) => {
  try {
    const { otp, photo_url } = req.body;
    if (!otp) throw new BadRequestError('Delivery OTP required.');

    const { data: parcel } = await supabase.from('parcels')
      .select('delivery_otp_hash, driver_id, estimated_fare')
      .eq('id', req.params.id).single();

    if (!parcel) throw new NotFoundError('Parcel not found.');
    if (parcel.driver_id !== req.user.id) throw new BadRequestError('Not your delivery.');

    const valid = await compareHash(otp, parcel.delivery_otp_hash);
    if (!valid) throw new BadRequestError('Wrong delivery OTP.');

    // Mark delivered + create payment
    const finalFare = parcel.estimated_fare;
    const commission = calculateCommission(finalFare);

    const { data } = await supabase.from('parcels')
      .update({
        delivery_verified: true,
        delivery_photo_url: photo_url || null,
        status: 'delivered',
        delivered_at: new Date().toISOString(),
        final_fare: finalFare,
        payment_status: 'completed',
      })
      .eq('id', req.params.id)
      .select().single();

    // Record payment
    await supabase.from('payments').insert({
      ride_id: req.params.id,  // reusing payments table
      payer_id: data.sender_id,
      payee_id: data.driver_id,
      amount: finalFare,
      payment_method: data.payment_method,
      status: 'completed',
      platform_commission: commission.platformAmount,
      driver_earning: commission.driverAmount,
      payment_type: 'parcel',
    });

    successResponse(res, {
      ...data,
      driver_earning: commission.driverAmount,
      platform_commission: commission.platformAmount,
    }, 'Parcel delivered!');
  } catch (e) { next(e); }
});

// ── F45: Cancel parcel ──
router.put('/:id/cancel', async (req, res, next) => {
  try {
    const { reason } = req.body;
    const { data: parcel } = await supabase.from('parcels').select('status').eq('id', req.params.id).single();
    if (!parcel) throw new NotFoundError('Parcel not found.');
    if (['delivered', 'cancelled'].includes(parcel.status)) throw new BadRequestError('Cannot cancel.');

    const { data } = await supabase.from('parcels')
      .update({
        status: 'cancelled',
        cancelled_at: new Date().toISOString(),
        cancelled_by: req.user.id,
        cancellation_reason: reason,
      })
      .eq('id', req.params.id)
      .select().single();

    successResponse(res, data, 'Parcel cancelled');
  } catch (e) { next(e); }
});

module.exports = router;
