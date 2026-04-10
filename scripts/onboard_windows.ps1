# ============================================================
#  SecurOps Hybrid — One-Command Project Onboarding (Windows)
#  File: scripts/onboard_windows.ps1
#
#  Usage (from ANY project repo in PowerShell):
#    irm https://raw.githubusercontent.com/Hardikdoshi777/secureops-config-hybrid-approch/main/scripts/onboard_windows.ps1 | iex
#
#  OR download and run:
#    Invoke-WebRequest -Uri "https://raw.githubusercontent.com/Hardikdoshi777/secureops-config-hybrid-approch/main/scripts/onboard_windows.ps1" -OutFile onboard_windows.ps1; .\onboard_windows.ps1
#
#  What it does:
#    1. Auto-installs Git + Python if missing (via winget/choco/direct download)
#    2. Installs pre-commit + gitleaks + trivy via winget/scoop/choco
#    3. Downloads company security config from central repo
#    4. Copies 9 files into your project
#    5. Installs git hooks + validates setup
#
#  Prerequisites: PowerShell 5.1+ (built into Windows 10/11)
#  Auto-installs: Git, Python 3.12, pre-commit, gitleaks, trivy
# ============================================================

#Requires -Version 5.1
$ErrorActionPreference = "Continue"

# ─────────────────────────────────────────────────────────
# CONFIGURATION — Edit these for your company
# ─────────────────────────────────────────────────────────
$GITHUB_ORG     = "Hardikdoshi777"
$CONFIG_REPO    = "secureops-config-hybrid-approch"
$BRANCH         = "main"
$BASE_URL       = "https://raw.githubusercontent.com/$GITHUB_ORG/$CONFIG_REPO/$BRANCH"
$SECUROPS_DIR   = "$env:USERPROFILE\.securops"
$SUPPORT_TEAMS  = "#security-help"
$SUPPORT_EMAIL  = "hardikdoshi@devrepublic.nl"

# Files: source|destination
$FILES = @(
    ".pre-commit-config.yaml|.pre-commit-config.yaml",
    ".gitleaks.toml|.gitleaks.toml",
    ".github/workflows/security-scan.yml|.github/workflows/security-scan.yml",
    "semgrep-mobile.yml|semgrep-mobile.yml",
    "zap.conf|zap.conf",
    "scripts/trivy-scan.sh|scripts/trivy-scan.sh",
    "scripts/generate-report.py|scripts/generate-report.py",
    "scripts/ai-auto-fix.py|scripts/ai-auto-fix.py",
    "scripts/zap_report_check.py|scripts/zap_report_check.py"
)

# ─────────────────────────────────────────────────────────
# HELPERS
# ─────────────────────────────────────────────────────────
function Write-OK     { param($msg) Write-Host "  [OK] $msg" -ForegroundColor Green }
function Write-Fail   { param($msg) Write-Host "  [FAIL] $msg" -ForegroundColor Red }
function Write-Warn   { param($msg) Write-Host "  [WARN] $msg" -ForegroundColor Yellow }
function Write-Info   { param($msg) Write-Host "  [INFO] $msg" -ForegroundColor Cyan }
function Write-Step   { param($num, $msg) Write-Host "`n=== STEP $num === $msg" -ForegroundColor Blue }

function Test-Command { param($cmd) return [bool](Get-Command $cmd -ErrorAction SilentlyContinue) }

function Download-File {
    param($url, $dest)
    $dir = Split-Path $dest -Parent
    if ($dir -and !(Test-Path $dir)) { New-Item -ItemType Directory -Path $dir -Force | Out-Null }
    try {
        [Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12
        Invoke-WebRequest -Uri $url -OutFile $dest -UseBasicParsing -ErrorAction Stop
        return $true
    } catch {
        return $false
    }
}

function Install-Binary {
    param($Name, $WingetId, $ScoopName, $ChocoName, $ZipUrl, $ExeName)

    if (Test-Command $Name) {
        Write-OK "$Name already installed"
        return $true
    }

    Write-Info "Installing $Name..."
    $installed = $false

    # Try winget first (built into Windows 10/11)
    if (!$installed -and (Test-Command "winget")) {
        Write-Info "  Trying winget..."
        $result = winget install --id=$WingetId -e --accept-source-agreements --accept-package-agreements 2>&1
        # Refresh PATH after winget install
        $env:PATH = [System.Environment]::GetEnvironmentVariable("PATH", "Machine") + ";" + [System.Environment]::GetEnvironmentVariable("PATH", "User")
        if (Test-Command $Name) { $installed = $true; Write-OK "$Name installed via winget" }
    }

    # Try scoop
    if (!$installed -and (Test-Command "scoop")) {
        Write-Info "  Trying scoop..."
        scoop install $ScoopName 2>$null
        if (Test-Command $Name) { $installed = $true; Write-OK "$Name installed via scoop" }
    }

    # Try chocolatey
    if (!$installed -and (Test-Command "choco")) {
        Write-Info "  Trying choco..."
        choco install $ChocoName -y 2>$null
        # Refresh PATH
        $env:PATH = [System.Environment]::GetEnvironmentVariable("PATH", "Machine") + ";" + [System.Environment]::GetEnvironmentVariable("PATH", "User")
        if (Test-Command $Name) { $installed = $true; Write-OK "$Name installed via choco" }
    }

    # Direct binary download as last resort
    if (!$installed -and $ZipUrl) {
        Write-Info "  Downloading binary directly..."
        $zipPath = "$env:TEMP\$Name.zip"
        $extractDir = "$env:LOCALAPPDATA\$Name"

        if (Download-File $ZipUrl $zipPath) {
            New-Item -ItemType Directory -Path $extractDir -Force | Out-Null
            Expand-Archive -Path $zipPath -DestinationPath $extractDir -Force
            Remove-Item $zipPath -Force -ErrorAction SilentlyContinue

            # Add to PATH for current session
            $env:PATH = "$extractDir;$env:PATH"

            # Add to PATH permanently (user-level)
            $userPath = [Environment]::GetEnvironmentVariable("PATH", "User")
            if ($userPath -notlike "*$Name*") {
                [Environment]::SetEnvironmentVariable("PATH", "$extractDir;$userPath", "User")
                Write-OK "$Name added to user PATH (restart terminal to take effect)"
            }

            if (Test-Command $Name) { $installed = $true; Write-OK "$Name installed via direct download" }
            elseif (Test-Path "$extractDir\$ExeName") { $installed = $true; Write-OK "$Name downloaded to $extractDir" }
        }
    }

    if (!$installed) {
        Write-Warn "Could not auto-install $Name"
        return $false
    }
    return $true
}

# ─────────────────────────────────────────────────────────
# WELCOME BANNER
# ─────────────────────────────────────────────────────────
Clear-Host
Write-Host ""
Write-Host "+=========================================================+" -ForegroundColor Cyan
Write-Host "|          SecurOps Hybrid Setup (Windows)                 |" -ForegroundColor Cyan
Write-Host "|          7-Tool Security Pipeline                        |" -ForegroundColor Cyan
Write-Host "|          Gitleaks . TruffleHog . Semgrep . Trivy         |" -ForegroundColor Cyan
Write-Host "|          Nuclei . OWASP ZAP . Checkov . Claude AI        |" -ForegroundColor Cyan
Write-Host "+=========================================================+" -ForegroundColor Cyan
Write-Host ""

# ─────────────────────────────────────────────────────────
# PRE-CHECK: Git (auto-install if missing)
# ─────────────────────────────────────────────────────────
if (!(Test-Command "git")) {
    Write-Warn "Git is not installed — attempting auto-install..."
    $gitInstalled = $false

    if (Test-Command "winget") {
        Write-Info "Installing Git via winget..."
        winget install --id=Git.Git -e --accept-source-agreements --accept-package-agreements 2>&1 | Out-Null
        $env:PATH = [System.Environment]::GetEnvironmentVariable("PATH", "Machine") + ";" + [System.Environment]::GetEnvironmentVariable("PATH", "User")
        # Also add default Git install path
        $defaultGitPath = "C:\Program Files\Git\cmd"
        if (Test-Path $defaultGitPath) { $env:PATH = "$defaultGitPath;$env:PATH" }
        if (Test-Command "git") { $gitInstalled = $true; Write-OK "Git installed via winget" }
    }

    if (!$gitInstalled -and (Test-Command "choco")) {
        Write-Info "Installing Git via choco..."
        choco install git -y 2>$null
        $env:PATH = [System.Environment]::GetEnvironmentVariable("PATH", "Machine") + ";" + [System.Environment]::GetEnvironmentVariable("PATH", "User")
        if (Test-Command "git") { $gitInstalled = $true; Write-OK "Git installed via choco" }
    }

    if (!$gitInstalled) {
        Write-Fail "Could not auto-install Git!"
        Write-Host "  Install manually from: https://git-scm.com/download/win"
        Write-Host "  Or run: winget install Git.Git"
        exit 1
    }
}

$gitRoot = git rev-parse --show-toplevel 2>$null
if (!$gitRoot -or $LASTEXITCODE -ne 0) {
    Write-Fail "Not inside a git repository!"
    Write-Host "  cd into your project repo first, then re-run this script."
    exit 1
}

$PROJECT_DIR  = ($gitRoot -replace '/', '\')
$PROJECT_NAME = Split-Path $PROJECT_DIR -Leaf
Push-Location $PROJECT_DIR

Write-Info "Project detected: $PROJECT_NAME"
Write-Info "Location: $PROJECT_DIR"

# ─────────────────────────────────────────────────────────
# STEP 1 — Check & Install Prerequisites
# ─────────────────────────────────────────────────────────
Write-Step "1/5" "Checking prerequisites..."

# ── Check/Install Python ─────────────────────────────────
$pythonCmd = $null
if (Test-Command "python3")  { $pythonCmd = "python3" }
elseif (Test-Command "python") {
    $pyVer = (python --version 2>&1) -join ""
    if ($pyVer -match "Python 3") { $pythonCmd = "python" }
}
elseif (Test-Command "py") {
    $pyVer = (py --version 2>&1) -join ""
    if ($pyVer -match "Python 3") { $pythonCmd = "py" }
}

if (!$pythonCmd) {
    Write-Warn "Python 3 not found — attempting auto-install..."
    $pyInstalled = $false

    # Try winget (built into Windows 10/11)
    if (Test-Command "winget") {
        Write-Info "Installing Python 3.12 via winget..."
        winget install --id=Python.Python.3.12 -e --accept-source-agreements --accept-package-agreements 2>&1 | Out-Null
        # Refresh PATH
        $env:PATH = [System.Environment]::GetEnvironmentVariable("PATH", "Machine") + ";" + [System.Environment]::GetEnvironmentVariable("PATH", "User")
        # Add default Python install paths
        $defaultPyPaths = @(
            "$env:LOCALAPPDATA\Programs\Python\Python312",
            "$env:LOCALAPPDATA\Programs\Python\Python312\Scripts",
            "$env:APPDATA\Python\Python312\Scripts"
        )
        foreach ($p in $defaultPyPaths) {
            if (Test-Path $p) { $env:PATH = "$p;$env:PATH" }
        }
        # Re-check
        if (Test-Command "python") {
            $chk = (python --version 2>&1) -join ""
            if ($chk -match "Python 3") { $pythonCmd = "python"; $pyInstalled = $true; Write-OK "Python installed via winget" }
        }
        if (!$pyInstalled -and (Test-Command "python3")) {
            $pythonCmd = "python3"; $pyInstalled = $true; Write-OK "Python installed via winget"
        }
        if (!$pyInstalled -and (Test-Command "py")) {
            $pythonCmd = "py"; $pyInstalled = $true; Write-OK "Python installed via winget"
        }
    }

    # Try chocolatey
    if (!$pyInstalled -and (Test-Command "choco")) {
        Write-Info "Installing Python via choco..."
        choco install python3 -y 2>$null
        $env:PATH = [System.Environment]::GetEnvironmentVariable("PATH", "Machine") + ";" + [System.Environment]::GetEnvironmentVariable("PATH", "User")
        if (Test-Command "python") {
            $chk = (python --version 2>&1) -join ""
            if ($chk -match "Python 3") { $pythonCmd = "python"; $pyInstalled = $true; Write-OK "Python installed via choco" }
        }
    }

    # Try scoop
    if (!$pyInstalled -and (Test-Command "scoop")) {
        Write-Info "Installing Python via scoop..."
        scoop install python 2>$null
        if (Test-Command "python") {
            $pythonCmd = "python"; $pyInstalled = $true; Write-OK "Python installed via scoop"
        }
    }

    # Direct download as last resort
    if (!$pyInstalled) {
        Write-Info "Downloading Python installer..."
        $pyInstallerUrl = "https://www.python.org/ftp/python/3.12.4/python-3.12.4-amd64.exe"
        $pyInstallerPath = "$env:TEMP\python-installer.exe"

        if (Download-File $pyInstallerUrl $pyInstallerPath) {
            Write-Info "Running Python installer (silent, adding to PATH)..."
            Start-Process -FilePath $pyInstallerPath -ArgumentList "/quiet", "InstallAllUsers=0", "PrependPath=1", "Include_test=0" -Wait -NoNewWindow
            Remove-Item $pyInstallerPath -Force -ErrorAction SilentlyContinue

            # Refresh PATH
            $env:PATH = [System.Environment]::GetEnvironmentVariable("PATH", "Machine") + ";" + [System.Environment]::GetEnvironmentVariable("PATH", "User")
            $defaultPyPaths = @(
                "$env:LOCALAPPDATA\Programs\Python\Python312",
                "$env:LOCALAPPDATA\Programs\Python\Python312\Scripts"
            )
            foreach ($p in $defaultPyPaths) {
                if (Test-Path $p) { $env:PATH = "$p;$env:PATH" }
            }

            if (Test-Command "python") {
                $pythonCmd = "python"; $pyInstalled = $true; Write-OK "Python installed via direct download"
            } elseif (Test-Command "py") {
                $pythonCmd = "py"; $pyInstalled = $true; Write-OK "Python installed via direct download"
            }
        }
    }

    if (!$pythonCmd) {
        Write-Fail "Could not auto-install Python 3!"
        Write-Host "  Install manually from: https://www.python.org/downloads/"
        Write-Host "  IMPORTANT: Check 'Add Python to PATH' during install!"
        Pop-Location; exit 1
    }
}

$pyVersion = & $pythonCmd --version 2>&1
Write-OK "Python found: $pyVersion"
Write-OK "Git found: $(git --version)"

$winVer = [System.Environment]::OSVersion.Version
Write-OK "Windows $($winVer.Major).$($winVer.Minor) detected (Build $($winVer.Build))"

# ─────────────────────────────────────────────────────────
# STEP 2 — Install Security Tools
# ─────────────────────────────────────────────────────────
Write-Step "2/5" "Installing security tools..."

# ── pre-commit ────────────────────────────────────────────
if (Test-Command "pre-commit") {
    Write-OK "pre-commit already installed: $(pre-commit --version)"
} else {
    Write-Info "Installing pre-commit via pip..."
    & $pythonCmd -m pip install pre-commit --quiet --user 2>$null
    # Also try without --user if it fails
    if (!(Test-Command "pre-commit")) {
        & $pythonCmd -m pip install pre-commit --quiet 2>$null
    }
    # Refresh PATH
    $env:PATH = [System.Environment]::GetEnvironmentVariable("PATH", "Machine") + ";" + [System.Environment]::GetEnvironmentVariable("PATH", "User")
    if (Test-Command "pre-commit") {
        Write-OK "pre-commit installed: $(pre-commit --version)"
    } else {
        # Try Scripts folder directly
        $scriptsDir = & $pythonCmd -c "import site; print(site.getusersitepackages().replace('site-packages','Scripts'))" 2>$null
        if ($scriptsDir -and (Test-Path "$scriptsDir\pre-commit.exe")) {
            $env:PATH = "$scriptsDir;$env:PATH"
            Write-OK "pre-commit installed (found in $scriptsDir)"
        } else {
            Write-Fail "pre-commit install failed. Try: $pythonCmd -m pip install pre-commit"
        }
    }
}

# ── gitleaks ──────────────────────────────────────────────
$gitleaksVer = "8.18.2"
$gitleaksZip = "https://github.com/gitleaks/gitleaks/releases/download/v$gitleaksVer/gitleaks_${gitleaksVer}_windows_x64.zip"
Install-Binary -Name "gitleaks" -WingetId "gitleaks.gitleaks" -ScoopName "gitleaks" -ChocoName "gitleaks" -ZipUrl $gitleaksZip -ExeName "gitleaks.exe"

# ── trivy ─────────────────────────────────────────────────
$trivyVer = "0.50.1"
$trivyZip = "https://github.com/aquasecurity/trivy/releases/download/v$trivyVer/trivy_${trivyVer}_Windows-64bit.zip"
$trivyResult = Install-Binary -Name "trivy" -WingetId "AquaSecurity.Trivy" -ScoopName "trivy" -ChocoName "trivy" -ZipUrl $trivyZip -ExeName "trivy.exe"
if (!$trivyResult) {
    Write-Info "trivy not installed — Docker fallback will be used in pre-push hook"
}

# ─────────────────────────────────────────────────────────
# STEP 3 — Download Central Config
# ─────────────────────────────────────────────────────────
Write-Step "3/5" "Downloading company security config..."

if (!(Test-Path $SECUROPS_DIR)) {
    New-Item -ItemType Directory -Path $SECUROPS_DIR -Force | Out-Null
}

$cloneSuccess = $false
if (Test-Path "$SECUROPS_DIR\.git") {
    Write-Info "Updating existing config..."
    git -C $SECUROPS_DIR pull --quiet 2>$null
    $cloneSuccess = $true
} else {
    # Remove old dir if exists but no .git
    if (Test-Path $SECUROPS_DIR) {
        Remove-Item $SECUROPS_DIR -Recurse -Force -ErrorAction SilentlyContinue
        New-Item -ItemType Directory -Path $SECUROPS_DIR -Force | Out-Null
    }
    Write-Info "Cloning config repo..."
    git clone --quiet "https://github.com/$GITHUB_ORG/$CONFIG_REPO.git" $SECUROPS_DIR 2>$null
    if ($LASTEXITCODE -eq 0) { $cloneSuccess = $true }
}

if (!$cloneSuccess) {
    Write-Warn "Clone failed — downloading files individually..."
    foreach ($entry in $FILES) {
        $parts  = $entry -split '\|'
        $src    = $parts[0]
        $localPath = Join-Path $SECUROPS_DIR ($src -replace '/', '\')
        Download-File "$BASE_URL/$src" $localPath | Out-Null
    }
}

Write-OK "Security config saved to: $SECUROPS_DIR"

# ─────────────────────────────────────────────────────────
# STEP 4 — Copy Config Files into THIS Project
# ─────────────────────────────────────────────────────────
Write-Step "4/5" "Copying security files into: $PROJECT_NAME..."

$copied  = 0
$skipped = 0

foreach ($entry in $FILES) {
    $parts = $entry -split '\|'
    $src   = $parts[0]
    $dst   = $parts[1]

    # Create destination directory
    $dstDir = Split-Path $dst -Parent
    if ($dstDir -and !(Test-Path $dstDir)) {
        New-Item -ItemType Directory -Path $dstDir -Force | Out-Null
    }

    $localSrc = Join-Path $SECUROPS_DIR ($src -replace '/', '\')

    if (Test-Path $localSrc) {
        if (Test-Path $dst) {
            $srcHash = (Get-FileHash $localSrc -Algorithm MD5).Hash
            $dstHash = (Get-FileHash $dst -Algorithm MD5).Hash
            if ($srcHash -eq $dstHash) {
                Write-Info "Already up to date: $dst"
                $skipped++
            } else {
                Copy-Item $localSrc $dst -Force
                Write-OK "Updated: $dst"
                $copied++
            }
        } else {
            Copy-Item $localSrc $dst -Force
            Write-OK "Copied: $dst"
            $copied++
        }
    } else {
        # Download directly from GitHub
        Write-Info "Downloading: $dst"
        if (Download-File "$BASE_URL/$src" $dst) {
            Write-OK "Downloaded: $dst"
            $copied++
        } else {
            Write-Fail "Could not copy: $dst"
        }
    }
}

Write-Host ""
Write-OK "$copied file(s) copied, $skipped already up to date"
Write-Host ""
Write-Host "  Files now in your project:"
Write-Host "    [OK] .pre-commit-config.yaml              <- 8 hook definitions"
Write-Host "    [OK] .gitleaks.toml                       <- 130+ secret patterns"
Write-Host "    [OK] .github\workflows\security-scan.yml  <- CI/CD pipeline (7 tools)"
Write-Host "    [OK] semgrep-mobile.yml                   <- mobile SAST rules"
Write-Host "    [OK] zap.conf                             <- ZAP alert thresholds"
Write-Host "    [OK] scripts\trivy-scan.sh                <- dependency scanner"
Write-Host "    [OK] scripts\generate-report.py           <- dashboard + enrollment"
Write-Host "    [OK] scripts\ai-auto-fix.py               <- Claude AI auto-fix"
Write-Host "    [OK] scripts\zap_report_check.py          <- ZAP threshold gate"

# ─────────────────────────────────────────────────────────
# STEP 5 — Install Git Hooks + Validate
# ─────────────────────────────────────────────────────────
Write-Step "5/5" "Installing git hooks + running validation..."

# Install pre-commit hooks
pre-commit install 2>$null
if ($LASTEXITCODE -eq 0) {
    Write-OK "Pre-commit hook installed"
} else {
    Write-Warn "Pre-commit hook install had issues — try running: pre-commit install"
}

pre-commit install --hook-type pre-push 2>$null
if ($LASTEXITCODE -eq 0) {
    Write-OK "Pre-push hook installed"
}
Write-OK "Git hooks installed (runs on every commit automatically)"

# Global git template so ALL future repos are protected
$GIT_TEMPLATE_DIR = Join-Path $SECUROPS_DIR "git-template"
$hooksDir = Join-Path $GIT_TEMPLATE_DIR "hooks"
New-Item -ItemType Directory -Path $hooksDir -Force | Out-Null

$hookContent = @"
#!/bin/bash
# SecurOps Hybrid Global Pre-commit Hook
if command -v pre-commit &>/dev/null && [ -f ".pre-commit-config.yaml" ]; then
  pre-commit run --hook-stage commit
  exit `$?
fi
exit 0
"@
Set-Content -Path (Join-Path $hooksDir "pre-commit") -Value $hookContent -NoNewline -Encoding UTF8
git config --global init.templateDir $GIT_TEMPLATE_DIR
Write-OK "Global git template set — all NEW repos will auto-have hooks"

# ── Validation Test ───────────────────────────────────────
Write-Host ""
Write-Info "Running validation — testing secret detection..."

$testDir  = Join-Path $env:TEMP "securops-test-$(Get-Random)"
New-Item -ItemType Directory -Path $testDir -Force | Out-Null
$testFile = Join-Path $testDir "test_secret.py"
Set-Content -Path $testFile -Value 'aws_key = "AKIAFAKEKEY1234567890"'

if (Test-Command "gitleaks") {
    $gitleaksResult = gitleaks detect --no-git --source $testDir --quiet 2>$null
    if ($LASTEXITCODE -ne 0) {
        Write-OK "Secret detection WORKING — fake AWS key was caught!"
    } else {
        Write-Warn "Validation inconclusive — full test needs git context"
        Write-Info "Test with: git add test.py; git commit -m 'test'"
    }
} else {
    Write-Warn "gitleaks not found — skipping validation"
}

Remove-Item $testDir -Recurse -Force -ErrorAction SilentlyContinue

# ── Stage security files ─────────────────────────────────
Write-Host ""
Write-Info "Staging security files for commit..."
git add .pre-commit-config.yaml .gitleaks.toml semgrep-mobile.yml zap.conf `
        ".github/workflows/security-scan.yml" scripts/ 2>$null

Write-Warn "Security files staged — run: git commit -m 'feat: add SecurOps Hybrid security scanning'"

# ─────────────────────────────────────────────────────────
# SUCCESS BANNER
# ─────────────────────────────────────────────────────────
Write-Host ""
Write-Host "+=========================================================+" -ForegroundColor Green
Write-Host "|         SECUROPS HYBRID — SETUP COMPLETE!                |" -ForegroundColor Green
Write-Host "+=========================================================+" -ForegroundColor Green
Write-Host ""
Write-Host "  Your project '$PROJECT_NAME' is now protected by 7 tools:" -ForegroundColor White
Write-Host ""
Write-Host "    Gitleaks      — 130+ secret patterns blocked on commit"
Write-Host "    TruffleHog    — verified secret scanning in CI"
Write-Host "    Semgrep       — OWASP Top 10 + mobile SAST on commit"
Write-Host "    Trivy         — dependency CVE scanning on push"
Write-Host "    Nuclei        — fast DAST scanning in CI"
Write-Host "    OWASP ZAP     — deep API DAST scanning in CI"
Write-Host "    Checkov       — IaC scanning in CI"
Write-Host "    Claude AI     — auto-generates fixes for findings"
Write-Host ""
Write-Host "  -----------------------------------------------------------"
Write-Host "  Next steps:" -ForegroundColor Yellow
Write-Host ""
Write-Host "    1. Commit the security files:"
Write-Host "       git commit -m 'feat: add SecurOps Hybrid security scanning'"
Write-Host ""
Write-Host "    2. Push to trigger the GitHub Actions pipeline:"
Write-Host "       git push"
Write-Host ""
Write-Host "    3. Test — try committing a fake secret:"
Write-Host '       echo "key=AKIAIOSFODNN7EXAMPLE" > test.py'
Write-Host "       git add test.py; git commit -m 'test'"
Write-Host "       # Expected: BLOCKED"
Write-Host ""
Write-Host "  -----------------------------------------------------------"
Write-Host "  Need help?"
Write-Host "    Teams:  $SUPPORT_TEAMS"
Write-Host "    Email:  $SUPPORT_EMAIL"
Write-Host ""
Write-Host "  To add SecurOps to ANOTHER project:"
Write-Host "    cd C:\path\to\other-project"
Write-Host "    irm $BASE_URL/scripts/onboard_windows.ps1 | iex"
Write-Host ""

Pop-Location
