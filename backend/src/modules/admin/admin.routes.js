// ============================================
// RideShare AI Pro — Admin Module
// F33-F38, F42-F44: Admin Panel APIs
// ============================================

const express = require('express');
const router = express.Router();
const { supabase } = require('../../config/supabase');
const { successResponse } = require('../../utils/helpers');
const { BadRequestError, UnauthorizedError } = require('../../utils/errors');
const { hashString, compareHash, generateToken } = require('../../utils/helpers');

// ── F33: Admin Login ──────────────────────────
router.post('/login', async (req, res, next) => {
  try {
    const { email, password } = req.body;
    if (!email || !password) throw new BadRequestError('Email and password required.');

    const { data: admin } = await supabase
      .from('admin_users')
      .select('*')
      .eq('email', email)
      .single();

    if (!admin) throw new UnauthorizedError('Invalid credentials.');
    if (!admin.is_active) throw new UnauthorizedError('Account disabled.');

    const valid = await compareHash(password, admin.password_hash);
    if (!valid) {
      await supabase.from('admin_users')
        .update({ failed_login_attempts: (admin.failed_login_attempts || 0) + 1 })
        .eq('id', admin.id);
      throw new UnauthorizedError('Invalid credentials.');
    }

    // Reset failed attempts & update last login
    await supabase.from('admin_users')
      .update({ failed_login_attempts: 0, last_login: new Date().toISOString() })
      .eq('id', admin.id);

    const token = generateToken({ adminId: admin.id, role: admin.role, isAdmin: true }, '8h');

    successResponse(res, { token, admin: { id: admin.id, email: admin.email, role: admin.role } });
  } catch (e) { next(e); }
});

// Admin auth middleware (inline for simplicity)
const adminAuth = async (req, res, next) => {
  try {
    const authHeader = req.headers.authorization;
    if (!authHeader) throw new UnauthorizedError('No token.');
    const token = authHeader.split(' ')[1];
    const { verifyToken } = require('../../utils/helpers');
    const decoded = verifyToken(token);
    if (!decoded.isAdmin) throw new UnauthorizedError('Not admin.');
    req.admin = decoded;
    next();
  } catch (e) { next(new UnauthorizedError('Invalid admin token.')); }
};

// ── F36: Dashboard ────────────────────────────
router.get('/dashboard', adminAuth, async (req, res, next) => {
  try {
    const { count: totalUsers } = await supabase.from('users').select('*', { count: 'exact', head: true });
    const { count: totalRiders } = await supabase.from('users').select('*', { count: 'exact', head: true }).eq('role', 'rider');
    const { count: totalDrivers } = await supabase.from('users').select('*', { count: 'exact', head: true }).eq('role', 'driver');
    const { count: totalRides } = await supabase.from('rides').select('*', { count: 'exact', head: true });
    const { count: completedRides } = await supabase.from('rides').select('*', { count: 'exact', head: true }).eq('status', 'completed');
    const { count: pendingVerifications } = await supabase.from('driver_profiles').select('*', { count: 'exact', head: true }).eq('verification_status', 'pending');
    const { count: openDisputes } = await supabase.from('disputes').select('*', { count: 'exact', head: true }).eq('status', 'open');

    successResponse(res, {
      totalUsers, totalRiders, totalDrivers, totalRides, completedRides, pendingVerifications, openDisputes,
    });
  } catch (e) { next(e); }
});

// ── F35: Driver Verification ──────────────────
router.get('/drivers/pending', adminAuth, async (req, res, next) => {
  try {
    const { data } = await supabase
      .from('driver_profiles')
      .select('*, user:users(id, phone, full_name, photo_url)')
      .eq('verification_status', 'pending')
      .order('created_at', { ascending: true });
    successResponse(res, data || []);
  } catch (e) { next(e); }
});

router.put('/drivers/:userId/verify', adminAuth, async (req, res, next) => {
  try {
    const { action, reason } = req.body; // action: 'approved' or 'rejected'
    if (!['approved', 'rejected'].includes(action)) throw new BadRequestError('Action must be approved or rejected.');

    const updateData = { verification_status: action, verified_by: req.admin.adminId, verified_at: new Date().toISOString() };
    if (action === 'rejected') updateData.rejection_reason = reason;

    await supabase.from('driver_profiles').update(updateData).eq('user_id', req.params.userId);

    // If approved, mark driver as verified
    if (action === 'approved') {
      await supabase.from('drivers').update({ is_verified: true }).eq('user_id', req.params.userId);
    }

    // Log verification
    await supabase.from('verification_logs').insert({
      driver_id: req.params.userId,
      admin_id: req.admin.adminId,
      action,
      reason,
    });

    // Audit log
    await supabase.from('audit_logs').insert({
      admin_id: req.admin.adminId,
      action: `driver_${action}`,
      entity_type: 'driver_profile',
      entity_id: req.params.userId,
      details: { reason },
    });

    successResponse(res, { message: `Driver ${action}` });
  } catch (e) { next(e); }
});

// ── F37: Ride Monitoring ──────────────────────
router.get('/rides', adminAuth, async (req, res, next) => {
  try {
    const { status, page = 1 } = req.query;
    const limit = 20;
    const offset = (page - 1) * limit;

    let query = supabase.from('rides').select('*, rider:users!rides_rider_id_fkey(full_name, phone), driver:users!rides_driver_id_fkey(full_name, phone)', { count: 'exact' });
    if (status) query = query.eq('status', status);

    const { data, count } = await query.order('created_at', { ascending: false }).range(offset, offset + limit - 1);
    successResponse(res, { rides: data || [], total: count, page: parseInt(page) });
  } catch (e) { next(e); }
});

// ── F38: User Management ──────────────────────
router.get('/users', adminAuth, async (req, res, next) => {
  try {
    const { role, status, search, page = 1 } = req.query;
    const limit = 20;
    const offset = (page - 1) * limit;

    let query = supabase.from('users').select('*', { count: 'exact' });
    if (role) query = query.eq('role', role);
    if (status) query = query.eq('status', status);
    if (search) query = query.or(`phone.ilike.%${search}%,full_name.ilike.%${search}%`);

    const { data, count } = await query.order('created_at', { ascending: false }).range(offset, offset + limit - 1);
    successResponse(res, { users: data || [], total: count, page: parseInt(page) });
  } catch (e) { next(e); }
});

router.put('/users/:id/block', adminAuth, async (req, res, next) => {
  try {
    const { status } = req.body; // 'active' or 'blocked'
    await supabase.from('users').update({ status }).eq('id', req.params.id);
    await supabase.from('audit_logs').insert({
      admin_id: req.admin.adminId, action: `user_${status}`, entity_type: 'user', entity_id: req.params.id,
    });
    successResponse(res, { message: `User ${status}` });
  } catch (e) { next(e); }
});

// ── F42: Disputes ─────────────────────────────
router.get('/disputes', adminAuth, async (req, res, next) => {
  try {
    const { data } = await supabase
      .from('disputes')
      .select('*, ride:rides(id, pickup_address, drop_address), reporter:users!disputes_reported_by_fkey(full_name, phone)')
      .order('created_at', { ascending: false });
    successResponse(res, data || []);
  } catch (e) { next(e); }
});

router.put('/disputes/:id/resolve', adminAuth, async (req, res, next) => {
  try {
    const { resolution, refund_amount } = req.body;
    await supabase.from('disputes').update({
      status: 'resolved', resolution, resolved_by: req.admin.adminId,
      refund_amount: refund_amount || 0, refund_issued: !!refund_amount,
    }).eq('id', req.params.id);
    successResponse(res, { message: 'Dispute resolved' });
  } catch (e) { next(e); }
});

// User can submit dispute
router.post('/disputes', async (req, res, next) => {
  try {
    const { ride_id, reported_against, reason } = req.body;
    // Get auth header to check if user or admin
    const authHeader = req.headers.authorization;
    const token = authHeader?.split(' ')[1];
    const { verifyToken } = require('../../utils/helpers');
    const decoded = verifyToken(token);

    const { data, error } = await supabase.from('disputes').insert({
      ride_id, reported_by: decoded.userId || decoded.adminId, reported_against, reason,
    }).select().single();

    if (error) throw new BadRequestError(error.message);
    successResponse(res, data, 'Dispute submitted', 201);
  } catch (e) { next(e); }
});

// ── F43: Broadcast Notifications ──────────────
router.post('/broadcast', adminAuth, async (req, res, next) => {
  try {
    const { target_type, title, body } = req.body;
    const { data, error } = await supabase.from('broadcast_notifications').insert({
      admin_id: req.admin.adminId, target_type, title, body, status: 'sent', sent_at: new Date().toISOString(),
    }).select().single();
    if (error) throw new BadRequestError(error.message);
    successResponse(res, data, 'Broadcast sent', 201);
  } catch (e) { next(e); }
});

// ── F44: Settlements ──────────────────────────
router.get('/settlements', adminAuth, async (req, res, next) => {
  try {
    const { data } = await supabase
      .from('driver_settlements')
      .select('*, driver:users(full_name, phone)')
      .order('created_at', { ascending: false });
    successResponse(res, data || []);
  } catch (e) { next(e); }
});

// ── Create first admin (one-time setup) ───────
router.post('/setup', async (req, res, next) => {
  try {
    const { email, password } = req.body;
    const { count } = await supabase.from('admin_users').select('*', { count: 'exact', head: true });
    if (count > 0) throw new BadRequestError('Admin already exists. Use login.');

    const hash = await hashString(password);
    const { data, error } = await supabase.from('admin_users')
      .insert({ email, password_hash: hash, role: 'super_admin' })
      .select('id, email, role')
      .single();

    if (error) throw new BadRequestError(error.message);
    successResponse(res, data, 'Super admin created', 201);
  } catch (e) { next(e); }
});

module.exports = router;
