CREATE TABLE admin_users (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    email VARCHAR(255) UNIQUE NOT NULL,
    password_hash VARCHAR(255) NOT NULL,
    role VARCHAR(20) NOT NULL DEFAULT 'verifier',
    is_active BOOLEAN DEFAULT TRUE,
    totp_secret VARCHAR(255),
    last_login TIMESTAMP,
    created_at TIMESTAMP NOT NULL DEFAULT NOW()
);

CREATE TABLE users (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    phone VARCHAR(11) UNIQUE NOT NULL,
    role VARCHAR(10) NOT NULL,
    status VARCHAR(10) NOT NULL DEFAULT 'active',
    full_name VARCHAR(100),
    photo_url VARCHAR(500),
    date_of_birth DATE,
    email VARCHAR(255),
    emergency_contact_name VARCHAR(100),
    emergency_contact_phone VARCHAR(11),
    language_preference VARCHAR(5) DEFAULT 'en',
    average_rating DECIMAL(3,2) DEFAULT 0.00,
    total_ratings INTEGER DEFAULT 0,
    created_at TIMESTAMP NOT NULL DEFAULT NOW(),
    updated_at TIMESTAMP NOT NULL DEFAULT NOW()
);

CREATE TABLE otp_verifications (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    phone VARCHAR(11) NOT NULL,
    otp_code VARCHAR(255) NOT NULL,
    attempts INTEGER NOT NULL DEFAULT 0,
    expires_at TIMESTAMP NOT NULL,
    created_at TIMESTAMP NOT NULL DEFAULT NOW()
);

CREATE TABLE driver_profiles (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id UUID NOT NULL REFERENCES users(id),
    nid_front_url VARCHAR(500),
    nid_back_url VARCHAR(500),
    license_url VARCHAR(500),
    vehicle_type VARCHAR(10) NOT NULL DEFAULT 'car',
    vehicle_model VARCHAR(100),
    vehicle_year INTEGER,
    registration_number VARCHAR(50),
    vehicle_photo_url VARCHAR(500),
    account_holder_name VARCHAR(100),
    account_number VARCHAR(255),
    bank_name VARCHAR(100),
    branch_name VARCHAR(100),
    routing_number VARCHAR(50),
    verification_status VARCHAR(10) NOT NULL DEFAULT 'pending',
    verified_by UUID REFERENCES admin_users(id),
    verified_at TIMESTAMP,
    rejection_reason TEXT,
    resubmission_count INTEGER DEFAULT 0,
    created_at TIMESTAMP NOT NULL DEFAULT NOW()
);

CREATE TABLE drivers (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id UUID NOT NULL REFERENCES users(id),
    status VARCHAR(10) NOT NULL DEFAULT 'offline',
    current_lat DECIMAL(10,7),
    current_lng DECIMAL(10,7),
    last_location_update TIMESTAMP,
    is_verified BOOLEAN NOT NULL DEFAULT FALSE,
    vehicle_type VARCHAR(10) DEFAULT 'car',
    acceptance_rate DECIMAL(5,2) DEFAULT 100.00,
    average_rating DECIMAL(3,2) DEFAULT 0.00,
    total_rides INTEGER DEFAULT 0,
    total_requests INTEGER DEFAULT 0,
    total_accepts INTEGER DEFAULT 0,
    total_declines INTEGER DEFAULT 0,
    created_at TIMESTAMP NOT NULL DEFAULT NOW()
);

CREATE TABLE fare_rules (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    vehicle_type VARCHAR(10) NOT NULL UNIQUE,
    base_fare DECIMAL(10,2) NOT NULL,
    distance_rate DECIMAL(10,2) NOT NULL,
    time_rate DECIMAL(10,2) NOT NULL,
    minimum_fare DECIMAL(10,2) NOT NULL,
    updated_at TIMESTAMP NOT NULL DEFAULT NOW()
);

CREATE TABLE rides (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    rider_id UUID NOT NULL REFERENCES users(id),
    driver_id UUID REFERENCES users(id),
    pickup_lat DECIMAL(10,7) NOT NULL,
    pickup_lng DECIMAL(10,7) NOT NULL,
    pickup_address VARCHAR(500) NOT NULL,
    drop_lat DECIMAL(10,7) NOT NULL,
    drop_lng DECIMAL(10,7) NOT NULL,
    drop_address VARCHAR(500) NOT NULL,
    vehicle_type VARCHAR(10) NOT NULL DEFAULT 'car',
    status VARCHAR(20) NOT NULL DEFAULT 'searching_driver',
    estimated_fare DECIMAL(10,2),
    final_fare DECIMAL(10,2),
    surge_multiplier DECIMAL(3,1) DEFAULT 1.0,
    fare_breakdown TEXT,
    estimated_distance DECIMAL(10,2),
    estimated_duration INTEGER,
    actual_distance DECIMAL(10,2),
    actual_duration INTEGER,
    pickup_otp_hash VARCHAR(255),
    otp_attempts INTEGER DEFAULT 0,
    otp_verified BOOLEAN DEFAULT FALSE,
    otp_generated_at TIMESTAMP,
    scheduled_at TIMESTAMP,
    started_at TIMESTAMP,
    completed_at TIMESTAMP,
    cancelled_at TIMESTAMP,
    cancellation_reason TEXT,
    created_at TIMESTAMP NOT NULL DEFAULT NOW()
);

CREATE TABLE scheduled_ride_jobs (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    ride_id UUID NOT NULL REFERENCES rides(id),
    job_type VARCHAR(20) NOT NULL,
    scheduled_for TIMESTAMP NOT NULL,
    executed_at TIMESTAMP,
    status VARCHAR(10) NOT NULL DEFAULT 'pending',
    created_at TIMESTAMP NOT NULL DEFAULT NOW()
);

CREATE TABLE ride_requests (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    ride_id UUID NOT NULL REFERENCES rides(id),
    driver_id UUID NOT NULL REFERENCES users(id),
    sent_at TIMESTAMP NOT NULL DEFAULT NOW(),
    response VARCHAR(10) NOT NULL DEFAULT 'pending',
    responded_at TIMESTAMP
);

CREATE TABLE ride_route_points (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    ride_id UUID NOT NULL REFERENCES rides(id),
    lat DECIMAL(10,7) NOT NULL,
    lng DECIMAL(10,7) NOT NULL,
    speed DECIMAL(6,2),
    heading DECIMAL(5,2),
    recorded_at TIMESTAMP NOT NULL DEFAULT NOW()
);

CREATE TABLE payments (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    ride_id UUID NOT NULL REFERENCES rides(id),
    amount DECIMAL(10,2) NOT NULL,
    payment_method VARCHAR(10) NOT NULL,
    status VARCHAR(10) NOT NULL DEFAULT 'pending',
    platform_commission DECIMAL(10,2),
    driver_earning DECIMAL(10,2),
    stripe_payment_intent_id VARCHAR(255),
    paid_at TIMESTAMP,
    receipt_url VARCHAR(500),
    verified_by VARCHAR(10),
    dispute_status VARCHAR(10),
    dispute_reason TEXT,
    created_at TIMESTAMP NOT NULL DEFAULT NOW()
);

CREATE TABLE payment_methods (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id UUID NOT NULL REFERENCES users(id),
    stripe_payment_method_id VARCHAR(255) NOT NULL,
    last4 VARCHAR(4) NOT NULL,
    brand VARCHAR(20) NOT NULL,
    is_default BOOLEAN DEFAULT FALSE,
    created_at TIMESTAMP NOT NULL DEFAULT NOW()
);

CREATE TABLE ratings (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    ride_id UUID NOT NULL REFERENCES rides(id),
    rated_by UUID NOT NULL REFERENCES users(id),
    rated_user UUID NOT NULL REFERENCES users(id),
    role VARCHAR(20) NOT NULL,
    stars INTEGER NOT NULL,
    comment TEXT,
    created_at TIMESTAMP NOT NULL DEFAULT NOW()
);

CREATE TABLE device_tokens (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id UUID NOT NULL REFERENCES users(id),
    token VARCHAR(500) NOT NULL,
    platform VARCHAR(10) NOT NULL,
    updated_at TIMESTAMP NOT NULL DEFAULT NOW()
);

CREATE TABLE notifications_log (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id UUID NOT NULL REFERENCES users(id),
    type VARCHAR(50) NOT NULL,
    title VARCHAR(200) NOT NULL,
    body TEXT NOT NULL,
    data TEXT,
    sent_at TIMESTAMP NOT NULL DEFAULT NOW(),
    delivered BOOLEAN DEFAULT FALSE
);

CREATE TABLE disputes (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    ride_id UUID NOT NULL REFERENCES rides(id),
    payment_id UUID REFERENCES payments(id),
    reported_by UUID NOT NULL REFERENCES users(id),
    reported_against UUID NOT NULL REFERENCES users(id),
    reason TEXT NOT NULL,
    evidence_urls TEXT,
    status VARCHAR(15) NOT NULL DEFAULT 'open',
    resolution TEXT,
    resolved_by UUID REFERENCES admin_users(id),
    refund_amount DECIMAL(10,2),
    refund_issued BOOLEAN DEFAULT FALSE,
    created_at TIMESTAMP NOT NULL DEFAULT NOW()
);

CREATE TABLE audit_logs (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    admin_id UUID NOT NULL REFERENCES admin_users(id),
    action VARCHAR(100) NOT NULL,
    entity_type VARCHAR(50) NOT NULL,
    entity_id VARCHAR(100) NOT NULL,
    details TEXT,
    ip_address VARCHAR(45),
    created_at TIMESTAMP NOT NULL DEFAULT NOW()
);

CREATE TABLE verification_logs (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    driver_id UUID NOT NULL REFERENCES users(id),
    admin_id UUID NOT NULL REFERENCES admin_users(id),
    action VARCHAR(10) NOT NULL,
    reason TEXT,
    documents_to_resubmit TEXT,
    created_at TIMESTAMP NOT NULL DEFAULT NOW()
);

CREATE TABLE broadcast_notifications (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    admin_id UUID NOT NULL REFERENCES admin_users(id),
    target_type VARCHAR(20) NOT NULL,
    target_data TEXT,
    title VARCHAR(200) NOT NULL,
    body TEXT NOT NULL,
    deep_link VARCHAR(500),
    scheduled_for TIMESTAMP,
    sent_at TIMESTAMP,
    total_sent INTEGER DEFAULT 0,
    delivered_count INTEGER DEFAULT 0,
    status VARCHAR(10) NOT NULL DEFAULT 'draft',
    created_at TIMESTAMP NOT NULL DEFAULT NOW()
);

CREATE TABLE driver_settlements (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    driver_id UUID NOT NULL REFERENCES users(id),
    period_start DATE NOT NULL,
    period_end DATE NOT NULL,
    total_collected DECIMAL(10,2) NOT NULL,
    platform_commission DECIMAL(10,2) NOT NULL,
    driver_earning DECIMAL(10,2) NOT NULL,
    total_rides INTEGER NOT NULL,
    settlement_status VARCHAR(10) NOT NULL DEFAULT 'pending',
    payment_method VARCHAR(50),
    transaction_reference VARCHAR(100),
    settled_at TIMESTAMP,
    created_at TIMESTAMP NOT NULL DEFAULT NOW()
);
