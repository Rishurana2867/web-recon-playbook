# Phase 6 — Advanced Checks

> **Goal**: Identify misconfigurations that automated scanners commonly miss.  
> **Risk level**: Low-Medium (mostly passive or single-request checks)

---

## CORS Misconfiguration

```bash
# Check if arbitrary origin is reflected
curl -s -I \
  -H "Origin: https://evil.com" \
  https://target.com/api/user \
  | grep -i "access-control"

# What to look for:
# Access-Control-Allow-Origin: https://evil.com  ← VULNERABLE (reflected)
# Access-Control-Allow-Origin: *                  ← check if credentials also allowed
# Access-Control-Allow-Credentials: true          ← dangerous if combined with reflected origin

# Test null origin
curl -s -I \
  -H "Origin: null" \
  https://target.com/api/user \
  | grep -i "access-control"
```

---

## WAF Detection

```bash
# Detect WAF type
wafw00f https://target.com

# If Cloudflare detected → lower rate limits
# If no WAF → standard rates are fine
# If Akamai/Imperva → use delay and header rotation
```

---

## HTTP Method Testing

```bash
TARGET="https://target.com/api/user"

# Check allowed methods
curl -s -X OPTIONS "$TARGET" -i | grep -i "allow"

# Test dangerous methods (document, don't execute destructively)
curl -s -X PUT "$TARGET/1" -v
curl -s -X DELETE "$TARGET/1" -v
curl -s -X PATCH "$TARGET/1" -d '{"admin":true}' -v

# TRACE — can enable cross-site tracing (XST)
curl -s -X TRACE https://target.com -v
```

---

## Cookie Analysis

```bash
# Check for missing security flags
curl -s -I https://target.com | grep -i "set-cookie"

# What to look for:
# Missing: HttpOnly    → XSS can steal cookies
# Missing: Secure      → cookie sent over HTTP
# Missing: SameSite    → CSRF risk
# SameSite=None without Secure → misconfiguration
```

---

## SSL/TLS Check

```bash
# Check for weak ciphers, outdated protocols
testssl.sh --severity HIGH https://target.com

# Quick check for common issues
testssl.sh --fast https://target.com 2>/dev/null | grep -E "(WARN|VULN|HIGH|CRITICAL)"
```

---

## CMS Scanning

### WordPress
```bash
wpscan --url https://target.com \
  --enumerate vp,vt,u \
  -o wpscan_results.txt

# Aggressive plugin detection
wpscan --url https://target.com \
  --enumerate p \
  --plugins-detection aggressive
```

### Detect CMS type first
```bash
whatweb https://target.com
curl -s https://target.com | grep -iE "(wordpress|joomla|drupal|magento)"
```

---

## Source Code & Config File Checks

```bash
TARGET="https://target.com"

# Common exposed config files
for path in .env .env.backup .git/config wp-config.php config.php \
            database.yml settings.py .htaccess web.config \
            phpinfo.php info.php test.php; do
  code=$(curl -s -o /dev/null -w "%{http_code}" "$TARGET/$path")
  [ "$code" = "200" ] && echo "[FOUND] $TARGET/$path"
done
```

---

## Cloud Storage Checks

```bash
COMPANY="targetcompany"

# Common bucket patterns
for bucket in "$COMPANY" "$COMPANY-dev" "$COMPANY-prod" \
              "$COMPANY-backup" "$COMPANY-assets" "$COMPANY-static"; do
  # AWS S3
  curl -s -o /dev/null -w "%{http_code}" \
    "https://$bucket.s3.amazonaws.com/" \
    | grep -q "200" && echo "[OPEN S3] $bucket"
  
  # GCS
  curl -s -o /dev/null -w "%{http_code}" \
    "https://storage.googleapis.com/$bucket" \
    | grep -q "200" && echo "[OPEN GCS] $bucket"
done
```

---

## Output Summary

| Check | What It Finds |
|-------|---------------|
| CORS | Misconfigured cross-origin policies |
| WAF | Protection level, informs scan strategy |
| HTTP Methods | PUT/DELETE enabled → data modification |
| Cookies | Missing HttpOnly/Secure/SameSite flags |
| SSL/TLS | Weak ciphers, expired certs, BEAST/POODLE |
| CMS | WordPress plugin vulns, user enumeration |
| Config files | Exposed .env, .git/config, database creds |
| Cloud buckets | Publicly readable/writable storage |

---

**Previous**: [Phase 5 — Vulnerability Scanning](../phase-5-vuln-scanning/README.md)  
**Back to**: [Main README](../README.md)
