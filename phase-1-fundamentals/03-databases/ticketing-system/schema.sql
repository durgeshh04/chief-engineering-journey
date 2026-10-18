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
  'RESERVED',
  'BOOKED',
  'OPEN'
);

CREATE TYPE "eventType" AS ENUM (
  'CULTURAL',
  'SPORTS',
  'PARTY',
  'EDUCATION'
);

CREATE TABLE "users" (
  "id" uuid UNIQUE PRIMARY KEY DEFAULT gen_random_uuid(),
  "name" text,
  "email" text,
  "isEmailVerified" boolean,
  "userType" "userType",
  "password" text,
  "isActive" boolean,
  "createdAt" timestamptz DEFAULT NOW(),
  "updatedAt" timestamptz,
  "deletedAt" timestamptz
);

CREATE TABLE "sessions" (
  "id" uuid UNIQUE PRIMARY KEY DEFAULT gen_random_uuid(),
  "userId" uuid NOT NULL,
  "refreshToken" text UNIQUE,
  "isRevoked" boolean,
  "createdAt" timestamptz DEFAULT NOW(),
  "updatedAt" timestamptz,
  "deletedAt" timestamptz,
  CONSTRAINT "fk_sessions_user" FOREIGN KEY ("userId") REFERENCES "users"("id") ON DELETE RESTRICT
);

CREATE TABLE "venue" (
  "id" uuid UNIQUE PRIMARY KEY DEFAULT gen_random_uuid(),
  "name" text,
  "ownerId" uuid NOT NULL,
  "totalSeats" integer,
  "addressLine" text,
  "city" text,
  "state" text,
  "isActive" boolean,
  "createdAt" timestamptz DEFAULT NOW(),
  "updatedAt" timestamptz,
  "deletedAt" timestamptz,
  CONSTRAINT "fk_venue_user" FOREIGN KEY ("ownerId") REFERENCES "users"("id") ON DELETE RESTRICT
);

CREATE TABLE "venueSeats" (
  "id" uuid UNIQUE PRIMARY KEY DEFAULT gen_random_uuid(),
  "venueId" uuid NOT NULL,
  "seatingLabel" text,
  "seatingRowNumber" integer,
  "seatType" "seatingCategory",
  "createdBy" uuid NOT NULL,
  "createdAt" timestamptz DEFAULT NOW(),
  "updatedAt" timestamptz,
  "deletedAt" timestamptz,
  CONSTRAINT "fk_venueseats_venue" FOREIGN KEY ("venueId") REFERENCES "venue"("id") ON DELETE RESTRICT,
  CONSTRAINT "fk_venueseats_createdby" FOREIGN KEY ("createdBy") REFERENCES "users"("id") ON DELETE RESTRICT
);

CREATE TABLE "event" (
  "id" uuid UNIQUE PRIMARY KEY DEFAULT gen_random_uuid(),
  "name" text,
  "eventType" "eventType",
  "eventStatus" status,
  "venueId" uuid NOT NULL,
  "organizerName" text,
  "eventStartTime" timestamptz,
  "eventEndTime" timestamptz,
  "bookingStartTime" timestamptz,
  "bookingEndTime" timestamptz,
  "totalCapacity" bigint,
  "createdBy" uuid NOT NULL,
  "createdAt" timestamptz DEFAULT NOW(),
  "updatedAt" timestamptz,
  "deletedAt" timestamptz,
  CONSTRAINT "fk_event_venue" FOREIGN KEY ("venueId") REFERENCES "venue"("id") ON DELETE RESTRICT,
  CONSTRAINT "fk_event_createdby" FOREIGN KEY ("createdBy") REFERENCES "users"("id") ON DELETE RESTRICT
);

CREATE TABLE "eventSeats" (
  "id" uuid UNIQUE PRIMARY KEY DEFAULT gen_random_uuid(),
  "eventId" uuid NOT NULL,
  "seatId" uuid NOT NULL,
  "status" "seatStatus",
  "createdAt" timestamptz,
  "updatedAt" timestamptz,
  "deletedAt" timestamptz,
  CONSTRAINT "fk_eventseats_event" FOREIGN KEY ("eventId") REFERENCES "event"("id") ON DELETE RESTRICT,
  CONSTRAINT "fk_eventseats_seat" FOREIGN KEY ("seatId") REFERENCES "venueSeats"("id") ON DELETE RESTRICT
);

CREATE TABLE "pricing" (
  "id" uuid UNIQUE PRIMARY KEY DEFAULT gen_random_uuid(),
  "eventId" uuid NOT NULL,
  "seatType" "seatingCategory",
  "price" decimal(10,2),
  "createdBy" uuid NOT NULL,
  "createdAt" timestamptz,
  "updatedAt" timestamptz,
  "deletedAt" timestamptz,
  CONSTRAINT "fk_pricing_event" FOREIGN KEY ("eventId") REFERENCES "event"("id") ON DELETE RESTRICT,
  CONSTRAINT "fk_pricing_createdby" FOREIGN KEY ("createdBy") REFERENCES "users"("id") ON DELETE RESTRICT
);

CREATE TABLE "bookings" (
  "id" uuid UNIQUE PRIMARY KEY DEFAULT gen_random_uuid(),
  "eventId" uuid NOT NULL,
  "eventSeatId" uuid NOT NULL UNIQUE,
  "bookingStatus" status,
  "pricePaid" decimal(10,2),
  "createdBy" uuid NOT NULL,
  "createdAt" timestamptz,
  "updatedAt" timestamptz,
  "deletedAt" timestamptz,
  CONSTRAINT "fk_bookings_event" FOREIGN KEY ("eventId") REFERENCES "event"("id") ON DELETE RESTRICT,
  CONSTRAINT "fk_bookings_eventseat" FOREIGN KEY ("eventSeatId") REFERENCES "eventSeats"("id") ON DELETE RESTRICT,
  CONSTRAINT "fk_bookings_createdby" FOREIGN KEY ("createdBy") REFERENCES "users"("id") ON DELETE RESTRICT
);
