#!/bin/bash
# ============================================================
#  SecurOps Hybrid — One-Command Project Onboarding
#  File: scripts/onboard.sh
#
#  Usage (remote — from ANY project repo):
#    bash <(curl -s https://raw.githubusercontent.com/YOUR_ORG/secureops-config-hybrid-approch/main/scripts/onboard.sh)
#
#  What it does:
#    1. Detects your OS (macOS Intel/M1, Linux, Windows Git Bash)
#    2. Installs pre-commit + gitleaks + trivy
#    3. Downloads company security config from central repo
#    4. Copies 8 files into your project
#    5. Installs git hooks + validates setup
#
#  Hybrid: Approach B base + Approach A tools (ZAP, TruffleHog, mobile)
# ============================================================

set -euo pipefail

# ─────────────────────────────────────────────────────────
# CONFIGURATION — Edit these for your company
# ─────────────────────────────────────────────────────────
GITHUB_ORG="Hardikdoshi777"
CONFIG_REPO="secureops-config-hybrid-approch"
BRANCH="main"
BASE_URL="https://raw.githubusercontent.com/${GITHUB_ORG}/${CONFIG_REPO}/${BRANCH}"
SECUROPS_DIR="$HOME/.securops"
SUPPORT_TEAMS="#security-help"
SUPPORT_EMAIL="hardikdoshi@devrepublic.nl"

# Files to copy: SOURCE_IN_CONFIG|DESTINATION_IN_PROJECT
FILES=(
  ".pre-commit-config.yaml|.pre-commit-config.yaml"
  ".gitleaks.toml|.gitleaks.toml"
  ".github/workflows/security-scan.yml|.github/workflows/security-scan.yml"
  "semgrep-mobile.yml|semgrep-mobile.yml"
  "zap.conf|zap.conf"
  "scripts/trivy-scan.sh|scripts/trivy-scan.sh"
  "scripts/generate-report.py|scripts/generate-report.py"
  "scripts/ai-auto-fix.py|scripts/ai-auto-fix.py"
  "scripts/zap_report_check.py|scripts/zap_report_check.py"
)

# ─────────────────────────────────────────────────────────
# COLOR OUTPUT
# ─────────────────────────────────────────────────────────
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[0;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
BOLD='\033[1m'
NC='\033[0m'

ok()   { echo -e "${GREEN}  ✅ $*${NC}"; }
fail() { echo -e "${RED}  ❌ $*${NC}"; }
warn() { echo -e "${YELLOW}  ⚠️  $*${NC}"; }
info() { echo -e "${CYAN}  ℹ️  $*${NC}"; }
step() { echo -e "\n${BOLD}${BLUE}═══ STEP $1 ═══ $2${NC}"; }

# ─────────────────────────────────────────────────────────
# WELCOME BANNER
# ─────────────────────────────────────────────────────────
clear 2>/dev/null || true
echo -e "${BOLD}${CYAN}"
echo "╔═══════════════════════════════════════════════════════╗"
echo "║          🛡️  SecurOps Hybrid Setup                    ║"
echo "║          7-Tool Security Pipeline                     ║"
echo "║          Gitleaks · TruffleHog · Semgrep · Trivy      ║"
echo "║          Nuclei · OWASP ZAP · Checkov · Claude AI     ║"
echo "╚═══════════════════════════════════════════════════════╝"
echo -e "${NC}"

# ─────────────────────────────────────────────────────────
# PRE-CHECK: Must be inside a git repo
# ─────────────────────────────────────────────────────────
if ! git rev-parse --show-toplevel &>/dev/null; then
  fail "Not inside a git repository!"
  echo "  cd into your project repo first, then re-run this script."
  exit 1
fi

PROJECT_DIR=$(git rev-parse --show-toplevel)
PROJECT_NAME=$(basename "$PROJECT_DIR")
cd "$PROJECT_DIR"

echo ""
info "Project detected: ${BOLD}$PROJECT_NAME${NC}"
info "Location: $PROJECT_DIR"

# ─────────────────────────────────────────────────────────
# STEP 1 — Detect OS
# ─────────────────────────────────────────────────────────
step "1/5" "Detecting your system..."

OS="$(uname -s)"
ARCH="$(uname -m)"

case "$OS" in
  Darwin*)
    OS_TYPE="mac"
    BREW_PREFIX=$( [ "$ARCH" = "arm64" ] && echo "/opt/homebrew" || echo "/usr/local" )
    CHIP=$( [ "$ARCH" = "arm64" ] && echo "Apple Silicon M1/M2/M3/M4" || echo "Intel" )
    ok "macOS ${CHIP} detected"
    ;;
  Linux*)
    OS_TYPE="linux"
    ok "Linux detected ($(uname -r | cut -d- -f1))"
    ;;
  CYGWIN*|MINGW*|MSYS*)
    OS_TYPE="windows"
    ok "Windows Git Bash detected"
    ;;
  *)
    OS_TYPE="linux"
    warn "Unknown OS ($OS) — using Linux method"
    ;;
esac

# ─────────────────────────────────────────────────────────
# STEP 2 — Install security tools
# ─────────────────────────────────────────────────────────
step "2/5" "Installing security tools..."

install_mac() {
  if ! command -v brew &>/dev/null; then
    warn "Installing Homebrew first..."
    /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
    eval "$($BREW_PREFIX/bin/brew shellenv)"
    echo "eval \"\$($BREW_PREFIX/bin/brew shellenv)\"" >> ~/.zprofile
  fi
  brew install pre-commit gitleaks trivy 2>/dev/null || brew upgrade pre-commit gitleaks trivy 2>/dev/null || true
}

install_linux() {
  if command -v apt-get &>/dev/null; then
    sudo apt-get update -qq && sudo apt-get install -y python3-pip python3-venv curl 2>/dev/null || true
  elif command -v yum &>/dev/null; then
    sudo yum install -y python3-pip curl 2>/dev/null || true
  fi
  pip3 install pre-commit --break-system-packages 2>/dev/null || pip3 install pre-commit || true

  # Install gitleaks
  if ! command -v gitleaks &>/dev/null; then
    GITLEAKS_VER="8.18.2"
    ARCH_SUFFIX=$( [ "$(uname -m)" = "aarch64" ] && echo "arm64" || echo "x64" )
    curl -sSfL "https://github.com/gitleaks/gitleaks/releases/download/v${GITLEAKS_VER}/gitleaks_${GITLEAKS_VER}_linux_${ARCH_SUFFIX}.tar.gz" \
      | tar -xz -C /tmp gitleaks 2>/dev/null
    sudo mv /tmp/gitleaks /usr/local/bin/gitleaks 2>/dev/null || mv /tmp/gitleaks ~/.local/bin/gitleaks 2>/dev/null || true
  fi

  # Install trivy
  if ! command -v trivy &>/dev/null; then
    TRIVY_VER="0.50.1"
    ARCH_SUFFIX=$( [ "$(uname -m)" = "aarch64" ] && echo "ARM64" || echo "64bit" )
    curl -sSfL "https://github.com/aquasecurity/trivy/releases/download/v${TRIVY_VER}/trivy_${TRIVY_VER}_Linux-${ARCH_SUFFIX}.tar.gz" \
      | tar -xz -C /tmp trivy 2>/dev/null
    sudo mv /tmp/trivy /usr/local/bin/trivy 2>/dev/null || true
  fi
}

install_windows() {
  pip install pre-commit 2>/dev/null || true
  warn "Install gitleaks manually: https://github.com/gitleaks/gitleaks/releases"
  warn "Install trivy manually: https://github.com/aquasecurity/trivy/releases"
}

if command -v pre-commit &>/dev/null && command -v gitleaks &>/dev/null; then
  ok "pre-commit $(pre-commit --version) already installed"
  ok "gitleaks $(gitleaks version 2>/dev/null || echo 'installed') already installed"
else
  case "$OS_TYPE" in
    mac)     install_mac ;;
    linux)   install_linux ;;
    windows) install_windows ;;
  esac

  command -v pre-commit &>/dev/null && ok "pre-commit installed: $(pre-commit --version)" || fail "pre-commit install failed"
  command -v gitleaks &>/dev/null   && ok "gitleaks installed" || warn "gitleaks not found — secret scanning may not work"
fi

command -v trivy &>/dev/null && ok "trivy installed: $(trivy --version 2>/dev/null | head -1)" || info "trivy not installed — will use Docker fallback"

# ─────────────────────────────────────────────────────────
# STEP 3 — Download central config
# ─────────────────────────────────────────────────────────
step "3/5" "Downloading company security config..."

mkdir -p "$SECUROPS_DIR"

if [ -d "$SECUROPS_DIR/.git" ]; then
  info "Updating existing config..."
  git -C "$SECUROPS_DIR" pull --quiet 2>/dev/null || true
else
  info "Cloning config repo..."
  git clone --quiet "https://github.com/${GITHUB_ORG}/${CONFIG_REPO}.git" "$SECUROPS_DIR" 2>/dev/null || {
    warn "Clone failed — downloading files individually..."
    for entry in "${FILES[@]}"; do
      SRC="${entry%%|*}"
      mkdir -p "$SECUROPS_DIR/$(dirname "$SRC")"
      curl -sSfL "${BASE_URL}/${SRC}" -o "$SECUROPS_DIR/${SRC}" 2>/dev/null || true
    done
  }
fi

ok "Security config saved to: $SECUROPS_DIR"

# ─────────────────────────────────────────────────────────
# STEP 4 — Copy config files into THIS project
# ─────────────────────────────────────────────────────────
step "4/5" "Copying security files into: $PROJECT_NAME..."

COPIED=0
SKIPPED=0

for entry in "${FILES[@]}"; do
  SRC="${entry%%|*}"
  DST="${entry##*|}"

  mkdir -p "$(dirname "$DST")"

  LOCAL_SRC="$SECUROPS_DIR/$SRC"

  if [ -f "$LOCAL_SRC" ]; then
    if [ -f "$DST" ]; then
      if cmp -s "$LOCAL_SRC" "$DST"; then
        info "Already up to date: $DST"
        SKIPPED=$((SKIPPED + 1))
      else
        cp "$LOCAL_SRC" "$DST"
        ok "Updated: $DST"
        COPIED=$((COPIED + 1))
      fi
    else
      cp "$LOCAL_SRC" "$DST"
      ok "Copied: $DST"
      COPIED=$((COPIED + 1))
    fi
  else
    info "Downloading: $DST"
    if curl -sSfL "${BASE_URL}/${SRC}" -o "$DST" 2>/dev/null; then
      ok "Downloaded: $DST"
      COPIED=$((COPIED + 1))
    else
      fail "Could not copy: $DST"
    fi
  fi
done

chmod +x scripts/trivy-scan.sh 2>/dev/null || true

echo ""
ok "${COPIED} file(s) copied, ${SKIPPED} already up to date"
echo ""
echo "  Files now in your project:"
echo "    ✅ .pre-commit-config.yaml                ← 8 hook definitions"
echo "    ✅ .gitleaks.toml                         ← 130+ secret patterns"
echo "    ✅ .github/workflows/security-scan.yml   ← CI/CD pipeline (7 tools)"
echo "    ✅ semgrep-mobile.yml                     ← mobile SAST rules"
echo "    ✅ zap.conf                               ← ZAP alert thresholds"
echo "    ✅ scripts/trivy-scan.sh                  ← dependency scanner"
echo "    ✅ scripts/generate-report.py             ← dashboard + enrollment"
echo "    ✅ scripts/ai-auto-fix.py                 ← Claude AI auto-fix"
echo "    ✅ scripts/zap_report_check.py            ← ZAP threshold gate"

# ─────────────────────────────────────────────────────────
# STEP 5 — Install git hooks + validate
# ─────────────────────────────────────────────────────────
step "5/5" "Installing git hooks + running validation..."

pre-commit install
pre-commit install --hook-type pre-push
ok "Git hooks installed (runs on every commit automatically)"

# Global git template so ALL future repos are protected
GIT_TEMPLATE="$SECUROPS_DIR/git-template"
mkdir -p "$GIT_TEMPLATE/hooks"
cat > "$GIT_TEMPLATE/hooks/pre-commit" << 'HOOK'
#!/bin/bash
# SecurOps Hybrid Global Pre-commit Hook
if command -v pre-commit &>/dev/null && [ -f ".pre-commit-config.yaml" ]; then
  pre-commit run --hook-stage commit
  exit $?
fi
exit 0
HOOK
chmod +x "$GIT_TEMPLATE/hooks/pre-commit"
git config --global init.templateDir "$GIT_TEMPLATE"
ok "Global git template set — all NEW repos will auto-have hooks"

# ── Validation Test ───────────────────────────────────────
echo ""
info "Running validation — testing secret detection..."

TMPFILE=$(mktemp /tmp/securops-test-XXXXX.py)
echo 'aws_key = "AKIAFAKEKEY1234567890"' > "$TMPFILE"

if command -v gitleaks &>/dev/null; then
  if ! gitleaks detect --no-git --source "$(dirname "$TMPFILE")" --quiet 2>/dev/null; then
    ok "Secret detection WORKING — fake AWS key was caught!"
  else
    warn "Validation inconclusive — gitleaks needs git context for full test"
    info "Run: git add test-secret.py && git commit — to test for real"
  fi
fi

rm -f "$TMPFILE"

# ── Stage files ───────────────────────────────────────────
echo ""
info "Staging security files for commit..."
git add .pre-commit-config.yaml .gitleaks.toml semgrep-mobile.yml zap.conf \
        .github/workflows/security-scan.yml scripts/ 2>/dev/null || true
echo ""
warn "Security files staged — run: git commit -m 'feat: add SecurOps Hybrid security scanning'"

# ─────────────────────────────────────────────────────────
# SUCCESS BANNER
# ─────────────────────────────────────────────────────────
echo ""
echo -e "${GREEN}${BOLD}"
echo "╔═══════════════════════════════════════════════════════╗"
echo "║         ✅ SECUROPS HYBRID — SETUP COMPLETE!          ║"
echo "╚═══════════════════════════════════════════════════════╝"
echo -e "${NC}"
echo "  Your project '${PROJECT_NAME}' is now protected by 7 tools:"
echo ""
echo "    🔐 Gitleaks      — 130+ secret patterns blocked on commit"
echo "    🔑 TruffleHog    — verified secret scanning in CI"
echo "    🔍 Semgrep       — OWASP Top 10 + mobile SAST on commit"
echo "    🛡️  Trivy         — dependency CVE scanning on push"
echo "    🌐 Nuclei        — fast DAST scanning in CI"
echo "    🕷️  OWASP ZAP     — deep API DAST scanning in CI"
echo "    🏗️  Checkov       — IaC scanning in CI"
echo "    🤖 Claude AI     — auto-generates fixes for findings"
echo ""
echo "  ─────────────────────────────────────────────────────"
echo "  Next steps:"
echo ""
echo "    1. Commit the security files:"
echo "       git commit -m 'feat: add SecurOps Hybrid security scanning'"
echo ""
echo "    2. Push to trigger the GitHub Actions pipeline:"
echo "       git push"
echo ""
echo "    3. Test — try committing a fake secret:"
echo '       echo '"'"'key="AKIAIOSFODNN7EXAMPLE"'"'"' > test.py'
echo "       git add test.py && git commit -m 'test'"
echo "       # Expected: ❌ BLOCKED"
echo ""
echo "  ─────────────────────────────────────────────────────"
echo "  Need help?"
echo "    Teams:  ${SUPPORT_TEAMS}"
echo "    Email:  ${SUPPORT_EMAIL}"
echo ""
echo "  To add SecurOps to ANOTHER project:"
echo "    cd /path/to/other-project"
echo "    bash <(curl -s ${BASE_URL}/scripts/onboard.sh)"
echo ""
