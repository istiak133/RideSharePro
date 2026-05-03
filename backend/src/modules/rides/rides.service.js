// ============================================
// RideShare AI Pro — Rides Service (Supabase)
// F3-F11: Maps, Fare, Booking, Schedule, OTP, Tracking
// ============================================

const { supabase } = require('../../config/supabase');
const { BadRequestError, NotFoundError } = require('../../utils/errors');
const { generateOTP, hashString, compareHash, roundToNearest5, calculateCommission } = require('../../utils/helpers');
const { RIDE_STATUS, OTP } = require('../../utils/constants');

/**
 * F5: Get fare estimate
 */
const getFareEstimate = async (distance, duration, vehicleType = 'car') => {
  const { data: rule } = await supabase
    .from('fare_rules')
    .select('*')
    .eq('vehicle_type', vehicleType)
    .single();

  if (!rule) throw new NotFoundError('Fare rules not found for vehicle type.');

  // TODO: Add surge pricing logic later
  const surgeMult = 1.0;

  const distanceFare = distance * rule.distance_rate;
  const timeFare = duration * rule.time_rate;
  let totalFare = rule.base_fare + distanceFare + timeFare;
  totalFare = totalFare * surgeMult;
  totalFare = Math.max(totalFare, rule.minimum_fare);
  totalFare = roundToNearest5(totalFare);

  return {
    estimated_fare: totalFare,
    surge_multiplier: surgeMult,
    fare_breakdown: {
      base_fare: rule.base_fare,
      distance_fare: parseFloat(distanceFare.toFixed(2)),
      time_fare: parseFloat(timeFare.toFixed(2)),
      surge_multiplier: surgeMult,
      total: totalFare,
    },
  };
};

/**
 * F6: Create ride booking
 */
const createRide = async (riderId, rideData) => {
  const { pickup_lat, pickup_lng, pickup_address, drop_lat, drop_lng, drop_address,
          vehicle_type, estimated_fare, estimated_distance, estimated_duration,
          surge_multiplier, fare_breakdown, scheduled_at } = rideData;

  // Generate pickup OTP
  const otp = generateOTP(OTP.LENGTH); // 4-digit
  const otpHash = await hashString(otp);

  const status = scheduled_at ? RIDE_STATUS.SCHEDULED : RIDE_STATUS.SEARCHING_DRIVER;

  const { data: ride, error } = await supabase
    .from('rides')
    .insert({
      rider_id: riderId,
      pickup_lat, pickup_lng, pickup_address,
      drop_lat, drop_lng, drop_address,
      vehicle_type: vehicle_type || 'car',
      status,
      estimated_fare, estimated_distance, estimated_duration,
      surge_multiplier: surge_multiplier || 1.0,
      fare_breakdown,
      pickup_otp_hash: otpHash,
      otp_generated_at: new Date().toISOString(),
      scheduled_at: scheduled_at || null,
    })
    .select()
    .single();

  if (error) throw new BadRequestError('Failed to create ride: ' + error.message);

  // F7: If scheduled, create reminder jobs
  if (scheduled_at) {
    const scheduledTime = new Date(scheduled_at);
    const jobs = [
      { job_type: '15min_notify', scheduled_for: new Date(scheduledTime - 15 * 60000).toISOString() },
      { job_type: '10min_retry', scheduled_for: new Date(scheduledTime - 10 * 60000).toISOString() },
      { job_type: '5min_final', scheduled_for: new Date(scheduledTime - 5 * 60000).toISOString() },
    ];
    await supabase.from('scheduled_ride_jobs').insert(
      jobs.map(j => ({ ride_id: ride.id, ...j }))
    );
  }

  return { ...ride, pickup_otp: otp }; // Return plain OTP to rider
};

/**
 * Get ride by ID
 */
const getRide = async (rideId) => {
  const { data, error } = await supabase
    .from('rides')
    .select('*, rider:users!rides_rider_id_fkey(id, full_name, phone, photo_url, average_rating), driver:users!rides_driver_id_fkey(id, full_name, phone, photo_url, average_rating)')
    .eq('id', rideId)
    .single();

  if (error || !data) throw new NotFoundError('Ride not found.');
  return data;
};

/**
 * Get user's ride history
 */
const getRideHistory = async (userId, role, page = 1, limit = 20) => {
  const field = role === 'rider' ? 'rider_id' : 'driver_id';
  const offset = (page - 1) * limit;

  const { data, error, count } = await supabase
    .from('rides')
    .select('*', { count: 'exact' })
    .eq(field, userId)
    .in('status', ['completed', 'cancelled'])
    .order('created_at', { ascending: false })
    .range(offset, offset + limit - 1);

  return { rides: data || [], total: count, page, limit };
};

/**
 * Cancel ride
 */
const cancelRide = async (rideId, userId, reason) => {
  const { data: ride } = await supabase.from('rides').select('status, rider_id, driver_id').eq('id', rideId).single();
  if (!ride) throw new NotFoundError('Ride not found.');
  if (['completed', 'cancelled'].includes(ride.status)) throw new BadRequestError('Cannot cancel this ride.');

  const { data, error } = await supabase
    .from('rides')
    .update({
      status: RIDE_STATUS.CANCELLED,
      cancelled_at: new Date().toISOString(),
      cancelled_by: userId,
      cancellation_reason: reason || null,
    })
    .eq('id', rideId)
    .select()
    .single();

  if (error) throw new BadRequestError(error.message);
  return data;
};

/**
 * F8+F23: Find nearby drivers and send requests
 */
const findNearbyDrivers = async (rideId, pickupLat, pickupLng, radiusKm = 5) => {
  // Simple distance filter using lat/lng bounds
  const latDiff = radiusKm / 111;
  const lngDiff = radiusKm / (111 * Math.cos(pickupLat * Math.PI / 180));

  const { data: drivers } = await supabase
    .from('drivers')
    .select('id, user_id, current_lat, current_lng, acceptance_rate')
    .eq('status', 'online')
    .eq('is_verified', true)
    .gte('current_lat', pickupLat - latDiff)
    .lte('current_lat', pickupLat + latDiff)
    .gte('current_lng', pickupLng - lngDiff)
    .lte('current_lng', pickupLng + lngDiff)
    .order('acceptance_rate', { ascending: false })
    .limit(10);

  if (!drivers || drivers.length === 0) return [];

  // Create ride requests
  const requests = drivers.map(d => ({
    ride_id: rideId,
    driver_id: d.user_id,
  }));

  await supabase.from('ride_requests').insert(requests);
  return drivers;
};

/**
 * F24: Driver accepts ride
 */
const acceptRide = async (rideId, driverUserId) => {
  // Check ride is still available
  const { data: ride } = await supabase
    .from('rides')
    .select('status')
    .eq('id', rideId)
    .single();

  if (!ride || ride.status !== RIDE_STATUS.SEARCHING_DRIVER) {
    throw new BadRequestError('Ride is no longer available.');
  }

  // Assign driver
  const { data, error } = await supabase
    .from('rides')
    .update({ driver_id: driverUserId, status: RIDE_STATUS.DRIVER_ASSIGNED })
    .eq('id', rideId)
    .eq('status', RIDE_STATUS.SEARCHING_DRIVER) // optimistic lock
    .select()
    .single();

  if (error || !data) throw new BadRequestError('Ride already taken by another driver.');

  // Update ride request
  await supabase
    .from('ride_requests')
    .update({ response: 'accepted', responded_at: new Date().toISOString() })
    .eq('ride_id', rideId)
    .eq('driver_id', driverUserId);

  // Update driver stats
  const { data: driverStats } = await supabase
    .from('drivers')
    .select('total_accepts, total_requests')
    .eq('user_id', driverUserId)
    .single();

  if (driverStats) {
    const newAccepts = (driverStats.total_accepts || 0) + 1;
    const newRequests = (driverStats.total_requests || 0) + 1;
    await supabase
      .from('drivers')
      .update({
        status: 'busy',
        total_accepts: newAccepts,
        total_requests: newRequests,
        acceptance_rate: parseFloat(((newAccepts / newRequests) * 100).toFixed(2)),
      })
      .eq('user_id', driverUserId);
  }

  // Expire other pending requests
  await supabase
    .from('ride_requests')
    .update({ response: 'expired', responded_at: new Date().toISOString() })
    .eq('ride_id', rideId)
    .eq('response', 'pending')
    .neq('driver_id', driverUserId);

  return data;
};

/**
 * F24: Driver declines ride
 */
const declineRide = async (rideId, driverUserId) => {
  await supabase
    .from('ride_requests')
    .update({ response: 'declined', responded_at: new Date().toISOString() })
    .eq('ride_id', rideId)
    .eq('driver_id', driverUserId);

  // Update driver stats
  const { data: driverStats } = await supabase
    .from('drivers')
    .select('total_declines, total_requests')
    .eq('user_id', driverUserId)
    .single();

  if (driverStats) {
    await supabase
      .from('drivers')
      .update({
        total_declines: (driverStats.total_declines || 0) + 1,
        total_requests: (driverStats.total_requests || 0) + 1,
      })
      .eq('user_id', driverUserId);
  }

  return { message: 'Ride declined' };
};

/**
 * F10+F26: Verify pickup OTP
 */
const verifyPickupOTP = async (rideId, driverUserId, otpCode) => {
  const { data: ride } = await supabase
    .from('rides')
    .select('pickup_otp_hash, otp_attempts, driver_id, status')
    .eq('id', rideId)
    .single();

  if (!ride) throw new NotFoundError('Ride not found.');
  if (ride.driver_id !== driverUserId) throw new BadRequestError('Not your ride.');
  if (ride.otp_attempts >= 3) throw new BadRequestError('Max OTP attempts reached.');

  const isValid = await compareHash(otpCode, ride.pickup_otp_hash);

  // Log audit
  await supabase.from('otp_audit_log').insert({
    ride_id: rideId,
    driver_id: driverUserId,
    attempt_number: ride.otp_attempts + 1,
    success: isValid,
  });

  if (!isValid) {
    await supabase.from('rides').update({ otp_attempts: ride.otp_attempts + 1 }).eq('id', rideId);
    throw new BadRequestError(`Wrong OTP. ${2 - ride.otp_attempts} attempts left.`);
  }

  // OTP verified — update ride
  await supabase
    .from('rides')
    .update({ otp_verified: true, status: RIDE_STATUS.ARRIVED })
    .eq('id', rideId);

  return { message: 'OTP verified! Ready to start ride.' };
};

/**
 * F27: Start ride
 */
const startRide = async (rideId, driverUserId) => {
  const { data, error } = await supabase
    .from('rides')
    .update({ status: RIDE_STATUS.STARTED, started_at: new Date().toISOString() })
    .eq('id', rideId)
    .eq('driver_id', driverUserId)
    .eq('otp_verified', true)
    .select()
    .single();

  if (error || !data) throw new BadRequestError('Cannot start. OTP not verified or not your ride.');
  return data;
};

/**
 * F29: Complete ride
 */
const completeRide = async (rideId, driverUserId, actualDistance, actualDuration) => {
  const { data: ride } = await supabase.from('rides').select('*').eq('id', rideId).single();
  if (!ride || ride.driver_id !== driverUserId) throw new BadRequestError('Not your ride.');
  if (ride.status !== RIDE_STATUS.STARTED) throw new BadRequestError('Ride not started.');

  // Recalculate fare based on actual distance/duration
  const fareEstimate = await getFareEstimate(actualDistance || ride.estimated_distance, actualDuration || ride.estimated_duration);

  const { data, error } = await supabase
    .from('rides')
    .update({
      status: RIDE_STATUS.COMPLETED,
      completed_at: new Date().toISOString(),
      final_fare: fareEstimate.estimated_fare,
      actual_distance: actualDistance || ride.estimated_distance,
      actual_duration: actualDuration || ride.estimated_duration,
    })
    .eq('id', rideId)
    .select()
    .single();

  if (error) throw new BadRequestError(error.message);

  // Update driver total_rides
  await supabase.rpc('increment_driver_rides', { driver_user_id: driverUserId }).catch(() => {});
  // Fallback: manual update if RPC doesn't exist
  const { data: driver } = await supabase.from('drivers').select('total_rides').eq('user_id', driverUserId).single();
  if (driver) {
    await supabase.from('drivers').update({ total_rides: (driver.total_rides || 0) + 1, status: 'online' }).eq('user_id', driverUserId);
  }

  return data;
};

/**
 * F11: Record route point (GPS telemetry)
 */
const recordRoutePoint = async (rideId, lat, lng, speed, heading) => {
  await supabase.from('ride_route_points').insert({ ride_id: rideId, lat, lng, speed, heading });
  return { message: 'Point recorded' };
};

/**
 * F22: Toggle driver online/offline
 */
const toggleDriverStatus = async (userId, status, lat, lng) => {
  const updateData = { status };
  if (lat && lng) {
    updateData.current_lat = lat;
    updateData.current_lng = lng;
    updateData.last_location_update = new Date().toISOString();
  }

  const { data, error } = await supabase
    .from('drivers')
    .update(updateData)
    .eq('user_id', userId)
    .select()
    .single();

  if (error) throw new BadRequestError(error.message);
  return data;
};

/**
 * Update driver location
 */
const updateDriverLocation = async (userId, lat, lng) => {
  await supabase
    .from('drivers')
    .update({ current_lat: lat, current_lng: lng, last_location_update: new Date().toISOString() })
    .eq('user_id', userId);
  return { message: 'Location updated' };
};

module.exports = {
  getFareEstimate, createRide, getRide, getRideHistory, cancelRide,
  findNearbyDrivers, acceptRide, declineRide,
  verifyPickupOTP, startRide, completeRide, recordRoutePoint,
  toggleDriverStatus, updateDriverLocation,
};
