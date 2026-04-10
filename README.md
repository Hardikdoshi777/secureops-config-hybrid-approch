# 🛡️ SecurOps Hybrid — Enterprise Security Pipeline

**The best of both worlds:** High-fidelity scanning + automated developer-friendly infrastructure.

Merges Approach A (TruffleHog, OWASP ZAP, mobile SAST) with Approach B (Gitleaks, Semgrep, Trivy, Nuclei, Checkov, Claude AI) into a unified 7-tool, 10-job security pipeline.

---

## Quick Start (2 minutes)

```bash
# From ANY project repo:
cd /path/to/your-project
bash <(curl -s https://raw.githubusercontent.com/Hardikdoshi777/secureops-config-hybrid-approch/main/scripts/onboard.sh)
```

This single command:
✅ Detects your OS (macOS Intel/M1, Linux, Windows)  
✅ Installs pre-commit + gitleaks + trivy  
✅ Copies 9 security config files into your project  
✅ Installs git hooks (auto-runs on every commit)  
✅ Validates setup with a test secret scan  

---

## 7-Tool Security Stack

| Layer | Tool | What It Does | When |
|-------|------|-------------|------|
| 🔐 Secrets | **Gitleaks** | Blocks 130+ secret patterns (AWS, GCP, Stripe, etc.) | Every commit |
| 🔑 Verified | **TruffleHog** | Pings providers to confirm real (active) keys | CI pipeline |
| 🔍 SAST | **Semgrep** | OWASP Top 10 + CWE Top 25 + mobile-specific rules | Every commit + CI |
| 🛡️ SCA | **Trivy** | Scans dependencies for known CVEs | Every push + CI |
| 🌐 DAST | **Nuclei** | Fast config/exposure scanning | CI pipeline |
| 🕷️ DAST | **OWASP ZAP** | Deep API penetration testing | CI (optional) |
| 🏗️ IaC | **Checkov** | Terraform, Dockerfile, K8s, GHA misconfigs | CI pipeline |
| 🤖 AI | **Claude** | Auto-generates fixes + creates GitHub Issues | On failure |

---

## Pipeline Architecture

```
Developer commits code
     │
     ├── PRE-COMMIT (~3s)
     │   ├── 🔐 Gitleaks (130+ patterns)
     │   ├── 🔍 Semgrep (OWASP + mobile)
     │   └── Safety checks (private-key, merge-conflict, large-files)
     │
     ├── PRE-PUSH
     │   └── 🛡️ Trivy (dependency CVEs)
     │
     └── CI/CD PIPELINE (~5min, 10 parallel jobs)
         ├── 🔐 Gitleaks (SARIF → GitHub Security)
         ├── 🔑 TruffleHog (verified secrets)
         ├── 🔍 Semgrep (SARIF + mobile rules)
         ├── 🛡️ Trivy (SARIF → GitHub Security)
         ├── 🌐 Nuclei (fast DAST)
         ├── 🕷️ OWASP ZAP (deep DAST, optional)
         ├── 🏗️ Checkov (IaC, SARIF → GitHub Security)
         ├── 🤖 Claude AI Auto-Fix (on failure)
         ├── 📊 Dashboard + Enrollment + PR Comments
         └── 🚦 Security Gate (pass/fail)
```

---

## File Structure

```
secureops-config-hybrid-approch/
├── .github/workflows/
│   └── security-scan.yml          ← 10-job CI/CD pipeline
├── .pre-commit-config.yaml        ← 8 hooks (commit + push)
├── .gitleaks.toml                 ← 130+ secret detection patterns
├── semgrep-mobile.yml             ← Android/iOS/Flutter SAST rules
├── zap.conf                       ← ZAP alert thresholds (FAIL/WARN/IGNORE)
├── azure-pipelines.yml            ← Azure DevOps equivalent pipeline
├── scripts/
│   ├── onboard.sh                 ← One-command remote setup (370 lines)
│   ├── ai-auto-fix.py             ← Claude AI reads reports → creates Issues
│   ├── generate-report.py         ← HTML dashboard + enrollment + PR comments
│   ├── trivy-scan.sh              ← Trivy wrapper (native + Docker fallback)
│   └── zap_report_check.py        ← ZAP threshold gate (Block HIGH, Warn MEDIUM)
├── docs/
│   ├── SecurOps_Developer_Guide.md   ← Developer quick-reference
│   ├── SecurOps_Org_Rollout_Guide.md ← Org-wide rollout plan
│   └── employee-email-template.txt   ← Ready-to-send onboarding email
├── .gitignore
└── README.md                      ← You are here
```

---

## GitHub Secrets Required

| Secret | Purpose | Required |
|--------|---------|----------|
| `GITHUB_TOKEN` | Auto-provided | ✅ Auto |
| `ANTHROPIC_API_KEY` | Claude AI auto-fix | 🟡 Recommended |
| `TARGET_URL` | ZAP/Nuclei URL target | 🟡 Optional |

GitHub Variables:
| Variable | Purpose | Default |
|----------|---------|---------|
| `ENABLE_ZAP` | Enable OWASP ZAP | `false` |

---

## Security Gate

The pipeline **blocks merges** if ANY of these are found:
- ❌ Verified secrets (TruffleHog confirmed active keys)
- ❌ HIGH severity SAST findings (Semgrep)
- ❌ CRITICAL/HIGH SCA vulnerabilities (Trivy)
- ❌ CRITICAL/HIGH DAST findings (Nuclei or ZAP)
- ❌ CRITICAL IaC misconfigurations (Checkov)

**MEDIUM** findings generate warnings but don't block.

---

## Support

- **Slack:** #security-help
- **Email:** hardikdoshi@devrepublic.nl
- **Docs:** See `docs/` folder

---

*Built with ❤️ by the Security Team — Phase 1 of the SecurOps SaaS Product*
