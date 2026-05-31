# Phase 5 — Vulnerability Scanning

> **Goal**: Run automated template-based scanning for known CVEs, misconfigs, and takeover opportunities.  
> **Risk level**: Medium — use rate limiting, avoid destructive templates

---

## Step 1 — Nuclei: Focused Scan (Start Here)

```bash
nuclei -l live_subs.txt \
  -t exposures/ \
  -t misconfiguration/ \
  -t cves/ \
  -severity medium,high,critical \
  -rate-limit 30 \
  -silent \
  -o nuclei_results.txt
```

## Step 2 — Nuclei: Full Template Scan

```bash
nuclei -l live_subs.txt \
  -t exposures/ \
  -t misconfiguration/ \
  -t cves/ \
  -t technologies/ \
  -t default-logins/ \
  -t takeovers/ \
  -severity medium,high,critical \
  -rate-limit 30 \
  -silent \
  -o nuclei_full.txt
```

## Step 3 — WAF-Aware Nuclei (If WAF Detected)

```bash
# Drop rate further, add bypass headers
nuclei -l live_subs.txt \
  -t cves/ \
  -rate-limit 10 \
  -H "X-Forwarded-For: 127.0.0.1" \
  -retries 1 \
  -timeout 15 \
  -silent \
  -o nuclei_waf.txt
```

## Step 4 — Subdomain Takeover Check

```bash
subzy run \
  --targets live_subs.txt \
  --concurrency 20 \
  --output takeover.txt

# Also check with nuclei takeover templates
nuclei -l live_subs.txt \
  -t takeovers/ \
  -silent \
  -o takeover_nuclei.txt
```

## Step 5 — Outdated JavaScript Libraries

```bash
# Scan local JS files
retire --js \
  --outputformat json \
  --outputpath retire_results.json \
  --path ./js_local/

# View critical findings
cat retire_results.json | jq '.[] | select(.vulnerabilities[].severity == "critical")'
```

## Step 6 — Error Triggering (Manual Fingerprinting)

Force the app to reveal stack traces, versions, and internal paths:

```bash
TARGET="https://target.com"

# 404 — leaks framework/version in error page
curl -s "$TARGET/doesnotexist123" | grep -iE "(error|exception|stack|version|framework)"

# SQL error trigger
curl -s -X POST "$TARGET/api/user" \
  -d "id='" \
  | grep -iE "(sql|mysql|syntax|error|exception)"

# Type confusion
curl -s "$TARGET/api/user?id[]=1" \
  | grep -iE "(error|invalid|exception)"

# Path traversal probe
curl -s "$TARGET/api/user?file=../../../etc/passwd"
```

## Step 7 — robots.txt & Sitemap (Often Missed)

```bash
TARGET="https://target.com"
curl -s "$TARGET/robots.txt"
curl -s "$TARGET/sitemap.xml"
curl -s "$TARGET/sitemap_index.xml"

# Check for disallowed paths (those are interesting)
curl -s "$TARGET/robots.txt" | grep "Disallow" | awk '{print $2}'
```

---

## Output Files

| File | Contents |
|------|----------|
| `nuclei_results.txt` | Medium/High/Critical nuclei findings |
| `nuclei_full.txt` | Full template scan results |
| `takeover.txt` | Subdomain takeover candidates |
| `retire_results.json` | Vulnerable JS libraries |

---

## What to Prioritize

1. **Critical/High nuclei findings** → validate manually before reporting
2. **Subdomain takeover** → claim the subdomain to prove impact
3. **Default logins** → test before changing anything
4. **Exposed admin panels** → check for auth bypass
5. **Outdated libraries with known CVEs** → check if exploitable in context

---

**Previous**: [Phase 4 — Fuzzing](../phase-4-fuzzing/README.md)  
**Next**: [Phase 6 — Advanced Checks](../phase-6-advanced/README.md)
