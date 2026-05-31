# Phase 1 — Subdomain Enumeration + Probing

> **Goal**: Discover every live subdomain and get a visual/technical snapshot of each one.  
> **Risk level**: Low (passive) → Medium (active probing)

---

## Step 1 — Passive Subdomain Enumeration

Run all three tools independently, then merge:

```bash
# subfinder — fastest, most sources
subfinder -d target.com \
  -all \
  -silent \
  -t 10 \
  -timeout 30 \
  -max-time 10 \
  -duc \
  -o subs_subfinder.txt

# amass — deeper passive, slower
amass enum \
  -passive \
  -d target.com \
  -timeout 30 \
  -max-dns-queries 5 \
  -silent \
  -o subs_amass.txt

# assetfinder — quick hits, good for edge cases
assetfinder --subs-only target.com \
  | grep -F ".target.com" \
  | sort -u > subs_asset.txt
```

## Step 2 — Certificate Transparency (crt.sh)

```bash
curl -s "https://crt.sh/?q=%25.target.com&output=json" \
  | jq '.[].name_value' \
  | sed 's/\"//g' \
  | sed 's/\*\.//g' \
  | sort -u > crtsh_subs.txt
```

## Step 3 — Merge & Deduplicate All Sources

```bash
cat subs_subfinder.txt \
    subs_amass.txt \
    subs_asset.txt \
    crtsh_subs.txt \
  | sort -u \
  | tee all_subs.txt \
  | wc -l

echo "[+] Total unique subdomains: $(wc -l < all_subs.txt)"
```

## Step 4 — Probe with httpx

Filters out dead subdomains, captures useful metadata:

```bash
httpx -l all_subs.txt \
  -silent \
  -status-code \
  -title \
  -tech-detect \
  -threads 30 \
  -o live_subs.txt

echo "[+] Live subdomains: $(wc -l < live_subs.txt)"
```
## filter the results

'''bash
cat live_subs.txt | grep "\[200\]" | tee 200.txt
'''

'''bash
grep "\[403\]" live_subs.txt > 403.txt
'''

## Step 5 — Screenshot All Live Hosts

Visual recon catches things automated tools miss (login panels, forgotten apps, old UIs):

```bash
gowitness file \
  -f live_subs.txt \
  -P ./screenshots \
  --delay 2

# View in browser
gowitness report serve
```

## Step 6 — Port Scanning on Live Hosts

```bash
# Extract just the URLs
cat live_subs.txt | awk '{print $1}' > live_urls.txt

naabu -l live_urls.txt \
  -p 80,443,8080,8443,3000,8000,9090,4443,5000,8888 \
  -silent \
  -rate 100 \
  -o open_ports.txt
```

---

## Output Files

| File | Contents |
|------|----------|
| `all_subs.txt` | All unique subdomains (unverified) |
| `live_subs.txt` | Confirmed live subdomains with status/title |
| `screenshots/` | Visual screenshots of every live host |
| `open_ports.txt` | Non-standard ports discovered |

---

## What to Look For

- **Subdomains with 401/403** → auth bypass candidates
- **Subdomains with old titles** → legacy apps, forgotten instances
- **Non-standard ports** → dev servers, internal tools exposed
- **`staging.`, `dev.`, `test.`, `api.`** prefixes → often less hardened
- **Screenshots showing login panels** → credential stuffing, default creds

---

**Previous**: [Phase 0 — Infrastructure](../phase-0-infra/README.md)  
**Next**: [Phase 2 — Crawling & JS Extraction](../phase-2-crawling/README.md)
