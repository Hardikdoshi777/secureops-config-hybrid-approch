# SecurOps Developer Security Guide

## What is SecurOps Hybrid?

SecurOps is your company's automated security scanning pipeline. It integrates 7 open-source security tools into your development workflow, catching vulnerabilities **before they reach production**.

## Architecture

```
┌─────────────────────────────────────────────────────────────┐
│                    Developer Workflow                         │
├──────────┬──────────┬───────────┬──────────┬────────────────┤
│   IDE    │  Commit  │   Push    │   PR     │   Merge        │
│          │          │           │          │                │
│ DevSkim  │ Gitleaks │ Trivy     │ 7 tools  │ Security Gate  │
│ alerts   │ Semgrep  │           │ parallel │ Pass/Fail      │
│          │ safety   │           │ 5 min    │                │
└──────────┴──────────┴───────────┴──────────┴────────────────┘
```

## The 7 Tools

### 1. 🔐 Gitleaks (Secrets)
**When:** Every commit (pre-commit hook)
**What:** Scans for 130+ secret patterns (AWS keys, API tokens, passwords)
**If blocked:** Remove the secret, rotate it immediately, commit again

### 2. 🔑 TruffleHog (Verified Secrets)
**When:** CI pipeline only
**What:** Pings actual providers (AWS, GitHub, Stripe) to confirm if a key is real
**Why both?** Gitleaks is fast (regex), TruffleHog eliminates false positives

### 3. 🔍 Semgrep (SAST - Static Analysis)
**When:** Every commit + CI pipeline
**What:** Checks for OWASP Top 10, SQL injection, XSS, insecure crypto
**Mobile rules:** Android `MODE_WORLD_READABLE`, iOS `NSLog`, Dart `Random()`

### 4. 🛡️ Trivy (SCA - Dependency Scanning)
**When:** Every push (pre-push hook) + CI pipeline
**What:** Scans package.json, pubspec.yaml, requirements.txt for known CVEs

### 5. 🌐 Nuclei (Fast DAST)
**When:** CI pipeline only
**What:** Scans for exposed configs, tokens, and common misconfigurations

### 6. 🕷️ OWASP ZAP (Deep DAST)
**When:** CI pipeline (optional, when ENABLE_ZAP=true or on schedule)
**What:** Real HTTP attacks — SQL injection, XSS, auth bypass testing

### 7. 🏗️ Checkov (IaC Scanning)
**When:** CI pipeline only
**What:** Scans Dockerfiles, Terraform, Kubernetes, GitHub Actions for misconfigs

## Common Fixes

### Secret Detected
```bash
# 1. Remove the secret from your code
# 2. Rotate the compromised credential immediately
# 3. Use environment variables or a secrets manager instead:

# ❌ BAD — hardcoded credentials
api_key = "<YOUR_ACCESS_KEY_HERE>"   # Never hardcode real keys!

# ✅ GOOD — use environment variables
api_key = os.environ.get("API_KEY")
```

### SAST Issue (SQL Injection)
```python
# ❌ BAD
cursor.execute(f"SELECT * FROM users WHERE id = {user_id}")

# ✅ GOOD
cursor.execute("SELECT * FROM users WHERE id = %s", (user_id,))
```

### Dependency Vulnerability
```bash
# Check which package is vulnerable:
trivy fs --severity HIGH,CRITICAL .

# Update the specific package:
npm update vulnerable-package
# or
pip install --upgrade vulnerable-package
```

## 🧠 AI Code Review (Automatic on PRs)

When you create a Pull Request, our AI reviewer will automatically:
- Post **inline comments** on problematic lines (like CodeRabbit)
- Show a **summary table** with findings count per category
- Apply a **Quality Gate** (pass/warning/fail)
- Provide **one-click fixes** — click "Apply suggestion" right in the PR!

**Categories checked:**
| # | Category | What It Finds |
|---|----------|--------------|
| 🔒 | Security | OWASP Top 10, injection, hardcoded secrets |
| 🐛 | Bugs | Null references, race conditions, resource leaks |
| 🧹 | Quality | Complexity, dead code, naming, duplication |
| ⚡ | Performance | N+1 queries, memory leaks, inefficient loops |
| 📏 | Best Practices | Language-specific conventions |
| 🧪 | Testing | Missing test coverage |
| 🏗️ | Architecture | SOLID violations, API design |
| 📝 | Documentation | Missing docs, outdated comments |

## 💻 IDE Extensions (Optional, Free)

Get real-time security scanning in your editor before you even commit:

### VS Code
| Extension | What It Does | Install |
|-----------|-------------|---------|
| **Semgrep** | Real-time SAST scanning | `ext install Semgrep.semgrep` |
| **Trivy** | Dependency vulnerability scanning | `ext install AquaSecurity.trivy-vulnerability-scanner` |
| **GitLens** | Git blame + secret detection | `ext install eamodio.gitlens` |
| **SonarLint** | Code quality + code smells | `ext install SonarSource.sonarlint-vscode` |

### IntelliJ / Android Studio
| Plugin | What It Does | Install |
|--------|-------------|---------|
| **Semgrep** | Real-time SAST | Search "Semgrep" in Plugins |
| **SonarLint** | Code quality + smells | Search "SonarLint" in Plugins |
| **Snyk** | SCA + container scan | Search "Snyk" in Plugins |

### How to Install (VS Code):
```bash
# Install all recommended extensions at once:
code --install-extension Semgrep.semgrep
code --install-extension AquaSecurity.trivy-vulnerability-scanner
code --install-extension eamodio.gitlens
code --install-extension SonarSource.sonarlint-vscode
```

## Need an Exception?

If a finding is a false positive:
1. Contact the Security Team on Teams `#security-help`
2. Provide the finding details and why it's false positive
3. If approved, it will be added to `.gitleaks.toml` allowlist
