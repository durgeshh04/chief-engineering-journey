-- SEED.SQL — Ticketing System

-- 1. Insert one user
INSERT INTO "users" 
("id", "name", "email", "isEmailVerified", "userType", "password", "isActive")
VALUES (
  'a0eebc99-9c0b-4ef8-bb6d-6bb9bd380a11',
  'Chief Durgesh',
  'chief@ticketing.com',
  true,
  'ADMIN',
  'hashed_password',
  true
);

-- 2. Insert one venue
INSERT INTO "venue"
("id", "name", "ownerId", "totalSeats", "addressLine", "city", "state", "isActive")
VALUES (
  'b1eebc99-9c0b-4ef8-bb6d-6bb9bd380a22',
  'Wankhede Stadium',
  'a0eebc99-9c0b-4ef8-bb6d-6bb9bd380a11',
  1000,
  'D Road, Churchgate',
  'Mumbai',
  'Maharashtra',
  true
);

-- 3. Insert one event
INSERT INTO "event"
("id", "name", "eventType", "eventStatus", "venueId", "organizerName",
 "eventStartTime", "eventEndTime", "bookingStartTime", "bookingEndTime", 
 "totalCapacity", "createdBy")
VALUES (
  'c2eebc99-9c0b-4ef8-bb6d-6bb9bd380a33',
  'IPL Final 2026',
  'SPORTS',
  'PENDING',
  'b1eebc99-9c0b-4ef8-bb6d-6bb9bd380a22',
  'BCCI',
  NOW() + interval '7 days',
  NOW() + interval '7 days' + interval '4 hours',
  NOW(),
  NOW() + interval '6 days',
  1000,
  'a0eebc99-9c0b-4ef8-bb6d-6bb9bd380a11'
);

-- 4. Insert 1000 venueSeats
INSERT INTO "venueSeats" ("venueId", "seatingLabel", "seatingRowNumber", "seatType", "createdBy")
SELECT
  'b1eebc99-9c0b-4ef8-bb6d-6bb9bd380a22',
  'SEAT-' || i,
  (i / 10) + 1,
  (ARRAY['SILVER','GOLD','DIAMOND','BALCONY','PREMIUM','VIP']::text[])[((i % 6) + 1)]::"seatingCategory",
  'a0eebc99-9c0b-4ef8-bb6d-6bb9bd380a11'
FROM generate_series(1, 1000) AS i;

-- 5. Insert eventSeats for each venueSeat
INSERT INTO "eventSeats" ("eventId", "seatId", "status")
SELECT
  'c2eebc99-9c0b-4ef8-bb6d-6bb9bd380a33',
  "id",
  'OPEN'
FROM "venueSeats";

-- 6. Insert pricing per seat category
INSERT INTO "pricing" ("eventId", "seatType", "price", "createdBy")
VALUES
  ('c2eebc99-9c0b-4ef8-bb6d-6bb9bd380a33', 'SILVER',  500.00, 'a0eebc99-9c0b-4ef8-bb6d-6bb9bd380a11'),
  ('c2eebc99-9c0b-4ef8-bb6d-6bb9bd380a33', 'GOLD',    1000.00, 'a0eebc99-9c0b-4ef8-bb6d-6bb9bd380a11'),
  ('c2eebc99-9c0b-4ef8-bb6d-6bb9bd380a33', 'DIAMOND', 2000.00, 'a0eebc99-9c0b-4ef8-bb6d-6bb9bd380a11'),
  ('c2eebc99-9c0b-4ef8-bb6d-6bb9bd380a33', 'BALCONY', 1500.00, 'a0eebc99-9c0b-4ef8-bb6d-6bb9bd380a11'),
  ('c2eebc99-9c0b-4ef8-bb6d-6bb9bd380a33', 'PREMIUM', 3000.00, 'a0eebc99-9c0b-4ef8-bb6d-6bb9bd380a11'),
  ('c2eebc99-9c0b-4ef8-bb6d-6bb9bd380a33', 'VIP',     5000.00, 'a0eebc99-9c0b-4ef8-bb6d-6bb9bd380a11');

-- 7. Insert 1 million bookings using generate_series
-- First insert 1000 real bookings linked to eventSeats
INSERT INTO "bookings" ("eventId", "eventSeatId", "bookingStatus", "pricePaid", "createdBy")
SELECT
  'c2eebc99-9c0b-4ef8-bb6d-6bb9bd380a33',
  es."id",
  'CONFIRMED',
  500.00,
  'a0eebc99-9c0b-4ef8-bb6d-6bb9bd380a11'
FROM "eventSeats" es;

-- 8. Now seed 1M rows into a separate large table for EXPLAIN ANALYZE demo
-- Create demo table
CREATE TABLE IF NOT EXISTS "bookings_large" (
  "id" uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  "eventId" uuid NOT NULL,
  "userId" uuid NOT NULL,
  "status" status DEFAULT 'PENDING',
  "pricePaid" decimal(10,2),
  "createdAt" timestamptz DEFAULT NOW()
);

-- Insert 1 million rows
INSERT INTO "bookings_large" ("eventId", "userId", "pricePaid")
SELECT
  'c2eebc99-9c0b-4ef8-bb6d-6bb9bd380a33',
  'a0eebc99-9c0b-4ef8-bb6d-6bb9bd380a11',
  (random() * 5000)::decimal(10,2)
FROM generate_series(1, 1000000);
