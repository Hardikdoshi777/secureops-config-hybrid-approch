# 🛡️ SecurOps Hybrid — Enterprise Security Pipeline

**The best of both worlds:** High-fidelity scanning + automated developer-friendly infrastructure.

Merges Approach A (TruffleHog, OWASP ZAP, mobile SAST) with Approach B (Gitleaks, Semgrep, Trivy, Nuclei, Checkov, Gemini AI) into a unified 8-tool, 12-job security pipeline.

---

## Quick Start (2 minutes)

### 🍎 Mac / Linux
```bash
cd /path/to/your-project
curl -fsSL https://raw.githubusercontent.com/Hardikdoshi777/secureops-config-hybrid-approch/main/scripts/onboard.sh -o /tmp/secureops_onboard.sh
bash /tmp/secureops_onboard.sh
rm /tmp/secureops_onboard.sh
```

**One-liner:**
```bash
cd /path/to/your-project && curl -fsSL https://raw.githubusercontent.com/Hardikdoshi777/secureops-config-hybrid-approch/main/scripts/onboard.sh -o /tmp/secureops_onboard.sh && bash /tmp/secureops_onboard.sh && rm /tmp/secureops_onboard.sh
```

### 🪟 Windows (PowerShell)
```powershell
cd C:\path\to\your-project
Invoke-WebRequest -Uri "https://raw.githubusercontent.com/Hardikdoshi777/secureops-config-hybrid-approch/main/scripts/onboard_windows.ps1" -OutFile "$env:TEMP\secureops_onboard.ps1"
PowerShell -ExecutionPolicy Bypass -File "$env:TEMP\secureops_onboard.ps1"
Remove-Item "$env:TEMP\secureops_onboard.ps1"
```

**One-liner:**
```powershell
cd C:\path\to\your-project; Invoke-WebRequest -Uri "https://raw.githubusercontent.com/Hardikdoshi777/secureops-config-hybrid-approch/main/scripts/onboard_windows.ps1" -OutFile "$env:TEMP\secureops_onboard.ps1"; PowerShell -ExecutionPolicy Bypass -File "$env:TEMP\secureops_onboard.ps1"; Remove-Item "$env:TEMP\secureops_onboard.ps1"
```

This single command:
✅ Detects your OS and installs tools automatically  
✅ Installs pre-commit + gitleaks + trivy (via winget/scoop/choco on Windows)  
✅ Copies 9 security config files into your project  
✅ Installs git hooks (auto-runs on every commit)  
✅ Validates setup with a test secret scan  

---

## 8-Tool Security Stack

| Layer | Tool | What It Does | When |
|-------|------|-------------|------|
| 🔐 Secrets | **Gitleaks** | Blocks 130+ secret patterns (AWS, GCP, Stripe, etc.) | Every commit |
| 🔑 Verified | **TruffleHog** | Pings providers to confirm real (active) keys | CI pipeline |
| 🔍 SAST | **Semgrep** | OWASP Top 10 + CWE Top 25 + mobile-specific rules | Every commit + CI |
| 🔬 Deep SAST | **CodeQL** | Inter-file taint analysis (like Checkmarx, FREE) | CI pipeline |
| 🛡️ SCA | **Trivy** | Scans dependencies for known CVEs | Every push + CI |
| 🌐 DAST | **Nuclei** | Fast config/exposure scanning | CI pipeline |
| 🕷️ DAST | **OWASP ZAP** | Deep API penetration testing | CI (optional) |
| 🏗️ IaC | **Checkov** | Terraform, Dockerfile, K8s, GHA misconfigs | CI pipeline |
| 🤖 AI Fix | **NVIDIA/Groq/Gemini** | Auto-generates fixes + creates GitHub Issues (3-provider fallback) | On failure |
| 🧠 AI Review | **NVIDIA/Groq/Gemini** | PR inline comments with one-click fixes (NVIDIA kimi-k2.6 primary) | On PR |

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
     └── CI/CD PIPELINE (~5min, 12 jobs)
         ├── 🔐 Gitleaks (SARIF → GitHub Security)
         ├── 🔑 TruffleHog (verified secrets)
         ├── 🔍 Semgrep (SARIF + mobile rules)
         ├── 🛡️ Trivy (SARIF → GitHub Security)
         ├── 🌐 Nuclei (fast DAST)
         ├── 🕷️ OWASP ZAP (deep DAST, optional)
         ├── 🏗️ Checkov (IaC, SARIF → GitHub Security)
         ├── 🧠 AI Code Review (inline PR comments)
         ├── 🤖 AI Auto-Fix (Gemini, on failure)
         ├── 📊 Dashboard + Enrollment + PR Comments
         └── 🚦 Security Gate (pass/fail)
```

---

## File Structure

```
secureops-config-hybrid-approch/
├── .github/workflows/
│   └── security-scan.yml          ← 12-job CI/CD pipeline
├── .pre-commit-config.yaml        ← 8 hooks (commit + push)
├── .gitleaks.toml                 ← 130+ secret detection patterns
├── semgrep-mobile.yml             ← Android/iOS/Flutter SAST rules
├── zap.conf                       ← ZAP alert thresholds (FAIL/WARN/IGNORE)
├── azure-pipelines.yml            ← Azure DevOps equivalent pipeline
├── scripts/
│   ├── onboard.sh                 ← One-command setup (Mac/Linux)
│   ├── onboard_windows.ps1        ← One-command setup (Windows PowerShell)
│   ├── ai-code-review.py          ← AI Code Review for PRs (Gemini/Groq)
│   ├── ai-auto-fix.py             ← AI Auto-Fix reads reports → creates Issues
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
| `NVIDIA_API_KEY` | NVIDIA NIM AI — primary provider (kimi-k2.6) | 🟡 Recommended |
| `GROQ_API_KEY` | Groq AI — fallback provider (llama-3.3-70b) | 🟡 Recommended |
| `GOOGLE_AI_API_KEY` | Gemini AI — last resort (gemini-2.0-flash) | ⚪ Optional |
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

- **Teams:** #security-help
- **Email:** hardikdoshi@devrepublic.nl
- **Docs:** See `docs/` folder

---

*Built with ❤️ by the Security Team — Phase 1 of the SecurOps SaaS Product*
