const express = require('express');
const axios = require('axios');
const { requireAuth } = require('../../middleware/auth');
const supabase = require('../../config/supabase');

const router = express.Router();

// bKash Sandbox URLs
const BKASH_BASE_URL = 'https://tokenized.sandbox.bka.sh/v1.2.0-beta';

// Helper to get headers
const getBkashHeaders = async () => {
  // 1. Get Grant Token
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

// @route   POST /api/payment/bkash/create
// @desc    Create a bKash payment URL
router.post('/bkash/create', requireAuth, async (req, res) => {
  try {
    const { rideId, amount } = req.body;
    
    if (!rideId || !amount) {
      return res.status(400).json({ success: false, message: 'rideId and amount are required' });
    }

    const headers = await getBkashHeaders();

    // The callback URL should point to our backend execute endpoint
    // In local development, we use ngrok or local IP if testing from emulator.
    // For emulator testing, use host IP. But generally we can just use a deeplink or a web route.
    // Let's use a dummy callback that the frontend will intercept.
    const callbackURL = 'http://localhost:3000/api/payment/bkash/callback';

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

// @route   GET /api/payment/bkash/callback
// @desc    Callback URL for bKash. Frontend WebView intercepts this or it executes here.
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
    // Here we extract the rideId from the merchantInvoiceNumber
    const rideId = data.merchantInvoiceNumber.split('_')[1];

    await supabase
      .from('rides')
      .update({ payment_status: 'paid', status: 'completed' })
      .eq('id', rideId);

    // Return a success HTML page that the WebView can parse or show to user
    res.send(`
      <html>
        <head><meta name="viewport" content="width=device-width, initial-scale=1"></head>
        <body style="display:flex; flex-direction:column; align-items:center; justify-content:center; height:100vh; font-family:sans-serif;">
          <h1 style="color: #00D9A6;">Payment Successful!</h1>
          <p>Transaction ID: ${data.trxID}</p>
          <p>You can close this window now.</p>
          <!-- Frontend can inject JS here to close the webview -->
          <script>
            // Notify Flutter
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
