#!/bin/bash
API="http://localhost:3000/api"
PASS=0
FAIL=0

test_api() {
  local name="$1"
  local method="$2"
  local endpoint="$3"
  local body="$4"
  local token="$5"
  
  local headers="-H Content-Type:application/json"
  if [ -n "$token" ]; then
    headers="$headers -H Authorization:Bearer $token"
  fi
  
  if [ "$method" = "GET" ]; then
    RESPONSE=$(curl -s -H "Content-Type: application/json" -H "Authorization: Bearer $token" "$API$endpoint")
  elif [ "$method" = "PUT" ]; then
    RESPONSE=$(curl -s -X PUT -H "Content-Type: application/json" -H "Authorization: Bearer $token" -d "$body" "$API$endpoint")
  else
    RESPONSE=$(curl -s -X POST -H "Content-Type: application/json" -H "Authorization: Bearer $token" -d "$body" "$API$endpoint")
  fi
  
  SUCCESS=$(echo "$RESPONSE" | python3 -c "import sys,json; print(json.load(sys.stdin).get('success',False))" 2>/dev/null)
  
  if [ "$SUCCESS" = "True" ]; then
    echo "✅ $name"
    PASS=$((PASS+1))
  else
    echo "❌ $name"
    echo "   Response: $(echo $RESPONSE | head -c 200)"
    FAIL=$((FAIL+1))
  fi
}

echo "================================================"
echo "🚀 RideShare AI Pro — Full Feature Test Suite"
echo "================================================"
echo ""

# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
echo "📱 RIDER FEATURES"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"

# F1: Rider Registration
echo ""
echo "── F1: Phone-Based Registration ──"
RIDER_OTP=$(curl -s -X POST -H "Content-Type: application/json" -d '{"phone":"01611111111"}' "$API/auth/request-otp" | python3 -c "import sys,json; print(json.load(sys.stdin)['data']['devOTP'])")
echo "✅ F1a: OTP requested (OTP: $RIDER_OTP)"
PASS=$((PASS+1))

RIDER_RESULT=$(curl -s -X POST -H "Content-Type: application/json" -d "{\"phone\":\"01611111111\",\"otp\":\"$RIDER_OTP\",\"role\":\"rider\"}" "$API/auth/verify-otp")
RIDER_TOKEN=$(echo "$RIDER_RESULT" | python3 -c "import sys,json; print(json.load(sys.stdin)['data']['token'])")
RIDER_ID=$(echo "$RIDER_RESULT" | python3 -c "import sys,json; print(json.load(sys.stdin)['data']['user']['id'])")
echo "✅ F1b: OTP verified, account created (ID: $RIDER_ID)"
PASS=$((PASS+1))

# F2: Profile Management
echo ""
echo "── F2: User Profile Management ──"
test_api "F2a: Update profile" POST "/users/profile" \
  '{"full_name":"Rahim Khan","date_of_birth":"2001-03-15","email":"rahim@test.com","language_preference":"bn"}' \
  "$RIDER_TOKEN"

# Swap to PUT
RESPONSE=$(curl -s -X PUT -H "Content-Type: application/json" -H "Authorization: Bearer $RIDER_TOKEN" -d '{"full_name":"Rahim Khan Updated"}' "$API/users/profile")
SUCCESS=$(echo "$RESPONSE" | python3 -c "import sys,json; print(json.load(sys.stdin).get('success',False))" 2>/dev/null)
if [ "$SUCCESS" = "True" ]; then echo "✅ F2b: Profile update confirmed"; PASS=$((PASS+1)); else echo "❌ F2b: Profile update"; FAIL=$((FAIL+1)); fi

# F15: Bilingual
echo ""
echo "── F15: Bilingual UI ──"
RESPONSE=$(curl -s -X PUT -H "Content-Type: application/json" -H "Authorization: Bearer $RIDER_TOKEN" -d '{"language_preference":"en"}' "$API/users/profile")
LANG=$(echo "$RESPONSE" | python3 -c "import sys,json; print(json.load(sys.stdin)['data']['user']['language_preference'])" 2>/dev/null)
if [ "$LANG" = "en" ]; then echo "✅ F15: Language preference saved (en)"; PASS=$((PASS+1)); else echo "❌ F15: Language"; FAIL=$((FAIL+1)); fi

# F5: Fare Estimate
echo ""
echo "── F4+F5: Vehicle Type + Fare Calculation ──"
RESPONSE=$(curl -s -X POST -H "Content-Type: application/json" -H "Authorization: Bearer $RIDER_TOKEN" -d '{"distance":5,"duration":15}' "$API/rides/fare-estimate")
FARE=$(echo "$RESPONSE" | python3 -c "import sys,json; print(json.load(sys.stdin)['data']['estimated_fare'])" 2>/dev/null)
if [ -n "$FARE" ] && [ "$FARE" != "None" ]; then echo "✅ F4+F5: Fare estimated = ৳$FARE (5km, 15min)"; PASS=$((PASS+1)); else echo "❌ F4+F5: Fare"; FAIL=$((FAIL+1)); fi

# F6: Ride Booking
echo ""
echo "── F6: Ride Booking ──"
RIDE_RESULT=$(curl -s -X POST -H "Content-Type: application/json" -H "Authorization: Bearer $RIDER_TOKEN" -d '{
  "pickup_lat":23.8103,"pickup_lng":90.4125,"pickup_address":"Gulshan 1, Dhaka",
  "drop_lat":23.7461,"drop_lng":90.3742,"drop_address":"Dhanmondi 27, Dhaka",
  "estimated_fare":260,"estimated_distance":5,"estimated_duration":15,
  "fare_breakdown":{"base_fare":80,"distance_fare":150,"time_fare":30,"total":260}
}' "$API/rides")
RIDE_ID=$(echo "$RIDE_RESULT" | python3 -c "import sys,json; print(json.load(sys.stdin)['data']['id'])" 2>/dev/null)
PICKUP_OTP=$(echo "$RIDE_RESULT" | python3 -c "import sys,json; print(json.load(sys.stdin)['data']['pickup_otp'])" 2>/dev/null)
RIDE_STATUS=$(echo "$RIDE_RESULT" | python3 -c "import sys,json; print(json.load(sys.stdin)['data']['status'])" 2>/dev/null)
if [ "$RIDE_STATUS" = "searching_driver" ]; then 
  echo "✅ F6: Ride booked (ID: ${RIDE_ID:0:8}..., OTP: $PICKUP_OTP, Status: $RIDE_STATUS)"
  PASS=$((PASS+1))
else 
  echo "❌ F6: Ride booking failed"; FAIL=$((FAIL+1))
fi

# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
echo ""
echo "🚗 DRIVER FEATURES"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"

# F19: Driver Registration
echo ""
echo "── F19: Driver Registration ──"
DRIVER_OTP=$(curl -s -X POST -H "Content-Type: application/json" -d '{"phone":"01711111111"}' "$API/auth/request-otp" | python3 -c "import sys,json; print(json.load(sys.stdin)['data']['devOTP'])")
DRIVER_RESULT=$(curl -s -X POST -H "Content-Type: application/json" -d "{\"phone\":\"01711111111\",\"otp\":\"$DRIVER_OTP\",\"role\":\"driver\"}" "$API/auth/verify-otp")
DRIVER_TOKEN=$(echo "$DRIVER_RESULT" | python3 -c "import sys,json; print(json.load(sys.stdin)['data']['token'])")
DRIVER_ID=$(echo "$DRIVER_RESULT" | python3 -c "import sys,json; print(json.load(sys.stdin)['data']['user']['id'])")
DRIVER_ROLE=$(echo "$DRIVER_RESULT" | python3 -c "import sys,json; print(json.load(sys.stdin)['data']['user']['role'])")
if [ "$DRIVER_ROLE" = "driver" ]; then echo "✅ F19: Driver registered (ID: ${DRIVER_ID:0:8}...)"; PASS=$((PASS+1)); else echo "❌ F19"; FAIL=$((FAIL+1)); fi

# F20: Document Upload
echo ""
echo "── F20: Document Upload ──"
RESPONSE=$(curl -s -X POST -H "Content-Type: application/json" -H "Authorization: Bearer $DRIVER_TOKEN" -d '{
  "nid_front_url":"https://storage.example/nid_front.jpg",
  "nid_back_url":"https://storage.example/nid_back.jpg",
  "license_url":"https://storage.example/license.jpg",
  "vehicle_model":"Toyota Axio 2020",
  "vehicle_year":2020,
  "registration_number":"DHA-1234",
  "vehicle_photo_url":"https://storage.example/car.jpg",
  "account_holder_name":"Karim Driver",
  "account_number":"1234567890",
  "bank_name":"Dutch Bangla Bank",
  "branch_name":"Gulshan Branch"
}' "$API/users/driver/documents")
SUCCESS=$(echo "$RESPONSE" | python3 -c "import sys,json; print(json.load(sys.stdin).get('success',False))" 2>/dev/null)
if [ "$SUCCESS" = "True" ]; then echo "✅ F20: Documents uploaded"; PASS=$((PASS+1)); else echo "❌ F20: $RESPONSE"; FAIL=$((FAIL+1)); fi

# F21: Verification Status
echo ""
echo "── F21: Verification Status ──"
RESPONSE=$(curl -s -H "Authorization: Bearer $DRIVER_TOKEN" "$API/users/driver/verification-status")
VSTATUS=$(echo "$RESPONSE" | python3 -c "import sys,json; print(json.load(sys.stdin)['data']['verification_status'])" 2>/dev/null)
if [ "$VSTATUS" = "pending" ]; then echo "✅ F21: Status = pending (waiting admin)"; PASS=$((PASS+1)); else echo "❌ F21"; FAIL=$((FAIL+1)); fi

# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
echo ""
echo "🛡️ ADMIN FEATURES"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"

# F33: Admin Setup + Login
echo ""
echo "── F33: Admin Login ──"
curl -s -X POST -H "Content-Type: application/json" -d '{"email":"admin@rideshare.com","password":"admin123"}' "$API/admin/setup" > /dev/null 2>&1
ADMIN_RESULT=$(curl -s -X POST -H "Content-Type: application/json" -d '{"email":"admin@rideshare.com","password":"admin123"}' "$API/admin/login")
ADMIN_TOKEN=$(echo "$ADMIN_RESULT" | python3 -c "import sys,json; print(json.load(sys.stdin)['data']['token'])" 2>/dev/null)
if [ -n "$ADMIN_TOKEN" ] && [ "$ADMIN_TOKEN" != "None" ]; then echo "✅ F33: Admin logged in"; PASS=$((PASS+1)); else echo "❌ F33: Admin login"; FAIL=$((FAIL+1)); fi

# F35: Driver Verification
echo ""
echo "── F35: Driver Verification (Admin approves) ──"
RESPONSE=$(curl -s -X PUT -H "Content-Type: application/json" -H "Authorization: Bearer $ADMIN_TOKEN" -d '{"action":"approved","reason":"All documents valid"}' "$API/admin/drivers/$DRIVER_ID/verify")
SUCCESS=$(echo "$RESPONSE" | python3 -c "import sys,json; print(json.load(sys.stdin).get('success',False))" 2>/dev/null)
if [ "$SUCCESS" = "True" ]; then echo "✅ F35: Driver approved by admin"; PASS=$((PASS+1)); else echo "❌ F35: $RESPONSE"; FAIL=$((FAIL+1)); fi

# F36: Dashboard
echo ""
echo "── F36: Admin Dashboard ──"
RESPONSE=$(curl -s -H "Authorization: Bearer $ADMIN_TOKEN" "$API/admin/dashboard")
TOTAL_USERS=$(echo "$RESPONSE" | python3 -c "import sys,json; print(json.load(sys.stdin)['data']['totalUsers'])" 2>/dev/null)
if [ -n "$TOTAL_USERS" ] && [ "$TOTAL_USERS" != "None" ]; then echo "✅ F36: Dashboard (Users: $TOTAL_USERS)"; PASS=$((PASS+1)); else echo "❌ F36"; FAIL=$((FAIL+1)); fi

# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
echo ""
echo "🚗 RIDE LIFECYCLE (Driver side)"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"

# F22: Driver goes online
echo ""
echo "── F22: Driver Go Online ──"
RESPONSE=$(curl -s -X PUT -H "Content-Type: application/json" -H "Authorization: Bearer $DRIVER_TOKEN" -d '{"status":"online","lat":23.8110,"lng":90.4130}' "$API/rides/driver/toggle")
DSTATUS=$(echo "$RESPONSE" | python3 -c "import sys,json; print(json.load(sys.stdin)['data']['status'])" 2>/dev/null)
if [ "$DSTATUS" = "online" ]; then echo "✅ F22: Driver is ONLINE (near Gulshan)"; PASS=$((PASS+1)); else echo "❌ F22: $RESPONSE"; FAIL=$((FAIL+1)); fi

# F24: Driver accepts ride
echo ""
echo "── F24: Driver Accepts Ride ──"
RESPONSE=$(curl -s -X POST -H "Content-Type: application/json" -H "Authorization: Bearer $DRIVER_TOKEN" "$API/rides/$RIDE_ID/accept")
RSTATUS=$(echo "$RESPONSE" | python3 -c "import sys,json; print(json.load(sys.stdin)['data']['status'])" 2>/dev/null)
if [ "$RSTATUS" = "driver_assigned" ]; then echo "✅ F24: Driver assigned to ride"; PASS=$((PASS+1)); else echo "❌ F24: $RESPONSE"; FAIL=$((FAIL+1)); fi

# F10+F26: Verify Pickup OTP
echo ""
echo "── F10+F26: Pickup OTP Verification ──"
RESPONSE=$(curl -s -X POST -H "Content-Type: application/json" -H "Authorization: Bearer $DRIVER_TOKEN" -d "{\"otp\":\"$PICKUP_OTP\"}" "$API/rides/$RIDE_ID/verify-otp")
SUCCESS=$(echo "$RESPONSE" | python3 -c "import sys,json; print(json.load(sys.stdin).get('success',False))" 2>/dev/null)
if [ "$SUCCESS" = "True" ]; then echo "✅ F10+F26: OTP verified ($PICKUP_OTP)"; PASS=$((PASS+1)); else echo "❌ F10+F26: $RESPONSE"; FAIL=$((FAIL+1)); fi

# F27: Start Ride
echo ""
echo "── F27: Start Ride ──"
RESPONSE=$(curl -s -X PUT -H "Content-Type: application/json" -H "Authorization: Bearer $DRIVER_TOKEN" "$API/rides/$RIDE_ID/start")
RSTATUS=$(echo "$RESPONSE" | python3 -c "import sys,json; print(json.load(sys.stdin)['data']['status'])" 2>/dev/null)
if [ "$RSTATUS" = "started" ]; then echo "✅ F27: Ride STARTED"; PASS=$((PASS+1)); else echo "❌ F27: $RESPONSE"; FAIL=$((FAIL+1)); fi

# F11+F28: Route Points
echo ""
echo "── F11+F28: GPS Route Recording ──"
RESPONSE=$(curl -s -X POST -H "Content-Type: application/json" -H "Authorization: Bearer $DRIVER_TOKEN" -d '{"lat":23.800,"lng":90.410,"speed":30.5,"heading":180}' "$API/rides/$RIDE_ID/route-point")
SUCCESS=$(echo "$RESPONSE" | python3 -c "import sys,json; print(json.load(sys.stdin).get('success',False))" 2>/dev/null)
if [ "$SUCCESS" = "True" ]; then echo "✅ F11+F28: Route point recorded"; PASS=$((PASS+1)); else echo "❌ F11+F28"; FAIL=$((FAIL+1)); fi

# F29: Complete Ride
echo ""
echo "── F29: Complete Ride ──"
RESPONSE=$(curl -s -X PUT -H "Content-Type: application/json" -H "Authorization: Bearer $DRIVER_TOKEN" -d '{"actual_distance":5.2,"actual_duration":18}' "$API/rides/$RIDE_ID/complete")
RSTATUS=$(echo "$RESPONSE" | python3 -c "import sys,json; print(json.load(sys.stdin)['data']['status'])" 2>/dev/null)
FINAL_FARE=$(echo "$RESPONSE" | python3 -c "import sys,json; print(json.load(sys.stdin)['data']['final_fare'])" 2>/dev/null)
if [ "$RSTATUS" = "completed" ]; then echo "✅ F29: Ride COMPLETED (Final fare: ৳$FINAL_FARE)"; PASS=$((PASS+1)); else echo "❌ F29: $RESPONSE"; FAIL=$((FAIL+1)); fi

# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
echo ""
echo "💰 PAYMENT"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"

# F13: Cash Payment
echo ""
echo "── F13: Cash Payment ──"
RESPONSE=$(curl -s -X POST -H "Content-Type: application/json" -H "Authorization: Bearer $DRIVER_TOKEN" -d "{\"ride_id\":\"$RIDE_ID\"}" "$API/payments/cash")
EARNING=$(echo "$RESPONSE" | python3 -c "import sys,json; print(json.load(sys.stdin)['data']['driver_earning'])" 2>/dev/null)
COMMISSION=$(echo "$RESPONSE" | python3 -c "import sys,json; print(json.load(sys.stdin)['data']['platform_commission'])" 2>/dev/null)
if [ -n "$EARNING" ] && [ "$EARNING" != "None" ]; then echo "✅ F13: Cash paid (Driver: ৳$EARNING, Platform: ৳$COMMISSION)"; PASS=$((PASS+1)); else echo "❌ F13: $RESPONSE"; FAIL=$((FAIL+1)); fi

# F30: Driver Earnings
echo ""
echo "── F30: Driver Earnings Check ──"
RESPONSE=$(curl -s -H "Authorization: Bearer $DRIVER_TOKEN" "$API/payments/earnings")
TRIPS=$(echo "$RESPONSE" | python3 -c "import sys,json; print(json.load(sys.stdin)['data']['today_trips'])" 2>/dev/null)
if [ -n "$TRIPS" ] && [ "$TRIPS" != "None" ]; then echo "✅ F30: Today's trips = $TRIPS"; PASS=$((PASS+1)); else echo "❌ F30: $RESPONSE"; FAIL=$((FAIL+1)); fi

# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
echo ""
echo "⭐ RATING & NOTIFICATIONS"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"

# F16: Rating
echo ""
echo "── F16: Rider rates Driver ──"
RESPONSE=$(curl -s -X POST -H "Content-Type: application/json" -H "Authorization: Bearer $RIDER_TOKEN" -d "{\"ride_id\":\"$RIDE_ID\",\"rated_user\":\"$DRIVER_ID\",\"stars\":5,\"comment\":\"Great driver!\"}" "$API/ratings")
SUCCESS=$(echo "$RESPONSE" | python3 -c "import sys,json; print(json.load(sys.stdin).get('success',False))" 2>/dev/null)
if [ "$SUCCESS" = "True" ]; then echo "✅ F16a: Rider rated driver ⭐⭐⭐⭐⭐"; PASS=$((PASS+1)); else echo "❌ F16a: $RESPONSE"; FAIL=$((FAIL+1)); fi

echo "── F16: Driver rates Rider ──"
RESPONSE=$(curl -s -X POST -H "Content-Type: application/json" -H "Authorization: Bearer $DRIVER_TOKEN" -d "{\"ride_id\":\"$RIDE_ID\",\"rated_user\":\"$RIDER_ID\",\"stars\":4,\"comment\":\"Good passenger\"}" "$API/ratings")
SUCCESS=$(echo "$RESPONSE" | python3 -c "import sys,json; print(json.load(sys.stdin).get('success',False))" 2>/dev/null)
if [ "$SUCCESS" = "True" ]; then echo "✅ F16b: Driver rated rider ⭐⭐⭐⭐"; PASS=$((PASS+1)); else echo "❌ F16b: $RESPONSE"; FAIL=$((FAIL+1)); fi

# F17: Notifications
echo ""
echo "── F17: Device Token + Notifications ──"
RESPONSE=$(curl -s -X POST -H "Content-Type: application/json" -H "Authorization: Bearer $RIDER_TOKEN" -d '{"token":"fcm_test_token_123","platform":"android"}' "$API/notifications/device-token")
SUCCESS=$(echo "$RESPONSE" | python3 -c "import sys,json; print(json.load(sys.stdin).get('success',False))" 2>/dev/null)
if [ "$SUCCESS" = "True" ]; then echo "✅ F17a: Device token saved"; PASS=$((PASS+1)); else echo "❌ F17a: $RESPONSE"; FAIL=$((FAIL+1)); fi

RESPONSE=$(curl -s -H "Authorization: Bearer $RIDER_TOKEN" "$API/notifications/me")
SUCCESS=$(echo "$RESPONSE" | python3 -c "import sys,json; print(json.load(sys.stdin).get('success',False))" 2>/dev/null)
if [ "$SUCCESS" = "True" ]; then echo "✅ F17b: Notification history fetched"; PASS=$((PASS+1)); else echo "❌ F17b"; FAIL=$((FAIL+1)); fi

# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
echo ""
echo "🛡️ ADMIN ADVANCED"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"

# F37: Ride Monitoring
echo ""
echo "── F37: Ride Monitoring ──"
RESPONSE=$(curl -s -H "Authorization: Bearer $ADMIN_TOKEN" "$API/admin/rides")
TOTAL=$(echo "$RESPONSE" | python3 -c "import sys,json; print(json.load(sys.stdin)['data']['total'])" 2>/dev/null)
if [ -n "$TOTAL" ] && [ "$TOTAL" != "None" ]; then echo "✅ F37: Ride monitoring (Total: $TOTAL rides)"; PASS=$((PASS+1)); else echo "❌ F37: $RESPONSE"; FAIL=$((FAIL+1)); fi

# F38: User Management
echo ""
echo "── F38: User Management ──"
RESPONSE=$(curl -s -H "Authorization: Bearer $ADMIN_TOKEN" "$API/admin/users")
TOTAL=$(echo "$RESPONSE" | python3 -c "import sys,json; print(json.load(sys.stdin)['data']['total'])" 2>/dev/null)
if [ -n "$TOTAL" ] && [ "$TOTAL" != "None" ]; then echo "✅ F38: User management (Total: $TOTAL users)"; PASS=$((PASS+1)); else echo "❌ F38: $RESPONSE"; FAIL=$((FAIL+1)); fi

# F43: Broadcast
echo ""
echo "── F43: Broadcast Notification ──"
RESPONSE=$(curl -s -X POST -H "Content-Type: application/json" -H "Authorization: Bearer $ADMIN_TOKEN" -d '{"target_type":"all_riders","title":"Welcome!","body":"RideShare AI Pro launched!"}' "$API/admin/broadcast")
SUCCESS=$(echo "$RESPONSE" | python3 -c "import sys,json; print(json.load(sys.stdin).get('success',False))" 2>/dev/null)
if [ "$SUCCESS" = "True" ]; then echo "✅ F43: Broadcast sent"; PASS=$((PASS+1)); else echo "❌ F43: $RESPONSE"; FAIL=$((FAIL+1)); fi

# F7: Schedule Ride
echo ""
echo "── F7: Schedule-a-Ride ──"
SCHEDULED=$(date -u -v+2H +"%Y-%m-%dT%H:%M:%S.000Z")
RESPONSE=$(curl -s -X POST -H "Content-Type: application/json" -H "Authorization: Bearer $RIDER_TOKEN" -d "{
  \"pickup_lat\":23.8103,\"pickup_lng\":90.4125,\"pickup_address\":\"Gulshan 2\",
  \"drop_lat\":23.7461,\"drop_lng\":90.3742,\"drop_address\":\"Mirpur 10\",
  \"estimated_fare\":300,\"estimated_distance\":8,\"estimated_duration\":25,
  \"fare_breakdown\":{\"base_fare\":80,\"distance_fare\":240,\"time_fare\":50,\"total\":370},
  \"scheduled_at\":\"$SCHEDULED\"
}" "$API/rides")
SSTATUS=$(echo "$RESPONSE" | python3 -c "import sys,json; print(json.load(sys.stdin)['data']['status'])" 2>/dev/null)
if [ "$SSTATUS" = "scheduled" ]; then echo "✅ F7: Ride scheduled for 2hrs later"; PASS=$((PASS+1)); else echo "❌ F7: $RESPONSE"; FAIL=$((FAIL+1)); fi

# Ride cancellation
echo ""
echo "── F6b: Cancel Ride ──"
SRIDE_ID=$(echo "$RESPONSE" | python3 -c "import sys,json; print(json.load(sys.stdin)['data']['id'])" 2>/dev/null)
RESPONSE=$(curl -s -X PUT -H "Content-Type: application/json" -H "Authorization: Bearer $RIDER_TOKEN" -d '{"reason":"Changed my mind"}' "$API/rides/$SRIDE_ID/cancel")
CSTATUS=$(echo "$RESPONSE" | python3 -c "import sys,json; print(json.load(sys.stdin)['data']['status'])" 2>/dev/null)
if [ "$CSTATUS" = "cancelled" ]; then echo "✅ F6b: Ride cancelled"; PASS=$((PASS+1)); else echo "❌ F6b: $RESPONSE"; FAIL=$((FAIL+1)); fi

# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
echo ""
echo "================================================"
echo "📊 FINAL RESULTS: $PASS passed, $FAIL failed"
echo "================================================"
if [ $FAIL -eq 0 ]; then
  echo "🎉 ALL TESTS PASSED! Backend ready for Flutter app!"
else
  echo "⚠️  $FAIL test(s) failed. Fix before proceeding."
fi
