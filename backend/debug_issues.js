#!/usr/bin/env node
/**
 * Debug script to identify specific errors in failing features
 */

const axios = require('axios');
require('dotenv').config();

const API = 'http://localhost:3000/api';

async function test(featureName, fn) {
  try {
    console.log(`\n🔍 Testing: ${featureName}`);
    await fn();
  } catch (err) {
    console.error(`❌ Error:`, err.response?.data || err.message);
  }
}

async function runDebug() {
  console.log('\n🐛 DEBUGGING FAILED FEATURES\n');

  try {
    // Get OTP and tokens first
    const riderOtpRes = await axios.post(`${API}/auth/request-otp`, { phone: '01611111111' });
    const riderOTP = riderOtpRes.data.data.devOTP;
    
    const riderAuthRes = await axios.post(`${API}/auth/verify-otp`, {
      phone: '01611111111',
      otp: riderOTP,
      role: 'rider'
    });
    const riderToken = riderAuthRes.data.data.token;
    const riderId = riderAuthRes.data.data.user.id;

    const driverOtpRes = await axios.post(`${API}/auth/request-otp`, { phone: '01822222222' });
    const driverOTP = driverOtpRes.data.data.devOTP;
    
    const driverAuthRes = await axios.post(`${API}/auth/verify-otp`, {
      phone: '01822222222',
      otp: driverOTP,
      role: 'driver'
    });
    const driverToken = driverAuthRes.data.data.token;
    const driverId = driverAuthRes.data.data.user.id;

    console.log(`✅ Rider Token: ${riderToken.substring(0, 20)}...`);
    console.log(`✅ Driver Token: ${driverToken.substring(0, 20)}...`);

    // ━━━━━━━━━━━━━━━━━━━━━━━━━━━━
    // ISSUE 1: F20 - Driver Document Upload
    // ━━━━━━━━━━━━━━━━━━━━━━━━━━━━
    await test('F20: Driver Document Upload', async () => {
      const docRes = await axios.post(`${API}/users/driver/documents`, {
        nid_front_url: 'https://placeholder.com/nid-front.jpg',
        nid_back_url: 'https://placeholder.com/nid-back.jpg',
        license_url: 'https://placeholder.com/license.jpg',
        vehicle_photo_url: 'https://placeholder.com/vehicle.jpg',
        vehicle_model: 'Toyota Corolla',
        vehicle_year: 2022,
        registration_number: 'DHAKA-CA-12345',
        account_holder_name: 'Ahmed Hassan',
        account_number: '1234567890',
        bank_name: 'Dhaka Bank',
        branch_name: 'Gulshan Branch'
      }, { headers: { 'Authorization': `Bearer ${driverToken}` }});
      console.log('  Response:', JSON.stringify(docRes.data, null, 2));
    });

    // ━━━━━━━━━━━━━━━━━━━━━━━━━━━━
    // ISSUE 2: F10 - OTP Verification
    // ━━━━━━━━━━━━━━━━━━━━━━━━━━━━
    await test('F10/F26: OTP Verification', async () => {
      // Create ride first
      const rideRes = await axios.post(`${API}/rides`, {
        pickup_lat: 23.8103,
        pickup_lng: 90.4125,
        pickup_address: 'Gulshan 1, Dhaka',
        drop_lat: 23.7461,
        drop_lng: 90.3742,
        drop_address: 'Dhanmondi 27, Dhaka',
        vehicle_type: 'car',
        estimated_fare: 260,
        estimated_distance: 5,
        estimated_duration: 15,
        fare_breakdown: { base_fare: 80, distance_fare: 150, time_fare: 30, total: 260 }
      }, { headers: { 'Authorization': `Bearer ${riderToken}` }});
      
      const rideId = rideRes.data.data.id;
      const pickupOtp = rideRes.data.data.pickup_otp;
      
      console.log(`  Ride created: ${rideId}`);
      console.log(`  Pickup OTP: ${pickupOtp}`);
      
      // Driver goes online
      await axios.put(`${API}/rides/driver/toggle`, {
        status: 'online',
        current_lat: 23.8110,
        current_lng: 90.4115
      }, { headers: { 'Authorization': `Bearer ${driverToken}` }});
      
      // Driver accepts
      const acceptRes = await axios.post(`${API}/rides/${rideId}/accept`, {}, 
        { headers: { 'Authorization': `Bearer ${driverToken}` }});
      
      console.log(`  Driver accepted: ${acceptRes.data.data.status}`);
      
      // Now verify OTP
      const otpVerRes = await axios.post(`${API}/rides/${rideId}/verify-otp`, {
        otp: pickupOtp
      }, { headers: { 'Authorization': `Bearer ${driverToken}` }});
      
      console.log('  OTP Verify Response:', JSON.stringify(otpVerRes.data, null, 2));
    });

    // ━━━━━━━━━━━━━━━━━━━━━━━━━━━━
    // ISSUE 3: F30 - Driver Earnings
    // ━━━━━━━━━━━━━━━━━━━━━━━━━━━━
    await test('F30: Driver Earnings Dashboard', async () => {
      const earningsRes = await axios.get(`${API}/payments/earnings`,
        { headers: { 'Authorization': `Bearer ${driverToken}` }});
      
      console.log('  Earnings Response:', JSON.stringify(earningsRes.data, null, 2));
    });

    // ━━━━━━━━━━━━━━━━━━━━━━━━━━━━
    // ISSUE 4: F16 - Rating & Review
    // ━━━━━━━━━━━━━━━━━━━━━━━━━━━━
    await test('F16: Rating & Review', async () => {
      // Need a completed ride first
      const rideRes = await axios.post(`${API}/rides`, {
        pickup_lat: 23.8103,
        pickup_lng: 90.4125,
        pickup_address: 'Gulshan 2',
        drop_lat: 23.7461,
        drop_lng: 90.3742,
        drop_address: 'Dhanmondi',
        vehicle_type: 'car',
        estimated_fare: 300,
        estimated_distance: 6,
        estimated_duration: 18,
        fare_breakdown: { base_fare: 80, distance_fare: 180, time_fare: 40, total: 300 }
      }, { headers: { 'Authorization': `Bearer ${riderToken}` }});
      
      const rideId = rideRes.data.data.id;
      
      // Accept, verify OTP, start, complete
      await axios.put(`${API}/rides/driver/toggle`, {
        status: 'online',
        current_lat: 23.8110,
        current_lng: 90.4115
      }, { headers: { 'Authorization': `Bearer ${driverToken}` }});
      
      const acceptRes = await axios.post(`${API}/rides/${rideId}/accept`, {}, 
        { headers: { 'Authorization': `Bearer ${driverToken}` }});
      
      const pickupOtp = rideRes.data.data.pickup_otp;
      
      await axios.post(`${API}/rides/${rideId}/verify-otp`, { otp: pickupOtp }, 
        { headers: { 'Authorization': `Bearer ${driverToken}` }});
      
      await axios.put(`${API}/rides/${rideId}/start`, {}, 
        { headers: { 'Authorization': `Bearer ${driverToken}` }});
      
      const completeRes = await axios.put(`${API}/rides/${rideId}/complete`, { final_fare: 300 }, 
        { headers: { 'Authorization': `Bearer ${driverToken}` }});
      
      console.log(`  Ride completed: ${completeRes.data.data.status}`);
      
      // Now try to rate
      const ratingRes = await axios.post(`${API}/ratings`, {
        ride_id: rideId,
        rated_user: driverId,
        stars: 5,
        comment: 'Excellent ride!'
      }, { headers: { 'Authorization': `Bearer ${riderToken}` }});
      
      console.log('  Rating Response:', JSON.stringify(ratingRes.data, null, 2));
    });

  } catch (err) {
    console.error('\n❌ Critical Error:', err.message);
  }
}

runDebug();
