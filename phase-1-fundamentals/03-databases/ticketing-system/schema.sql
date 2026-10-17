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
  "id" uuid UNIQUE PRIMARY KEY,
  "name" text,
  "email" text,
  "isEmailVerified" boolean,
  "userType" "userType",
  "password" text,
  "isActive" boolean,
  "createdAt" timestamptz,
  "updatedAt" timestamptz,
  "deletedAt" timestamptz
);

CREATE TABLE "sessions" (
  "id" uuid UNIQUE PRIMARY KEY,
  "userId" uuid NOT NULL,
  "refreshToken" text UNIQUE,
  "isRevoked" boolean,
  "createdAt" timestamptz,
  "updatedAt" timestamptz,
  "deletedAt" timestamptz
);

CREATE TABLE "venue" (
  "id" uuid UNIQUE PRIMARY KEY,
  "name" text,
  "ownerId" uuid NOT NULL,
  "totalSeats" integer,
  "addressLine" text,
  "city" text,
  "state" text,
  "isActive" boolean,
  "createdAt" timestamptz,
  "updatedAt" timestamptz,
  "deletedAt" timestamptz
);

CREATE TABLE "venueSeats" (
  "id" uuid UNIQUE PRIMARY KEY,
  "venueId" uuid NOT NULL,
  "seatingLabel" text,
  "seatingRowNumber" integer,
  "seatType" "seatingCategory",
  "createdBy" uuid NOT NULL,
  "createdAt" timestamptz,
  "updatedAt" timestamptz,
  "deletedAt" timestamptz
);

CREATE TABLE "eventSeats" (
  "id" uuid UNIQUE PRIMARY KEY,
  "eventId" uuid NOT NULL,
  "seatId" uuid NOT NULL,
  "status" "seatStatus",
  "createdAt" timestamptz,
  "updatedAt" timestamptz,
  "deletedAt" timestamptz
);

CREATE TABLE "pricing" (
  "id" uuid UNIQUE PRIMARY KEY,
  "eventId" uuid NOT NULL,
  "seatType" "seatingCategory",
  "price" decimal(10,2),
  "createdBy" uuid NOT NULL,
  "createdAt" timestamptz,
  "updatedAt" timestamptz,
  "deletedAt" timestamptz
);

CREATE TABLE "event" (
  "id" uuid UNIQUE PRIMARY KEY,
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
  "createdAt" timestamptz,
  "updatedAt" timestamptz,
  "deletedAt" timestamptz
);

CREATE TABLE "bookings" (
  "id" uuid UNIQUE PRIMARY KEY,
  "eventId" uuid NOT NULL,
  "eventSeatId" uuid NOT NULL,
  "bookingStatus" status,
  "pricePaid" decimal(10,2),
  "createdBy" uuid NOT NULL,
  "createdAt" timestamptz,
  "updatedAt" timestamptz,
  "deletedAt" timestamptz
);

ALTER TABLE "sessions" ADD FOREIGN KEY ("userId") REFERENCES "users" ("id") DEFERRABLE INITIALLY IMMEDIATE;

ALTER TABLE "venue" ADD FOREIGN KEY ("ownerId") REFERENCES "users" ("id") DEFERRABLE INITIALLY IMMEDIATE;

ALTER TABLE "venueSeats" ADD FOREIGN KEY ("venueId") REFERENCES "venue" ("id") DEFERRABLE INITIALLY IMMEDIATE;

ALTER TABLE "venueSeats" ADD FOREIGN KEY ("createdBy") REFERENCES "users" ("id") DEFERRABLE INITIALLY IMMEDIATE;

ALTER TABLE "eventSeats" ADD FOREIGN KEY ("eventId") REFERENCES "event" ("id") DEFERRABLE INITIALLY IMMEDIATE;

ALTER TABLE "eventSeats" ADD FOREIGN KEY ("seatId") REFERENCES "venueSeats" ("id") DEFERRABLE INITIALLY IMMEDIATE;

ALTER TABLE "pricing" ADD FOREIGN KEY ("eventId") REFERENCES "event" ("id") DEFERRABLE INITIALLY IMMEDIATE;

ALTER TABLE "pricing" ADD FOREIGN KEY ("createdBy") REFERENCES "users" ("id") DEFERRABLE INITIALLY IMMEDIATE;

ALTER TABLE "event" ADD FOREIGN KEY ("venueId") REFERENCES "venue" ("id") DEFERRABLE INITIALLY IMMEDIATE;

ALTER TABLE "event" ADD FOREIGN KEY ("createdBy") REFERENCES "users" ("id") DEFERRABLE INITIALLY IMMEDIATE;

ALTER TABLE "bookings" ADD FOREIGN KEY ("eventId") REFERENCES "event" ("id") DEFERRABLE INITIALLY IMMEDIATE;

ALTER TABLE "bookings" ADD FOREIGN KEY ("eventSeatId") REFERENCES "eventSeats" ("id") DEFERRABLE INITIALLY IMMEDIATE;

ALTER TABLE "bookings" ADD FOREIGN KEY ("createdBy") REFERENCES "users" ("id") DEFERRABLE INITIALLY IMMEDIATE;
