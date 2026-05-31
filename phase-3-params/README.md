# Phase 3 — Parameter Discovery & GF Pattern Matching

> **Goal**: Build a complete list of injectable parameters, then sort them by vulnerability class.  
> **Risk level**: Low (mostly offline analysis of collected URLs)

---

## Step 1 — Extract URLs With Parameters

```bash
cat all_endpoints.txt | grep "?" | sort -u > urls_with_params.txt
cat katana_deep.txt | grep "?" | sort -u >> urls_with_params.txt
sort -u urls_with_params.txt -o urls_with_params.txt

echo "[+] URLs with params: $(wc -l < urls_with_params.txt)"
```

## Step 2 — GF Pattern Matching (Sort by Vuln Class)

GF uses regex patterns to identify parameters likely vulnerable to specific bugs:

```bash
# XSS candidates
cat all_endpoints.txt | gf xss > xss_params.txt

# IDOR candidates
cat all_endpoints.txt | gf idor > idor_params.txt

# SSRF candidates
cat all_endpoints.txt | gf ssrf > ssrf_params.txt

# Open redirect candidates
cat all_endpoints.txt | gf redirect > redirect_params.txt

# RCE candidates
cat all_endpoints.txt | gf rce > rce_params.txt

# SQLi candidates
cat all_endpoints.txt | gf sqli > sqli_params.txt

# LFI candidates
cat all_endpoints.txt | gf lfi > lfi_params.txt
```

> **Install GF patterns**: `git clone https://github.com/tomnomnom/gf && cp -r examples ~/.gf`  
> **Extra patterns**: `git clone https://github.com/1ndianl33t/Gf-Patterns`

## Step 3 — Active Parameter Discovery with Arjun

Finds **hidden parameters** not visible in URLs — extremely useful for API endpoints:

```bash
# Single endpoint
arjun -u https://target.com/api/endpoint \
  -m GET \
  --stable \
  -oJ arjun_params.json

# Multiple endpoints from file
arjun -i urls_with_params.txt \
  -m GET,POST \
  --stable \
  -oJ arjun_bulk.json

# POST-only endpoint
arjun -u https://target.com/api/user \
  -m POST \
  --stable \
  -oJ arjun_post.json
```

## Step 4 — Extract Param Names From JS

```bash
cat jsfiles.txt | while read url; do
  curl -sk "$url" | grep -oP '[?&][a-zA-Z_]+=' | sort -u
done | sort -u > params_from_js.txt
```

## Step 5 — Deduplicate & Clean Final Param List

```bash
cat urls_with_params.txt \
    katana_deep.txt \
    params_from_js.txt \
  | grep "?" \
  | sort -u \
  | uro \
  > final_params.txt

echo "[+] Unique parameterized URLs: $(wc -l < final_params.txt)"
```

> `uro` removes redundant parameter combinations — install: `pip install uro`

---

## Output Files

| File | Contents |
|------|----------|
| `urls_with_params.txt` | All URLs containing parameters |
| `xss_params.txt` | XSS-prone parameters |
| `idor_params.txt` | IDOR-prone parameters (id, user_id, etc.) |
| `ssrf_params.txt` | SSRF-prone parameters (url, host, etc.) |
| `redirect_params.txt` | Open redirect candidates |
| `sqli_params.txt` | SQL injection candidates |
| `lfi_params.txt` | LFI candidates |
| `arjun_params.json` | Hidden params discovered via Arjun |
| `final_params.txt` | Deduplicated master param list |

---

## What to Look For

- **`id=`, `user_id=`, `account=`** → IDOR
- **`url=`, `host=`, `redirect=`, `next=`** → SSRF / Open Redirect
- **`file=`, `path=`, `page=`** → LFI / Path Traversal
- **`q=`, `search=`, `query=`** → XSS, SQLi
- **`cmd=`, `exec=`, `run=`** → RCE
- **`token=`, `key=`, `auth=`** → Auth bypass, key exposure

---

**Previous**: [Phase 2 — Crawling & JS](../phase-2-crawling/README.md)  
**Next**: [Phase 4 — Directory Fuzzing](../phase-4-fuzzing/README.md)
