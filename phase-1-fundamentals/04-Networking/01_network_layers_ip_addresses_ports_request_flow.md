# 01 - Network Layers, IP Addresses, Ports & Request Flow

## 1. The 4-Layer TCP/IP Model
Whenever your browser talks to a server, data travels down through 4 layers on your machine and back up through the same 4 layers on the server.

| Layer | Name | What It Does | Real-World Analogy | Key Examples |
| :--- | :--- | :--- | :--- | :--- |
| **4** | **Application** | Creates the actual message/data your app wants to send. | Writing the letter inside an envelope. | HTTP, HTTPS, DNS, WebSockets |
| **3** | **Transport** | Adds **Port numbers** so data reaches the right app, and handles reliability. | Writing the recipient's apartment/flat number. | **TCP** (reliable), **UDP** (fast, no handshake) |
| **2** | **Internet (Network)** | Adds **IP addresses** to route data across the global internet. | Writing the city and street address. | **IPv4**, **IPv6** |
| **1** | **Network Access (Link)** | Moves raw bits over physical wires/Wi-Fi using **MAC addresses**. | The local delivery van moving between neighboring houses. | Ethernet, Wi-Fi, ARP |

---

## 2. IP Addresses, MAC Addresses & Ports

- **MAC Address (Layer 2):** A permanent hardware ID burned into your Wi-Fi/network card (e.g., `14-B5-CD-40-00-F1`). Only used to talk to devices on your **local** network (like your home router).
- **IP Address (Layer 3):** A logical address used to locate devices across the **global** internet (e.g., `142.250.190.46`).
  - **Private IP:** Your device's local nickname inside your home Wi-Fi (e.g., `10.0.0.2` or `192.168.1.11`). Cannot be routed on the public internet.
  - **Public IP:** Your Wi-Fi router's real address visible to the outside world (e.g., `223.233.85.54`).
  - **IPv4 vs. IPv6:** IPv4 uses 32-bit addresses (`192.168.1.1`, ~4.3 billion limit). IPv6 uses 128-bit hexadecimal addresses (`2401:4900:1c7e:...`) to solve IPv4 exhaustion.
- **Port Number (Layer 4):** A 16-bit number (`0` to `65535`) identifying **which specific program** on a server should receive the traffic.
  - `80` → HTTP (unencrypted web traffic)
  - `443` → HTTPS (encrypted web traffic)
  - `53` → DNS (domain name lookup)
  - `5432` → PostgreSQL
  - `3000` / `8080` → Typical backend API development ports

---

## 3. Router & NAT (Network Address Translation)
Because your laptop only has a **Private IP** (`192.168.1.11`), it cannot talk to public servers directly.

1. Your laptop sends the packet to your **Default Gateway (Wi-Fi Router)** using the router's **MAC address** (found via **ARP**).
2. **NAT:** The router swaps your Private IP (`192.168.1.11`) with its own **Public IP**, saves a record in its **NAT Table** (`Private IP + Port ↔ Public IP + Port`), and sends the packet to the internet.
3. When the server replies, the router checks its NAT table and forwards the data back to your laptop.

---

## 4. What Happens When You Type `google.com` & Press Enter

1. **URL Check & HSTS (Force HTTPS):**
   - The browser confirms `google.com` is a domain, not a search term.
   - It checks its built-in **HSTS (HTTP Strict Transport Security)** preload list, sees `google.com`, and automatically forces **HTTPS on Port 443** instead of plain HTTP on Port 80.

2. **DNS Lookup (Finding the IP Address):**
   - Checks Browser Cache → OS `hosts` file → sends a **UDP request on Port 53** to a DNS resolver (`1.1.1.1` or `8.8.8.8`) via your router's NAT.
   - DNS replies with Google's Public IP address.

3. **TCP 3-Way Handshake (Opening the Connection):**
   - Laptop and Google open a reliable TCP connection on **Port 443**:
     - `SYN` (Laptop: *"Can we connect?"*)
     - `SYN-ACK` (Google: *"Yes, ready. Are you?"*)
     - `ACK` (Laptop: *"Yes, connected!"*)

4. **TLS 1.3 Handshake (Encryption & Protocol Setup):**
   - **Client Hello:** Browser sends **SNI** (Server Name Indication: *"I want `google.com`"*), **ALPN** (negotiating **HTTP/2**), and its public key share.
   - **Server Hello:** Google returns its **SSL/TLS Certificate** and key share.
   - Both sides derive the exact same **Symmetric Session Key** to encrypt/decrypt traffic fast.

5. **HTTP/2 Request & Response:**
   - Browser encrypts a `GET /` request and sends it over the open TCP pipe.
   - Google decrypts it, fetches `index.html`, encrypts it, and streams it back.

6. **Parallel Asset Loading & Rendering:**
   - Browser decrypts the HTML and discovers CSS, JS, and image links.
   - Over **HTTP/2**, it downloads all assets **in parallel** using multiple streams over that **single TCP connection** and renders the page.

---

## 5. Top Interview Questions & Short Answers

**Q1: Why do we need both a MAC address and an IP address?**
**A:** **IP addresses** guide a packet across the **entire journey** from start to finish (like a home street address), while **MAC addresses** carry the data **one physical hop at a time** over local Wi-Fi or cables (Laptop → Router → Next Router).

**Q2: What is the difference between a Private IP and a Public IP, and how does NAT connect them?**
**A:** A **Private IP** (like `192.168.1.11`) is used inside a local home or office network and cannot travel on the public internet. A **Public IP** (like `223.233.85.54`) is assigned to your router by your ISP. **NAT (Network Address Translation)** translates your private IP + port into the router's public IP + port for outbound requests and maps replies back to your device.

**Q3: What is the difference between TCP and UDP? When would you use each?**
**A:** **TCP** sets up a connection (3-way handshake) and guarantees every packet arrives in order without loss—used for REST APIs, WebSockets, and databases. **UDP** sends packets immediately without a handshake or retries—used where raw speed matters more than an occasional dropped packet, like DNS lookups, video calls, and online gaming.

**Q4: What is the difference between HTTP and HTTPS (TLS)?**
**A:** **HTTP** sends data in plain text on **Port 80**, meaning anyone on the Wi-Fi or network can read or edit it. **HTTPS** wraps HTTP inside **TLS encryption** on **Port 443**, locking the data, verifying the server's identity with a TLS certificate, and preventing tampering.

**Q5: Walk me through what happens when you type a URL in the browser and hit Enter.**
**A:** The browser enforces HTTPS via **HSTS**, resolves the domain to an IP via **DNS (UDP :53)**, opens a connection with a **TCP 3-Way Handshake (:443)**, encrypts the channel via a **TLS Handshake**, sends an **HTTP `GET` request**, and renders the returned HTML/CSS/JS assets.

---

## 6. Hands-On Practice Exercises (Windows PowerShell)

Open **PowerShell** on your laptop and run these commands to inspect every layer live:

### Exercise 1: View Your MAC Address, Private IPv4, IPv6, and Router (Default Gateway)
```powershell
ipconfig /all
```
**What to look for under `Wireless LAN adapter Wi-Fi`:**
* **Physical Address:** Your Layer 2 MAC address.
* **IPv4 Address:** Your Layer 3 Private IP (e.g., `192.168.1.x`).
* **IPv6 Address:** Your globally unique 128-bit IPv6 address.
* **Default Gateway:** Your home Wi-Fi router's IP (`192.168.1.1`).

---

### Exercise 2: View Your Router's Public IPv4 Address (NAT in Action)
```powershell
curl.exe -4 ifconfig.me
```
**What to observe:**
* Compare this public IP against your private `192.168.1.x` IP from Exercise 1—your router uses NAT to translate between the two.

---

### Exercise 3: See How Your Laptop Finds Your Router's MAC Address (ARP Table)
```powershell
arp -a
```
**What to observe:**
* Find your **Default Gateway** IP (`192.168.1.1`) in the list—the physical address next to it is your router's MAC address.

---

### Exercise 4: Perform a Live DNS Lookup (UDP Port 53)
```powershell
nslookup google.com
```
**What to observe:**
* Shows which DNS server answered your query and the IPv4/IPv6 addresses returned for `google.com`.

---

## Key Takeaways
- **IP** finds the machine; **Port** finds the exact app running on that machine.
- **NAT** allows multiple private home devices to share one public IP address safely.
- **Order of connection:** `DNS (UDP :53)` → `TCP 3-Way Handshake (:443)` → `TLS Handshake` → `Encrypted HTTP Request`.