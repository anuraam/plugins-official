#!/usr/bin/env bash
# validate-prerequisites.sh
# Validates that the environment is ready for release note generation.
# Run as a PreToolUse hook before Bash tool executions.
#
# Reading  — git for commit history, tag resolution, and repo structure (all hosts)
# Writing  — gh (GitHub) to create/edit a GitHub Release, or
#            curl + AZURE-DEVOPS-TOKEN (Azure DevOps) to PUT a wiki page.
#            This agent never commits or pushes code.
#
# Credentials
#   GH_TOKEN / GITHUB-TOKEN  — used by `gh` for github.com remotes
#   AZURE-DEVOPS-TOKEN       — PAT for Azure DevOps wiki PUT,
#                              scope: Wiki (Read & Write), Pull Requests (Read)

set -euo pipefail

INPUT=$(cat)
COMMAND=$(echo "$INPUT" | grep -o '"command":"[^"]*"' | head -1 | cut -d'"' -f4 2>/dev/null || echo "")

# GitHub CLI — used to list merged PRs and create/edit GitHub Releases
if echo "$COMMAND" | grep -qE "(^|[[:space:]])gh[[:space:]]"; then
    if ! command -v gh > /dev/null 2>&1; then
        echo '{"decision": "block", "reason": "GitHub CLI (gh) is not installed or not in PATH. Install: https://cli.github.com — see docs/platform-setup.md"}'
        exit 0
    fi
    if ! git rev-parse --is-inside-work-tree > /dev/null 2>&1; then
        echo '{"decision": "block", "reason": "Not inside a git repository. gh release commands require a checked-out repo."}'
        exit 0
    fi

    # Platform-exclusive CLI: gh is for GitHub remotes only.
    # On Azure DevOps / generic remotes, gh will fail with auth prompts and
    # waste turns. Block early and point the orchestrator at the correct provider.
    REMOTE_URL=$(git remote get-url origin 2>/dev/null || echo "")
    if [ -n "$REMOTE_URL" ] && ! echo "$REMOTE_URL" | grep -q "github.com"; then
        if echo "$REMOTE_URL" | grep -qE "(dev\.azure\.com|visualstudio\.com)"; then
            echo '{"decision": "block", "reason": "gh CLI is for GitHub remotes only — this remote is Azure DevOps. Use curl + AZURE-DEVOPS-TOKEN per providers/azure-devops.md."}'
        else
            echo '{"decision": "block", "reason": "gh CLI is for GitHub remotes only — this remote is not GitHub. Write release notes to RELEASE_NOTES.md per providers/generic.md."}'
        fi
        exit 0
    fi

    exit 0
fi

# curl to Azure DevOps REST — require AZURE-DEVOPS-TOKEN, with a token-name hygiene check.
# Some upstream environments export the token as AZURE-DEVOPS-TOKEN (with hyphens),
# which is not a valid bash identifier and cannot be referenced as $AZURE-DEVOPS-TOKEN.
# Detect that and surface a clear, actionable error instead of a silent 401 on the
# wiki PUT call.
if echo "$COMMAND" | grep -qE "curl.*(dev\.azure\.com|visualstudio\.com|app\.vssps\.visualstudio\.com)"; then
    if [ -z "${AZURE-DEVOPS-TOKEN:-}" ]; then
        if env | grep -q '^AZURE-DEVOPS-TOKEN='; then
            echo '{"decision": "block", "reason": "Found AZURE-DEVOPS-TOKEN (with hyphens) but AZURE-DEVOPS-TOKEN (with underscores) is empty. Bash cannot reference hyphenated names — re-export as: export AZURE-DEVOPS-TOKEN=\"$(env | sed -n s/^AZURE-DEVOPS-TOKEN=//p)\""}'
        else
            echo '{"decision": "block", "reason": "AZURE-DEVOPS-TOKEN is not set. Pass it at runtime: AZURE-DEVOPS-TOKEN=<pat> claude ... (see docs/platform-setup.md)"}'
        fi
        exit 0
    fi
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
    echo '{"decision": "block", "reason": "Not inside a git repository. Release note generation requires a checked-out git project."}'
    exit 0
fi

# Warn (but do not block) if a tag-related command runs and HEAD has no tag
if echo "$COMMAND" | grep -qE "git tag"; then
    TAGS_AT_HEAD=$(git tag --points-at HEAD 2>/dev/null | wc -l | tr -d ' ')
    if [ "$TAGS_AT_HEAD" = "0" ]; then
        echo '{"decision": "approve", "reason": "No tag found at HEAD. If this is a manual invocation, pass the tag explicitly: /release-notes <tag>. Tag resolution will proceed from git tag --sort=-version:refname."}'
    fi
fi

# All checks passed — allow the command to proceed
exit 0
