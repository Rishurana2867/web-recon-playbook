#!/bin/bash
# ============================================================
# full_recon.sh — Complete Web Recon Pipeline
# Usage: ./full_recon.sh target.com
# Author: @Rishurana2867
# ============================================================

TARGET=$1

if [ -z "$TARGET" ]; then
  echo "Usage: $0 target.com"
  exit 1
fi

OUTDIR="recon_${TARGET}_$(date +%Y%m%d_%H%M%S)"
mkdir -p "$OUTDIR"/{subs,live,screenshots,js,params,fuzz,nuclei,logs}

echo "============================================================"
echo "  Web Recon Playbook — Full Pipeline"
echo "  Target: $TARGET"
echo "  Output: $OUTDIR"
echo "============================================================"

log() { echo "[$(date +%H:%M:%S)] $1" | tee -a "$OUTDIR/logs/recon.log"; }

# ─────────────────────────────────────────────
# PHASE 0 — Infrastructure
# ─────────────────────────────────────────────
log "[PHASE 0] ASN & IP Mapping"

TARGET_IP=$(dig +short "$TARGET" | head -1)
log "Resolved $TARGET → $TARGET_IP"

whois "$TARGET_IP" 2>/dev/null | grep -i "origin" | tee "$OUTDIR/logs/asn.txt"

# ─────────────────────────────────────────────
# PHASE 1 — Passive Subdomain Enum
# ─────────────────────────────────────────────
log "[PHASE 1] Passive Subdomain Enumeration"

subfinder -d "$TARGET" -all -silent -t 10 -timeout 30 -duc \
  -o "$OUTDIR/subs/subfinder.txt" 2>/dev/null
log "  subfinder: $(wc -l < "$OUTDIR/subs/subfinder.txt") subdomains"

amass enum -passive -d "$TARGET" -timeout 30 -silent \
  -o "$OUTDIR/subs/amass.txt" 2>/dev/null
log "  amass: $(wc -l < "$OUTDIR/subs/amass.txt") subdomains"

assetfinder --subs-only "$TARGET" \
  | grep -F ".$TARGET" | sort -u \
  > "$OUTDIR/subs/assetfinder.txt" 2>/dev/null
log "  assetfinder: $(wc -l < "$OUTDIR/subs/assetfinder.txt") subdomains"

curl -s "https://crt.sh/?q=%25.$TARGET&output=json" \
  | jq '.[].name_value' 2>/dev/null \
  | sed 's/\"//g;s/\*\.//' \
  | sort -u > "$OUTDIR/subs/crtsh.txt"
log "  crt.sh: $(wc -l < "$OUTDIR/subs/crtsh.txt") subdomains"

# Merge all
cat "$OUTDIR/subs/"*.txt | sort -u > "$OUTDIR/subs/all_subs.txt"
log "  Total unique: $(wc -l < "$OUTDIR/subs/all_subs.txt") subdomains"

# ─────────────────────────────────────────────
# PHASE 1 cont — Probe with httpx
# ─────────────────────────────────────────────
log "[PHASE 1] Probing with httpx"

httpx -l "$OUTDIR/subs/all_subs.txt" \
  -silent -status-code -title -tech-detect -threads 30 \
  -o "$OUTDIR/live/live_subs.txt" 2>/dev/null
log "  Live subdomains: $(wc -l < "$OUTDIR/live/live_subs.txt")"

# Extract just URLs for downstream tools
awk '{print $1}' "$OUTDIR/live/live_subs.txt" > "$OUTDIR/live/live_urls.txt"

# Screenshots
log "[PHASE 1] Screenshotting live hosts"
gowitness file \
  -f "$OUTDIR/live/live_urls.txt" \
  -P "$OUTDIR/screenshots" \
  --delay 2 2>/dev/null
log "  Screenshots saved to $OUTDIR/screenshots/"

# ─────────────────────────────────────────────
# PHASE 2 — URL Collection
# ─────────────────────────────────────────────
log "[PHASE 2] Passive URL Collection"

gau "$TARGET" --threads 5 -o "$OUTDIR/js/gau_urls.txt" 2>/dev/null
echo "$TARGET" | waybackurls > "$OUTDIR/js/wayback_urls.txt" 2>/dev/null

cat "$OUTDIR/js/gau_urls.txt" "$OUTDIR/js/wayback_urls.txt" \
  | sort -u > "$OUTDIR/js/all_urls.txt"
log "  Historical URLs: $(wc -l < "$OUTDIR/js/all_urls.txt")"

log "[PHASE 2] Active Crawling with Katana"
katana -l "$OUTDIR/live/live_urls.txt" -silent -d 3 \
  -o "$OUTDIR/js/katana_endpoints.txt" 2>/dev/null
log "  Katana endpoints: $(wc -l < "$OUTDIR/js/katana_endpoints.txt")"

cat "$OUTDIR/js/all_urls.txt" "$OUTDIR/js/katana_endpoints.txt" \
  | sort -u > "$OUTDIR/js/all_endpoints.txt"

# Extract JS files
cat "$OUTDIR/js/all_endpoints.txt" | grep "\.js$" | sort -u > "$OUTDIR/js/jsfiles.txt"
log "  JS files: $(wc -l < "$OUTDIR/js/jsfiles.txt")"

# ─────────────────────────────────────────────
# PHASE 3 — Parameters
# ─────────────────────────────────────────────
log "[PHASE 3] Parameter Extraction"

cat "$OUTDIR/js/all_endpoints.txt" | grep "?" | sort -u \
  > "$OUTDIR/params/urls_with_params.txt"
log "  URLs with params: $(wc -l < "$OUTDIR/params/urls_with_params.txt")"

# GF patterns
for pattern in xss idor ssrf redirect rce sqli lfi; do
  cat "$OUTDIR/js/all_endpoints.txt" | gf "$pattern" \
    > "$OUTDIR/params/${pattern}_params.txt" 2>/dev/null
  count=$(wc -l < "$OUTDIR/params/${pattern}_params.txt")
  [ "$count" -gt "0" ] && log "  GF $pattern: $count matches"
done

# ─────────────────────────────────────────────
# PHASE 4 — Fuzzing (first live host only for automation)
# ─────────────────────────────────────────────
log "[PHASE 4] Directory Fuzzing (first live host)"
FIRST_HOST=$(head -1 "$OUTDIR/live/live_urls.txt")

if [ -n "$FIRST_HOST" ]; then
  ffuf -u "$FIRST_HOST/FUZZ" \
    -w /usr/share/seclists/Discovery/Web-Content/raft-medium-directories.txt \
    -mc 200,403 -rate 30 -timeout 10 -silent \
    -o "$OUTDIR/fuzz/ffuf_results.json" -of json 2>/dev/null

  cat "$OUTDIR/fuzz/ffuf_results.json" \
    | jq '.results[] | select(.status==200) | .url' 2>/dev/null \
    | tr -d '"' > "$OUTDIR/fuzz/found_200.txt"
  
  cat "$OUTDIR/fuzz/ffuf_results.json" \
    | jq '.results[] | select(.status==403) | .url' 2>/dev/null \
    | tr -d '"' > "$OUTDIR/fuzz/forbidden_403.txt"

  log "  200 OK: $(wc -l < "$OUTDIR/fuzz/found_200.txt"), 403: $(wc -l < "$OUTDIR/fuzz/forbidden_403.txt")"
fi

# ─────────────────────────────────────────────
# PHASE 5 — Nuclei
# ─────────────────────────────────────────────
log "[PHASE 5] Nuclei Vulnerability Scan"

nuclei -l "$OUTDIR/live/live_urls.txt" \
  -t exposures/ -t misconfiguration/ -t cves/ -t takeovers/ \
  -severity medium,high,critical \
  -rate-limit 30 -silent \
  -o "$OUTDIR/nuclei/results.txt" 2>/dev/null
log "  Nuclei findings: $(wc -l < "$OUTDIR/nuclei/results.txt")"

# Subdomain takeover
subzy run \
  --targets "$OUTDIR/live/live_urls.txt" \
  --concurrency 20 \
  --output "$OUTDIR/nuclei/takeover.txt" 2>/dev/null

# ─────────────────────────────────────────────
# SUMMARY
# ─────────────────────────────────────────────
echo ""
echo "============================================================"
echo "  RECON COMPLETE — Summary"
echo "============================================================"
echo "  Target         : $TARGET"
echo "  Output dir     : $OUTDIR"
echo "  Subdomains     : $(wc -l < "$OUTDIR/subs/all_subs.txt")"
echo "  Live hosts     : $(wc -l < "$OUTDIR/live/live_subs.txt")"
echo "  Endpoints      : $(wc -l < "$OUTDIR/js/all_endpoints.txt")"
echo "  JS files       : $(wc -l < "$OUTDIR/js/jsfiles.txt")"
echo "  Params (w/?)   : $(wc -l < "$OUTDIR/params/urls_with_params.txt")"
echo "  Nuclei findings: $(wc -l < "$OUTDIR/nuclei/results.txt")"
echo "============================================================"
echo ""
echo "  Next steps:"
echo "  → Review screenshots:    $OUTDIR/screenshots/"
echo "  → Check nuclei findings: $OUTDIR/nuclei/results.txt"
echo "  → Check GF patterns:     $OUTDIR/params/"
echo "  → Manual testing:        Start with xss_params, idor_params"
echo "============================================================"
