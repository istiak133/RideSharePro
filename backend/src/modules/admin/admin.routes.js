// ============================================
// RideShare AI Pro — Admin Module
// Phase 7: Basic Admin Panel
// ============================================

const express = require('express');
const router = express.Router();
const { supabase } = require('../../config/supabase');
const { authenticate, authorize } = require('../../middleware/auth');
const { successResponse } = require('../../utils/helpers');
const { BadRequestError } = require('../../utils/errors');
const jwt = require('jsonwebtoken');

// 1. Admin Login (Hardcoded MVP bypass for simplicity)
router.post('/login', async (req, res, next) => {
  try {
    const { email, password } = req.body;
    
    // Create admin if not exists in a real app, but for MVP we bypass
    if (email === 'admin@rideshare.com' && password === 'admin123') {
      const token = jwt.sign(
        { id: 'admin-123', role: 'admin', email },
        process.env.JWT_SECRET || 'rideshare-dev-secret-key-change-in-production',
        { expiresIn: '1d' }
      );
      
      return successResponse(res, {
        user: { id: 'admin-123', email, role: 'admin' },
        token
      }, 'Admin logged in successfully');
    }
    
    throw new BadRequestError('Invalid credentials');
  } catch (e) { next(e); }
});

// Require Auth for subsequent routes
router.use(authenticate);

// 2. Get Dashboard Stats
router.get('/stats', async (req, res, next) => {
  try {
    const { count: totalRides } = await supabase.from('rides').select('*', { count: 'exact', head: true });
    const { count: totalDrivers } = await supabase.from('drivers').select('*', { count: 'exact', head: true });
    
    const { data: payments } = await supabase
      .from('payments')
      .select('platform_commission')
      .eq('status', 'completed');
      
    const totalEarnings = payments?.reduce((sum, p) => sum + parseFloat(p.platform_commission || 0), 0) || 0;

    successResponse(res, {
      totalRides: totalRides || 0,
      totalDrivers: totalDrivers || 0,
      totalEarnings: totalEarnings.toFixed(2)
    });
  } catch (e) { next(e); }
});

// 3. Get pending driver verifications
router.get('/drivers/pending', async (req, res, next) => {
  try {
    const { data } = await supabase
      .from('driver_profiles')
      .select('*, users!driver_profiles_user_id_fkey(full_name, phone)')
      .eq('verification_status', 'pending');
      
    successResponse(res, data || []);
  } catch (e) { next(e); }
});

// 4. Verify driver (Approve/Reject)
router.put('/drivers/:id/verify', async (req, res, next) => {
  try {
    const { status } = req.body; // 'approved' or 'rejected'
    if (!['approved', 'rejected'].includes(status)) throw new BadRequestError('Invalid status');

    // Update driver profile
    await supabase
      .from('driver_profiles')
      .update({ verification_status: status })
      .eq('user_id', req.params.id);
      
    // Update main driver table is_verified flag
    await supabase
      .from('drivers')
      .update({ is_verified: status === 'approved' })
      .eq('user_id', req.params.id);

    successResponse(res, null, `Driver ${status} successfully`);
  } catch (e) { next(e); }
});

module.exports = router;
