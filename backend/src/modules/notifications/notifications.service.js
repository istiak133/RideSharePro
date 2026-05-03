// ============================================
// RideShare AI Pro — Notifications Service
// F17: Push Notifications / In-App Logging
// ============================================

const { supabase } = require('../../config/supabase');

/**
 * Send a notification (Mock FCM push + Save to DB)
 * @param {string} userId - Target user ID
 * @param {string} type - Notification type from constants
 * @param {string} title - Notification title
 * @param {string} body - Notification body
 * @param {object} payload - Extra data payload
 */
const sendNotification = async (userId, type, title, body, payload = {}) => {
  try {
    // 1. Log to database for in-app notification history
    await supabase.from('notifications_log').insert({
      user_id: userId,
      type,
      title,
      body,
      payload,
    });

    // 2. Fetch device tokens (if FCM was fully integrated)
    // const { data: tokens } = await supabase.from('device_tokens').select('token').eq('user_id', userId);
    // if (tokens && tokens.length > 0) {
    //   // TODO: Integrate Firebase Admin SDK here
    //   // admin.messaging().sendMulticast({ tokens: tokens.map(t => t.token), notification: { title, body } });
    // }

    // For MVP, since we use Supabase Realtime for instant UI updates,
    // saving to `notifications_log` allows the frontend to show a notification bell count.
    console.log(`[Notification Sent] to ${userId}: ${title}`);
    
  } catch (error) {
    console.error('Failed to send notification:', error.message);
  }
};

module.exports = { sendNotification };
