-- ==========================================
-- SEED.SQL — Production-Grade Test Dataset
-- ==========================================

-- 1. Insert Base Admin User & Customer Pool
INSERT INTO "users" ("id", "name", "email", "isEmailVerified", "userType", "password", "isActive")
VALUES 
  ('a0eebc99-9c0b-4ef8-bb6d-6bb9bd380a11', 'Chief Durgesh', 'chief@ticketing.com', true, 'ADMIN', 'hashed_password', true),
  ('a0eebc99-9c0b-4ef8-bb6d-6bb9bd380a22', 'Customer One', 'user1@ticketing.com', true, 'CUSTOMER', 'hashed_password', true),
  ('a0eebc99-9c0b-4ef8-bb6d-6bb9bd380a33', 'Customer Two', 'user2@ticketing.com', true, 'CUSTOMER', 'hashed_password', true),
  ('a0eebc99-9c0b-4ef8-bb6d-6bb9bd380a44', 'Customer Three', 'user3@ticketing.com', true, 'CUSTOMER', 'hashed_password', true),
  ('a0eebc99-9c0b-4ef8-bb6d-6bb9bd380a55', 'Customer Four', 'user4@ticketing.com', true, 'CUSTOMER', 'hashed_password', true)
ON CONFLICT ("id") DO NOTHING;

-- 2. Insert Base Venue
INSERT INTO "venue" ("id", "name", "ownerId", "totalSeats", "addressLine", "city", "state", "isActive")
VALUES (
  'b1eebc99-9c0b-4ef8-bb6d-6bb9bd380a22',
  'Wankhede Stadium',
  'a0eebc99-9c0b-4ef8-bb6d-6bb9bd380a11',
  1000,
  'D Road, Churchgate',
  'Mumbai',
  'Maharashtra',
  true
)
ON CONFLICT ("id") DO NOTHING;

-- 3. Insert Main Event
INSERT INTO "event" (
  "id", "name", "eventType", "eventStatus", "venueId", "organizerName",
  "eventStartTime", "eventEndTime", "bookingStartTime", "bookingEndTime", 
  "totalCapacity", "createdBy"
)
VALUES (
  'c2eebc99-9c0b-4ef8-bb6d-6bb9bd380a33',
  'IPL Final 2026',
  'SPORTS',
  'CONFIRMED',
  'b1eebc99-9c0b-4ef8-bb6d-6bb9bd380a22',
  'BCCI',
  NOW() + INTERVAL '7 days',
  NOW() + INTERVAL '7 days' + INTERVAL '4 hours',
  NOW(),
  NOW() + INTERVAL '6 days',
  1000,
  'a0eebc99-9c0b-4ef8-bb6d-6bb9bd380a11'
)
ON CONFLICT ("id") DO NOTHING;

-- 4. Insert 1,000 Physical Seats for Venue
INSERT INTO "venueSeats" ("venueId", "seatingLabel", "seatingRowNumber", "seatType", "createdBy")
SELECT
  'b1eebc99-9c0b-4ef8-bb6d-6bb9bd380a22',
  'SEAT-' || i,
  (i / 10) + 1,
  (ARRAY['SILVER','GOLD','DIAMOND','BALCONY','PREMIUM','VIP']::"seatingCategory"[])[((i % 6) + 1)],
  'a0eebc99-9c0b-4ef8-bb6d-6bb9bd380a11'
FROM generate_series(1, 1000) AS i;

-- 5. Link venue seats to the main event (all start OPEN)
INSERT INTO "eventSeats" ("eventId", "seatId", "status")
SELECT
  'c2eebc99-9c0b-4ef8-bb6d-6bb9bd380a33',
  "id",
  'OPEN'::"seatStatus"
FROM "venueSeats";

-- 6. Configure Seat Pricing per Category
INSERT INTO "pricing" ("eventId", "seatType", "price", "createdBy")
VALUES
  ('c2eebc99-9c0b-4ef8-bb6d-6bb9bd380a33', 'SILVER',  500.00,  'a0eebc99-9c0b-4ef8-bb6d-6bb9bd380a11'),
  ('c2eebc99-9c0b-4ef8-bb6d-6bb9bd380a33', 'GOLD',    1000.00, 'a0eebc99-9c0b-4ef8-bb6d-6bb9bd380a11'),
  ('c2eebc99-9c0b-4ef8-bb6d-6bb9bd380a33', 'DIAMOND', 2000.00, 'a0eebc99-9c0b-4ef8-bb6d-6bb9bd380a11'),
  ('c2eebc99-9c0b-4ef8-bb6d-6bb9bd380a33', 'BALCONY', 1500.00, 'a0eebc99-9c0b-4ef8-bb6d-6bb9bd380a11'),
  ('c2eebc99-9c0b-4ef8-bb6d-6bb9bd380a33', 'PREMIUM', 3000.00, 'a0eebc99-9c0b-4ef8-bb6d-6bb9bd380a11'),
  ('c2eebc99-9c0b-4ef8-bb6d-6bb9bd380a33', 'VIP',     5000.00, 'a0eebc99-9c0b-4ef8-bb6d-6bb9bd380a11');

-- 7. Book 200 seats: mark them BOOKED and create their CONFIRMED bookings
--    in one statement, so seat status and bookings can never disagree.
WITH booked AS (
  UPDATE "eventSeats"
  SET "status" = 'BOOKED'::"seatStatus",
      "updatedAt" = NOW()
  WHERE "id" IN (
    SELECT "id" FROM "eventSeats"
    WHERE "eventId" = 'c2eebc99-9c0b-4ef8-bb6d-6bb9bd380a33'
    ORDER BY "id"
    LIMIT 200
  )
  RETURNING "id", "eventId", "seatId"
)
INSERT INTO "bookings" ("eventId", "eventSeatId", "bookingStatus", "pricePaid", "createdBy")
SELECT
  b."eventId",
  b."id",
  'CONFIRMED'::"status",
  p."price",
  'a0eebc99-9c0b-4ef8-bb6d-6bb9bd380a11'
FROM booked b
JOIN "venueSeats" vs ON vs."id" = b."seatId"
JOIN "pricing" p ON p."eventId" = b."eventId" AND p."seatType" = vs."seatType";

-- ======================================================================
-- 8. LARGE BENCHMARKING DATASET (1,000,000 Rows across 10 Event Hotspots)
-- ======================================================================

CREATE TABLE IF NOT EXISTS "bookings_large" (
  "id" uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  "eventId" uuid NOT NULL,
  "userId" uuid NOT NULL,
  "status" "status" DEFAULT 'PENDING',
  "pricePaid" decimal(10,2),
  "createdAt" timestamptz DEFAULT NOW()
);

-- Seed 1M records distributed across 10 distinct event UUIDs
WITH event_pool AS (
  SELECT ARRAY[
    '11111111-1111-1111-1111-111111111111'::uuid,
    '22222222-2222-2222-2222-222222222222'::uuid,
    '33333333-3333-3333-3333-333333333333'::uuid,
    '44444444-4444-4444-4444-444444444444'::uuid,
    '55555555-5555-5555-5555-555555555555'::uuid,
    '66666666-6666-6666-6666-666666666666'::uuid,
    '77777777-7777-7777-7777-777777777777'::uuid,
    '88888888-8888-8888-8888-888888888888'::uuid,
    '99999999-9999-9999-9999-999999999999'::uuid,
    'c2eebc99-9c0b-4ef8-bb6d-6bb9bd380a33'::uuid
  ] AS events
),
user_pool AS (
  SELECT ARRAY[
    'a0eebc99-9c0b-4ef8-bb6d-6bb9bd380a11'::uuid,
    'a0eebc99-9c0b-4ef8-bb6d-6bb9bd380a22'::uuid,
    'a0eebc99-9c0b-4ef8-bb6d-6bb9bd380a33'::uuid,
    'a0eebc99-9c0b-4ef8-bb6d-6bb9bd380a44'::uuid,
    'a0eebc99-9c0b-4ef8-bb6d-6bb9bd380a55'::uuid
  ] AS users
)
INSERT INTO "bookings_large" ("eventId", "userId", "status", "pricePaid")
SELECT
  events[floor(random() * 10 + 1)] AS "eventId",
  users[floor(random() * 5 + 1)] AS "userId",
  (ARRAY['PENDING','CONFIRMED','CANCELLED']::"status"[])[floor(random() * 3 + 1)] AS "status",
  (random() * 5000)::decimal(10,2) AS "pricePaid"
FROM event_pool, user_pool, generate_series(1, 1000000);

-- Refresh table stats for Cost-Based Optimizer
ANALYZE "bookings_large";
