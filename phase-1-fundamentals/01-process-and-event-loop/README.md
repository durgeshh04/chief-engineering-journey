# 01 - Process, Execution Context & Event Loop

## Execution Context

When JavaScript runs any code, it creates an Execution Context. There are two types:

- **Global Execution Context** — created once when code starts
- **Function Execution Context** — created every time a function is called

Each execution context has two phases:

1. **Memory Creation Phase** — variables and functions are stored in memory before any code runs
2. **Execution Phase** — code runs line by line

## Call Stack

The call stack manages execution contexts using **LIFO** (Last In First Out).

- When a function is called → its context is pushed to the stack
- When a function finishes → its context is popped off the stack
- When stack is empty → event loop takes over

## Microtask Queue vs Macrotask Queue

| Queue | Priority | Contains |
| :--- | :--- | :--- |
| **Microtask** | HIGH - runs first | Promises, `async/await`, `process.nextTick` |
| **Macrotask** | LOW - runs after | `setTimeout`, `setInterval`, I/O callbacks |

> **Note:** The Event loop always clears the entire microtask queue before picking one task from the macrotask queue.

## The Event Loop

The Event Loop continuously checks:

- Is the call stack empty?
  - **YES** → take from microtask queue first (clear completely) → then take one from macrotask queue → push to call stack
  - **NO** → keep waiting

It does **NOT** execute callbacks itself or assign them. Node.js APIs and Web APIs handle event monitoring; the Event Loop only moves callbacks to the Call Stack when the stack is empty.

---

## Why Node.js Stays Alive: libuv and the OS

### 1. What Makes a Script Exit and a Server Stay Alive

A Node.js script exits as soon as it has no pending work or active listeners left to wait for. A server stays alive because calling `listen()` creates an active handle that waits for network connections, keeping the process open without consuming CPU cycles.

### 2. Who Does the Waiting: Node or the OS

The Operating System does the actual waiting, not Node.js. Node hands a list of open network sockets to the OS kernel, puts its process thread to sleep, and relies on the kernel to notify it when an event occurs.

### 3. What libuv’s Job Is

`libuv` is the C library inside Node.js that bridges JavaScript with the operating system's native I/O interfaces (like `epoll` or `kqueue`). It maintains the active event handle counters, manages I/O polling, and drops triggered callbacks onto the Event Loop queue.

### 4. Full Request Lifecycle Path

1. **OS Kernel:** Receives TCP packet on port 3000 and wakes `libuv` from its sleep state.
2. **libuv:** Reads raw socket bytes and pushes the network event callback to the Event Loop.
3. **Event Loop:** Detects an empty Call Stack and shifts the callback from the queue to the stack.
4. **Call Stack / V8:** Executes your JS code, routing the request through NestJS/Express middleware to your controller handler.

### 5. What `app.close()` and `SIGTERM` Do

When Cloud Run or Docker stops a container, it sends a `SIGTERM` signal asking the app to shut down gracefully. Calling `app.close()` stops accepting new traffic, finishes in-flight requests, and closes all active `libuv` handles—allowing the active handle count to drop to zero so Node exits cleanly.

---

## Code Execution Examples & Output Order

### Nested Promise Behavior

If a Promise callback creates another Promise inside it, that new `.then()` callback goes straight to the microtask queue. Since the event loop always clears the microtask queue completely before touching the macrotask queue, the nested Promise always executes before any `setTimeout` callback.

### Execution Order Proof

```javascript
console.log("1 - Start");

setTimeout(() => {
  console.log("2 - setTimeout");
}, 0);

Promise.resolve().then(() => {
  console.log("3 - Promise");
  Promise.resolve().then(() => {
    console.log("3.5 - nested Promise");
  });
});

console.log("4 - End");
