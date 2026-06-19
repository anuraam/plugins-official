#!/usr/bin/env bash
# notify-update.sh
# PostToolUse hook — runs after every Bash tool execution.
# If the command published release notes (gh release create/edit on GitHub,
# or a curl PUT to an Azure DevOps wiki page), prints a confirmation line.
# No-op for any other command.

set -euo pipefail

INPUT=$(cat)
COMMAND=$(echo "$INPUT" | grep -o '"command":"[^"]*"' | head -1 | cut -d'"' -f4 2>/dev/null || echo "")

REMOTE=$(git remote get-url origin 2>/dev/null || echo "unknown remote")

# GitHub: gh release create <tag> ... or gh release edit <tag> ...
if echo "$COMMAND" | grep -qE "(^|[[:space:]])gh[[:space:]]+release[[:space:]]+(create|edit)"; then
    echo "Release notes published via gh release on ${REMOTE}"
    exit 0
fi

# Azure DevOps: curl -X PUT .../wiki/wikis/.../pages?...
if echo "$COMMAND" | grep -qE "curl.*-X[[:space:]]+PUT.*wiki.*pages"; then
    echo "Release notes published via Azure DevOps wiki PUT on ${REMOTE}"
    exit 0
fi

# No-op for any other command
exit 0
