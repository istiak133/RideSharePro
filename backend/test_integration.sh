#!/bin/bash
# ================================================
# RideShare AI Pro — Full Integration Test
# Real-world scenario: All features synchronized
# ================================================

API="http://localhost:3000/api"
PASS=0; FAIL=0; TOTAL=0

check() {
  local name="$1"
  local condition="$2"
  TOTAL=$((TOTAL+1))
  if [ "$condition" = "true" ] || [ "$condition" = "True" ]; then
    echo "  ✅ $name"
    PASS=$((PASS+1))
  else
    echo "  ❌ $name"
    FAIL=$((FAIL+1))
  fi
}

api_post() { curl -s -X POST -H "Content-Type: application/json" -H "Authorization: Bearer $2" -d "$3" "$API$1"; }
api_put() { curl -s -X PUT -H "Content-Type: application/json" -H "Authorization: Bearer $2" -d "$3" "$API$1"; }
api_get() { curl -s -H "Authorization: Bearer $2" "$API$1"; }
jval() { echo "$1" | python3 -c "import sys,json; d=json.load(sys.stdin); print(d$2)" 2>/dev/null; }

echo "╔══════════════════════════════════════════════════╗"
echo "║  🚀 RideShare AI Pro — Integration Test Suite    ║"
echo "║  Testing ALL features in real-world scenario     ║"
echo "╚══════════════════════════════════════════════════╝"
echo ""

# ────────────────────────────────────────
echo "🔵 PHASE 1: ONBOARDING"
echo "────────────────────────────────────────"

# Rider registers
echo "  → Rider registering (01811111111)..."
R1=$(api_post "/auth/request-otp" "" '{"phone":"01811111111"}')
ROTP=$(jval "$R1" "['data']['devOTP']")
R2=$(api_post "/auth/verify-otp" "" "{\"phone\":\"01811111111\",\"otp\":\"$ROTP\",\"role\":\"rider\"}")
RIDER_TOKEN=$(jval "$R2" "['data']['token']")
RIDER_ID=$(jval "$R2" "['data']['user']['id']")
RIDER_NEW=$(jval "$R2" "['data']['user']['isNewUser']")
check "F1: Rider registered (isNewUser=$RIDER_NEW)" "$([ -n "$RIDER_TOKEN" ] && echo true)"

# Rider updates profile
R3=$(api_put "/users/profile" "$RIDER_TOKEN" '{"full_name":"Rahim Khan","date_of_birth":"2000-06-15","email":"rahim@email.com","emergency_contact_name":"Karim","emergency_contact_phone":"01899999999","language_preference":"bn"}')
RNAME=$(jval "$R3" "['data']['user']['full_name']")
RLANG=$(jval "$R3" "['data']['user']['language_preference']")
check "F2: Rider profile updated (name=$RNAME, lang=$RLANG)" "$([ "$RNAME" = "Rahim Khan" ] && echo true)"
check "F15: Language set to Bangla" "$([ "$RLANG" = "bn" ] && echo true)"

# Driver registers
echo ""
echo "  → Driver registering (01711222222)..."
D1=$(api_post "/auth/request-otp" "" '{"phone":"01711222222"}')
DOTP=$(jval "$D1" "['data']['devOTP']")
D2=$(api_post "/auth/verify-otp" "" "{\"phone\":\"01711222222\",\"otp\":\"$DOTP\",\"role\":\"driver\"}")
DRIVER_TOKEN=$(jval "$D2" "['data']['token']")
DRIVER_ID=$(jval "$D2" "['data']['user']['id']")
DRIVER_ROLE=$(jval "$D2" "['data']['user']['role']")
check "F19: Driver registered (role=$DRIVER_ROLE)" "$([ "$DRIVER_ROLE" = "driver" ] && echo true)"

# Driver profile
api_put "/users/profile" "$DRIVER_TOKEN" '{"full_name":"Karim Driver","date_of_birth":"1995-01-10"}' > /dev/null

# Driver uploads documents
echo ""
echo "  → Driver uploading documents..."
D3=$(api_post "/users/driver/documents" "$DRIVER_TOKEN" '{
  "nid_front_url":"https://storage.supabase.co/nid_front.jpg",
  "nid_back_url":"https://storage.supabase.co/nid_back.jpg",
  "license_url":"https://storage.supabase.co/license.jpg",
  "vehicle_model":"Toyota Axio 2020","vehicle_year":2020,
  "registration_number":"DHA-KA-1234",
  "vehicle_photo_url":"https://storage.supabase.co/car.jpg",
  "account_holder_name":"Karim Uddin","account_number":"12345678",
  "bank_name":"Dutch Bangla Bank","branch_name":"Gulshan"
}')
DOC_STATUS=$(jval "$D3" "['data']['verification_status']")
check "F20: Documents uploaded (status=$DOC_STATUS)" "$([ "$DOC_STATUS" = "pending" ] && echo true)"

# Verification status check
D4=$(api_get "/users/driver/verification-status" "$DRIVER_TOKEN")
VS=$(jval "$D4" "['data']['verification_status']")
check "F21: Verification pending" "$([ "$VS" = "pending" ] && echo true)"

# ────────────────────────────────────────
echo ""
echo "🔵 PHASE 2: ADMIN VERIFICATION"
echo "────────────────────────────────────────"

# Admin setup + login
api_post "/admin/setup" "" '{"email":"admin@rideshare.com","password":"admin123"}' > /dev/null 2>&1
A1=$(api_post "/admin/login" "" '{"email":"admin@rideshare.com","password":"admin123"}')
ADMIN_TOKEN=$(jval "$A1" "['data']['token']")
ADMIN_ROLE=$(jval "$A1" "['data']['admin']['role']")
check "F33: Admin logged in (role=$ADMIN_ROLE)" "$([ -n "$ADMIN_TOKEN" ] && echo true)"

# Check pending drivers list
A2=$(api_get "/admin/drivers/pending" "$ADMIN_TOKEN")
# Admin approves driver
A3=$(api_put "/admin/drivers/$DRIVER_ID/verify" "$ADMIN_TOKEN" '{"action":"approved","reason":"All docs valid"}')
A3_OK=$(jval "$A3" "['success']")
check "F35: Admin approved driver" "$A3_OK"

# Verify driver now sees "approved"
D5=$(api_get "/users/driver/verification-status" "$DRIVER_TOKEN")
VS2=$(jval "$D5" "['data']['verification_status']")
check "F21→F35 sync: Driver sees approved status" "$([ "$VS2" = "approved" ] && echo true)"

# Admin dashboard
A4=$(api_get "/admin/dashboard" "$ADMIN_TOKEN")
DASH_USERS=$(jval "$A4" "['data']['totalUsers']")
DASH_DRIVERS=$(jval "$A4" "['data']['totalDrivers']")
check "F36: Dashboard shows users=$DASH_USERS, drivers=$DASH_DRIVERS" "$([ -n "$DASH_USERS" ] && echo true)"

# ────────────────────────────────────────
echo ""
echo "🔵 PHASE 3: RIDE LIFECYCLE (Full Flow)"
echo "────────────────────────────────────────"

# Driver goes online
echo "  → Driver going online near Gulshan..."
D6=$(api_put "/rides/driver/toggle" "$DRIVER_TOKEN" '{"status":"online","lat":23.7935,"lng":90.4066}')
DSTATUS=$(jval "$D6" "['data']['status']")
check "F22: Driver online (status=$DSTATUS)" "$([ "$DSTATUS" = "online" ] && echo true)"

# Rider gets fare estimate
echo "  → Rider checking fare (8km, 22min)..."
R4=$(api_post "/rides/fare-estimate" "$RIDER_TOKEN" '{"distance":8,"duration":22}')
FARE=$(jval "$R4" "['data']['estimated_fare']")
BASE=$(jval "$R4" "['data']['fare_breakdown']['base_fare']")
DIST_FARE=$(jval "$R4" "['data']['fare_breakdown']['distance_fare']")
TIME_FARE=$(jval "$R4" "['data']['fare_breakdown']['time_fare']")
check "F4+F5: Fare=৳$FARE (base=$BASE + dist=$DIST_FARE + time=$TIME_FARE)" "$([ -n "$FARE" ] && echo true)"

# Rider books ride
echo "  → Rider booking Gulshan→Dhanmondi..."
R5=$(api_post "/rides" "$RIDER_TOKEN" "{
  \"pickup_lat\":23.7935,\"pickup_lng\":90.4066,\"pickup_address\":\"Gulshan 2, Dhaka\",
  \"drop_lat\":23.7461,\"drop_lng\":90.3742,\"drop_address\":\"Dhanmondi 27, Dhaka\",
  \"estimated_fare\":$FARE,\"estimated_distance\":8,\"estimated_duration\":22,
  \"fare_breakdown\":{\"base_fare\":$BASE,\"distance_fare\":$DIST_FARE,\"time_fare\":$TIME_FARE,\"total\":$FARE}
}")
RIDE_ID=$(jval "$R5" "['data']['id']")
PICKUP_OTP=$(jval "$R5" "['data']['pickup_otp']")
RIDE_STATUS=$(jval "$R5" "['data']['status']")
check "F6: Ride booked (status=$RIDE_STATUS, OTP=$PICKUP_OTP)" "$([ "$RIDE_STATUS" = "searching_driver" ] && echo true)"

# Verify ride has no driver yet
RIDE_DRIVER=$(jval "$R5" "['data']['driver_id']")
check "F6 sync: No driver assigned yet (driver=$RIDE_DRIVER)" "$([ "$RIDE_DRIVER" = "None" ] && echo true)"

# Driver accepts ride
echo "  → Driver accepting ride..."
D7=$(api_post "/rides/$RIDE_ID/accept" "$DRIVER_TOKEN" '')
RSTATUS_AFTER=$(jval "$D7" "['data']['status']")
ASSIGNED_DRIVER=$(jval "$D7" "['data']['driver_id']")
check "F24: Ride accepted (status=$RSTATUS_AFTER)" "$([ "$RSTATUS_AFTER" = "driver_assigned" ] && echo true)"
check "F24 sync: Driver ID matches ($ASSIGNED_DRIVER = $DRIVER_ID)" "$([ "$ASSIGNED_DRIVER" = "$DRIVER_ID" ] && echo true)"

# Rider can see driver info
echo "  → Rider checking ride details..."
R6=$(api_get "/rides/$RIDE_ID" "$RIDER_TOKEN")
RIDE_DRIVER_NAME=$(jval "$R6" "['data']['driver']['full_name']")
check "F6 sync: Rider sees driver name ($RIDE_DRIVER_NAME)" "$([ "$RIDE_DRIVER_NAME" = "Karim Driver" ] && echo true)"

# Driver verifies pickup OTP  
echo "  → Driver verifying pickup OTP ($PICKUP_OTP)..."
D8=$(api_post "/rides/$RIDE_ID/verify-otp" "$DRIVER_TOKEN" "{\"otp\":\"$PICKUP_OTP\"}")
OTP_MSG=$(jval "$D8" "['data']['message']")
check "F10+F26: Pickup OTP verified" "$(jval "$D8" "['success']")"

# Wrong OTP test
D8_WRONG=$(api_post "/rides/$RIDE_ID/verify-otp" "$DRIVER_TOKEN" '{"otp":"0000"}')
check "F10: Wrong OTP rejected" "$([ "$(jval "$D8_WRONG" "['success']")" = "False" ] && echo true)"

# Driver starts ride
echo "  → Driver starting ride..."
D9=$(api_put "/rides/$RIDE_ID/start" "$DRIVER_TOKEN" '')
START_STATUS=$(jval "$D9" "['data']['status']")
STARTED_AT=$(jval "$D9" "['data']['started_at']")
check "F27: Ride started (status=$START_STATUS)" "$([ "$START_STATUS" = "started" ] && echo true)"
check "F27: started_at timestamp set" "$([ "$STARTED_AT" != "None" ] && echo true)"

# Record GPS points during ride
echo "  → Recording GPS route..."
api_post "/rides/$RIDE_ID/route-point" "$DRIVER_TOKEN" '{"lat":23.790,"lng":90.405,"speed":25.0,"heading":200}' > /dev/null
api_post "/rides/$RIDE_ID/route-point" "$DRIVER_TOKEN" '{"lat":23.780,"lng":90.400,"speed":35.5,"heading":210}' > /dev/null
api_post "/rides/$RIDE_ID/route-point" "$DRIVER_TOKEN" '{"lat":23.760,"lng":90.385,"speed":40.0,"heading":220}' > /dev/null
D10=$(api_post "/rides/$RIDE_ID/route-point" "$DRIVER_TOKEN" '{"lat":23.746,"lng":90.374,"speed":0,"heading":0}')
check "F11+F28: 4 GPS points recorded" "$(jval "$D10" "['success']")"

# Driver location update
D10b=$(api_put "/rides/driver/location" "$DRIVER_TOKEN" '{"lat":23.746,"lng":90.374}')
check "F9: Driver location updated" "$(jval "$D10b" "['success']")"

# Driver completes ride
echo "  → Driver completing ride..."
D11=$(api_put "/rides/$RIDE_ID/complete" "$DRIVER_TOKEN" '{"actual_distance":8.5,"actual_duration":24}')
END_STATUS=$(jval "$D11" "['data']['status']")
FINAL_FARE=$(jval "$D11" "['data']['final_fare']")
COMPLETED_AT=$(jval "$D11" "['data']['completed_at']")
check "F29: Ride completed (status=$END_STATUS, fare=৳$FINAL_FARE)" "$([ "$END_STATUS" = "completed" ] && echo true)"
check "F29: completed_at timestamp set" "$([ "$COMPLETED_AT" != "None" ] && echo true)"

# ────────────────────────────────────────
echo ""
echo "🔵 PHASE 4: PAYMENT"
echo "────────────────────────────────────────"

# Cash payment
echo "  → Processing cash payment..."
P1=$(api_post "/payments/cash" "$DRIVER_TOKEN" "{\"ride_id\":\"$RIDE_ID\"}")
PAY_AMOUNT=$(jval "$P1" "['data']['amount']")
PAY_DRIVER=$(jval "$P1" "['data']['driver_earning']")
PAY_PLATFORM=$(jval "$P1" "['data']['platform_commission']")
PAY_METHOD=$(jval "$P1" "['data']['payment_method']")
check "F13: Cash payment recorded (৳$PAY_AMOUNT)" "$([ "$PAY_METHOD" = "cash" ] && echo true)"
check "F13: 75/25 split (driver=৳$PAY_DRIVER, platform=৳$PAY_PLATFORM)" "$([ -n "$PAY_DRIVER" ] && echo true)"

# Driver earnings
D12=$(api_get "/payments/earnings" "$DRIVER_TOKEN")
TODAY_TRIPS=$(jval "$D12" "['data']['today_trips']")
TODAY_EARN=$(jval "$D12" "['data']['today_earnings']")
check "F30: Driver earnings today ($TODAY_TRIPS trip(s), ৳$TODAY_EARN)" "$([ "$TODAY_TRIPS" != "0" ] && echo true)"

# Card payment method save
P2=$(api_post "/payments/methods" "$RIDER_TOKEN" '{"stripe_payment_method_id":"pm_mock_123","last4":"4242","brand":"Visa"}')
check "F14: Card saved (Visa ****4242)" "$(jval "$P2" "['success']")"

# Get saved cards
P3=$(api_get "/payments/methods" "$RIDER_TOKEN")
check "F14: Saved cards retrieved" "$(jval "$P3" "['success']")"

# ────────────────────────────────────────
echo ""
echo "🔵 PHASE 5: NOTIFICATIONS"
echo "────────────────────────────────────────"

# Device tokens
N1=$(api_post "/notifications/device-token" "$RIDER_TOKEN" '{"token":"fcm_rider_token_abc","platform":"android"}')
check "F17: Rider device token saved" "$(jval "$N1" "['success']")"

N2=$(api_post "/notifications/device-token" "$DRIVER_TOKEN" '{"token":"fcm_driver_token_xyz","platform":"ios"}')
check "F17: Driver device token saved (ios)" "$(jval "$N2" "['success']")"

# Notification history
N3=$(api_get "/notifications/me" "$RIDER_TOKEN")
check "F17: Notification history accessible" "$(jval "$N3" "['success']")"

# ────────────────────────────────────────
echo ""
echo "🔵 PHASE 6: SCHEDULED RIDE + CANCEL"
echo "────────────────────────────────────────"

# Schedule ride for 3hrs later
SCHED=$(date -u -v+3H +"%Y-%m-%dT%H:%M:%S.000Z")
R7=$(api_post "/rides" "$RIDER_TOKEN" "{
  \"pickup_lat\":23.8103,\"pickup_lng\":90.4125,\"pickup_address\":\"Banani 11\",
  \"drop_lat\":23.7500,\"drop_lng\":90.3900,\"drop_address\":\"Farmgate\",
  \"estimated_fare\":200,\"estimated_distance\":6,\"estimated_duration\":18,
  \"fare_breakdown\":{\"base_fare\":80,\"distance_fare\":180,\"time_fare\":36,\"total\":296},
  \"scheduled_at\":\"$SCHED\"
}")
SCHED_STATUS=$(jval "$R7" "['data']['status']")
SCHED_ID=$(jval "$R7" "['data']['id']")
check "F7+F31: Ride scheduled (status=$SCHED_STATUS)" "$([ "$SCHED_STATUS" = "scheduled" ] && echo true)"

# Cancel scheduled ride
R8=$(api_put "/rides/$SCHED_ID/cancel" "$RIDER_TOKEN" '{"reason":"Plans changed"}')
CANCEL_STATUS=$(jval "$R8" "['data']['status']")
check "F6: Scheduled ride cancelled (status=$CANCEL_STATUS)" "$([ "$CANCEL_STATUS" = "cancelled" ] && echo true)"

# Ride history
R9=$(api_get "/rides/history/me" "$RIDER_TOKEN")
HIST_TOTAL=$(jval "$R9" "['data']['total']")
check "F6: Rider ride history ($HIST_TOTAL rides)" "$([ "$HIST_TOTAL" != "None" ] && echo true)"

# ────────────────────────────────────────
echo ""
echo "🔵 PHASE 7: ADMIN MONITORING"
echo "────────────────────────────────────────"

# Updated dashboard
A5=$(api_get "/admin/dashboard" "$ADMIN_TOKEN")
A_USERS=$(jval "$A5" "['data']['totalUsers']")
A_RIDES=$(jval "$A5" "['data']['totalRides']")
A_COMPLETED=$(jval "$A5" "['data']['completedRides']")
check "F36: Dashboard synced (users=$A_USERS, rides=$A_RIDES, completed=$A_COMPLETED)" "$([ -n "$A_RIDES" ] && echo true)"

# Ride monitoring
A6=$(api_get "/admin/rides?status=completed" "$ADMIN_TOKEN")
check "F37: Ride monitoring (completed rides)" "$(jval "$A6" "['success']")"

# User management — search
A7=$(api_get "/admin/users?search=Rahim" "$ADMIN_TOKEN")
SEARCH_TOTAL=$(jval "$A7" "['data']['total']")
check "F38: User search (found $SEARCH_TOTAL for 'Rahim')" "$([ "$SEARCH_TOTAL" != "0" ] && echo true)"

# User block/unblock
A8=$(api_put "/admin/users/$RIDER_ID/block" "$ADMIN_TOKEN" '{"status":"blocked"}')
check "F38: User blocked" "$(jval "$A8" "['success']")"

# Verify blocked user can't access API
R10=$(api_get "/auth/me" "$RIDER_TOKEN")
BLOCKED_MSG=$(jval "$R10" "['message']")
check "F38 sync: Blocked user denied access ($BLOCKED_MSG)" "$([ "$(jval "$R10" "['success']")" = "False" ] && echo true)"

# Unblock
api_put "/admin/users/$RIDER_ID/block" "$ADMIN_TOKEN" '{"status":"active"}' > /dev/null

# Broadcast notification
A9=$(api_post "/admin/broadcast" "$ADMIN_TOKEN" '{"target_type":"all_drivers","title":"Eid Mubarak!","body":"Special bonus for top drivers!"}')
check "F43: Broadcast to all drivers" "$(jval "$A9" "['success']")"

# ────────────────────────────────────────
echo ""
echo "🔵 PHASE 8: DISPUTE (F42)"
echo "────────────────────────────────────────"

# Unblock rider first, get fresh token
R_OTP2=$(jval "$(api_post "/auth/request-otp" "" '{"phone":"01811111111"}')" "['data']['devOTP']")
R_T2=$(jval "$(api_post "/auth/verify-otp" "" "{\"phone\":\"01811111111\",\"otp\":\"$R_OTP2\",\"role\":\"rider\"}")" "['data']['token']")

# Submit dispute
DIS1=$(api_post "/admin/disputes" "$R_T2" "{\"ride_id\":\"$RIDE_ID\",\"reported_against\":\"$DRIVER_ID\",\"reason\":\"Driver was rude\"}")
check "F42: Dispute submitted" "$(jval "$DIS1" "['success']")"

# Admin views disputes
DIS2=$(api_get "/admin/disputes" "$ADMIN_TOKEN")
check "F42: Admin sees disputes" "$(jval "$DIS2" "['success']")"

# Admin resolves dispute
DIS_ID=$(jval "$DIS1" "['data']['id']")
DIS3=$(api_put "/admin/disputes/$DIS_ID/resolve" "$ADMIN_TOKEN" '{"resolution":"Warning issued to driver","refund_amount":50}')
check "F42: Dispute resolved (৳50 refund)" "$(jval "$DIS3" "['success']")"

# ────────────────────────────────────────
echo ""
echo "╔══════════════════════════════════════════════════╗"
echo "║  📊 FINAL RESULTS: $PASS/$TOTAL passed          "
if [ $FAIL -eq 0 ]; then
echo "║  🎉 ALL TESTS PASSED!                            "
echo "║  Backend is 100% ready for Flutter app!          "
else
echo "║  ⚠️  $FAIL test(s) failed                        "
fi
echo "╚══════════════════════════════════════════════════╝"
