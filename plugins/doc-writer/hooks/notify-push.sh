#!/usr/bin/env bash
# notify-push.sh
# PostToolUse hook — runs after every Bash tool execution.
# If the command was a git push, outputs confirmation with branch and remote details.

set -euo pipefail

INPUT=$(cat)
COMMAND=$(echo "$INPUT" | grep -o '"command":"[^"]*"' | head -1 | cut -d'"' -f4 2>/dev/null || echo "")

# Only act on git push commands
if ! echo "$COMMAND" | grep -qE "^git push"; then
    exit 0
fi

REMOTE=$(git remote get-url origin 2>/dev/null || echo "unknown remote")
BRANCH=$(git rev-parse --abbrev-ref HEAD 2>/dev/null || echo "unknown branch")
COMMIT=$(git log -1 --oneline 2>/dev/null || echo "")

echo "Push complete — branch '${BRANCH}' pushed to ${REMOTE}"
echo "Latest commit: ${COMMIT}"

# Documentation pushes always land on a separate docs/pr-<n>-sync branch — never directly
# on the original PR's feature branch. The next step is always to open (or update) the
# companion documentation PR and then post the summary on the original PR.
if echo "${BRANCH}" | grep -qE '^docs/(pr-[0-9]+-sync|[^/]+-sync|pr-[0-9]+-followup)$'; then
    if echo "$REMOTE" | grep -q "github.com"; then
        echo "Next step: open the companion docs PR with 'gh pr create --base <PR head branch> --head ${BRANCH}', then post the summary on the original PR (see providers/github.md)."
    elif echo "$REMOTE" | grep -qE "dev.azure.com|visualstudio.com"; then
        echo "Next step: open the companion docs PR (POST .../pullrequests with sourceRefName=refs/heads/${BRANCH}, targetRefName=refs/heads/<PR head branch>), then post the summary thread on the original PR (see providers/azure-devops.md)."
    else
        echo "Next step: write the documentation update report to doc-update-report.md, including the manual merge instructions for ${BRANCH} → <PR head branch> (see providers/generic.md)."
    fi
else
    echo "WARN: unexpected branch '${BRANCH}' for a doc-writer push — doc-writer should push docs/pr-<n>-sync, not the original PR branch."
fi
