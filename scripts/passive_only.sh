#!/bin/bash
# ============================================================
# passive_only.sh — Zero-touch passive recon
# No active requests to the target
# Usage: ./passive_only.sh target.com
# Author: @Rishurana2867
# ============================================================

TARGET=$1

if [ -z "$TARGET" ]; then
  echo "Usage: $0 target.com"
  exit 1
fi

OUTDIR="passive_${TARGET}_$(date +%Y%m%d_%H%M%S)"
mkdir -p "$OUTDIR"

echo "[*] Passive Recon: $TARGET"
echo "[*] Output: $OUTDIR"
echo ""

# Subdomains — passive sources only
echo "[1/5] Subfinder (passive)..."
subfinder -d "$TARGET" -all -silent -duc -o "$OUTDIR/subfinder.txt" 2>/dev/null
echo "      Found: $(wc -l < "$OUTDIR/subfinder.txt")"

echo "[2/5] crt.sh..."
curl -s "https://crt.sh/?q=%25.$TARGET&output=json" \
  | jq '.[].name_value' 2>/dev/null \
  | sed 's/\"//g;s/\*\.//' \
  | sort -u > "$OUTDIR/crtsh.txt"
echo "      Found: $(wc -l < "$OUTDIR/crtsh.txt")"

echo "[3/5] GAU (historical URLs)..."
gau "$TARGET" --threads 5 -o "$OUTDIR/gau_urls.txt" 2>/dev/null
echo "      Found: $(wc -l < "$OUTDIR/gau_urls.txt")"

echo "[4/5] Waybackurls..."
echo "$TARGET" | waybackurls > "$OUTDIR/wayback_urls.txt" 2>/dev/null
echo "      Found: $(wc -l < "$OUTDIR/wayback_urls.txt")"

echo "[5/5] Merging..."
cat "$OUTDIR/subfinder.txt" "$OUTDIR/crtsh.txt" | sort -u > "$OUTDIR/all_subs.txt"
cat "$OUTDIR/gau_urls.txt" "$OUTDIR/wayback_urls.txt" | sort -u > "$OUTDIR/all_urls.txt"
cat "$OUTDIR/all_urls.txt" | grep "?" | sort -u > "$OUTDIR/urls_with_params.txt"
cat "$OUTDIR/all_urls.txt" | grep "\.js$" | sort -u > "$OUTDIR/jsfiles.txt"

echo ""
echo "=== PASSIVE RECON DONE ==="
echo "  Unique subdomains : $(wc -l < "$OUTDIR/all_subs.txt")"
echo "  Historical URLs   : $(wc -l < "$OUTDIR/all_urls.txt")"
echo "  URLs with params  : $(wc -l < "$OUTDIR/urls_with_params.txt")"
echo "  JS files          : $(wc -l < "$OUTDIR/jsfiles.txt")"
echo ""
echo "  Next: run httpx on all_subs.txt to find live hosts"
echo "  httpx -l $OUTDIR/all_subs.txt -silent -status-code -title -o live_subs.txt"
