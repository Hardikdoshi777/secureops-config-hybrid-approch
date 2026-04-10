# SecurOps Hybrid — Organization-Wide Rollout Guide

## Rollout Strategy

### Phase 1: Pilot (Week 1-2)
- Onboard 3-5 critical repos (API backend, main mobile app, infrastructure)
- Security team monitors findings and tunes false positives
- Collect developer feedback on friction points

### Phase 2: Engineering-Wide (Week 3-4)
- Send company-wide email (see `docs/employee-email-template.txt`)
- One-command onboard: `bash <(curl -s .../onboard.sh)`
- Track enrollment via dashboard
- Hold 15-min "SecurOps Quick Start" in team standup

### Phase 3: Mandatory (Month 2)
- Enable branch protection: require `security-gate` check to pass
- All new repos auto-protected via global git template
- Monthly security posture report to management

## Enabling Branch Protection

1. Go to GitHub repo → Settings → Branches → Branch Protection Rules
2. Add rule for `main` branch
3. Check "Require status checks to pass before merging"
4. Add these required checks:
   - `🔐 Secrets (Gitleaks)`
   - `🔍 SAST (Semgrep)`
   - `🛡️ SCA (Trivy)`
   - `🚦 Security Gate`

## Enabling OWASP ZAP (Optional)

ZAP is disabled by default (it's slow, ~10min, needs Docker). To enable:

1. Go to repo → Settings → Variables → Actions
2. Add variable: `ENABLE_ZAP` = `true`
3. Add a `TARGET_URL` secret for baseline scanning, OR
4. Place API spec file (`swagger.json` / `openapi.yaml`) in repo root

ZAP runs automatically on weekly schedule even without manual enable.

## Required GitHub Secrets

| Secret | Purpose | Required? |
|--------|---------|-----------|
| `GITHUB_TOKEN` | Auto-provided by GitHub Actions | ✅ Auto |
| `ANTHROPIC_API_KEY` | Claude AI auto-fix | 🟡 Optional |
| `TARGET_URL` | ZAP/Nuclei target URL | 🟡 Optional |

## Monitoring Enrollment

The pipeline automatically tracks who has onboarded:
- `enrollment-tracking.json` in artifacts shows all enrolled developers
- Dashboard `security-dashboard.html` shows enrollment count + pass rate
- PR comments show scan results to developers immediately

## KPIs to Track

| Metric | Target | How to Measure |
|--------|--------|----------------|
| **Enrollment rate** | 100% active repos | enrollment-tracking.json |
| **Scan pass rate** | >90% | Dashboard stats |
| **Mean time to fix** | <24 hours | GitHub Issues (AI-created) |
| **False positive rate** | <5% | Developer feedback + .gitleaks.toml allowlist growth |
| **Secrets caught pre-commit** | 100% before CI | Pre-commit hook logs |
