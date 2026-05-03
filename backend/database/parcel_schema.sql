-- ============================================
-- RideShare AI Pro — Parcel Delivery Tables
-- F45-F51: 7 Parcel Features
-- Run this in Supabase SQL Editor
-- ============================================

-- Parcel size categories & pricing
CREATE TABLE IF NOT EXISTS parcel_categories (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  name VARCHAR(50) NOT NULL,          -- small, medium, large, extra_large
  max_weight_kg DECIMAL(5,2) NOT NULL, -- max weight in kg
  max_length_cm INT,
  max_width_cm INT,
  max_height_cm INT,
  base_fare DECIMAL(10,2) NOT NULL DEFAULT 60,
  per_km_rate DECIMAL(10,2) NOT NULL DEFAULT 15,
  weight_surcharge DECIMAL(10,2) DEFAULT 0,   -- extra charge per kg over base
  fragile_surcharge DECIMAL(10,2) DEFAULT 30,
  is_active BOOLEAN DEFAULT true,
  created_at TIMESTAMPTZ DEFAULT NOW()
);

-- Main parcels table
CREATE TABLE IF NOT EXISTS parcels (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  sender_id UUID NOT NULL REFERENCES users(id),
  driver_id UUID REFERENCES users(id),
  
  -- Parcel details
  category_id UUID REFERENCES parcel_categories(id),
  parcel_description TEXT,
  weight_kg DECIMAL(5,2),
  is_fragile BOOLEAN DEFAULT false,
  special_instructions TEXT,
  
  -- Pickup info
  pickup_lat DECIMAL(10,7) NOT NULL,
  pickup_lng DECIMAL(10,7) NOT NULL,
  pickup_address TEXT NOT NULL,
  pickup_contact_name VARCHAR(100) NOT NULL,
  pickup_contact_phone VARCHAR(15) NOT NULL,
  
  -- Drop info
  drop_lat DECIMAL(10,7) NOT NULL,
  drop_lng DECIMAL(10,7) NOT NULL,
  drop_address TEXT NOT NULL,
  receiver_name VARCHAR(100) NOT NULL,
  receiver_phone VARCHAR(15) NOT NULL,
  
  -- Status & lifecycle
  status VARCHAR(30) DEFAULT 'pending',
  -- pending → driver_assigned → pickup_arrived → picked_up → in_transit → delivered → cancelled
  
  -- Fare
  estimated_fare DECIMAL(10,2),
  final_fare DECIMAL(10,2),
  fare_breakdown JSONB,
  estimated_distance DECIMAL(10,2),
  estimated_duration INT,
  
  -- OTP verification
  pickup_otp_hash VARCHAR(255),
  delivery_otp_hash VARCHAR(255),
  pickup_verified BOOLEAN DEFAULT false,
  delivery_verified BOOLEAN DEFAULT false,
  
  -- Photo proofs
  pickup_photo_url TEXT,
  delivery_photo_url TEXT,
  
  -- Payment
  payment_method VARCHAR(20) DEFAULT 'cash',
  payment_status VARCHAR(20) DEFAULT 'pending',
  
  -- Timestamps
  scheduled_at TIMESTAMPTZ,
  picked_up_at TIMESTAMPTZ,
  delivered_at TIMESTAMPTZ,
  cancelled_at TIMESTAMPTZ,
  cancellation_reason TEXT,
  cancelled_by UUID REFERENCES users(id),
  created_at TIMESTAMPTZ DEFAULT NOW(),
  updated_at TIMESTAMPTZ DEFAULT NOW()
);

-- Parcel tracking points (GPS during delivery)
CREATE TABLE IF NOT EXISTS parcel_tracking (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  parcel_id UUID NOT NULL REFERENCES parcels(id) ON DELETE CASCADE,
  lat DECIMAL(10,7) NOT NULL,
  lng DECIMAL(10,7) NOT NULL,
  status_update VARCHAR(50),
  note TEXT,
  recorded_at TIMESTAMPTZ DEFAULT NOW()
);

-- Insert default parcel categories
INSERT INTO parcel_categories (name, max_weight_kg, max_length_cm, max_width_cm, max_height_cm, base_fare, per_km_rate, weight_surcharge, fragile_surcharge) VALUES
  ('small',       2,   30, 20, 15, 50,  12, 0,  20),
  ('medium',      5,   50, 40, 30, 80,  15, 5,  30),
  ('large',       15,  80, 60, 50, 120, 20, 8,  50),
  ('extra_large', 30, 120, 80, 70, 180, 25, 10, 80)
ON CONFLICT DO NOTHING;

-- Indexes
CREATE INDEX IF NOT EXISTS idx_parcels_sender ON parcels(sender_id);
CREATE INDEX IF NOT EXISTS idx_parcels_driver ON parcels(driver_id);
CREATE INDEX IF NOT EXISTS idx_parcels_status ON parcels(status);
CREATE INDEX IF NOT EXISTS idx_parcel_tracking_parcel ON parcel_tracking(parcel_id);
