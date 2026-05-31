# Phase 0 — ASN & IP Infrastructure Mapping

> **Goal**: Understand the full IP footprint of the target before touching any subdomains.  
> **Risk level**: Very low (mostly passive lookups)

---

## Step 1 — Resolve Target to IP

```bash
dig +short target.com
# Output example: 142.251.221.206
```

## Step 2 — Find ASN from IP

```bash
whois 142.251.221.206
# Look for: origin: AS15169
```

## Step 3 — Find All IP Ranges from ASN

**Manual method** (visual, good for scoping):
```
https://bgp.he.net/
→ Search: AS15169
→ Click: Prefixes → IPv4 Prefixes
→ You'll see all CIDR blocks
```

**Automated method**:
```bash
# Install asnmap
go install github.com/projectdiscovery/asnmap/cmd/asnmap@latest

asnmap -a AS15169 -silent | tee asn_ranges.txt
```

## Step 4 — Expand CIDRs to Individual IPs

```bash
mapcidr -cidr 8.34.208.0/24 | httpx -silent -o live_ips_from_cidr.txt
```

For multiple ranges:
```bash
cat asn_ranges.txt | mapcidr | httpx -silent -o live_ips_from_cidr.txt
```

## Step 5 — Reverse DNS on All IPs

```bash
# Create IP list
cat live_ips_from_cidr.txt | sed 's|https\?://||' > ips.txt

# Run reverse DNS
cat ips.txt | hakrevdns -d | tee reverse_dns.txt

# Filter to just target domain
grep "\.target\.com" reverse_dns.txt | awk '{print $2}' | sort -u > infra_subs.txt
```

## Step 6 — Cloud Provider Check (Exclude if needed)

```bash
# Check if target is behind Cloudflare (often out-of-scope for IPs)
curl -s https://target.com | grep -i "cloudflare"
dnsx -d target.com -a -resp
```

---

## Output Files

| File | Contents |
|------|----------|
| `ips.txt` | Raw IPs from CIDR expansion |
| `reverse_dns.txt` | IP → hostname mappings |
| `infra_subs.txt` | Subdomains discovered via reverse DNS |

---

## Notes

- IPs discovered via reverse DNS are **gold** — often not found in certificate logs
- Always cross-reference infra subs with your scope before probing
- Some cloud IPs are shared infrastructure — don't assume all IPs belong to the target

---

**Next**: [Phase 1 — Subdomain Enumeration](../phase-1-subdomains/README.md)
