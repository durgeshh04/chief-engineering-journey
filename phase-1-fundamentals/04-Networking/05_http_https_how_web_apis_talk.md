# Topic 5: HTTP, HTTPS & How Web APIs Talk

## 1. What Is HTTP?

In Topics 1–4, we built a safe, reliable pipe (**TCP**) between your browser and your backend server. **HTTP (Hypertext Transfer Protocol)** is the actual language your frontend and backend speak inside that pipe.

Think of it like ordering food at a restaurant:
* **Your Browser (Client):** The customer reading the menu and placing an order (**HTTP Request**).
* **Your Backend (Server):** The kitchen preparing the food and sending it back (**HTTP Response**).
* **Stateless Rule:** By default, HTTP has no memory. Every single API request must carry everything the server needs to know (like your login token), because the server treats each request as brand new.

---

## 2. Inside an HTTP Request & Response

Every HTTP message has two main parts: **Headers** (the envelope label) and **Body** (the actual package inside).

### A. What Your Frontend Sends (HTTP Request)
```http
POST /api/v1/indents HTTP/2
Host: api.chainagex.com
Authorization: Bearer eyJhbGciOiJIUzI1Ni...
Content-Type: application/json

{
  "material": "Cement",
  "quantity": 50
}
```
* **Method (`POST`):** Tells the backend *what action* you want to take.
* **Path (`/api/v1/indents`):** Tells the backend *which resource* you want.
* **Headers (`Authorization`, `Content-Type`):** Extra metadata like your login token and what format the data is in.
* **Body (`{ "material": "Cement"... }`):** The actual JSON data you are sending (used in `POST`, `PUT`, `PATCH`).

### B. What Your Backend Sends Back (HTTP Response)
```http
HTTP/2 201 Created
Content-Type: application/json

{
  "id": "IND-104",
  "status": "PENDING"
}
```
* **Status Code (`201 Created`):** A 3-digit number telling the frontend if the request worked or failed.
* **Headers:** Metadata about the reply (e.g., data format, caching rules).
* **Body:** The JSON result your frontend displays on screen.

---

## 3. Essential HTTP Methods & Status Codes for Backends

### Common HTTP Methods
* **`GET`:** Read data (e.g., fetch the indents list). Never changes data on the server.
* **`POST`:** Create something new (e.g., create a new indent or login).
* **`PUT`:** Replace an entire existing record with new data.
* **`PATCH`:** Update only *one or two fields* of an existing record (e.g., change status to `APPROVED`).
* **`DELETE`:** Remove a record.

*(Interview Tip: A method is **Idempotent** if running it 1 time or 10 times leaves the database in the exact same state. `GET`, `PUT`, and `DELETE` are idempotent; `POST` is **not**, because running it twice creates two separate indents!)*

### Status Code Families
* **`2xx` (Success):** Everything worked.
  * `200 OK`: Standard success (used for `GET`, `PATCH`).
  * `201 Created`: New resource successfully saved in the database (`POST`).
* **`3xx` (Redirection):** Go look somewhere else (e.g., `301` permanent redirect from `http://` to `https://`).
* **`4xx` (Client / User Error):** The frontend sent something wrong.
  * `400 Bad Request`: Missing or invalid JSON fields.
  * `401 Unauthorized`: Missing or expired login token (Who are you?).
  * `403 Forbidden`: Logged in, but no permission (e.g., a driver trying to access an admin page).
  * `404 Not Found`: That indent ID or route does not exist.
  * `429 Too Many Requests`: User hit your API rate limit.
* **`5xx` (Server Error):** Your backend code or database broke.
  * `500 Internal Server Error`: Unhandled crash/bug in your NestJS code.
  * `502 Bad Gateway` / `503 Service Unavailable`: Server is restarting, overloaded, or Cloud Run couldn't reach your container.

---

## 4. HTTP vs. HTTPS (How TLS Locks Your Data)

* **HTTP (Port 80):** Sends everything in **plain text**. Anyone sitting on the same public Wi-Fi or router can read passwords, tokens, and JSON payloads.
* **HTTPS (Port 443):** Runs HTTP inside an encrypted **TLS (Transport Layer Security)** tunnel.

### How TLS Encrypts Data Fast (2-Step Trick)
Encrypting large JSON responses with heavy public/private keys is slow. So TLS uses a clever mix of **two** encryption types during the TLS Handshake:
1. **Asymmetric Encryption (Public & Private Keys — Used ONLY at the start):**
   * The server sends its **TLS Certificate** (containing its Public Key) to prove it is genuinely `chainagex.com` and not a fake hacker server.
   * Both sides safely agree on a secret shared password without anyone eavesdropping.
2. **Symmetric Encryption (One Shared Session Key — Used for all data):**
   * Once both sides have that shared secret key, they switch to super-fast symmetric encryption to lock and unlock all your API JSON traffic.

---

## 5. HTTP/1.1 vs. HTTP/2 vs. HTTP/3

Web protocols evolved to fix the slowdowns we learned about in Topics 3 and 4:

| Version | Transport | How It Sends Requests | Main Problem Solved |
| :--- | :--- | :--- | :--- |
| **HTTP/1.1** | TCP | **One request at a time** per connection. Browsers had to open 6 separate TCP connections just to load a page fast. | Simple text format, but slow when loading many files/APIs. |
| **HTTP/2** | TCP | **Multiplexing:** Sends dozens of requests and responses **in parallel** over **one single TCP connection** using binary frames. | Eliminated opening multiple TCP handshakes. *(Still suffers from TCP Head-of-Line blocking if 1 packet drops!)* |
| **HTTP/3** | **QUIC (over UDP)** | Replaces TCP with **QUIC**. Runs independent streams over UDP so one dropped packet only pauses *that one stream*, not the whole connection. | Solves TCP Head-of-Line blocking and connects faster on mobile networks. |

---

## 6. Top Interview Questions & Short Answers

**Q1: What is the difference between `401 Unauthorized` and `403 Forbidden`?**
**A:** **`401 Unauthorized`** means *Authentication* failed—the server doesn't know who you are because your token is missing or expired. **`403 Forbidden`** means *Authorization* failed—the server knows who you are, but your role does not have permission to perform that action.

**Q2: What does "Idempotent" mean in REST APIs, and why does it matter?**
**A:** An operation is idempotent if making the same request multiple times produces the exact same result as making it once (`GET`, `PUT`, `DELETE`). It matters because if a user's mobile network drops before receiving a response and the app retries the request, idempotent endpoints prevent duplicate side effects (like charging a customer twice).

**Q3: Why does HTTPS use both Asymmetric and Symmetric encryption?**
**A:** **Asymmetric encryption** (Public/Private keys) is great for verifying the server's identity and safely exchanging a secret over an open network, but it is computationally slow. Once that secret is shared, HTTPS switches to **Symmetric encryption** (a single shared session key) because it is much faster for encrypting large API payloads.

**Q4: How does HTTP/2 improve performance over HTTP/1.1?**
**A:** HTTP/2 introduces **Multiplexing**, allowing multiple parallel requests and responses to travel simultaneously over a **single TCP connection**, plus **HPACK header compression** to shrink repetitive headers (like long JWT tokens and cookies).

**Q5: Why was HTTP/3 built on UDP (QUIC) instead of TCP?**
**A:** Because in HTTP/2 over TCP, if a single packet gets lost on the network, TCP pauses *every* parallel stream until that one packet is retransmitted (**TCP Head-of-Line Blocking**). HTTP/3 uses **QUIC over UDP** so each stream handles its own packets independently—one lost packet never freezes other API calls.

---

## 7. Hands-On Practice Exercises (Windows PowerShell)

Open **PowerShell** on your laptop and inspect real HTTP headers, status codes, TLS certificates, and HTTP/2 in action:

### Exercise 1: See Raw HTTP/2 Headers & Status Code from Your Backend
Use `curl.exe -I -v` (`-I` fetches only headers, `-v` shows the TLS handshake and HTTP version):
```powershell
curl.exe -I -v https://chainagex-backend-prod-601125650534.asia-south1.run.app/api/v1/health
```
**What to look for in the output:**
* Look for **`ALPN: server accepted h2`** — that proves Google Cloud Run negotiated **HTTP/2**!
* Look for **`SSL connection using TLSv1.3`** — that shows the exact TLS version encrypting your API.
* Look for **`HTTP/2 200`** at the top of the response headers.

### Exercise 2: Trigger and Inspect a `404` vs. `200` Status Code
Test hitting a route that does not exist on your backend to see the raw HTTP status code:
```powershell
curl.exe -s -o NUL -w "Status Code: %{http_code}`nHTTP Version: %{http_version}`n" https://chainagex-backend-prod-601125650534.asia-south1.run.app/api/v1/non-existent-route
```
**What to observe:**
* You will see `Status Code: 404` and `HTTP Version: 2` printed cleanly.

### Exercise 3: Watch an HTTP (`301`) Redirect to HTTPS (`200`)
See what happens when someone types `http://google.com` instead of `https://google.com`:
```powershell
curl.exe -I http://google.com
```
**What to observe:**
* Google responds with **`HTTP/1.1 301 Moved Permanently`** and a **`Location: http://www.google.com/`** header telling your browser to redirect.

---

## Key Takeaways
* **HTTP** is stateless; every API request carries its own headers (`Authorization`, `Content-Type`) and body.
* **HTTPS** uses **Asymmetric encryption** once to verify identity and share a secret, then **Symmetric encryption** for fast data transfer.
* **HTTP/2** multiplexes multiple requests over one TCP pipe; **HTTP/3 (QUIC)** moves to UDP to eliminate TCP Head-of-Line blocking.