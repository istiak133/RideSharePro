// ============================================
// RideShare AI Pro — Ratings Module
// F16: Rating & Review
// ============================================

const express = require('express');
const router = express.Router();
const { supabase } = require('../../config/supabase');
const { authenticate } = require('../../middleware/auth');
const { successResponse } = require('../../utils/helpers');
const { BadRequestError } = require('../../utils/errors');

router.use(authenticate);

// F16: Submit rating
router.post('/', async (req, res, next) => {
  try {
    const { ride_id, rated_user, stars, comment } = req.body;
    if (!ride_id || !rated_user || !stars) throw new BadRequestError('ride_id, rated_user, stars required.');
    if (stars < 1 || stars > 5) throw new BadRequestError('Stars must be 1-5.');

    const role = req.user.role === 'rider' ? 'rider_rates_driver' : 'driver_rates_rider';

    const { data, error } = await supabase
      .from('ratings')
      .insert({ ride_id, rated_by: req.user.id, rated_user, role, stars, comment })
      .select()
      .single();

    if (error) {
      if (error.code === '23505') throw new BadRequestError('Already rated this ride.');
      throw new BadRequestError(error.message);
    }

    // Update average rating on rated user
    const { data: allRatings } = await supabase
      .from('ratings')
      .select('stars')
      .eq('rated_user', rated_user);

    if (allRatings && allRatings.length > 0) {
      const avg = allRatings.reduce((sum, r) => sum + r.stars, 0) / allRatings.length;
      await supabase
        .from('users')
        .update({ average_rating: parseFloat(avg.toFixed(2)), total_ratings: allRatings.length })
        .eq('id', rated_user);
    }

    successResponse(res, data, 'Rating submitted', 201);
  } catch (e) { next(e); }
});

// Get ratings for a user
router.get('/user/:userId', async (req, res, next) => {
  try {
    const { data } = await supabase
      .from('ratings')
      .select('*')
      .eq('rated_user', req.params.userId)
      .order('created_at', { ascending: false })
      .limit(50);
    successResponse(res, data || []);
  } catch (e) { next(e); }
});

module.exports = router;
