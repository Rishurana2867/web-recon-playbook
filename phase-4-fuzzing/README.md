# Phase 4 — Directory & Endpoint Fuzzing

> **Goal**: Discover hidden endpoints, files, and admin panels not visible via crawling.  
> **Risk level**: Medium-High — always check scope, use rate limiting

---

## ⚠️ Before You Fuzz

- Confirm the target is **in scope** for active testing
- Check for WAF first (see [Phase 6](../phase-6-advanced/README.md)) — adjust rate if detected
- Start with **low rate** (`-rate 30`) and increase if no issues
- Never fuzz production APIs without explicit scope confirmation

---

## Step 1 — Basic Directory Fuzzing

```bash
ffuf -u https://target.com/FUZZ \
  -w /usr/share/wordlists/dirb/common.txt \
  -mc 200,403 \
  -rate 30 \
  -timeout 10 \
  -H "User-Agent: Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36" \
  -o ffuf_basic.json \
  -of json
```

## Step 2 — Medium Wordlist (Better Coverage)

```bash
ffuf -u https://target.com/FUZZ \
  -w /usr/share/seclists/Discovery/Web-Content/raft-medium-directories.txt \
  -mc 200,204,301,302,403 \
  -rate 30 \
  -timeout 10 \
  -H "User-Agent: Mozilla/5.0" \
  -o ffuf_medium.json \
  -of json
```

## Step 3 — Sensitive File Discovery

```bash
ffuf -u https://target.com/FUZZ \
  -w /usr/share/seclists/Discovery/Web-Content/raft-medium-files.txt \
  -mc 200,403 \
  -rate 30 \
  -o sensitive_files.json \
  -of json
```

## Step 4 — Recursive Fuzzing

```bash
ffuf -u https://target.com/FUZZ \
  -w /usr/share/seclists/Discovery/Web-Content/raft-medium-directories.txt \
  -mc 200,403 \
  -rate 30 \
  -recursion \
  -recursion-depth 2 \
  -o ffuf_recursive.json \
  -of json
```

## Step 5 — API Endpoint Fuzzing

```bash
# API-specific wordlist
ffuf -u https://target.com/api/FUZZ \
  -w /usr/share/seclists/Discovery/Web-Content/api/objects.txt \
  -mc 200,201,204,401,403 \
  -rate 30 \
  -H "Content-Type: application/json" \
  -o ffuf_api.json \
  -of json

# API versioning
ffuf -u https://target.com/FUZZ/users \
  -w /usr/share/seclists/Discovery/Web-Content/api/api-versioning.txt \
  -mc 200,401,403 \
  -rate 30
```

## Step 6 — Process Results

```bash
# Extract 403 endpoints (bypass candidates)
cat ffuf_medium.json | jq '.results[] | select(.status==403) | .url' \
  | tr -d '"' > forbidden_403.txt

# Extract 200 endpoints (confirmed accessible)
cat ffuf_medium.json | jq '.results[] | select(.status==200) | .url' \
  | tr -d '"' > found_200.txt

echo "[+] 200 OK: $(wc -l < found_200.txt)"
echo "[+] 403 Forbidden: $(wc -l < forbidden_403.txt)"
```

## Step 7 — 403 Bypass Attempts

For each forbidden endpoint, try header-based bypass:

```bash
cat forbidden_403.txt | while read url; do
  echo "[*] Testing: $url"
  # Try X-Forwarded-For bypass
  curl -s -o /dev/null -w "%{http_code}" \
    -H "X-Forwarded-For: 127.0.0.1" \
    -H "X-Real-IP: 127.0.0.1" \
    -H "X-Original-URL: $url" \
    "$url"
  echo " -> $url"
done
```

---

## Wordlist Reference

| Wordlist | Use Case | Size |
|----------|----------|------|
| `/usr/share/wordlists/dirb/common.txt` | Fast baseline scan | ~4,600 |
| `/usr/share/seclists/Discovery/Web-Content/raft-medium-directories.txt` | Standard bug bounty | ~30,000 |
| `/usr/share/seclists/Discovery/Web-Content/raft-medium-files.txt` | File discovery | ~17,000 |
| `/usr/share/seclists/Discovery/Web-Content/api/objects.txt` | API endpoints | ~3,000 |
| Combined custom | Maximum coverage | varies |

See [`../wordlists/README.md`](../wordlists/README.md) for full list + download links.

---

## Output Files

| File | Contents |
|------|----------|
| `ffuf_medium.json` | Full ffuf results (JSON) |
| `found_200.txt` | Accessible endpoints |
| `forbidden_403.txt` | Forbidden endpoints (bypass candidates) |

---

**Previous**: [Phase 3 — Parameter Discovery](../phase-3-params/README.md)  
**Next**: [Phase 5 — Vulnerability Scanning](../phase-5-vuln-scanning/README.md)
