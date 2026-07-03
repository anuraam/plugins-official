#!/usr/bin/env bash
# post-start-comment.sh — posts the "review in progress" comment.
#
# Reads everything it needs from /tmp/pr_review_state.json (written by gather-context.sh) —
# does not depend on any shell variable surviving from another Bash call.
#
# Usage: bash "${CLAUDE_PLUGIN_ROOT}/scripts/post-start-comment.sh"
# Non-fatal by design: a failure here prints a warning and exits 0 — the review should
# still proceed even if this cosmetic comment can't be posted.

set -u
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
STATE_FILE="${PR_REVIEW_STATE_FILE:-/tmp/pr_review_state.json}"

if [ ! -f "$STATE_FILE" ]; then
  echo "WARN: $STATE_FILE not found — run gather-context.sh first. Skipping start comment." >&2
  exit 0
fi

PLATFORM=$(python3 -c "import json; print(json.load(open('$STATE_FILE'))['platform'])")

case "$PLATFORM" in
  azuredevops)
    source "$SCRIPT_DIR/lib/azure-devops.sh"
    eval "$(python3 -c "
import json, shlex
d = json.load(open('$STATE_FILE'))
a = d['azure']
def e(v): return shlex.quote(str(v))
print('AZURE_ORG=' + e(a['org']))
print('AZURE_PROJECT=' + e(a['project']))
print('AZURE_REPO=' + e(a['repo']))
print('API_BASE=' + e(a['api_base']))
print('PR_ID=' + e(d['pr_id']))
")"
    cat > /tmp/pr_thread_body.md <<'BODY'
**PR review in progress**

I'm running a comprehensive review covering code quality, security, test coverage, and performance. The full results will be posted as a review comment when complete — this may take a few minutes.
BODY
    ado_post_comment_thread /tmp/pr_thread_body.md || echo "WARN: could not post start comment — continuing." >&2
    ;;
  github)
    source "$SCRIPT_DIR/lib/github.sh"
    eval "$(python3 -c "
import json, shlex
d = json.load(open('$STATE_FILE'))
def e(v): return shlex.quote(str(v))
print('PR_NUMBER=' + e(d['pr_number']))
")"
    cat > /tmp/pr_thread_body.md <<'BODY'
🔍 **PR review in progress**

I'm running a comprehensive review covering code quality, security, test coverage, and performance. The full results will be posted as a review comment when complete — this may take a few minutes.
BODY
    gh_post_pr_comment /tmp/pr_thread_body.md || echo "WARN: could not post start comment — continuing." >&2
    ;;
  *)
    echo "No PR API for platform '$PLATFORM' — skipping start comment."
    ;;
esac
