# Mastering PostgreSQL Indexing: Strategies, Mechanics & Real-World Practice

An **Index** is a specialized, secondary data structure maintained on disk by the Database Management System (DBMS) that accelerates data retrieval queries ($O(\log N)$ or $O(1)$) without requiring full sequential scans ($O(N)$) across the underlying table heap.

---

## 1. Core Mechanics: How Indexing Works

Without an index, PostgreSQL stores table rows on disk in an unsorted array of data pages called the **Heap**. Finding a specific record requires a **Sequential Scan (`Seq Scan`)**, where Postgres reads every data page from top to bottom, inspecting every single row.

```
Without Index (Sequential Scan - O(N)):
Heap Pages: [Page 1] ──► [Page 2] ──► [Page 3] ... ──► [Page 12,346] (Scans 1M Rows)

With B-Tree Index (Index Scan - O(log N)):
B-Tree Root ──► Branch Node ──► Leaf Node (Tuple ID: Page 42, Offset 3) ──► Direct Heap Fetch
```

When an index is present:
1. Postgres traverses the balanced search tree on disk in 3–4 node hops.
2. The leaf node yields a **Tuple ID (TID)** containing the exact physical block address and byte offset on disk.
3. Postgres jumps directly to that target page in memory/disk to fetch the row.

---

## 2. PostgreSQL Index Types & Use Cases

PostgreSQL provides several specialized index types. Here is when and how to use each:

```
                            ┌───────────────────────────────┐
                            │    POSTGRES INDEX TYPES       │
                            └───────────────┬───────────────┘
                                            │
         ┌──────────────────┬───────────────┴───────────────┬──────────────────┐
         │                  │                               │                  │
┌────────┴────────┐┌────────┴────────┐             ┌────────┴────────┐┌────────┴────────┐
│  B-Tree Index   ││    GIN Index    │             │ Partial Index   ││   BRIN Index    │
│  (Default / 90%)││ (JSONB / Arrays)│             │ (Filtered Rows) ││  (Block Range)  │
└─────────────────┘└─────────────────┘             └─────────────────┘└─────────────────┘
```

### 1. B-Tree Index (Default)
* **Underlying Structure:** Self-balancing B-Tree search structure ($O(\log N)$ lookup time).
* **Supported Operators:** `=`, `<`, `>`, `<=`, `>=`, `IN`, `BETWEEN`, `IS NULL`, `ORDER BY`.
* **When to Use:**
  * Primary Keys and Foreign Key relationship columns.
  * Unique email, username, or identifier columns.
  * Numerical and timestamp range queries.
* **Syntax:**
  ```sql
  CREATE INDEX idx_users_email ON users (email);
  ```

### 2. Composite (Multi-Column) B-Tree Index
* **When to Use:** Queries filtering or sorting across multiple columns simultaneously (`WHERE eventId = x AND status = 'OPEN'`).
* **The Leftmost Prefix Rule:** Column order matters! Always place the most selective filter column first.
* **Syntax:**
  ```sql
  CREATE INDEX idx_eventseats_event_status ON "eventSeats" ("eventId", "status");
  ```

### 3. GIN (Generalized Inverted Index)
* **Underlying Structure:** Inverted index mapping internal values/keys directly to row IDs containing them.
* **When to Use:**
  * Semi-structured data (`JSONB`).
  * Native PostgreSQL array columns (`TEXT[]`, `INTEGER[]`).
  * Full-text search vectors (`tsvector`).
* **Operators:** `@>`, `?`, `?|`, `?&`.
* **Syntax:**
  ```sql
  CREATE INDEX idx_tasks_metadata_gin ON tasks USING GIN (metadata);
  ```

### 4. Partial / Filtered Index
* **When to Use:** Indexing only a small subset of records in a large table to drastically reduce index size on disk and reduce write overhead.
* **Real-World Case:** Indexing active, unexpired holds or pending orders.
* **Syntax:**
  ```sql
  CREATE INDEX idx_active_seat_holds ON "eventSeats" ("eventId", "reservedUntil") 
  WHERE "status" = 'RESERVED';
  ```

### 5. BRIN (Block Range Index)
* **Underlying Structure:** Stores min/max range summaries for physical page blocks on disk.
* **When to Use:** Massive time-series tables (100M+ rows) where data is sequentially appended by timestamp.
* **Syntax:**
  ```sql
  CREATE INDEX idx_logs_created_at_brin ON app_logs USING BRIN (created_at);
  ```

---

## 3. Real-World Decision Matrix

| Query Pattern | Recommended Index Type | Example Syntax |
| :--- | :--- | :--- |
| `WHERE id = 'uuid'` | B-Tree | `CREATE INDEX ON table (id);` |
| `WHERE status = 'OPEN' AND event_id = x` | Composite B-Tree | `CREATE INDEX ON table (event_id, status);` |
| `WHERE metadata @> '{"role": "admin"}'` | GIN | `CREATE INDEX ON table USING GIN (metadata);` |
| `WHERE status = 'PENDING'` (5% of data) | Partial Index | `CREATE INDEX ON table (created_at) WHERE status = 'PENDING';` |
| `WHERE created_at >= NOW() - INTERVAL '1 day'` (100M+ rows) | BRIN | `CREATE INDEX ON table USING BRIN (created_at);` |

---

## 4. Hands-On Practice Exercises

Run these queries in your PostgreSQL client to benchmark unindexed versus indexed query execution using `EXPLAIN (ANALYZE, BUFFERS)`.

### Exercise 1: B-Tree Index Speedup on Foreign Keys

```sql
-- 1. Run query without index
EXPLAIN (ANALYZE, BUFFERS)
SELECT * FROM "bookings" 
WHERE "eventId" = 'c2eebc99-9c0b-4ef8-bb6d-6bb9bd380a33';

-- 2. Add the B-Tree index
CREATE INDEX idx_bookings_event_id ON "bookings" ("eventId");

-- 3. Rerun execution plan and compare times
EXPLAIN (ANALYZE, BUFFERS)
SELECT * FROM "bookings" 
WHERE "eventId" = 'c2eebc99-9c0b-4ef8-bb6d-6bb9bd380a33';
```

### Exercise 2: Partial Indexing for Ephemeral State Cleanup

```sql
-- Create a partial index specifically for expired reservation cleanup tasks
CREATE INDEX idx_eventseats_expired_holds ON "eventSeats" ("reservedUntil")
WHERE "status" = 'RESERVED';

-- Test execution plan for background worker cleanup process
EXPLAIN (ANALYZE, BUFFERS)
SELECT "id", "eventId" 
FROM "eventSeats"
WHERE "status" = 'RESERVED' 
  AND "reservedUntil" < NOW();
```

---

## 5. Summary: The Golden Rules of Database Indexing

1. **Indexes Speed Up Reads, But Slow Down Writes:** Every `INSERT`, `UPDATE`, or `DELETE` forces Postgres to update both the heap table and every index defined on it.
2. **Always Index Foreign Keys:** PostgreSQL does *not* automatically create indexes on foreign key columns. Unindexed foreign keys cause full table scans during parent updates/deletes.
3. **Avoid Low-Cardinality Indexes:** Do not build standard B-Tree indexes on columns with very few unique values (e.g., `boolean` or `gender`), as Postgres will favor sequential scans.