# 01 - Process, Execution Context & Event Loop

## What is an Execution Context?

When JavaScript runs any code, it creates an Execution Context.
There are two types:

- **Global Execution Context** — created once when code starts
- **Function Execution Context** — created every time a function is called

Each execution context has two phases:

1. **Memory Creation Phase** — variables and functions are stored
   in memory before any code runs
2. **Execution Phase** — code runs line by line

## What is the Call Stack?

The call stack manages execution contexts using LIFO
(Last In First Out).

- When a function is called → its context is pushed to the stack
- When a function finishes → its context is popped off the stack
- When stack is empty → event loop takes over

## Microtask Queue vs Macrotask Queue

| Queue | Priority | Contains |
|-------|----------|----------|
| Microtask | HIGH - runs first | Promises, async/await |
| Macrotask | LOW - runs after | setTimeout, setInterval |

Event loop always clears the entire microtask queue
before picking one task from macrotask queue.

## What is the Event Loop?

```Event loop has one job — continuously check:
Is call stack empty?
YES → take from microtask queue first
if empty → take from macrotask queue
push to call stack
NO  → keep waiting
It does NOT assign callbacks.
Node.js APIs and Web APIs handle that part.
Event loop only moves callbacks to the stack when stack is clear.
```

## demo.js Output Explained

```javascript
console.log("1 - Start")        // sync → stack → executes immediately
setTimeout(() => ..., 0)        // goes to Node API → then macrotask queue
Promise.resolve().then(...)     // resolved → goes to microtask queue
console.log("4 - End")          // sync → stack → executes immediately
// stack now empty
// event loop checks microtask queue first → Promise runs
// then checks macrotask queue → setTimeout runs
```

**Output:**
1 - Start
4 - End
3 - Promise
2 - setTimeout

## Key Takeaway

JavaScript is single threaded. It can handle async operations
not by doing multiple things at once — but by knowing what
to do next using queues and the event loop.

## How the call stack works with the event loop

The call stack executes synchronous code line by line using
LIFO (Last In First Out). When async code is encountered,
it is handed off immediately — setTimeout goes to Node API,
Promises resolve and their .then() callbacks go to the
microtask queue.

The event loop has one job — continuously check:

- Is the call stack empty?
- If yes → pick from microtask queue first, clear it completely
- Then pick ONE task from macrotask queue
- Then check microtask queue again before next macrotask

## Nested Promise behaviour

If a Promise callback creates another Promise inside it,
that new .then() callback goes straight to the microtask
queue. Since the event loop always clears microtask queue
completely before touching macrotask queue — the nested
Promise always executes before any setTimeout callback.

Output order proof:
1 - Start        → synchronous, executes immediately
4 - End          → synchronous, executes immediately  
3 - Promise      → microtask, runs when stack clears
3.5 - nested     → microtask, created inside microtask,
                   still runs before macrotask
2 - setTimeout   → macrotask, runs last always

## Promise inside a setTimeout — execution order

1. setTimeout hits → goes to Node API →
   callback moves to macrotask queue

2. Stack is empty → event loop picks
   setTimeout callback → pushes to stack

3. Inside callback:
   console.log("1-Hello code") → sync →
   executes immediately ✓

   Promise.resolve() → .then() goes to
   microtask queue (not executed yet)

   console.log("2-Hello code") → sync →
   executes immediately ✓

4. setTimeout callback finishes → stack empty
   Event loop checks microtask queue first

5. Promise .then() runs → prints "3 - Promise"
   Inside it → new Promise created →
   goes to microtask queue again

6. Stack empty → microtask queue still has
   something → runs nested Promise
   Prints "3.5 - nested Promise"

7. Everything empty. Done.
