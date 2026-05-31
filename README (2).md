# 🕵️ Web Recon Playbook
### A complete, phase-by-phase recon methodology for bug bounty hunters & pentesters

[![Stars](https://img.shields.io/github/stars/Rishurana2867/web-recon-playbook?style=for-the-badge&color=yellow)](https://github.com/Rishurana2867/web-recon-playbook)
[![Twitter](https://img.shields.io/badge/Twitter-@Rishurana2867-1DA1F2?style=for-the-badge&logo=twitter)](https://twitter.com/Rishurana2867)
[![HackerOne](https://img.shields.io/badge/HackerOne-Profile-494649?style=for-the-badge&logo=hackerone)](https://hackerone.com)

> Built from real bug bounty hunting experience. Not theory — this is the actual workflow I use.

---

## 📌 Why This Repo?

Most recon checklists are either too shallow (just a list of tools with no context) or too bloated (100 tools, no order, no logic).

This playbook is **sequential**, **practical**, and **low-noise** — structured around how attackers actually move through a target, not how tools are alphabetically listed.

---

## 🗺️ The Full Recon Flow

ASN/IP Mapping → Passive Subdomain Enum → Probing + Screenshots → JS Extraction + Crawling → Parameter Discovery → Directory Fuzzing → Vulnerability Scanning → Advanced Checks (CORS, WAF, CMS, SSL)

---

## 📂 Repo Structure

- `phase-0-infra/` — ASN, IP ranges, reverse DNS
- `phase-1-subdomains/` — Passive + active subdomain enum
- `phase-2-crawling/` — JS extraction, endpoint crawling
- `phase-3-params/` — Parameter discovery, GF patterns
- `phase-4-fuzzing/` — Directory & file fuzzing
- `phase-5-vuln-scanning/` — Nuclei, takeover checks, retire.js
- `phase-6-advanced/` — CORS, WAF, CMS, SSL, HTTP methods
- `wordlists/` — Recommended wordlist index
- `scripts/` — full_recon.sh, passive_only.sh, quick_check.sh

---

## ⚡ Quick Start

```bash
git clone https://github.com/Rishurana2867/web-recon-playbook.git
cd web-recon-playbook
chmod +x scripts/full_recon.sh
./scripts/full_recon.sh target.com
```

---

## 🛠️ Tools Required

| Tool | Install | Phase |
|------|---------|-------|
| subfinder | `go install github.com/projectdiscovery/subfinder/v2/cmd/subfinder@latest` | 1 |
| amass | `go install github.com/owasp-amass/amass/v4/...@master` | 1 |
| assetfinder | `go install github.com/tomnomnom/assetfinder@latest` | 1 |
| httpx | `go install github.com/projectdiscovery/httpx/cmd/httpx@latest` | 1 |
| gowitness | `go install github.com/sensepost/gowitness@latest` | 1 |
| naabu | `go install github.com/projectdiscovery/naabu/v2/cmd/naabu@latest` | 1 |
| katana | `go install github.com/projectdiscovery/katana/cmd/katana@latest` | 2 |
| gau | `go install github.com/lc/gau/v2/cmd/gau@latest` | 2 |
| waybackurls | `go install github.com/tomnomnom/waybackurls@latest` | 2 |
| arjun | `pip install arjun` | 3 |
| gf | `go install github.com/tomnomnom/gf@latest` | 3 |
| ffuf | `go install github.com/ffuf/ffuf/v2@latest` | 4 |
| nuclei | `go install github.com/projectdiscovery/nuclei/v3/cmd/nuclei@latest` | 5 |
| subzy | `go install github.com/PentestPad/subzy@latest` | 5 |
| hakrevdns | `go install github.com/hakluke/hakrevdns@latest` | 0 |
| mapcidr | `go install github.com/projectdiscovery/mapcidr/cmd/mapcidr@latest` | 0 |
| wafw00f | `pip install wafw00f` | 6 |
| wpscan | `gem install wpscan` | 6 |
| uro | `pip install uro` | 3 |
| dnsx | `go install github.com/projectdiscovery/dnsx/cmd/dnsx@latest` | 0 |
| retire.js | `npm install -g retire` | 5 |

---

## 📖 Phase Index

| Phase | Name | Key Output |
|-------|------|------------|
| [Phase 0](./phase-0-infra/README.md) | ASN & IP Infrastructure | `ips.txt`, `reverse_dns.txt` |
| [Phase 1](./phase-1-subdomains/README.md) | Subdomain Enumeration | `live_subs.txt`, `screenshots/` |
| [Phase 2](./phase-2-crawling/README.md) | Crawling & JS Extraction | `jsfiles.txt`, `endpoints.txt` |
| [Phase 3](./phase-3-params/README.md) | Parameter Discovery | `final_params.txt`, `xss_params.txt` |
| [Phase 4](./phase-4-fuzzing/README.md) | Directory Fuzzing | `found_200.txt`, `forbidden_403.txt` |
| [Phase 5](./phase-5-vuln-scanning/README.md) | Vulnerability Scanning | `nuclei_results.txt`, `takeover.txt` |
| [Phase 6](./phase-6-advanced/README.md) | Advanced Checks | CORS, WAF, CMS, SSL |

---

## 💡 Recon Philosophy

> **Low noise. High signal. Always stay in scope.**

- Start **passive** — never touch the target until you understand its infrastructure
- Use **rate limiting** on all active tools
- **Screenshot everything** — visual recon catches what automated tools miss
- **Combine sources** — no single tool finds everything
- 403 is not a dead end — try bypass techniques before moving on

---

## ⚠️ Legal Disclaimer

For **authorized security testing only**. Only use on programs where you have explicit permission. Unauthorized scanning is illegal.

---

## 🤝 Contributing

PRs welcome. Found a better command or technique? Open an issue or submit a pull request.

---

## 🔗 Connect

- **X**: [@Rishurana2867](https://twitter.com/Rishurana2867)
- **GitHub**: [github.com/Rishurana2867](https://github.com/Rishurana2867)

---

*If this helped you find a bug, star the repo ⭐*
