#!/usr/bin/env bash
# notify-push.sh
# PostToolUse hook — runs after every Bash tool execution.
# If the command was a git push from an `arch/docs-*` branch,
# outputs a confirmation and a platform-specific next-step hint for opening the docs PR.

set -euo pipefail

INPUT=$(cat)
COMMAND=$(echo "$INPUT" | grep -o '"command":"[^"]*"' | head -1 | cut -d'"' -f4 2>/dev/null || echo "")

if ! echo "$COMMAND" | grep -qE "^git push"; then
    exit 0
fi

REMOTE=$(git remote get-url origin 2>/dev/null || echo "unknown remote")
BRANCH=$(git rev-parse --abbrev-ref HEAD 2>/dev/null || echo "unknown branch")
COMMIT=$(git log -1 --oneline 2>/dev/null || echo "")

echo "Push complete — branch '${BRANCH}' pushed to ${REMOTE}"
echo "Latest commit: ${COMMIT}"

if ! echo "${BRANCH}" | grep -qE "^arch/docs-"; then
    exit 0
fi

if echo "$REMOTE" | grep -q "github.com"; then
    echo "Next step: open or update the docs PR with 'gh pr create' (see providers/github.md)."
elif echo "$REMOTE" | grep -qE "dev.azure.com|visualstudio.com"; then
    echo "Next step: open or update the docs PR via Azure DevOps REST API (see providers/azure-devops.md)."
else
    echo "Next step: write arch-docs-pr-body.md and open the docs PR manually on your git host (see providers/generic.md)."
fi
