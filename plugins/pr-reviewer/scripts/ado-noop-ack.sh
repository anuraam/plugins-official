#!/usr/bin/env bash
# ado-noop-ack.sh — post a no-op acknowledgment on a same-sha re-trigger.
#
# Why this exists as a real script: the cost gate in detect-review-mode.sh
# only has value if the acknowledgment it triggers is actually verified to
# post — a silent failure here means a re-triggered run looks like it did
# nothing at all, with no trace on the PR.
#
# Usage:
#   bash "${CLAUDE_PLUGIN_ROOT}/scripts/ado-noop-ack.sh"
#
# Inputs:
#   /tmp/pr_azure.env   — API_BASE, AZURE_REPO, PR_ID (from ado-start-comment.sh)
#   /tmp/pr_prior.env   — PRIOR_SUMMARY_THREAD_ID (from ado-detect-prior.sh)
#   /tmp/pr_state.env   — HEAD_SHA
#   AZURE_DEVOPS_TOKEN  — required (soft-fail if unset)
#
# Outputs:
#   None persisted — this is a terminal step (the caller exits after it).
#   Deliberately posts NO marker: a no-op comment must never be mistaken for
#   a real review by the next run's prior-summary lookup.

set -euo pipefail

if [ -z "${AZURE_DEVOPS_TOKEN:-}" ]; then
  echo "WARN: AZURE_DEVOPS_TOKEN unset — skipping no-op acknowledgment" >&2
  exit 0
fi

# shellcheck disable=SC1091
[ -f /tmp/pr_state.env ] && source /tmp/pr_state.env
# shellcheck disable=SC1091
[ -f /tmp/pr_azure.env ] && source /tmp/pr_azure.env
# shellcheck disable=SC1091
[ -f /tmp/pr_prior.env ] && source /tmp/pr_prior.env

PR_ID="${PR_ID:-${PR_NUMBER:-}}"
if [ -z "$PR_ID" ] || [ -z "${API_BASE:-}" ] || [ -z "${AZURE_REPO:-}" ]; then
  echo "WARN: no-op acknowledgment needs /tmp/pr_azure.env (API_BASE, AZURE_REPO, PR_ID) — skipping" >&2
  exit 0
fi

if [ -z "${PRIOR_SUMMARY_THREAD_ID:-}" ]; then
  echo "WARN: PRIOR_SUMMARY_THREAD_ID empty — cannot reply to a prior summary thread; skipping no-op acknowledgment (no comment will appear on the PR for this run)" >&2
  exit 0
fi

HEAD_SHA="${HEAD_SHA:-$(git rev-parse HEAD 2>/dev/null || true)}"

cat > /tmp/pr_noop_body.md <<BODY
No new commits since the last review (\`${HEAD_SHA:0:7}\`) — nothing to re-analyze. Push a commit to trigger a fresh review.
BODY

python3 - <<'PY' > /tmp/pr_noop_reply_payload.json
import json
print(json.dumps({"content": open('/tmp/pr_noop_body.md').read(), "commentType": 1}))
PY

RESP=$(curl -sS -w "\nHTTP_STATUS:%{http_code}" \
  -H "Content-Type: application/json" -u ":${AZURE_DEVOPS_TOKEN}" -X POST \
  --data @/tmp/pr_noop_reply_payload.json \
  "${API_BASE}/_apis/git/repositories/${AZURE_REPO}/pullRequests/${PR_ID}/threads/${PRIOR_SUMMARY_THREAD_ID}/comments?api-version=7.1" \
  || true)
STATUS=$(echo "$RESP" | sed -n 's/^HTTP_STATUS://p')
if echo "${STATUS:-}" | grep -qE '^2'; then
  echo "No-op acknowledgment posted on PR #${PR_ID} (HTTP $STATUS)"
else
  echo "WARN: no-op acknowledgment failed HTTP ${STATUS:-curl-error} — body: $(echo "$RESP" | sed '$d')" >&2
fi
