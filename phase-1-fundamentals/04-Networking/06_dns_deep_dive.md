# Topic 6: DNS Deep Dive

## 1. What Is DNS?

Computers only know how to find each other using numeric **IP addresses** (like `34.143.73.2`), while humans prefer easy-to-remember names (like `chainagex.com` or `google.com`).

**DNS (Domain Name System)** is the **phonebook of the internet**. Whenever you type a domain name into your browser or mobile app, DNS translates that name into the server's real IP address so your laptop knows where to send the TCP handshake.

* **Port & Protocol:** DNS mostly runs over **UDP on Port 53** because a single quick question-and-answer packet is much faster than setting up a full TCP handshake. *(If a DNS reply is huge, it falls back to TCP Port 53).*

## 2. How a DNS Lookup Works (The 4-Step Relay Race)

When you visit a brand-new website that your laptop has never seen before, your computer asks four helpers in order until it finds the exact IP address:

1. **Local Cache Check (Your Laptop & Router):**

   * First, your browser checks its own memory, then Windows checks its local DNS cache and `hosts` file. If found, it stops immediately (`0 ms` network delay!).

2. **Recursive DNS Resolver (Your ISP or `1.1.1.1` / `8.8.8.8`):**

   * If your laptop doesn't know the IP, it asks a **Recursive Resolver** (like Cloudflare's `1.1.1.1` or Google's `8.8.8.8`). This server does the legwork of hunting down the answer for you.

3. **Root Server (`.`) $\rightarrow$ TLD Server (`.com`):**

   * The Resolver asks a **Root Server**: *"Where do I find `chainagex.com`?"* The Root Server points it to the **`.com` TLD (Top-Level Domain) Server**.

   * The `.com` TLD Server checks who manages that domain and points to its **Authoritative Name Server** (for example, **Vercel's Name Servers**).

4. **Authoritative Name Server (The Final Source of Truth):**

   * Vercel's DNS server holds your actual DNS records and replies: *"Here is the exact IP address for `api.chainagex.com`!"*

   * The Resolver saves this answer for next time and sends the IP back to your laptop.

```
[ Your Laptop ] ──1. Ask IP──► [ Recursive Resolver (8.8.8.8) ]
                                     │
                 ┌───────────────────┼───────────────────┐
                 ▼                   ▼                   ▼
         2. Root Server (.)   3. TLD (.com)    4. Authoritative DNS (Vercel)
         "Ask .com server"    "Ask Vercel"      "IP is 34.143.73.2!"
```

## 3. Essential DNS Record Types (What You Configure on Vercel)

Inside any DNS dashboard (Vercel, Cloudflare, Route 53), you manage rules called **DNS Records**:

| Record Type | What It Maps | Real-World Example |
| :--- | :--- | :--- |
| **`A`** | Domain name $\rightarrow$ **IPv4 address** | `chainagex.com` $\rightarrow$ `76.76.21.21` |
| **`AAAA`** | Domain name $\rightarrow$ **IPv6 address** | `google.com` $\rightarrow$ `2404:6800:4000:...` |
| **`CNAME`** | Domain name $\rightarrow$ **Another domain name** (Alias) | `api.chainagex.com` $\rightarrow$ `ghs.googlehosted.com` |
| **`TXT`** | Domain name $\rightarrow$ **Plain text note** | Proving you own `chainagex.com` to Google Cloud, Vercel, or email providers (SPF/DKIM) |
| **`MX`** | Domain name $\rightarrow$ **Mail server** | Tells the internet where to deliver emails sent to `support@chainagex.com` |
| **`NS`** | Domain name $\rightarrow$ **Name Servers** | Tells the `.com` registry that Vercel manages DNS for your domain |

## 4. TTL (Time to Live) & DNS Caching

Every DNS record has a **TTL (Time to Live)** measured in seconds (for example, `300` seconds = 5 minutes, or `3600` seconds = 1 hour).

* **How Caching Works:** Once your laptop or ISP resolver fetches the IP for `api.chainagex.com`, it saves that IP in memory until the **TTL countdown hits zero**. During that time, your app skips the 4-step lookup completely.

* **Why Server Migrations Take Time:** If you point your domain to a brand-new server IP, users whose ISPs still have the *old* IP cached will keep hitting the old server until their TTL expires. *(Pro tip: Lower your TTL to `60` seconds a day before migrating servers so the switch happens within 1 minute!)*

## 5. Why This Matters for Backend Engineers

* **Root Domain (`@`) vs. Subdomain (`api.`):** According to official DNS rules, you **cannot** put a `CNAME` record on a root domain like `chainagex.com` (because root domains must hold `NS` and `SOA` records). You must use an **`A` record** (or a provider's special `ALIAS`/`ANAME` flattening) for the root domain, and use **`CNAME`** for subdomains like `api.chainagex.com` or `www.chainagex.com`.

* **Zero-Downtime Traffic Shifting:** DNS lets you point `api.chainagex.com` to a load balancer or reverse proxy so you can swap backend containers behind the scenes without ever changing the URL in your frontend code.

## 6. Top Interview Questions & Short Answers

**Q1: Why does DNS primarily use UDP instead of TCP?**
**A:** A standard DNS query and response each fit inside a single tiny packet. Using **UDP** avoids the extra 1 Round-Trip Time (RTT) overhead of a TCP 3-way handshake, making domain lookups super fast. DNS only switches to TCP when a response is larger than 512 bytes (such as DNSSEC records or zone transfers).

**Q2: What is the difference between an `A` record and a `CNAME` record?**
**A:** An **`A` record** points a domain directly to a numeric **IPv4 address** (e.g., `76.76.21.21`). A **`CNAME` record** points a subdomain to **another domain name** (e.g., `api.chainagex.com` $\rightarrow$ `my-service.run.app`), which is ideal for cloud services whose underlying IP addresses can change automatically.

**Q3: Why can't you create a `CNAME` record on a root/apex domain (like `example.com`)?**
**A:** DNS standards forbid a `CNAME` from coexisting with any other record on the exact same name. Because a root domain *must* have `NS` (Name Server) and `SOA` (Start of Authority) records to function, adding a `CNAME` there would break DNS resolution.

**Q4: How do you safely migrate a production domain to a new server IP with minimal user disruption?**
**A:** 24 hours before the switch, lower the DNS record's **TTL** (e.g., from `3600s` down to `60s`) so caches expire quickly. At migration time, update the `A`/`CNAME` record to the new server while keeping the old server running briefly to handle any straggler requests still using cached DNS entries.

**Q5: What is a `TXT` record used for in backend development?**
**A:** `TXT` records store arbitrary text strings on a domain. Backends use them mainly for **domain ownership verification** (proving to Google Cloud, Vercel, or Stripe that you own the domain) and **email security** (`SPF`, `DKIM`, and `DMARC` records to stop spoofed emails).

## 7. Hands-On Practice Exercises (Windows PowerShell)

Open **PowerShell** on your laptop and inspect live DNS records and your local Windows DNS cache:

### Exercise 1: Query Specific DNS Record Types (`A`, `AAAA`, `TXT`, `NS`)

Use Windows' built-in `Resolve-DnsName` command to inspect `google.com`:

```powershell
Resolve-DnsName -Name google.com -Type A
Resolve-DnsName -Name google.com -Type TXT
Resolve-DnsName -Name google.com -Type NS
```

**What to look for:**

* **`A`:** Returns IPv4 addresses and their **`TTL`** countdown in seconds.

* **`TXT`:** Shows real-world verification tokens and email security rules (`v=spf1...`).

* **`NS`:** Shows Google's authoritative name servers (`ns1.google.com`, etc.).

### Exercise 2: Trace a `CNAME` Chain on a Subdomain

Run `Resolve-DnsName` on `www.github.com` to see how a `CNAME` alias points to another domain before resolving to an IP:

```powershell
Resolve-DnsName -Name www.github.com
```

**What to observe:**

* Notice how `www.github.com` first returns a **`CNAME`** pointing to `github.com`, which then resolves to an **`A`** record IP address!

### Exercise 3: View Your Laptop's Local DNS Cache

See every domain name Windows currently has saved in memory (along with its remaining TTL):

```powershell
ipconfig /displaydns | Select-String "Record Name|Time To Live|A \(Host\) Record"
```

**What to observe:**

* You will see domains your browser and apps recently visited, proving how Windows skips network lookups while `Time To Live` is greater than `0`.

## Key Takeaways

* **DNS** translates human domain names into IP addresses over **UDP Port 53**.

* **`A` / `AAAA`** point to IP addresses; **`CNAME`** points to another domain name; **`TXT`** verifies ownership and email rules.

* **TTL** controls how long ISPs and browsers cache a DNS answer before asking the authoritative server again.