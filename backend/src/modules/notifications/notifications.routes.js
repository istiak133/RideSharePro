// ============================================
// RideShare AI Pro — Notifications Module
// F17: Push Notifications
// ============================================

const express = require('express');
const router = express.Router();
const { supabase } = require('../../config/supabase');
const { authenticate } = require('../../middleware/auth');
const { successResponse } = require('../../utils/helpers');
const { BadRequestError } = require('../../utils/errors');

router.use(authenticate);

// Save device token
router.post('/device-token', async (req, res, next) => {
  try {
    const { token, platform } = req.body;
    if (!token || !platform) throw new BadRequestError('Token and platform required.');

    const { data, error } = await supabase
      .from('device_tokens')
      .upsert({ user_id: req.user.id, token, platform, updated_at: new Date().toISOString() },
        { onConflict: 'user_id,token' })
      .select()
      .single();

    successResponse(res, data, 'Token saved');
  } catch (e) { next(e); }
});

// Get my notifications
router.get('/me', async (req, res, next) => {
  try {
    const { data } = await supabase
      .from('notifications_log')
      .select('*')
      .eq('user_id', req.user.id)
      .order('sent_at', { ascending: false })
      .limit(50);
    successResponse(res, data || []);
  } catch (e) { next(e); }
});

module.exports = router;
