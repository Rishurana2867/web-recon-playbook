#!/bin/bash
# ============================================================
# quick_check.sh — Fast single-target fingerprint
# Runs in ~2 minutes, no heavy scanning
# Usage: ./quick_check.sh https://target.com
# Author: @Rishurana2867
# ============================================================

TARGET=$1

if [ -z "$TARGET" ]; then
  echo "Usage: $0 https://target.com"
  exit 1
fi

echo "============================================================"
echo "  Quick Recon: $TARGET"
echo "============================================================"

# Headers
echo ""
echo "[1] Response Headers:"
curl -s -I "$TARGET" 2>/dev/null | grep -iE "(server|x-powered-by|set-cookie|x-frame|content-security|strict-transport|x-content-type)"

# CORS check
echo ""
echo "[2] CORS Check (evil.com origin):"
curl -s -I -H "Origin: https://evil.com" "$TARGET" 2>/dev/null \
  | grep -i "access-control"

# robots.txt
echo ""
echo "[3] robots.txt:"
curl -s "$TARGET/robots.txt" 2>/dev/null | head -20

# Error triggering
echo ""
echo "[4] 404 Error Response (fingerprinting):"
curl -s "$TARGET/aaaanotexist12345" 2>/dev/null \
  | grep -iE "(error|exception|framework|version|powered|laravel|symfony|django|rails|express)" \
  | head -5

# HTTP methods
echo ""
echo "[5] Allowed HTTP Methods:"
curl -s -X OPTIONS "$TARGET" -i 2>/dev/null | grep -i "allow"

# WAF check
echo ""
echo "[6] WAF Detection:"
wafw00f "$TARGET" 2>/dev/null | grep -iE "(detected|no waf)"

# SSL
echo ""
echo "[7] SSL Certificate:"
echo | openssl s_client -connect "$(echo $TARGET | sed 's|https://||;s|/||'):443" 2>/dev/null \
  | openssl x509 -noout -subject -issuer -dates 2>/dev/null

echo ""
echo "============================================================"
echo "  Done. Manual testing recommended next."
echo "============================================================"
