-- ============================================
-- RideShare AI Pro — Chat Messages Table
-- F12/F32: Real-time Chat (Rider ↔ Driver)
-- Run this in Supabase SQL Editor
-- ============================================

CREATE TABLE IF NOT EXISTS chat_messages (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  ride_id UUID NOT NULL REFERENCES rides(id) ON DELETE CASCADE,
  sender_id UUID NOT NULL REFERENCES users(id),
  receiver_id UUID NOT NULL REFERENCES users(id),
  message TEXT NOT NULL,
  message_type VARCHAR(20) DEFAULT 'text',  -- text, image, location
  is_read BOOLEAN DEFAULT false,
  created_at TIMESTAMPTZ DEFAULT NOW()
);

-- Indexes for fast lookup
CREATE INDEX IF NOT EXISTS idx_chat_ride ON chat_messages(ride_id);
CREATE INDEX IF NOT EXISTS idx_chat_sender ON chat_messages(sender_id);
CREATE INDEX IF NOT EXISTS idx_chat_created ON chat_messages(ride_id, created_at);

-- Enable Supabase Realtime on this table
ALTER PUBLICATION supabase_realtime ADD TABLE chat_messages;
