#!/usr/bin/env bash
# notify-push.sh
# PostToolUse hook — runs after every Bash tool execution.
# If the command was a git push, outputs the remote branch URL for confirmation.

set -euo pipefail

# Real JSON parse, not a quote-blind grep — see validate-prerequisites.sh for why the old
# `"command":"[^"]*"` extraction silently truncates on any embedded `"` (e.g. a quoted commit
# message pushed just before this hook fires).
INPUT=$(cat)
COMMAND=$(printf '%s' "$INPUT" | python3 -c "
import json, sys
try:
    data = json.load(sys.stdin)
    print(data.get('tool_input', {}).get('command', ''))
except Exception:
    print('')
")

# Only act on git push commands
if ! echo "$COMMAND" | grep -qE "^git push"; then
    exit 0
fi

# Resolve the remote URL and current branch for a helpful confirmation message
REMOTE=$(git remote get-url origin 2>/dev/null || echo "unknown remote")
BRANCH=$(git rev-parse --abbrev-ref HEAD 2>/dev/null || echo "unknown branch")
COMMIT=$(git log -1 --oneline 2>/dev/null || echo "")

echo "Push complete — branch '${BRANCH}' pushed to ${REMOTE}"
echo "Latest commit: ${COMMIT}"

if echo "$REMOTE" | grep -q "github.com"; then
    echo "Platform: GitHub (providers/github.md)"
elif echo "$REMOTE" | grep -qE "dev.azure.com|visualstudio.com"; then
    echo "Platform: Azure DevOps (providers/azure-devops.md)"
else
    echo "Platform: Generic — report will be written to pr-review-report.md (providers/generic.md)"
fi
