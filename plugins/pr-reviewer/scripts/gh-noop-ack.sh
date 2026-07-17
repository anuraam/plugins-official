#!/usr/bin/env bash
# gh-noop-ack.sh — post a no-op acknowledgment on a same-sha re-trigger.
#
# Why this exists as a real script: the cost gate in detect-review-mode.sh
# only has value if the acknowledgment it triggers is actually verified to
# post — a silent failure here means a re-triggered run looks like it did
# nothing at all, with no trace on the PR.
#
# Usage:
#   PR_NUMBER=123 bash "${CLAUDE_PLUGIN_ROOT}/scripts/gh-noop-ack.sh"
#
# Inputs:
#   /tmp/pr_state.env   — PR_NUMBER, HEAD_SHA
#   gh CLI authenticated
#
# Outputs:
#   None persisted — this is a terminal step (the caller exits after it).
#   Deliberately posts NO marker: a no-op comment must never be mistaken for
#   a real review by the next run's prior-summary lookup.

set -euo pipefail

# shellcheck disable=SC1091
[ -f /tmp/pr_state.env ] && source /tmp/pr_state.env

if ! command -v gh >/dev/null 2>&1; then
  echo "WARN: gh CLI not found — skipping no-op acknowledgment" >&2
  exit 0
fi

PR_NUMBER="${PR_NUMBER:-${PR_ID:-}}"
if [ -z "$PR_NUMBER" ]; then
  echo "WARN: PR_NUMBER unset — skipping no-op acknowledgment" >&2
  exit 0
fi

HEAD_SHA="${HEAD_SHA:-$(git rev-parse HEAD 2>/dev/null || true)}"
BODY="No new commits since the last review (\`${HEAD_SHA:0:7}\`) — nothing to re-analyze. Push a commit to trigger a fresh review."

if gh pr comment "$PR_NUMBER" --body "$BODY" >/dev/null 2>/tmp/pr_noop_err.txt; then
  echo "No-op acknowledgment posted on PR #${PR_NUMBER}"
else
  echo "WARN: no-op acknowledgment failed to post: $(cat /tmp/pr_noop_err.txt) — no comment will appear on the PR for this run" >&2
fi
