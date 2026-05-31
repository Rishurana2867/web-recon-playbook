# Wordlists Reference

A curated index of wordlists for each scanning scenario — ordered by speed vs coverage tradeoff.

---

## Install SecLists (Required)

```bash
sudo apt install seclists
# or
git clone https://github.com/danielmiessler/SecLists.git /usr/share/seclists
```

---

## Recommended Wordlists by Use Case

### General Directory Discovery

| Priority | Path | Size | Use When |
|----------|------|------|----------|
| 1st (fastest) | `/usr/share/wordlists/dirb/common.txt` | ~4,600 | Quick first pass |
| 2nd (standard) | `/usr/share/seclists/Discovery/Web-Content/raft-medium-directories.txt` | ~30,000 | Most bug bounty targets |
| 3rd (thorough) | `/usr/share/seclists/Discovery/Web-Content/raft-large-directories.txt` | ~62,000 | Deep recon, slow targets |

### File Discovery

| Priority | Path | Size | Use When |
|----------|------|------|----------|
| 1st | `/usr/share/seclists/Discovery/Web-Content/raft-medium-files.txt` | ~17,000 | Sensitive files (.env, backups) |
| 2nd | `/usr/share/seclists/Discovery/Web-Content/raft-large-files.txt` | ~37,000 | Thorough file search |

### API Endpoints

| Priority | Path | Use When |
|----------|------|----------|
| 1st | `/usr/share/seclists/Discovery/Web-Content/api/objects.txt` | REST API object names |
| 2nd | `/usr/share/seclists/Discovery/Web-Content/api/api-endpoints.txt` | Common API paths |
| 3rd | `/usr/share/seclists/Discovery/Web-Content/api/api-versioning.txt` | v1, v2, v3 patterns |

### Subdomains

| Priority | Path | Use When |
|----------|------|----------|
| 1st | `/usr/share/seclists/Discovery/DNS/subdomains-top1million-5000.txt` | Quick subdomain brute |
| 2nd | `/usr/share/seclists/Discovery/DNS/subdomains-top1million-20000.txt` | Medium coverage |
| 3rd | `/usr/share/seclists/Discovery/DNS/subdomains-top1million-110000.txt` | Deep brute force |

### Password Lists (Login Forms)

| Path | Use When |
|------|----------|
| `/usr/share/seclists/Passwords/Common-Credentials/top-passwords-shortlist.txt` | Quick test |
| `/usr/share/seclists/Passwords/Leaked-Databases/rockyou-75.txt` | Credential stuffing |

---

## Build a Combined Wordlist

```bash
cat /usr/share/wordlists/dirb/common.txt \
    /usr/share/seclists/Discovery/Web-Content/raft-medium-directories.txt \
  | sort -u > /tmp/combined_dirs.txt

echo "[+] Combined wordlist: $(wc -l < /tmp/combined_dirs.txt) entries"
```

---

## Tips

- Start small — `common.txt` often finds 80% of what you need
- Add custom words based on the target's tech stack (Laravel → `artisan`, `storage`)
- For APIs: always include `graphql`, `swagger`, `openapi`, `docs`, `api-docs`
- If you get 0 results — the app may be filtering by User-Agent, try `-H "User-Agent: Mozilla/5.0"`
