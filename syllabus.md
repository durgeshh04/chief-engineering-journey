# Syllabus: Chief's Engineering Journey

Goal: become an engineer with deep fundamentals, who can pick up any language, framework, or tool and make sound design decisions.

**How every topic is studied:** watch one video, build something small, write notes in your own words from memory, push to GitHub, then explain it back.

---

## Daily and weekly tracks (run alongside every chapter)

- **Daily:** one LeetCode problem. State the time and space complexity and why.
- **Daily:** push something to the `chief-engineering-journey` repo.
- **Daily:** recall check at the start of each session, no notes.
- **Weekly (Sunday):** review test with 5 to 7 questions from the week, answered in your own words.
- **Reading:** The Pragmatic Programmer, then A Philosophy of Software Design, then Designing Data-Intensive Applications (DDIA), then Clean Code.

### DSA topics (covered through the daily LeetCode habit)

1. Arrays and two pointers
2. Hash maps and sets
3. Linked lists, stacks, queues
4. Trees and graphs (BFS, DFS)
5. Recursion and dynamic programming
6. Big-O analysis of time and space

---

## Chapter 1: How Node.js runs your code

1. Process vs thread
2. Why Node is single-threaded and how it still handles many requests
3. Blocking vs non-blocking I/O
4. I/O work vs CPU work (worker threads, queues)
5. Memory: stack vs heap
6. Garbage collection and memory leaks
7. Inspecting memory with `node --inspect` and heap snapshots
8. Execution context (global and function, memory-creation and execution phases)
9. The call stack
10. Microtask queue vs macrotask queue (including `process.nextTick`)
11. The event loop and how it moves callbacks to the stack
12. Why Node stays alive: libuv and OS polling (`epoll`, `kqueue`, IOCP)
13. Graceful shutdown: SIGTERM, `app.close()`, `enableShutdownHooks()`
14. Shared state and tenant data bleeding in a multi-tenant server
15. In-memory caching risks: scope, TTL, invalidation, multiple instances

---

## Chapter 2: Databases with PostgreSQL

1. Why databases exist: persistence, RAM vs disk, race conditions on plain files
2. What a DBMS is responsible for
3. Relational vs NoSQL
4. Why PostgreSQL
5. Data types and how to choose them (TEXT, DECIMAL, timestamptz, UUID, JSON vs JSONB, enums)
6. Schema design: entities, relationships, primary and foreign keys
7. Constraints: NOT NULL, UNIQUE, CHECK
8. Foreign key delete behaviour (CASCADE, RESTRICT, SET NULL) and soft deletes
9. Multi-tenant schema design
10. Migrations (up and down)
11. Seeding large datasets with `generate_series`
12. Sequential scan vs index scan
13. Reading `EXPLAIN` and `EXPLAIN ANALYZE`
14. B-tree indexes, cardinality, and when the planner ignores an index
15. Composite indexes and the leftmost-prefix rule
16. Partial indexes
17. GIN indexes and JSONB queries
18. The cost of indexes on writes, and when not to index
19. N+1 queries and query optimization
20. Transactions and ACID
21. Isolation levels and read anomalies (dirty, non-repeatable, phantom, lost update)
22. Row locking: `SELECT FOR UPDATE`, `SKIP LOCKED`
23. Race conditions and defence in depth (lock plus unique constraint)
24. MVCC, WAL, and VACUUM
25. Connection management and pooling (PgBouncer)
26. Replication, consistency, and reliability basics (DDIA chapters 1 to 5)

---

## Chapter 3: Networking

1. The layered model (four-layer TCP/IP)
2. IP addresses and ports, IPv4 vs IPv6
3. TCP and the three-way handshake, sequence numbers, retransmission, closing connections
4. TCP vs UDP
5. DNS: resolution, caching, TTL
6. HTTP: structure, methods, status codes, headers, keep-alive, HTTP/1.1 vs 2 vs 3
7. TLS and HTTPS: the handshake, certificates, what HTTPS protects
8. Load balancers and reverse proxies
9. WebSockets
10. Tracing one full request from the user's tap to your controller

---

## Chapter 4: Software design

1. Clean module boundaries and separation of concerns
2. SOLID principles applied to NestJS modules
3. Repository pattern
4. Factory pattern
5. Strategy pattern
6. Observer pattern
7. NestJS internals: modules, dependency injection, guards, pipes, interceptors
8. REST API design: resources, maturity levels
9. Idempotency and retries
10. Error contracts and consistent response shapes
11. Pagination patterns
12. API versioning
13. Permission and authorization design for multi-tenant systems
14. Writing short design docs and RFCs
15. Refactoring and technical debt triage

---

## Chapter 5: Infrastructure and deployment

1. Docker: images, layers, networking, multi-stage builds
2. Containers vs processes
3. Environment configuration and secrets management
4. Cloud Run and GCP: scaling, cold starts, IAM, least privilege
5. VPC networking and managed databases
6. CI/CD basics
7. Structured logging
8. Metrics, tracing, and alerting
9. SLOs and SLAs
10. Debugging a production issue methodically

---

## Chapter 6: Security

1. OWASP Top 10 for backend engineers
2. SQL injection and parameterized queries
3. Authentication: JWT, refresh tokens, session lifecycle
4. Broken access control and IDOR
5. Rate limiting
6. Secrets in code and in repos
7. Least-privilege database roles
8. Auditing your own API
9. Hardening a multi-tenant SaaS

---

## Chapter 7: Caching and asynchronous processing

1. Why and when to cache
2. Redis data structures
3. Cache invalidation strategies
4. Cache stampede
5. CDN caching
6. When caching hides a database problem instead of fixing it
7. Message queues and why they exist
8. BullMQ patterns in NestJS
9. Idempotent workers
10. Dead-letter queues
11. Queue vs direct call: choosing between them

---

## Chapter 8: System design

1. Requirements: functional vs non-functional
2. Back-of-envelope estimation
3. Load balancing
4. Horizontal vs vertical scaling
5. Database scaling: replicas, partitioning, sharding
6. Consistency models, CAP theorem, eventual consistency
7. Distributed systems failure modes
8. Rate limiting and backpressure
9. Design problems practised weekly, with written design docs
10. Graduation exercise: design ChainageX for 10x scale and defend every decision
11. DDIA chapters 6 to 12

---

## Chapter 9: AI engineering

1. How LLMs work, at a practical level
2. Calling LLM APIs
3. Prompting for code review and generation
4. Embeddings and vector search (pgvector)
5. Retrieval-augmented generation (RAG)
6. Evaluating and testing AI features
7. Building AI-assisted features into a real product
8. Knowing when AI output is wrong

---

## Cross-cutting track: Language-agnostic thinking

For each concept in the chapters above, see how the same idea appears in a second language.

1. Concurrency models: Node event loop, Go goroutines, Python asyncio
2. Memory management across languages
3. Error handling styles
4. Type systems
5. Reading unfamiliar code in Go, Python, or Java and mapping it back to concepts you already know

---

## Interview preparation (after the chapters)

1. LeetCode medium and hard at speed
2. Mock system design interviews
3. Behavioural stories from ChainageX and PlayerWalk
4. Resume and portfolio built from your GitHub repo
