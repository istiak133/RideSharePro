-- =============================================
-- RideShare AI Pro — Final Database Schema
-- 22 Tables | 39 MVP Features | PostgreSQL
-- Run this on Supabase SQL Editor to create all tables
-- =============================================

-- ┌─────────────────────────────────────┐
-- │  TABLE 1: admin_users               │
-- │  Features: F33 (Admin Login + 2FA)  │
-- │            F34 (RBAC)               │
-- └─────────────────────────────────────┘
CREATE TABLE IF NOT EXISTS admin_users (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    email VARCHAR(255) UNIQUE NOT NULL,
    password_hash VARCHAR(255) NOT NULL,
    role VARCHAR(20) NOT NULL DEFAULT 'verifier'
        CHECK (role IN ('super_admin', 'verifier')),
    is_active BOOLEAN DEFAULT TRUE,
    totp_secret VARCHAR(255),
    failed_login_attempts INTEGER DEFAULT 0,
    locked_until TIMESTAMP,
    last_login TIMESTAMP,
    created_at TIMESTAMP NOT NULL DEFAULT NOW()
);

-- ┌─────────────────────────────────────┐
-- │  TABLE 2: users                     │
-- │  Features: F1 (Registration)        │
-- │            F2 (Profile)             │
-- │            F15 (Bilingual)          │
-- │            F16 (Rating)             │
-- │            F19 (Driver Registration)│
-- └─────────────────────────────────────┘
CREATE TABLE IF NOT EXISTS users (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    phone VARCHAR(11) UNIQUE NOT NULL
        CHECK (LENGTH(phone) = 11),
    role VARCHAR(10) NOT NULL
        CHECK (role IN ('rider', 'driver')),
    status VARCHAR(10) NOT NULL DEFAULT 'active'
        CHECK (status IN ('active', 'blocked')),
    -- Profile fields (merged from user_profiles for simplicity)
    full_name VARCHAR(100),
    photo_url VARCHAR(500),
    date_of_birth DATE,
    email VARCHAR(255),
    emergency_contact_name VARCHAR(100),
    emergency_contact_phone VARCHAR(11),
    language_preference VARCHAR(5) DEFAULT 'en',
    -- Rating (denormalized for fast reads)
    average_rating DECIMAL(3,2) DEFAULT 0.00
        CHECK (average_rating >= 0 AND average_rating <= 5),
    total_ratings INTEGER DEFAULT 0,
    created_at TIMESTAMP NOT NULL DEFAULT NOW(),
    updated_at TIMESTAMP NOT NULL DEFAULT NOW()
);

-- ┌─────────────────────────────────────┐
-- │  TABLE 3: otp_verifications         │
-- │  Features: F1 (Phone OTP)           │
-- │            F19 (Driver OTP)         │
-- └─────────────────────────────────────┘
CREATE TABLE IF NOT EXISTS otp_verifications (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    phone VARCHAR(11) NOT NULL,
    otp_code VARCHAR(255) NOT NULL,       -- bcrypt hashed
    attempts INTEGER NOT NULL DEFAULT 0,
    expires_at TIMESTAMP NOT NULL,
    created_at TIMESTAMP NOT NULL DEFAULT NOW()
);

-- ┌──────────────────────────────────────┐
-- │  TABLE 4: driver_profiles            │
-- │  Features: F2 (Driver Profile)       │
-- │            F20 (Document Upload)     │
-- │            F21 (Verification Status) │
-- │            F35 (Admin Verification)  │
-- │  Merges: documents + vehicle + bank  │
-- └──────────────────────────────────────┘
CREATE TABLE IF NOT EXISTS driver_profiles (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id UUID NOT NULL UNIQUE REFERENCES users(id) ON DELETE CASCADE,
    -- Documents
    nid_front_url VARCHAR(500),
    nid_back_url VARCHAR(500),
    license_url VARCHAR(500),
    -- Vehicle info (Car only in MVP)
    vehicle_type VARCHAR(10) NOT NULL DEFAULT 'car'
        CHECK (vehicle_type IN ('car')),
    vehicle_model VARCHAR(100),
    vehicle_year INTEGER,
    registration_number VARCHAR(50),
    vehicle_photo_url VARCHAR(500),
    -- Bank account
    account_holder_name VARCHAR(100),
    account_number VARCHAR(255),           -- should be encrypted at app level
    bank_name VARCHAR(100),
    branch_name VARCHAR(100),
    routing_number VARCHAR(50),
    -- Verification
    verification_status VARCHAR(10) NOT NULL DEFAULT 'pending'
        CHECK (verification_status IN ('pending', 'approved', 'rejected')),
    verified_by UUID REFERENCES admin_users(id),
    verified_at TIMESTAMP,
    rejection_reason TEXT,
    resubmission_count INTEGER DEFAULT 0,
    created_at TIMESTAMP NOT NULL DEFAULT NOW()
);

-- ┌─────────────────────────────────────┐
-- │  TABLE 5: drivers                   │
-- │  Features: F8 (Driver Search)       │
-- │            F22 (Online/Offline)     │
-- │            F24 (Accept/Decline)     │
-- └─────────────────────────────────────┘
CREATE TABLE IF NOT EXISTS drivers (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id UUID NOT NULL UNIQUE REFERENCES users(id) ON DELETE CASCADE,
    status VARCHAR(10) NOT NULL DEFAULT 'offline'
        CHECK (status IN ('online', 'offline', 'break', 'busy')),
    current_lat DECIMAL(10,7),
    current_lng DECIMAL(10,7),
    last_location_update TIMESTAMP,
    is_verified BOOLEAN NOT NULL DEFAULT FALSE,
    vehicle_type VARCHAR(10) DEFAULT 'car',
    -- Stats (denormalized for fast matching queries)
    acceptance_rate DECIMAL(5,2) DEFAULT 100.00,
    total_rides INTEGER DEFAULT 0,
    total_requests INTEGER DEFAULT 0,
    total_accepts INTEGER DEFAULT 0,
    total_declines INTEGER DEFAULT 0,
    created_at TIMESTAMP NOT NULL DEFAULT NOW()
);

-- ┌─────────────────────────────────────┐
-- │  TABLE 6: fare_rules                │
-- │  Features: F4 (Vehicle Type)        │
-- │            F5 (Fare Calculation)    │
-- └─────────────────────────────────────┘
CREATE TABLE IF NOT EXISTS fare_rules (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    vehicle_type VARCHAR(10) NOT NULL UNIQUE,
    base_fare DECIMAL(10,2) NOT NULL,
    distance_rate DECIMAL(10,2) NOT NULL,  -- per km
    time_rate DECIMAL(10,2) NOT NULL,      -- per minute
    minimum_fare DECIMAL(10,2) NOT NULL,
    updated_at TIMESTAMP NOT NULL DEFAULT NOW()
);

-- ┌─────────────────────────────────────┐
-- │  TABLE 7: surge_history             │
-- │  Features: F5 (Surge Pricing)       │
-- └─────────────────────────────────────┘
CREATE TABLE IF NOT EXISTS surge_history (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    zone_id VARCHAR(50) NOT NULL,
    surge_multiplier DECIMAL(3,1) NOT NULL
        CHECK (surge_multiplier >= 1.0 AND surge_multiplier <= 3.0),
    active_rides INTEGER NOT NULL,
    available_drivers INTEGER NOT NULL,
    created_at TIMESTAMP NOT NULL DEFAULT NOW()
);

-- ┌──────────────────────────────────────────┐
-- │  TABLE 8: rides  ⭐ CENTRAL TABLE       │
-- │  Features: F3 (Maps), F5 (Fare),        │
-- │    F6 (Booking), F7 (Schedule),         │
-- │    F10 (Pickup OTP), F24 (Assign),      │
-- │    F27 (Start), F29 (End)               │
-- └──────────────────────────────────────────┘
CREATE TABLE IF NOT EXISTS rides (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    rider_id UUID NOT NULL REFERENCES users(id),
    driver_id UUID REFERENCES users(id),
    -- Location
    pickup_lat DECIMAL(10,7) NOT NULL,
    pickup_lng DECIMAL(10,7) NOT NULL,
    pickup_address VARCHAR(500) NOT NULL,
    drop_lat DECIMAL(10,7) NOT NULL,
    drop_lng DECIMAL(10,7) NOT NULL,
    drop_address VARCHAR(500) NOT NULL,
    -- Ride config
    vehicle_type VARCHAR(10) NOT NULL DEFAULT 'car',
    status VARCHAR(20) NOT NULL DEFAULT 'searching_driver'
        CHECK (status IN (
            'scheduled', 'searching_driver', 'driver_assigned',
            'driver_on_way', 'arrived', 'started',
            'completed', 'cancelled'
        )),
    -- Fare
    estimated_fare DECIMAL(10,2),
    final_fare DECIMAL(10,2),
    surge_multiplier DECIMAL(3,1) DEFAULT 1.0,
    fare_breakdown JSONB,
    estimated_distance DECIMAL(10,2),      -- km
    estimated_duration INTEGER,             -- minutes
    actual_distance DECIMAL(10,2),
    actual_duration INTEGER,
    -- Pickup OTP (F10)
    pickup_otp_hash VARCHAR(255),
    otp_attempts INTEGER DEFAULT 0,
    otp_verified BOOLEAN DEFAULT FALSE,
    otp_generated_at TIMESTAMP,
    -- Schedule (F7)
    scheduled_at TIMESTAMP,
    -- Lifecycle timestamps
    started_at TIMESTAMP,
    completed_at TIMESTAMP,
    cancelled_at TIMESTAMP,
    cancellation_reason TEXT,
    cancelled_by UUID REFERENCES users(id),
    created_at TIMESTAMP NOT NULL DEFAULT NOW()
);

-- ┌─────────────────────────────────────┐
-- │  TABLE 9: scheduled_ride_jobs       │
-- │  Features: F7 (Schedule-a-Ride)     │
-- │            F31 (Driver Scheduled)   │
-- └─────────────────────────────────────┘
CREATE TABLE IF NOT EXISTS scheduled_ride_jobs (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    ride_id UUID NOT NULL REFERENCES rides(id) ON DELETE CASCADE,
    job_type VARCHAR(20) NOT NULL
        CHECK (job_type IN ('15min_notify', '10min_retry', '5min_final')),
    scheduled_for TIMESTAMP NOT NULL,
    executed_at TIMESTAMP,
    status VARCHAR(10) NOT NULL DEFAULT 'pending'
        CHECK (status IN ('pending', 'executed', 'failed')),
    created_at TIMESTAMP NOT NULL DEFAULT NOW()
);

-- ┌─────────────────────────────────────┐
-- │  TABLE 10: ride_requests            │
-- │  Features: F8 (Driver Search)       │
-- │            F23 (Ride Request)       │
-- │            F24 (Accept/Decline)     │
-- └─────────────────────────────────────┘
CREATE TABLE IF NOT EXISTS ride_requests (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    ride_id UUID NOT NULL REFERENCES rides(id) ON DELETE CASCADE,
    driver_id UUID NOT NULL REFERENCES users(id),
    sent_at TIMESTAMP NOT NULL DEFAULT NOW(),
    response VARCHAR(10) NOT NULL DEFAULT 'pending'
        CHECK (response IN ('pending', 'accepted', 'declined', 'expired')),
    responded_at TIMESTAMP,
    UNIQUE(ride_id, driver_id)
);

-- ┌─────────────────────────────────────┐
-- │  TABLE 11: ride_route_points        │
-- │  Features: F11 (Ride Progress)      │
-- │            F28 (Navigation)         │
-- │            F37 (Admin Monitoring)   │
-- │            F42 (Dispute Evidence)   │
-- └─────────────────────────────────────┘
CREATE TABLE IF NOT EXISTS ride_route_points (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    ride_id UUID NOT NULL REFERENCES rides(id) ON DELETE CASCADE,
    lat DECIMAL(10,7) NOT NULL,
    lng DECIMAL(10,7) NOT NULL,
    speed DECIMAL(6,2),
    heading DECIMAL(5,2),
    recorded_at TIMESTAMP NOT NULL DEFAULT NOW()
);

-- ┌─────────────────────────────────────┐
-- │  TABLE 12: otp_audit_log            │
-- │  Features: F10 (OTP Security)       │
-- │            F26 (Driver OTP Verify)  │
-- └─────────────────────────────────────┘
CREATE TABLE IF NOT EXISTS otp_audit_log (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    ride_id UUID NOT NULL REFERENCES rides(id) ON DELETE CASCADE,
    driver_id UUID NOT NULL REFERENCES users(id),
    attempt_number INTEGER NOT NULL,
    success BOOLEAN NOT NULL,
    ip_address VARCHAR(45),
    created_at TIMESTAMP NOT NULL DEFAULT NOW()
);

-- ┌─────────────────────────────────────┐
-- │  TABLE 13: payments                 │
-- │  Features: F13 (Cash)               │
-- │            F14 (Card/Stripe)        │
-- │            F30 (Collect Payment)    │
-- └─────────────────────────────────────┘
CREATE TABLE IF NOT EXISTS payments (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    ride_id UUID NOT NULL REFERENCES rides(id),
    amount DECIMAL(10,2) NOT NULL
        CHECK (amount > 0),
    payment_method VARCHAR(10) NOT NULL
        CHECK (payment_method IN ('cash', 'card')),
    status VARCHAR(10) NOT NULL DEFAULT 'pending'
        CHECK (status IN ('pending', 'completed', 'failed', 'disputed', 'refunded')),
    platform_commission DECIMAL(10,2),     -- 25%
    driver_earning DECIMAL(10,2),          -- 75%
    stripe_payment_intent_id VARCHAR(255),
    paid_at TIMESTAMP,
    receipt_url VARCHAR(500),
    verified_by VARCHAR(10)
        CHECK (verified_by IN ('driver', 'rider', 'system', 'admin')),
    created_at TIMESTAMP NOT NULL DEFAULT NOW()
);

-- ┌─────────────────────────────────────┐
-- │  TABLE 14: payment_methods          │
-- │  Features: F14 (Card Payment)       │
-- └─────────────────────────────────────┘
CREATE TABLE IF NOT EXISTS payment_methods (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    stripe_payment_method_id VARCHAR(255) NOT NULL,
    last4 VARCHAR(4) NOT NULL,
    brand VARCHAR(20) NOT NULL,
    is_default BOOLEAN DEFAULT FALSE,
    created_at TIMESTAMP NOT NULL DEFAULT NOW()
);

-- ┌─────────────────────────────────────┐
-- │  TABLE 15: ratings                  │
-- │  Features: F16 (Rating & Review)    │
-- └─────────────────────────────────────┘
CREATE TABLE IF NOT EXISTS ratings (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    ride_id UUID NOT NULL REFERENCES rides(id),
    rated_by UUID NOT NULL REFERENCES users(id),
    rated_user UUID NOT NULL REFERENCES users(id),
    role VARCHAR(25) NOT NULL
        CHECK (role IN ('rider_rates_driver', 'driver_rates_rider')),
    stars INTEGER NOT NULL
        CHECK (stars >= 1 AND stars <= 5),
    comment TEXT,
    created_at TIMESTAMP NOT NULL DEFAULT NOW(),
    UNIQUE(ride_id, rated_by)
);

-- ┌─────────────────────────────────────┐
-- │  TABLE 16: device_tokens            │
-- │  Features: F17 (Push Notifications) │
-- └─────────────────────────────────────┘
CREATE TABLE IF NOT EXISTS device_tokens (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    token VARCHAR(500) NOT NULL,
    platform VARCHAR(10) NOT NULL
        CHECK (platform IN ('ios', 'android')),
    updated_at TIMESTAMP NOT NULL DEFAULT NOW(),
    UNIQUE(user_id, token)
);

-- ┌─────────────────────────────────────┐
-- │  TABLE 17: notifications_log        │
-- │  Features: F17 (Notification Track) │
-- └─────────────────────────────────────┘
CREATE TABLE IF NOT EXISTS notifications_log (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id UUID NOT NULL REFERENCES users(id),
    type VARCHAR(50) NOT NULL,
    title VARCHAR(200) NOT NULL,
    body TEXT NOT NULL,
    data JSONB,
    sent_at TIMESTAMP NOT NULL DEFAULT NOW(),
    delivered BOOLEAN DEFAULT FALSE
);

-- ┌─────────────────────────────────────┐
-- │  TABLE 18: disputes                 │
-- │  Features: F42 (Dispute Resolution) │
-- └─────────────────────────────────────┘
CREATE TABLE IF NOT EXISTS disputes (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    ride_id UUID NOT NULL REFERENCES rides(id),
    payment_id UUID REFERENCES payments(id),
    reported_by UUID NOT NULL REFERENCES users(id),
    reported_against UUID NOT NULL REFERENCES users(id),
    reason TEXT NOT NULL,
    evidence_urls JSONB,
    status VARCHAR(15) NOT NULL DEFAULT 'open'
        CHECK (status IN ('open', 'investigating', 'resolved', 'closed')),
    resolution TEXT,
    resolved_by UUID REFERENCES admin_users(id),
    refund_amount DECIMAL(10,2),
    refund_issued BOOLEAN DEFAULT FALSE,
    created_at TIMESTAMP NOT NULL DEFAULT NOW()
);

-- ┌─────────────────────────────────────┐
-- │  TABLE 19: audit_logs               │
-- │  Features: F33 (Admin Actions)      │
-- │            F34 (RBAC Tracking)      │
-- └─────────────────────────────────────┘
CREATE TABLE IF NOT EXISTS audit_logs (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    admin_id UUID NOT NULL REFERENCES admin_users(id),
    action VARCHAR(100) NOT NULL,
    entity_type VARCHAR(50) NOT NULL,
    entity_id VARCHAR(100) NOT NULL,
    details JSONB,
    ip_address VARCHAR(45),
    created_at TIMESTAMP NOT NULL DEFAULT NOW()
);

-- ┌─────────────────────────────────────┐
-- │  TABLE 20: verification_logs        │
-- │  Features: F35 (Driver Verification)│
-- └─────────────────────────────────────┘
CREATE TABLE IF NOT EXISTS verification_logs (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    driver_id UUID NOT NULL REFERENCES users(id),
    admin_id UUID NOT NULL REFERENCES admin_users(id),
    action VARCHAR(10) NOT NULL
        CHECK (action IN ('approved', 'rejected')),
    reason TEXT,
    documents_to_resubmit JSONB,
    created_at TIMESTAMP NOT NULL DEFAULT NOW()
);

-- ┌─────────────────────────────────────┐
-- │  TABLE 21: broadcast_notifications  │
-- │  Features: F43 (Notification Blast) │
-- └─────────────────────────────────────┘
CREATE TABLE IF NOT EXISTS broadcast_notifications (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    admin_id UUID NOT NULL REFERENCES admin_users(id),
    target_type VARCHAR(20) NOT NULL
        CHECK (target_type IN ('all_riders', 'all_drivers', 'zone', 'individual')),
    target_data JSONB,
    title VARCHAR(200) NOT NULL,
    body TEXT NOT NULL,
    deep_link VARCHAR(500),
    scheduled_for TIMESTAMP,
    sent_at TIMESTAMP,
    total_sent INTEGER DEFAULT 0,
    delivered_count INTEGER DEFAULT 0,
    status VARCHAR(10) NOT NULL DEFAULT 'draft'
        CHECK (status IN ('draft', 'scheduled', 'sent')),
    created_at TIMESTAMP NOT NULL DEFAULT NOW()
);

-- ┌─────────────────────────────────────┐
-- │  TABLE 22: driver_settlements       │
-- │  Features: F44 (Cash Settlement)    │
-- └─────────────────────────────────────┘
CREATE TABLE IF NOT EXISTS driver_settlements (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    driver_id UUID NOT NULL REFERENCES users(id),
    period_start DATE NOT NULL,
    period_end DATE NOT NULL,
    total_collected DECIMAL(10,2) NOT NULL,
    platform_commission DECIMAL(10,2) NOT NULL,
    driver_earning DECIMAL(10,2) NOT NULL,
    total_rides INTEGER NOT NULL,
    settlement_status VARCHAR(10) NOT NULL DEFAULT 'pending'
        CHECK (settlement_status IN ('pending', 'paid', 'overdue')),
    payment_method VARCHAR(50),
    transaction_reference VARCHAR(100),
    settled_at TIMESTAMP,
    created_at TIMESTAMP NOT NULL DEFAULT NOW()
);


-- =============================================
-- INDEXES — for query performance
-- =============================================

CREATE INDEX IF NOT EXISTS idx_users_phone ON users(phone);
CREATE INDEX IF NOT EXISTS idx_users_role ON users(role);
CREATE INDEX IF NOT EXISTS idx_users_status ON users(status);

CREATE INDEX IF NOT EXISTS idx_otp_phone ON otp_verifications(phone);

CREATE INDEX IF NOT EXISTS idx_driver_profiles_user ON driver_profiles(user_id);
CREATE INDEX IF NOT EXISTS idx_driver_profiles_status ON driver_profiles(verification_status);

CREATE INDEX IF NOT EXISTS idx_drivers_user ON drivers(user_id);
CREATE INDEX IF NOT EXISTS idx_drivers_status ON drivers(status);
CREATE INDEX IF NOT EXISTS idx_drivers_location ON drivers(current_lat, current_lng);
CREATE INDEX IF NOT EXISTS idx_drivers_verified ON drivers(is_verified);

CREATE INDEX IF NOT EXISTS idx_rides_rider ON rides(rider_id);
CREATE INDEX IF NOT EXISTS idx_rides_driver ON rides(driver_id);
CREATE INDEX IF NOT EXISTS idx_rides_status ON rides(status);
CREATE INDEX IF NOT EXISTS idx_rides_created ON rides(created_at);
CREATE INDEX IF NOT EXISTS idx_rides_scheduled ON rides(scheduled_at) WHERE scheduled_at IS NOT NULL;

CREATE INDEX IF NOT EXISTS idx_ride_requests_ride ON ride_requests(ride_id);
CREATE INDEX IF NOT EXISTS idx_ride_requests_driver ON ride_requests(driver_id);

CREATE INDEX IF NOT EXISTS idx_route_points_ride ON ride_route_points(ride_id);

CREATE INDEX IF NOT EXISTS idx_payments_ride ON payments(ride_id);
CREATE INDEX IF NOT EXISTS idx_payments_status ON payments(status);

CREATE INDEX IF NOT EXISTS idx_ratings_ride ON ratings(ride_id);
CREATE INDEX IF NOT EXISTS idx_ratings_user ON ratings(rated_user);

CREATE INDEX IF NOT EXISTS idx_device_tokens_user ON device_tokens(user_id);
CREATE INDEX IF NOT EXISTS idx_notifications_user ON notifications_log(user_id);

CREATE INDEX IF NOT EXISTS idx_disputes_ride ON disputes(ride_id);
CREATE INDEX IF NOT EXISTS idx_disputes_status ON disputes(status);

CREATE INDEX IF NOT EXISTS idx_settlements_driver ON driver_settlements(driver_id);
CREATE INDEX IF NOT EXISTS idx_settlements_status ON driver_settlements(settlement_status);

CREATE INDEX IF NOT EXISTS idx_audit_logs_admin ON audit_logs(admin_id);
CREATE INDEX IF NOT EXISTS idx_audit_logs_created ON audit_logs(created_at);


-- =============================================
-- SEED DATA — Default fare rules
-- =============================================

INSERT INTO fare_rules (vehicle_type, base_fare, distance_rate, time_rate, minimum_fare)
VALUES ('car', 80.00, 30.00, 2.00, 100.00)
ON CONFLICT (vehicle_type) DO NOTHING;
