// ============================================
// RideShare AI Pro — Payments Module
// F13: Cash + F14: Card + F30: Earnings
// ============================================

const express = require('express');
const axios = require('axios');
const router = express.Router();
const { supabase } = require('../../config/supabase');
const { authenticate, authorize } = require('../../middleware/auth');
const { successResponse } = require('../../utils/helpers');
const { BadRequestError } = require('../../utils/errors');
const { calculateCommission } = require('../../utils/helpers');

// bKash Sandbox URLs
const BKASH_BASE_URL = 'https://tokenized.sandbox.bka.sh/v1.2.0-beta';

// Helper to get headers
const getBkashHeaders = async () => {
  try {
    const { data } = await axios.post(
      `${BKASH_BASE_URL}/tokenized/checkout/token/grant`,
      {
        app_key: process.env.BKASH_APP_KEY,
        app_secret: process.env.BKASH_APP_SECRET,
      },
      {
        headers: {
          'Content-Type': 'application/json',
          'username': process.env.BKASH_USERNAME,
          'password': process.env.BKASH_PASSWORD,
        }
      }
    );
    return {
      'Content-Type': 'application/json',
      'Authorization': data.id_token,
      'X-APP-Key': process.env.BKASH_APP_KEY,
    };
  } catch (error) {
    console.error('bKash Grant Token Error:', error.response?.data || error.message);
    throw new Error('Failed to authenticate with bKash');
  }
};

// All routes need auth except bKash callback which bKash hits directly
// Wait, I should mount callback before authorize, or authorize after.
// Let's adjust route definitions so callback is public.
// F13: Pay with cash
router.post('/cash', authenticate, async (req, res, next) => {
// F13: Pay with cash
router.post('/cash', authenticate, async (req, res, next) => {
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
// F14: Pay with card (Stripe placeholder)
router.post('/card', authenticate, async (req, res, next) => {
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
// F14: Save card
router.post('/methods', authenticate, authorize('rider'), async (req, res, next) => {
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
// Get saved cards
router.get('/methods', authenticate, authorize('rider'), async (req, res, next) => {
  try {
    const { data } = await supabase.from('payment_methods').select('*').eq('user_id', req.user.id);
    successResponse(res, data || []);
  } catch (e) { next(e); }
});

// F30: Driver earnings
// F30: Driver earnings
router.get('/earnings', authenticate, authorize('driver'), async (req, res, next) => {
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


// ============================================
// bKash Integration
// ============================================

// @route   POST /api/payments/bkash/create
// @desc    Create a bKash payment URL
router.post('/bkash/create', authenticate, async (req, res) => {
  try {
    const { rideId, amount } = req.body;
    if (!rideId || !amount) {
      return res.status(400).json({ success: false, message: 'rideId and amount are required' });
    }

    const headers = await getBkashHeaders();

    // The callback URL should point to our backend execute endpoint
    // In emulator, we use http://10.0.2.2:3000 but bKash server can't reach local IP!
    // Actually, in bKash tokenized API, the callback redirects the USER's browser.
    // So if the user is on the emulator, the browser will redirect to the callback URL.
    // Let's use a custom scheme or just a local url that the webview can intercept.
    const callbackURL = 'http://localhost:3000/api/payments/bkash/callback';

    const invoiceNumber = `RIDE_${rideId}_${Date.now()}`;

    const requestData = {
      mode: '0011',
      payerReference: req.user.id,
      callbackURL: callbackURL,
      amount: amount.toString(),
      currency: 'BDT',
      intent: 'sale',
      merchantInvoiceNumber: invoiceNumber
    };

    const { data } = await axios.post(
      `${BKASH_BASE_URL}/tokenized/checkout/create`,
      requestData,
      { headers }
    );

    if (data.statusCode !== '0000') {
      return res.status(400).json({ success: false, message: data.statusMessage, data });
    }

    res.json({
      success: true,
      bkashURL: data.bkashURL,
      paymentID: data.paymentID,
    });
  } catch (error) {
    console.error('bKash Create Payment Error:', error.response?.data || error.message);
    res.status(500).json({ success: false, message: 'Failed to create bKash payment' });
  }
});

// @route   GET /api/payments/bkash/callback
// @desc    Callback URL for bKash. WebView intercepts this.
router.get('/bkash/callback', async (req, res) => {
  const { paymentID, status } = req.query;

  if (status !== 'success') {
    return res.status(400).send(`Payment ${status}. Please close this window.`);
  }

  try {
    const headers = await getBkashHeaders();

    const { data } = await axios.post(
      `${BKASH_BASE_URL}/tokenized/checkout/execute`,
      { paymentID },
      { headers }
    );

    if (data.statusCode && data.statusCode !== '0000') {
      return res.status(400).send(`Payment failed: ${data.statusMessage}. Please close this window.`);
    }

    // Success! Update database
    const rideId = data.merchantInvoiceNumber.split('_')[1];

    await supabase
      .from('rides')
      .update({ payment_status: 'paid', status: 'completed' })
      .eq('id', rideId);

    // Provide HTML for WebView to parse
    res.send(`
      <html>
        <head><meta name="viewport" content="width=device-width, initial-scale=1"></head>
        <body style="display:flex; flex-direction:column; align-items:center; justify-content:center; height:100vh; font-family:sans-serif;">
          <h1 style="color: #00D9A6;">Payment Successful!</h1>
          <p>Transaction ID: ${data.trxID}</p>
          <p>You can close this window now.</p>
          <script>
            if(window.PaymentChannel) window.PaymentChannel.postMessage('SUCCESS');
          </script>
        </body>
      </html>
    `);
  } catch (error) {
    console.error('bKash Execute Payment Error:', error.response?.data || error.message);
    res.status(500).send('Error verifying payment. Please contact support.');
  }
});

module.exports = router;
