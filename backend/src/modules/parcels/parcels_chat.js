// ============================================
// Parcel Chat + Live Location + ETA
// Mounted AFTER parcels.routes.js
// ============================================
const express = require('express');
const router = express.Router();
const { supabase } = require('../../config/supabase');
const { authenticate } = require('../../middleware/auth');
const { successResponse } = require('../../utils/helpers');
const { BadRequestError, NotFoundError } = require('../../utils/errors');

router.use(authenticate);

const CHAT_OK = ['driver_assigned', 'pickup_arrived', 'picked_up', 'in_transit'];

function distKm(lat1, lng1, lat2, lng2) {
  const R = 6371, dLat = (lat2-lat1)*Math.PI/180, dLng = (lng2-lng1)*Math.PI/180;
  const a = Math.sin(dLat/2)**2 + Math.cos(lat1*Math.PI/180)*Math.cos(lat2*Math.PI/180)*Math.sin(dLng/2)**2;
  return R * 2 * Math.atan2(Math.sqrt(a), Math.sqrt(1-a));
}

// Send chat message
router.post('/:id/chat/send', async (req, res, next) => {
  try {
    const { message, message_type } = req.body;
    if (!message || !message.trim()) throw new BadRequestError('Message empty.');
    const { data: p } = await supabase.from('parcels').select('sender_id, driver_id, status').eq('id', req.params.id).single();
    if (!p) throw new NotFoundError('Parcel not found.');
    if (p.sender_id !== req.user.id && p.driver_id !== req.user.id) throw new BadRequestError('Not your delivery.');
    if (!CHAT_OK.includes(p.status)) throw new BadRequestError('Chat not available. Status: ' + p.status);
    const recv = p.sender_id === req.user.id ? p.driver_id : p.sender_id;
    const { data, error } = await supabase.from('chat_messages').insert({
      context_id: req.params.id, sender_id: req.user.id, receiver_id: recv,
      message: message.trim(), message_type: message_type || 'text',
    }).select().single();
    if (error) throw new BadRequestError(error.message);
    successResponse(res, data, 'Message sent', 201);
  } catch (e) { next(e); }
});

// Get chat history
router.get('/:id/chat', async (req, res, next) => {
  try {
    const { data: p } = await supabase.from('parcels').select('sender_id, driver_id, status').eq('id', req.params.id).single();
    if (!p) throw new NotFoundError('Not found.');
    if (p.sender_id !== req.user.id && p.driver_id !== req.user.id) throw new BadRequestError('Not yours.');
    const { data } = await supabase.from('chat_messages').select('*').eq('context_id', req.params.id).order('created_at', { ascending: true });
    successResponse(res, { messages: data || [], count: (data||[]).length, chat_enabled: CHAT_OK.includes(p.status) });
  } catch (e) { next(e); }
});

// Driver updates location during delivery
router.put('/:id/driver-location', async (req, res, next) => {
  try {
    const { lat, lng } = req.body;
    if (!lat || !lng) throw new BadRequestError('lat/lng required.');
    const { data: p } = await supabase.from('parcels').select('driver_id, drop_lat, drop_lng').eq('id', req.params.id).single();
    if (!p || p.driver_id !== req.user.id) throw new BadRequestError('Not your delivery.');
    await supabase.from('drivers').update({ current_lat: lat, current_lng: lng, last_location_update: new Date().toISOString() }).eq('user_id', req.user.id);
    await supabase.from('parcel_tracking').insert({ parcel_id: req.params.id, lat, lng, status_update: 'location_update' });
    const d = distKm(lat, lng, p.drop_lat, p.drop_lng);
    const eta = Math.ceil((d / 25) * 60);
    successResponse(res, { driver_lat: lat, driver_lng: lng, distance_to_destination_km: parseFloat(d.toFixed(2)), eta_minutes: eta, eta_text: eta <= 1 ? 'Almost there!' : eta + ' min remaining' });
  } catch (e) { next(e); }
});

// Sender gets live location + ETA
router.get('/:id/live-location', async (req, res, next) => {
  try {
    const { data: p } = await supabase.from('parcels').select('sender_id, driver_id, drop_lat, drop_lng, status').eq('id', req.params.id).single();
    if (!p) throw new NotFoundError('Not found.');
    if (p.sender_id !== req.user.id) throw new BadRequestError('Not your parcel.');
    if (!CHAT_OK.includes(p.status)) throw new BadRequestError('Tracking not available.');
    const { data: drv } = await supabase.from('drivers').select('current_lat, current_lng, last_location_update').eq('user_id', p.driver_id).single();
    if (!drv || !drv.current_lat) { successResponse(res, { available: false }); return; }
    const d = distKm(drv.current_lat, drv.current_lng, p.drop_lat, p.drop_lng);
    const eta = Math.ceil((d / 25) * 60);
    successResponse(res, { available: true, driver_lat: drv.current_lat, driver_lng: drv.current_lng, last_updated: drv.last_location_update, distance_remaining_km: parseFloat(d.toFixed(2)), eta_minutes: eta, eta_text: eta <= 1 ? 'Almost there!' : 'About ' + eta + ' min away', parcel_status: p.status });
  } catch (e) { next(e); }
});

module.exports = router;
