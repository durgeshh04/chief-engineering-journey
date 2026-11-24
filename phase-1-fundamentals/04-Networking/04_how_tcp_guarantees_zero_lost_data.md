# Topic 4: How TCP Guarantees Zero Lost Data

## 1. Why Does Data Get Lost on the Internet?
When your app sends a ticket booking payload, the internet does **not** send it through one direct private cable. It breaks your data into small pieces called **packets** and sends them through dozens of routers.

Along the way, packets can:
* **Get dropped** when a router gets overloaded with too much traffic.
* **Arrive out of order** because different packets take slightly different routes across the internet.
* **Get damaged** due to weak Wi-Fi or mobile signal interference.

**TCP's main job** is to hide all of this chaos from your application so your backend receives every single byte **in the exact right order, with zero missing pieces**.

---

## 2. How TCP Tracks Every Piece of Data (Sequence & ACK Numbers)

Think of sending a 300-page book by mailing 100 pages at a time:

1. **Sequence Numbers (`SEQ`) — Numbering Every Byte:**
   * TCP numbers every byte of data you send.
   * Example: If you send 300 bytes split into three chunks of 100 bytes:
     * **Packet 1:** `SEQ = 1` (contains bytes 1–100)
     * **Packet 2:** `SEQ = 101` (contains bytes 101–200)
     * **Packet 3:** `SEQ = 201` (contains bytes 201–300)

2. **Acknowledgments (`ACK`) — Sending a Receipt:**
   * Every time the server receives a packet cleanly, it sends back a tiny receipt called an **`ACK`** telling your laptop the **next byte number it expects**.
   * When the server receives bytes `1–100`, it replies with **`ACK = 101`** (*"Got everything up to 100, send 101 next!"*).

---

## 3. What Happens When a Packet Gets Lost or Arrives Late?

TCP uses two smart safety nets to fix lost or messy packets automatically:

### Safety Net 1: Timeout & Retransmission (Resending Lost Packets)
* Whenever your laptop sends a packet, it starts a **stopwatch (Retransmission Timer)**.
* If that packet gets dropped on bad Wi-Fi, the server never sends back an `ACK` receipt.
* When the stopwatch runs out, your laptop assumes the packet is lost and **automatically sends it again**.

### Safety Net 2: Fast Retransmit (Spotting Gaps Immediately)
* Suppose **Packet 1** (`1–100`) arrives, **Packet 2** (`101–200`) gets dropped, and **Packet 3** (`201–300`) arrives.
* The server notices a gap! Every time Packet 3 or 4 arrives, the server keeps replying **`ACK = 101`** (*"I'm still missing byte 101!"*).
* Once your laptop receives **3 duplicate `ACK = 101` replies** in a row, it doesn't even wait for the stopwatch—it immediately resends **Packet 2** (`101–200`).

### Safety Net 3: Reordering Buffer (Putting Pages Back in Order)
* Even if Packet 3 arrives before Packet 2, TCP holds Packet 3 in a temporary waiting area (**Receive Buffer**) until Packet 2 arrives.
* Once Packet 2 arrives, TCP stitches `1 → 2 → 3` together and hands clean, ordered data to your NestJS backend.

```text
[ Your Laptop ]                                          [ Backend Server ]
      │                                                          │
      │ ── Packet 1 (Bytes 1-100) ─────────────────────────────► │ (Got 1-100)
      │ ── Packet 2 (Bytes 101-200) ─────── X (Dropped!)         │
      │ ── Packet 3 (Bytes 201-300) ───────────────────────────► │ (Holds 201-300 in buffer)
      │                                                          │
      │ ◄─ ACK = 101 ("Still waiting for byte 101!") ─────────── │
      │                                                          │
      │ ── Resends Packet 2 (Bytes 101-200) ───────────────────► │ (Stitches 1+2+3 together!)
      │ ◄─ ACK = 301 ("Got all 300 bytes cleanly!") ──────────── │
```

---

## 4. Speed Control: Flow Control vs. Congestion Control

TCP doesn't just blast data at full speed—it carefully adjusts how fast it sends packets using two rules:

1. **Flow Control (Protecting the Receiver):**
   * *Problem:* What if your fast cloud server sends data faster than a user's cheap phone can read it? The phone's memory would overflow.
   * *Solution (**Receive Window**):* In every `ACK` message, the phone tells the server how much free space is left in its memory buffer (e.g., *"I have room for 5,000 more bytes"*). The server never sends more than that limit.

2. **Congestion Control (Protecting the Internet Roads):**
   * *Problem:* What if thousands of users send data at the same time and clog up the internet's routers?
   * *Solution (**Slow Start**):* Every new TCP connection starts by sending just a few packets, then doubles its speed each round-trip as long as `ACK` receipts return smoothly. The moment packets start dropping, TCP immediately cuts its speed in half so the network can recover.

---

## 5. How TCP Closes a Connection Cleanly (4-Way Fin)
Just like TCP uses a 3-way handshake to say *"hello"*, it uses a polite 4-step goodbye when closing a connection so no half-finished data gets cut off:
1. **Laptop $\rightarrow$ Server (`FIN`):** *"I am done sending data."*
2. **Server $\rightarrow$ Laptop (`ACK`):** *"Got it, let me finish sending my last response."*
3. **Server $\rightarrow$ Laptop (`FIN`):** *"Okay, I am done sending too."*
4. **Laptop $\rightarrow$ Server (`ACK`):** *"Goodbye!"* (Enters **`TIME_WAIT`** for a few seconds to catch any late straggler packets, then closes completely).

---

## 6. Why This Matters for Backend Engineers
* **Head-of-Line Blocking:** Because TCP refuses to pass Packet 3 to your app until missing Packet 2 arrives, a single dropped packet on a bad mobile network pauses the entire connection—making your API feel "frozen" for a second.
* **Why `TIME_WAIT` Matters on High-Traffic Servers:** If your backend opens and closes thousands of short connections per second (for example, calling an external payment or OTP API without Keep-Alive), thousands of sockets sit in `TIME_WAIT` and can temporarily run out of available local ports (**Port Exhaustion**).

---

## 7. Top Interview Questions & Short Answers

**Q1: How does TCP guarantee reliable, in-order delivery over an unreliable network?**
**A:** TCP assigns a **Sequence Number** to every byte sent and requires the receiver to reply with an **Acknowledgment (`ACK`)**. If an `ACK` doesn't arrive before a timeout (or 3 duplicate `ACK`s arrive), TCP retransmits the missing packet, while the receiver's buffer reorders any packets that arrived out of sequence.

**Q2: What is the difference between Flow Control and Congestion Control?**
**A:** **Flow Control** prevents a fast sender from overwhelming a slow *receiver's* memory buffer (using the Receive Window). **Congestion Control** prevents senders from overwhelming the *network routers* in between (using Slow Start and cutting speed when packet loss occurs).

**Q3: What is TCP Head-of-Line (HoL) Blocking?**
**A:** Because TCP delivers bytes strictly in order, if Packet 2 is lost, Packets 3, 4, and 5 sit waiting in the receiver's OS buffer and cannot be read by the application until Packet 2 is retransmitted and arrives. *(Note: HTTP/3 solves this by switching from TCP to QUIC over UDP).*

**Q4: Why does a closed TCP connection enter `TIME_WAIT` instead of closing instantly?**
**A:** To make sure the final `ACK` reached the other side and to absorb any delayed packets still floating around the network so they don't accidentally get mixed up with a brand-new connection on the same port.

---

## 8. Hands-On Practice Exercises (Windows PowerShell)

Open **PowerShell** on your laptop and run these commands to see TCP reliability, retransmissions, and connection states live:

### Exercise 1: View Live TCP Reliability & Retransmission Stats on Your Laptop
Run Windows' built-in TCP statistics report:
```powershell
netstat -s -p TCP
```
**What to look for:**
* **`Segments Received` & `Segments Sent`:** Total TCP packets your laptop has sent and received since booting up.
* **`Segments Retransmitted`:** The exact count of packets that got lost on Wi-Fi/internet and had to be automatically resent by TCP!

### Exercise 2: Watch `TIME_WAIT` Connections After Making Requests
Make a quick request to your backend and immediately inspect `TIME_WAIT` sockets:
```powershell
curl.exe -s https://chainagex-backend-prod-601125650534.asia-south1.run.app/api/v1/health | Out-Null
netstat -ano -p TCP | Select-String "TIME_WAIT"
```
**What to observe:**
* You will see closed connections sitting briefly in **`TIME_WAIT`** while Windows ensures all final packets have cleared the network before freeing the local port.

### Exercise 3: Check Packet Loss & Round-Trip Stability to Your Backend Region
Send 10 test pings to Google's Mumbai DNS/edge to see if any packets drop and how steady your Round-Trip Time (RTT) is:
```powershell
Test-Connection -ComputerName 8.8.8.8 -Count 10
```
**What to observe:**
* Look at **`ResponseTime` (in ms)**: Steady numbers (e.g., `25ms–35ms`) mean smooth Congestion Control; sudden spikes (`200ms+`) or dropped replies trigger TCP retransmissions.

---

## Key Takeaways
* **Sequence Numbers + `ACK`s** ensure zero lost bytes and perfect ordering.
* **Flow Control** protects the receiver's memory; **Congestion Control** protects the internet's routers.
* **Head-of-Line Blocking** happens because TCP strictly waits for missing packets before handing later packets to your app.