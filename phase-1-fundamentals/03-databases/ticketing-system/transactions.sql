-- ====================================================================
-- TRANSACTIONS.SQL — Race Condition Prevention & Pessimistic Locking
-- ====================================================================

-- THE PROBLEM:
-- Two users click "Book Now" for seat A1 at the exact same millisecond.
-- Without locking, both transactions run `SELECT status FROM "eventSeats"` simultaneously.
-- Both see status = 'OPEN', both run `UPDATE`, and both insert a booking record.
-- Result: Silent Double Booking (Data Corruption).

-- THE SOLUTION:
-- Pessimistic Row-Level Locking (`SELECT ... FOR UPDATE`) inside an ACID transaction.
-- Locking directly on the Primary Key (`id`) targets the B-Tree index immediately,
-- forcing concurrent transactions attempting to read/modify the same seat to block
-- until the active transaction completes (COMMIT or ROLLBACK).

-- ====================================================================
-- SCENARIO 1: USER A RESERVES A SEAT SUCCESSFULLY
-- ====================================================================

-- STEP 1: Start explicit transaction block
BEGIN;

-- STEP 2: Lock the row directly by its Primary Key
-- `FOR UPDATE` places an exclusive row-level lock (X-Lock) on the target seat.
-- Querying by Primary Key (`id`) hits the clustered index instantly for O(log N) lookup.
-- Any parallel query running `SELECT ... FOR UPDATE` or `UPDATE` on this specific row
-- will instantly pause and enter a blocked state until User A finishes.
SELECT "id", "eventId", "status"
FROM "eventSeats"
WHERE "id" = 'd3eebc99-9c0b-4ef8-bb6d-6bb9bd380a44'
FOR UPDATE;

-- STEP 3: Check status in application logic
-- The application code inspects the returned payload:
-- IF status == 'OPEN' -> Proceed to Step 4.
-- IF status != 'OPEN' -> Issue ROLLBACK and inform the user "Seat Unavailable".

-- STEP 4: Update seat status to 'RESERVED' and set hold expiration (10 minutes)
UPDATE "eventSeats"
SET "status"        = 'RESERVED'::"seatStatus",
    "reservedUntil" = NOW() + INTERVAL '10 minutes',
    "updatedAt"     = NOW()
WHERE "id" = 'd3eebc99-9c0b-4ef8-bb6d-6bb9bd380a44';

-- STEP 5: Insert booking record linked to the reserved seat
INSERT INTO "bookings" (
  "eventId",
  "eventSeatId",
  "bookingStatus",
  "pricePaid",
  "createdBy"
)
VALUES (
  'c2eebc99-9c0b-4ef8-bb6d-6bb9bd380a33',
  'd3eebc99-9c0b-4ef8-bb6d-6bb9bd380a44',
  'PENDING'::"status",
  500.00,
  'a0eebc99-9c0b-4ef8-bb6d-6bb9bd380a22'
);

-- STEP 6: Commit transaction
-- Writing `COMMIT` saves all updates permanently to disk and releases the row lock,
-- allowing any waiting connection to unblock and proceed.
COMMIT;


-- ====================================================================
-- WHAT HAPPENS TO USER B?
-- ====================================================================
-- 1. User B issues `SELECT ... WHERE "id" = 'd3eebc99...' FOR UPDATE` while User A's transaction is open.
-- 2. PostgreSQL detects the active row lock held by User A.
-- 3. User B's connection enters a BLOCKED state (waiting at Step 2).
-- 4. The moment User A issues `COMMIT`:
--    a. User B's statement unblocks and receives the result.
--    b. User B sees the newly committed status: 'RESERVED'.
--    c. User B's application layer sees `status != 'OPEN'`, aborts, and executes `ROLLBACK`.
--    d. User B receives a clean error response: "Seat already taken".


-- ====================================================================
-- SCENARIO 2: HIGH-THROUGHPUT FLASH SALES (`FOR UPDATE SKIP LOCKED`)
-- ====================================================================
-- During intense flash sales (e.g., "Assign me any available Silver seat"):
-- Waiting on locked rows creates queuing bottlenecks.
-- `FOR UPDATE SKIP LOCKED` skips rows currently locked by other concurrent transactions,
-- allowing parallel threads to instantly pick separate unlocked seats without blocking!

BEGIN;

SELECT "id"
FROM "eventSeats"
WHERE "eventId" = 'c2eebc99-9c0b-4ef8-bb6d-6bb9bd380a33'
  AND "status"  = 'OPEN'
LIMIT 1
FOR UPDATE SKIP LOCKED;

-- Application updates selected seat and commits...

COMMIT;


-- ====================================================================
-- SCENARIO 3: ROLLBACK EXAMPLE (HANDLING FAILURES / APPLICATION ABORTS)
-- ====================================================================
-- If a failure occurs (e.g., payment failure, validation error, or seat unavailable),
-- `ROLLBACK` restores the database state and instantly releases all acquired locks.

BEGIN;

SELECT "id", "status" 
FROM "eventSeats" 
WHERE "id" = 'd3eebc99-9c0b-4ef8-bb6d-6bb9bd380a44' 
FOR UPDATE;

-- Application logic detects seat status is not 'OPEN' (e.g. status = 'BOOKED')
-- Instead of COMMIT, abort all uncommitted changes:
ROLLBACK;
-- At this point, no updates were made, and all locks are released immediately.
