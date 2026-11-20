# Topic 3: The TCP 3-Way Handshake

## 1. What Is the TCP 3-Way Handshake?
Before your browser or app can send real data (like a ticket booking request), TCP sets up a safe, reliable connection with the server. It does this using a quick 3-message greeting called the **3-Way Handshake**.

Think of it like calling someone on the phone before talking:
* **You:** *"Hello, can you hear me?"*
* **Friend:** *"Yes, I hear you! Can you hear me?"*
* **You:** *"Yes, I hear you too. Let's talk."*

---

## 2. Why Does TCP Need This Handshake?
TCP uses these 3 quick messages to do two jobs before sending real data:
1. **Check that both sides are awake and ready:** It proves both computers can send messages *and* receive replies.
2. **Agree on starting page numbers (Sequence Numbers):** TCP breaks large data into small pieces (packets). Just like numbering pages in a book so chapters don't get mixed up, both sides pick a random starting number to count every byte sent and received.

---

## 3. The 3 Steps (Step-by-Step)

Suppose your laptop connects to your backend server:

1. **Step 1 — `SYN` (Synchronize: *"Hello, let's connect"*):**
   * Your laptop sends a tiny packet with the **SYN** switch turned on.
   * It picks a random starting number, say **`1000`**.
2. **Step 2 — `SYN-ACK` (Synchronize + Acknowledge: *"Got it, I'm ready too"*):**
   * The server receives your `1000` and replies with **`ACK = 1001`** (adding `1` to prove it got your message).
   * In the same packet, the server picks its own random starting number, say **`5000`** (**`SYN = 5000`**).
3. **Step 3 — `ACK` (Acknowledge: *"Confirmed, starting now"*):**
   * Your laptop receives the server's `5000` and replies with **`ACK = 5001`** (adding `1` to confirm).
   * Both sides mark the connection as **`ESTABLISHED`** (open). Real data (HTTP or WebSockets) can now move safely.

```text
[ Your Laptop ]                                        [ Backend Server ]
      │                                                        │
      │ ────────── 1. SYN (My start = 1000) ─────────────────► │
      │                                                        │
      │ ◄───────── 2. SYN-ACK (My start = 5000, Got = 1001) ── │
      │                                                        │
      │ ────────── 3. ACK (Got = 5001) ──────────────────────► │
      │                                                        │
      │ ══════════ Connection ESTABLISHED (Data flows) ═══════ │
```

*(Note: Once the 3-way handshake finishes, if the app uses `HTTPS` or `WSS`, the **TLS Handshake** runs right after this to encrypt the connection.)*

---

## 4. Common TCP Connection States
When you inspect a server or your laptop, every TCP connection is in one of these states:

* **`LISTENING`:** Your backend server (like NestJS on port `3000`) is awake and waiting for incoming connections.
* **`SYN_SENT`:** Your laptop just sent Step 1 (`SYN`) and is waiting for the server to reply.
* **`SYN_RECEIVED`:** The server got Step 1, sent Step 2 (`SYN-ACK`), and is waiting for Step 3 (`ACK`).
* **`ESTABLISHED`:** All 3 steps finished. The connection is open and data is flowing.
* **`TIME_WAIT`:** One side closed the connection, and the OS is waiting a few seconds to make sure any delayed packets finish arriving before cleaning up.

---

## 5. Why This Matters for Backend Engineers
* **Extra Waiting Time (1 RTT):** Every brand-new TCP connection costs **1 Round-Trip Time (RTT)**—one full trip from user to server and back—*before* your API even sees the request. If a user is far from your server, this adds noticeable delay.
* **Connection Reuse (Keep-Alive & Pooling):** Opening a new TCP handshake for every single request slows down high-traffic apps. That is why backends use **HTTP Keep-Alive** (reusing one open TCP connection for multiple API calls) and **Database Connection Pooling** (keeping 10–20 TCP connections permanently `ESTABLISHED` with PostgreSQL).
* **SYN Flood Attacks:** If an attacker sends millions of Step 1 (`SYN`) packets and never replies with Step 3 (`ACK`), the server gets stuck holding half-open `SYN_RECEIVED` connections until it runs out of memory. Cloud firewalls (like Cloudflare) block this automatically.

---

## Hands-On Practice Exercises (Windows PowerShell)

Open **PowerShell** on your laptop and run these three exercises to see the 3-way handshake and TCP states live.

### Exercise 1: See Your Laptop's Live TCP States
Run this command to list all active TCP connections on your machine:
```powershell
netstat -ano -p TCP
```
**What to look for:**
* Look at the **State** column on the right. You will see **`LISTENING`** (apps waiting for connections), **`ESTABLISHED`** (active connections currently open), and **`TIME_WAIT`** (connections that just closed).
* Notice the **Local Address** (`192.168.1.11:<random-port>`) talking to a **Foreign Address** (`<server-ip>:443`).

---

### Exercise 2: Measure How Long the TCP Handshake Takes
Run `curl.exe` against your Cloud Run health endpoint to measure the exact time spent on **DNS lookup** vs. the **TCP 3-Way Handshake**:
```powershell
curl.exe -s -o NUL -w "DNS Lookup: %{time_namelookup}s`nTCP Handshake: %{time_connect}s`nTLS Handshake: %{time_appconnect}s`nTotal Time: %{time_total}s`n" https://chainagex-backend-prod-601125650534.asia-south1.run.app/api/v1/health
```
**What to observe:**
* **`TCP Handshake` (`time_connect`):** Subtract `DNS Lookup` from `TCP Handshake`—that tiny fraction of a second is the exact time Steps 1, 2, and 3 took to travel from your laptop to Google Cloud in Mumbai and back!
* **`TLS Handshake` (`time_appconnect`):** Notice how TLS takes an extra round-trip *after* the TCP handshake finishes.

---

### Exercise 3: Watch a Port Test Perform a 3-Way Handshake
Use Windows' built-in network tester to run a fresh TCP 3-way handshake against Google's web port (`443`) and then against a closed port (`81`):
```powershell
Test-NetConnection -ComputerName google.com -Port 443
```
Then try a port where no server is listening:
```powershell
Test-NetConnection -ComputerName google.com -Port 81 -InformationLevel Quiet
```
**What happens:**
* On port `443`, Google's server replies with `SYN-ACK`, completing the handshake (`TcpTestSucceeded : True`).
* On port `81`, nothing is listening—your laptop sends `SYN`, gets no `SYN-ACK` back, retries a couple of times, and finally fails (`False`).