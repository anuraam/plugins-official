#!/usr/bin/env bash
# validate-prerequisites.sh
# Validates that the environment is ready for web-app-tester operations.
# Run as a PreToolUse hook before Bash tool executions.

set -euo pipefail

INPUT=$(cat)
COMMAND=$(echo "$INPUT" | grep -o '"command":"[^"]*"' | head -1 | cut -d'"' -f4 2>/dev/null || echo "")

# Check Python 3.10+ is available (required for Playwright Python and Webwright workflow)
if ! command -v python3 > /dev/null 2>&1; then
    echo '{"decision": "block", "reason": "python3 is not installed or not in PATH. Python 3.10+ is required to run Playwright tests via the Webwright workflow. Install Python from https://python.org — see docs/setup.md"}'
    exit 0
fi

PYTHON_MINOR=$(python3 -c "import sys; print(sys.version_info.major * 100 + sys.version_info.minor)" 2>/dev/null || echo "0")
if [ "$PYTHON_MINOR" -lt 310 ]; then
    echo '{"decision": "block", "reason": "Python 3.10+ is required but an older version was found. Upgrade Python — see docs/setup.md"}'
    exit 0
fi

# Check playwright Python package is available
if ! python3 -c "import playwright" > /dev/null 2>&1; then
    echo '{"decision": "block", "reason": "The playwright Python package is not installed. Run: pip install playwright && playwright install chromium — see docs/setup.md"}'
    exit 0
fi

# Validate .web-app-tester.json when present (warn, don't fail — authSetupCommand may create missing storage states)
if [ -f ".web-app-tester.json" ]; then
    if ! python3 -c "import json; json.load(open('.web-app-tester.json'))" > /dev/null 2>&1; then
        echo '{"decision": "block", "reason": ".web-app-tester.json exists but is not valid JSON. Fix or remove it — see docs/configuration.md"}'
        exit 0
    fi
    MISSING_STATES=$(python3 -c "
import json, os
cfg = json.load(open('.web-app-tester.json'))
missing = [p for env in cfg.get('environments', {}).values()
           for p in env.get('storageStates', {}).values()
           if not os.path.isfile(p)]
print(';'.join(missing))
" 2>/dev/null || echo "")
    if [ -n "$MISSING_STATES" ]; then
        echo "Warning: .web-app-tester.json references storage-state files that do not exist yet: ${MISSING_STATES}. The configured authSetupCommand may create them at run time." >&2
    fi
fi

# Detect platform from git remote
REMOTE_URL=$(git remote get-url origin 2>/dev/null || echo "")
if echo "$REMOTE_URL" | grep -q "github.com"; then
    PLATFORM="GitHub"
elif echo "$REMOTE_URL" | grep -qE "dev\.azure\.com|visualstudio\.com"; then
    PLATFORM="AzureDevOps"
else
    PLATFORM="Unknown"
fi

# --- GitHub platform checks ---
if [ "$PLATFORM" = "GitHub" ]; then
    # Only validate gh commands
    if ! echo "$COMMAND" | grep -qE "^gh "; then
        exit 0
    fi

    # Check gh CLI is installed
    if ! command -v gh > /dev/null 2>&1; then
        echo '{"decision": "block", "reason": "GitHub CLI (gh) is not installed or not in PATH. Install it: brew install gh (macOS), winget install GitHub.cli (Windows), or apt install gh (Linux)."}'
        exit 0
    fi

    # Check gh is authenticated (or GITHUB_TOKEN is set)
    if ! timeout 10s gh auth status > /dev/null 2>&1; then
        if [ -z "${GITHUB_TOKEN:-}" ]; then
            echo '{"decision": "block", "reason": "gh CLI is not authenticated and GITHUB_TOKEN is not set. Run: gh auth login — or export GITHUB_TOKEN=ghp_xxx."}'
            exit 0
        fi
    fi
fi

# --- Azure DevOps platform checks ---
if [ "$PLATFORM" = "AzureDevOps" ]; then
    # Only validate curl commands targeting Azure DevOps
    if ! echo "$COMMAND" | grep -qE "^curl "; then
        exit 0
    fi

    # Check curl is available
    if ! command -v curl > /dev/null 2>&1; then
        echo '{"decision": "block", "reason": "curl is not installed or not in PATH. curl is required for Azure DevOps API calls. Install it via your package manager."}'
        exit 0
    fi

    # Check AZURE-DEVOPS-TOKEN is set
    if [ -z "${AZURE-DEVOPS-TOKEN:-}" ]; then
        echo '{"decision": "block", "reason": "AZURE-DEVOPS-TOKEN is not set. Create a Personal Access Token in Azure DevOps (Work Items: Read+Write, Code: Read, Pull Requests: Read+Write) and export AZURE-DEVOPS-TOKEN=your_pat — see docs/setup.md"}'
        exit 0
    fi
fi

# All checks passed — allow the command to proceed
exit 0
