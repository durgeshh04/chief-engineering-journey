-- ====================================================================
-- SCHEMA.SQL — Production High-Concurrency Ticketing & Inventory Engine
-- ====================================================================

-- 1. ENUM TYPES
CREATE TYPE "userType" AS ENUM (
  'ADMIN',
  'CUSTOMER',
  'SELLER',
  'VENUE_OWNER'
);

CREATE TYPE "status" AS ENUM (
  'PENDING',
  'CANCELLED',
  'CONFIRMED'
);

CREATE TYPE "seatingCategory" AS ENUM (
  'SILVER',
  'GOLD',
  'DIAMOND',
  'BALCONY',
  'PREMIUM',
  'VIP'
);

CREATE TYPE "seatStatus" AS ENUM (
  'OPEN',
  'RESERVED',
  'BOOKED'
);

CREATE TYPE "eventType" AS ENUM (
  'CULTURAL',
  'SPORTS',
  'PARTY',
  'EDUCATION'
);

-- 2. CORE TABLES

CREATE TABLE "users" (
  "id" uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  "name" text NOT NULL,
  "email" text UNIQUE NOT NULL,
  "isEmailVerified" boolean DEFAULT false,
  "userType" "userType" NOT NULL DEFAULT 'CUSTOMER',
  "password" text NOT NULL,
  "isActive" boolean DEFAULT true,
  "createdAt" timestamptz DEFAULT NOW(),
  "updatedAt" timestamptz,
  "deletedAt" timestamptz
);

CREATE TABLE "sessions" (
  "id" uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  "userId" uuid NOT NULL,
  "refreshToken" text UNIQUE NOT NULL,
  "isRevoked" boolean DEFAULT false,
  "createdAt" timestamptz DEFAULT NOW(),
  "updatedAt" timestamptz,
  "deletedAt" timestamptz,
  CONSTRAINT "fk_sessions_user" FOREIGN KEY ("userId") REFERENCES "users"("id") ON DELETE CASCADE
);

CREATE TABLE "venue" (
  "id" uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  "name" text NOT NULL,
  "ownerId" uuid NOT NULL,
  "totalSeats" integer NOT NULL CHECK ("totalSeats" > 0),
  "addressLine" text,
  "city" text NOT NULL,
  "state" text NOT NULL,
  "isActive" boolean DEFAULT true,
  "createdAt" timestamptz DEFAULT NOW(),
  "updatedAt" timestamptz,
  "deletedAt" timestamptz,
  CONSTRAINT "fk_venue_user" FOREIGN KEY ("ownerId") REFERENCES "users"("id") ON DELETE RESTRICT
);

CREATE TABLE "venueSeats" (
  "id" uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  "venueId" uuid NOT NULL,
  "seatingLabel" text NOT NULL,
  "seatingRowNumber" integer NOT NULL,
  "seatType" "seatingCategory" NOT NULL,
  "createdBy" uuid NOT NULL,
  "createdAt" timestamptz DEFAULT NOW(),
  "updatedAt" timestamptz,
  "deletedAt" timestamptz,
  CONSTRAINT "fk_venueseats_venue" FOREIGN KEY ("venueId") REFERENCES "venue"("id") ON DELETE RESTRICT,
  CONSTRAINT "fk_venueseats_createdby" FOREIGN KEY ("createdBy") REFERENCES "users"("id") ON DELETE RESTRICT,
  CONSTRAINT "uq_venue_seat_label" UNIQUE ("venueId", "seatingLabel")
);

CREATE TABLE "event" (
  "id" uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  "name" text NOT NULL,
  "eventType" "eventType" NOT NULL,
  "eventStatus" "status" DEFAULT 'PENDING',
  "venueId" uuid NOT NULL,
  "organizerName" text NOT NULL,
  "eventStartTime" timestamptz NOT NULL,
  "eventEndTime" timestamptz NOT NULL,
  "bookingStartTime" timestamptz NOT NULL,
  "bookingEndTime" timestamptz NOT NULL,
  "totalCapacity" bigint NOT NULL CHECK ("totalCapacity" > 0),
  "createdBy" uuid NOT NULL,
  "createdAt" timestamptz DEFAULT NOW(),
  "updatedAt" timestamptz,
  "deletedAt" timestamptz,
  CONSTRAINT "fk_event_venue" FOREIGN KEY ("venueId") REFERENCES "venue"("id") ON DELETE RESTRICT,
  CONSTRAINT "fk_event_createdby" FOREIGN KEY ("createdBy") REFERENCES "users"("id") ON DELETE RESTRICT,
  CONSTRAINT "chk_event_times" CHECK ("eventEndTime" > "eventStartTime"),
  CONSTRAINT "chk_booking_times" CHECK ("bookingEndTime" > "bookingStartTime")
);

CREATE TABLE "eventSeats" (
  "id" uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  "eventId" uuid NOT NULL,
  "seatId" uuid NOT NULL,
  "status" "seatStatus" DEFAULT 'OPEN',
  "reservedUntil" timestamptz,
  "createdAt" timestamptz DEFAULT NOW(),
  "updatedAt" timestamptz,
  "deletedAt" timestamptz,
  CONSTRAINT "fk_eventseats_event" FOREIGN KEY ("eventId") REFERENCES "event"("id") ON DELETE RESTRICT,
  CONSTRAINT "fk_eventseats_seat" FOREIGN KEY ("seatId") REFERENCES "venueSeats"("id") ON DELETE RESTRICT,
  -- ZERO DOUBLE-BOOKING GUARANTEE
  CONSTRAINT "uq_event_seat" UNIQUE ("eventId", "seatId")
);

CREATE TABLE "pricing" (
  "id" uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  "eventId" uuid NOT NULL,
  "seatType" "seatingCategory" NOT NULL,
  "price" decimal(10,2) NOT NULL CHECK ("price" >= 0.00),
  "createdBy" uuid NOT NULL,
  "createdAt" timestamptz DEFAULT NOW(),
  "updatedAt" timestamptz,
  "deletedAt" timestamptz,
  CONSTRAINT "fk_pricing_event" FOREIGN KEY ("eventId") REFERENCES "event"("id") ON DELETE RESTRICT,
  CONSTRAINT "fk_pricing_createdby" FOREIGN KEY ("createdBy") REFERENCES "users"("id") ON DELETE RESTRICT,
  CONSTRAINT "uq_event_seat_type_pricing" UNIQUE ("eventId", "seatType")
);

CREATE TABLE "bookings" (
  "id" uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  "eventId" uuid NOT NULL,
  "eventSeatId" uuid NOT NULL UNIQUE,
  "bookingStatus" "status" DEFAULT 'PENDING',
  "pricePaid" decimal(10,2) NOT NULL CHECK ("pricePaid" >= 0.00),
  "createdBy" uuid NOT NULL,
  "createdAt" timestamptz DEFAULT NOW(),
  "updatedAt" timestamptz,
  "deletedAt" timestamptz,
  CONSTRAINT "fk_bookings_event" FOREIGN KEY ("eventId") REFERENCES "event"("id") ON DELETE RESTRICT,
  CONSTRAINT "fk_bookings_eventseat" FOREIGN KEY ("eventSeatId") REFERENCES "eventSeats"("id") ON DELETE RESTRICT,
  CONSTRAINT "fk_bookings_createdby" FOREIGN KEY ("createdBy") REFERENCES "users"("id") ON DELETE RESTRICT
);

-- 3. FOREIGN KEY & PERFORMANCE INDEXES

-- Sessions & Venues
CREATE INDEX "idx_sessions_user_id" ON "sessions" ("userId");
CREATE INDEX "idx_venue_owner_id" ON "venue" ("ownerId");

-- Venue Seats
CREATE INDEX "idx_venueseats_venue_id" ON "venueSeats" ("venueId");

-- Event
CREATE INDEX "idx_event_venue_id" ON "event" ("venueId");

-- Event Seats (High Read Volume)
CREATE INDEX "idx_eventseats_event_id" ON "eventSeats" ("eventId");
CREATE INDEX "idx_eventseats_seat_id" ON "eventSeats" ("seatId");
CREATE INDEX "idx_eventseats_event_status" ON "eventSeats" ("eventId", "status");

-- Partial Index for Active Holds Cleanup (Optimizes Expiration Checks)
CREATE INDEX "idx_eventseats_active_holds" ON "eventSeats" ("eventId", "reservedUntil") 
WHERE "status" = 'RESERVED';

-- Pricing
CREATE INDEX "idx_pricing_event_id" ON "pricing" ("eventId");

-- Bookings
CREATE INDEX "idx_bookings_event_id" ON "bookings" ("eventId");
CREATE INDEX "idx_bookings_user_id" ON "bookings" ("createdBy");
CREATE INDEX "idx_bookings_status" ON "bookings" ("bookingStatus");
