// ============================================
// RideShare AI Pro — Chat Module
// F12/F32: Real-time Chat (Rider ↔ Driver)
// Rule: Chat only works between ride accepted → completed
// ============================================

const express = require('express');
const router = express.Router();
const { supabase } = require('../../config/supabase');
const { authenticate } = require('../../middleware/auth');
const { successResponse } = require('../../utils/helpers');
const { BadRequestError, NotFoundError } = require('../../utils/errors');

router.use(authenticate);

// Active ride statuses where chat is allowed
const CHAT_ALLOWED_STATUSES = ['driver_assigned', 'arrived', 'started'];

/**
 * Check if chat is allowed for this ride
 */
const validateChatAccess = async (rideId, userId) => {
  const { data: ride } = await supabase
    .from('rides')
    .select('id, rider_id, driver_id, status')
    .eq('id', rideId)
    .single();

  if (!ride) throw new NotFoundError('Ride not found.');

  // User must be rider or driver of this ride
  if (ride.rider_id !== userId && ride.driver_id !== userId) {
    throw new BadRequestError('You are not part of this ride.');
  }

  // Chat only allowed during active ride
  if (!CHAT_ALLOWED_STATUSES.includes(ride.status)) {
    throw new BadRequestError(`Chat not available. Ride status: ${ride.status}. Chat works only after driver accepts and before ride completes.`);
  }

  // Return the other person's ID
  const receiverId = ride.rider_id === userId ? ride.driver_id : ride.rider_id;
  return { ride, receiverId };
};

// ── Send message ──
router.post('/:rideId/send', async (req, res, next) => {
  try {
    const { message, message_type } = req.body;
    if (!message || !message.trim()) throw new BadRequestError('Message cannot be empty.');

    const { ride, receiverId } = await validateChatAccess(req.params.rideId, req.user.id);

    const { data, error } = await supabase.from('chat_messages').insert({
      context_id: req.params.rideId,
      sender_id: req.user.id,
      receiver_id: receiverId,
      message: message.trim(),
      message_type: message_type || 'text',
    }).select().single();

    if (error) throw new BadRequestError(error.message);

    successResponse(res, data, 'Message sent', 201);
  } catch (e) { next(e); }
});

// ── Get chat history for a ride ──
router.get('/:rideId', async (req, res, next) => {
  try {
    // Allow reading chat even after ride completed (for history)
    const { data: ride } = await supabase
      .from('rides')
      .select('rider_id, driver_id')
      .eq('id', req.params.rideId)
      .single();

    if (!ride) throw new NotFoundError('Ride not found.');
    if (ride.rider_id !== req.user.id && ride.driver_id !== req.user.id) {
      throw new BadRequestError('You are not part of this ride.');
    }

    const { data } = await supabase
      .from('chat_messages')
      .select('*')
      .eq('context_id', req.params.rideId)
      .order('created_at', { ascending: true });

    successResponse(res, {
      messages: data || [],
      count: (data || []).length,
      chat_enabled: ['driver_assigned', 'arrived', 'started'].includes(
        (await supabase.from('rides').select('status').eq('id', req.params.rideId).single()).data?.status
      ),
    });
  } catch (e) { next(e); }
});

// ── Mark messages as read ──
router.put('/:rideId/read', async (req, res, next) => {
  try {
    await supabase
      .from('chat_messages')
      .update({ is_read: true })
      .eq('context_id', req.params.rideId)
      .eq('receiver_id', req.user.id)
      .eq('is_read', false);

    successResponse(res, { message: 'Messages marked as read' });
  } catch (e) { next(e); }
});

// ── Get unread count ──
router.get('/:rideId/unread', async (req, res, next) => {
  try {
    const { count } = await supabase
      .from('chat_messages')
      .select('*', { count: 'exact', head: true })
      .eq('context_id', req.params.rideId)
      .eq('receiver_id', req.user.id)
      .eq('is_read', false);

    successResponse(res, { unread: count || 0 });
  } catch (e) { next(e); }
});

module.exports = router;
