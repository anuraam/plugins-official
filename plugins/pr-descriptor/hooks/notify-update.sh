#!/usr/bin/env bash
# notify-update.sh
# PostToolUse hook — runs after every Bash tool execution.
# If the command fully replaced a PR's title/description (gh pr edit on
# GitHub, or an Azure DevOps PATCH to .../pullrequests/{id}), prints a
# confirmation line. No-op for any other command.

set -euo pipefail

INPUT=$(cat)
COMMAND=$(echo "$INPUT" | grep -o '"command":"[^"]*"' | head -1 | cut -d'"' -f4 2>/dev/null || echo "")

REMOTE=$(git remote get-url origin 2>/dev/null || echo "unknown remote")

# GitHub: gh pr edit <number> --title ... --body-file ...
if echo "$COMMAND" | grep -qE "(^|[[:space:]])gh[[:space:]]+pr[[:space:]]+edit"; then
    echo "PR description replaced via gh pr edit on ${REMOTE}"
    exit 0
fi

# Azure DevOps: curl -X PATCH .../pullrequests/{id}?api-version=...
if echo "$COMMAND" | grep -qE "curl.*-X[[:space:]]+PATCH.*pullrequests/"; then
    echo "PR description replaced via Azure DevOps PATCH on ${REMOTE}"
    exit 0
fi

# No-op for any other command
exit 0
