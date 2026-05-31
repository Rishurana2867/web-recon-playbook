# Phase 2 — Crawling, JS Extraction & Secret Hunting

> **Goal**: Map all endpoints and extract API keys, tokens, and hidden paths from JS files.  
> **Risk level**: Low-Medium (passive crawling via Wayback/GAU, active via Katana)

---

## Step 1 — Passive URL Collection (Do This First)

No requests to the target — pulls from archives:

```bash
# GAU — fetches from Wayback, AlienVault, CommonCrawl
gau target.com --threads 5 -o gau_urls.txt

# Waybackurls
echo "target.com" | waybackurls > wayback_urls.txt

# Merge
cat gau_urls.txt wayback_urls.txt | sort -u > all_urls.txt
echo "[+] Total historical URLs: $(wc -l < all_urls.txt)"
```

## Step 2 — Active Crawling with Katana

```bash
# Crawl live subdomains (uses live_subs.txt from Phase 1)
katana -l live_subs.txt \
  -silent \
  -d 3 \
  -o endpoints_katana.txt

# Deep single-target crawl
katana -u https://target.com \
  -d 4 \
  -jc \         # JavaScript crawling
  -kf all \     # Known files
  -silent \
  -o katana_deep.txt
```

## Step 3 — Combine All URLs

```bash
cat all_urls.txt endpoints_katana.txt | sort -u > all_endpoints.txt
echo "[+] Total endpoints: $(wc -l < all_endpoints.txt)"
```

## Step 4 — Extract JS Files

```bash
cat all_endpoints.txt | grep "\.js$" | sort -u > jsfiles.txt
echo "[+] JS files found: $(wc -l < jsfiles.txt)"
```

Also grab JS from active crawl:
```bash
cat all_endpoints.txt | grep -E "\.js(\?|$)" | sort -u >> jsfiles.txt
sort -u jsfiles.txt -o jsfiles.txt
```

## Step 5 — Download JS Files Locally

```bash
mkdir -p ./js_local
wget -r -l 2 -A "*.js" https://target.com -P ./js_local/ --quiet
```

## Step 6 — Secret Hunting in JS

### Option A: SecretFinder (per URL)
```bash
cat jsfiles.txt | while read url; do
  echo "[*] Scanning: $url"
  python3 /path/to/SecretFinder.py -i "$url" -o cli 2>/dev/null
done | tee secrets_found.txt
```

### Option B: Grep for common patterns (local files)
```bash
grep -rE "(api_key|apikey|secret|password|token|auth|bearer|private_key|access_key)" ./js_local/ \
  --include="*.js" \
  -l | tee files_with_secrets.txt

# Full matches
grep -rEi "(api_key|apikey|secret|password|token|auth|bearer)" ./js_local/ \
  --include="*.js" \
  -o | sort -u > potential_secrets.txt
```

### Option C: TruffleHog (best for git repos)
```bash
trufflehog filesystem ./js_local/ --only-verified
```

## Step 7 — Find Internal/Hidden Endpoints in JS

```bash
# API endpoints
grep -rE "(https?://|/api/|/v[0-9]/|/internal/|/admin/)" ./js_local/ \
  --include="*.js" \
  -o | sort -u > hidden_endpoints.txt

# Parameters embedded in JS
cat jsfiles.txt | while read url; do
  curl -sk "$url" | grep -oP '[?&][a-zA-Z_]+=' | sort -u
done | sort -u > js_params.txt
```

---

## Output Files

| File | Contents |
|------|----------|
| `all_urls.txt` | Merged historical URLs (Wayback + GAU) |
| `all_endpoints.txt` | All crawled endpoints |
| `jsfiles.txt` | All discovered JS file URLs |
| `secrets_found.txt` | Potential API keys / secrets |
| `hidden_endpoints.txt` | Internal endpoints found in JS |
| `js_params.txt` | Parameters extracted from JS |

---

## What to Look For

- **API keys** → Test if they're active (scope permitting)
- **Internal endpoints** (`/internal/`, `/admin/`, `/api/v2/`) → Unauthorized access
- **Hardcoded credentials** → Config leaks
- **S3/GCS bucket URLs** → Check for open/writable buckets
- **GraphQL endpoints** → `introspection` query for full schema

---

**Previous**: [Phase 1 — Subdomain Enumeration](../phase-1-subdomains/README.md)  
**Next**: [Phase 3 — Parameter Discovery](../phase-3-params/README.md)
