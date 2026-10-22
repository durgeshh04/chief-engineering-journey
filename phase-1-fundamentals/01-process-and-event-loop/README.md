# 01 - Process, Execution Context & Event Loop

## Execution Context

When JavaScript runs any code, it creates an Execution Context. There are two types:

- **Global Execution Context**: created once when code starts
- **Function Execution Context**: created every time a function is called

Each execution context has two phases:

1. **Memory Creation Phase**: variables and functions are stored in memory before any code runs
2. **Execution Phase**: code runs line by line

## Call Stack

The call stack manages execution contexts using **LIFO** (Last In First Out).

- When a function is called, its context is pushed to the stack
- When a function finishes, its context is popped off the stack
- The event loop is always running, but it can only move a callback onto the stack when the stack is empty

## Microtask Queue vs Macrotask Queue

| Queue | Priority | Contains |
| :--- | :--- | :--- |
| **Microtask** | HIGH, runs first | Promise callbacks (`.then`, `await`) |
| **Macrotask** | LOW, runs after | `setTimeout`, `setInterval`, I/O callbacks |

> **Note:** The event loop clears the entire microtask queue before picking one task from the macrotask queue.
>
> **Note:** `process.nextTick` has its own queue in Node. It runs before Promise callbacks.

## The Event Loop

The event loop runs continuously from the moment the program starts. On each pass it checks:

- Is the call stack empty?
  - **YES**: take from the microtask queue first (clear it completely), then take one task from the macrotask queue and push it to the call stack
  - **NO**: wait

It does **not** execute callbacks itself and it does not start the async work. Node APIs and libuv handle the waiting. The event loop only moves ready callbacks onto the stack when the stack is free.

---

## Why Node.js Stays Alive: libuv and the OS

### 1. What makes a script exit and a server stay alive

A Node.js script exits when it has no pending work or active handles left to wait for. A server stays alive because `listen()` registers an active handle that waits for network connections. That keeps the process open without burning CPU.

### 2. Who does the waiting: Node or the OS

The operating system does the waiting. Node gives the kernel a list of sockets to watch, goes idle, and relies on the kernel to wake it when something happens. Node never checks the port itself.

### 3. libuv's job

`libuv` is the C library inside Node.js that connects JavaScript to the OS's native I/O mechanisms: `epoll` on Linux, `kqueue` on macOS, IOCP on Windows. It is the event loop. It tracks active handles, polls for I/O, and finds the callbacks that are ready to run.

### 4. Full path from request to controller

1. **OS kernel:** a TCP packet arrives on port 3000 and the kernel wakes Node's poll step.
2. **libuv:** reads the bytes from the socket and marks the connection's callback as ready.
3. **Node HTTP parser:** turns the raw bytes into a request object (method, headers, body).
4. **Event loop:** when the call stack is empty, the ready callback is moved onto the stack.
5. **Call stack / V8:** runs your JS, passing the request through NestJS or Express middleware to your controller.

### 5. `SIGTERM` and `app.close()`

When Cloud Run stops a container, it sends a `SIGTERM` signal. By default, Node exits immediately when it gets `SIGTERM`, so in-flight requests are cut off. In NestJS, `app.enableShutdownHooks()` registers a handler that calls `app.close()` on that signal. `app.close()` stops accepting new connections, lets in-flight requests finish, and closes the active handles. The handle count then reaches zero and Node exits cleanly. Cloud Run force-kills the container if it hasn't exited after a short grace period (10 seconds by default), so shutdown has to finish within that window.

---

## Code Execution Examples

### Execution order

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
```

Output:

```
1 - Start
4 - End
3 - Promise
3.5 - nested Promise
2 - setTimeout
```

Why: synchronous code runs first (1, 4). Then the microtask queue is cleared completely, including the nested Promise that gets added while it runs (3, 3.5). The macrotask runs last (2).

### Promise inside a setTimeout

```javascript
setTimeout(() => {
  console.log("1-Hello code");
  Promise.resolve().then(() => {
    console.log("3 - Promise");
    Promise.resolve().then(() => console.log("3.5 - nested Promise"));
  });
  console.log("2-Hello code");
}, 0);
```

Output:

```
1-Hello code
2-Hello code
3 - Promise
3.5 - nested Promise
```

Why: the callback runs as a macrotask. Its synchronous lines (1, 2) finish first. The Promise callbacks it queued run next, and the whole microtask queue is cleared before the next macrotask can start.
