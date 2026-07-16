#!/usr/bin/env bash
# validate-prerequisites.sh
# Validates that the environment is ready to update documentation for a PR.
# Run as a PreToolUse hook before Bash tool executions.
#
# Credentials
#   GIT_TOKEN          — used by git push for HTTPS authentication (GitHub / generic)
#   AZURE_DEVOPS_TOKEN — used by git push and REST API on Azure DevOps remotes

set -euo pipefail

INPUT=$(cat)
COMMAND=$(echo "$INPUT" | grep -o '"command":"[^"]*"' | head -1 | cut -d'"' -f4 2>/dev/null || echo "")

# GitHub CLI — used for fetching PR metadata, diffs, posting comments, opening follow-up PRs
if echo "$COMMAND" | grep -qE "^gh "; then
    if ! command -v gh > /dev/null 2>&1; then
        echo '{"decision": "block", "reason": "GitHub CLI (gh) is not installed or not in PATH. Install: https://cli.github.com — see docs/platform-setup.md"}'
        exit 0
    fi
    if ! git rev-parse --is-inside-work-tree > /dev/null 2>&1; then
        echo '{"decision": "block", "reason": "Not inside a git repository. gh commands require a checked-out repo."}'
        exit 0
    fi
    if ! timeout 10s gh auth status > /dev/null 2>&1; then
        if [ -z "${GITHUB_TOKEN:-}" ] && [ -z "${GH_TOKEN:-}" ]; then
            echo '{"decision": "block", "reason": "gh CLI is not authenticated and neither GITHUB_TOKEN nor GH_TOKEN is set. Run: gh auth login — or export GITHUB_TOKEN=ghp_xxx. See docs/platform-setup.md"}'
            exit 0
        fi
    fi
    exit 0
fi

# Azure DevOps REST calls via curl
if echo "$COMMAND" | grep -qE "^curl.*(dev\.azure\.com|visualstudio\.com)"; then
    if [ -z "${AZURE_DEVOPS_TOKEN:-}" ]; then
        echo '{"decision": "block", "reason": "AZURE_DEVOPS_TOKEN is not set. Pass it at runtime: AZURE_DEVOPS_TOKEN=<pat> claude ... (see docs/platform-setup.md)"}'
        exit 0
    fi
    exit 0
fi

# Only validate git commands beyond this point
if ! echo "$COMMAND" | grep -qE "^git "; then
    exit 0
fi

# Check: git is available
if ! command -v git > /dev/null 2>&1; then
    echo '{"decision": "block", "reason": "git is not installed or not in PATH."}'
    exit 0
fi

# Check: must be inside a git repository
if ! git rev-parse --is-inside-work-tree > /dev/null 2>&1; then
    echo '{"decision": "block", "reason": "Not inside a git repository. Documentation updates require a git project."}'
    exit 0
fi

# For commit operations — require git identity to be set
if echo "$COMMAND" | grep -qE "^git commit"; then
    if [ -z "$(git config user.name 2>/dev/null)" ]; then
        echo '{"decision": "block", "reason": "git user.name is not set. Run: git config --global user.name \"Your Name\""}'
        exit 0
    fi
    if [ -z "$(git config user.email 2>/dev/null)" ]; then
        echo '{"decision": "block", "reason": "git user.email is not set. Run: git config --global user.email \"you@example.com\""}'
        exit 0
    fi
fi

# For push operations — require a remote and a token
if echo "$COMMAND" | grep -qE "^git push"; then
    if ! git remote | grep -q .; then
        echo '{"decision": "block", "reason": "No git remote configured. Add a remote with: git remote add origin <url>"}'
        exit 0
    fi

    REMOTE_URL=$(git remote get-url origin 2>/dev/null || echo "")

    # Only validate that the required token is present. The token is injected into
    # the push itself (via `git -c url.<...>.insteadOf ... push`) by the command flow,
    # NOT here: this hook runs in a separate process, so any variables it exports do
    # not reach the actual `git push` invocation.
    if echo "$REMOTE_URL" | grep -qE "(dev\.azure\.com|visualstudio\.com)"; then
        if [ -z "${AZURE_DEVOPS_TOKEN:-}" ]; then
            echo '{"decision": "block", "reason": "AZURE_DEVOPS_TOKEN is not set. Pass it at runtime: AZURE_DEVOPS_TOKEN=<pat> claude ... (see docs/platform-setup.md)"}'
            exit 0
        fi
    else
        if [ -z "${GIT_TOKEN:-}" ]; then
            echo '{"decision": "block", "reason": "GIT_TOKEN is not set. Pass it at runtime: GIT_TOKEN=<token> claude ... (see docs/platform-setup.md)"}'
            exit 0
        fi
    fi
fi

# All checks passed — allow the command to proceed
exit 0
