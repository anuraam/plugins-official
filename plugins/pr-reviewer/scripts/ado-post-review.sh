#!/usr/bin/env bash
# ado-post-review.sh — post vote + summary thread + inline findings to Azure DevOps.
#
# Why this exists as a real script (not just markdown): agents keep inventing shortened
# curl flows that abort before the summary posts. Run this file instead of retyping.
#
# Usage:
#   VERDICT="REQUEST CHANGES" REVIEW_MODE=initial bash "${CLAUDE_PLUGIN_ROOT}/scripts/ado-post-review.sh"
#
# Inputs:
#   /tmp/pr_azure.env              — from starting-comment / parse step (API_BASE, AZURE_REPO, PR_ID, …)
#   /tmp/pr_thread_body.md         — compiled report (fallback: /tmp/pr_review_summary.md)
#   /tmp/pr_inline_findings.jsonl  — one JSON object per finding (fallback: /tmp/pr_findings.jsonl)
#   VERDICT, REVIEW_MODE           — env vars
#   AZURE_DEVOPS_TOKEN             — required
#
# Optional: /tmp/pr_reconcile.json, /tmp/pr_external_reconcile.json

set -euo pipefail

: "${VERDICT:=NEEDS DISCUSSION}"
: "${REVIEW_MODE:=initial}"

# --- 0. Token ---
if [ -z "${AZURE_DEVOPS_TOKEN:-}" ]; then
  echo "ERROR: AZURE_DEVOPS_TOKEN unset — cannot post review" >&2
  exit 1
fi

# --- 1. Load API targets (from starting-comment step) or re-parse remote ---
if [ -f /tmp/pr_azure.env ]; then
  # shellcheck disable=SC1091
  source /tmp/pr_azure.env
else
  echo "WARN: /tmp/pr_azure.env missing — re-parsing remote" >&2
  REMOTE=$(git remote get-url origin)
  if echo "$REMOTE" | grep -qE '(ssh\.dev\.azure\.com|vs-ssh\.visualstudio\.com)'; then
    V3_PATH=$(echo "$REMOTE" | sed -E 's|^ssh://||; s|^[^@]+@||; s|^[^:/]+[:/]+||')
    REMOTE="https://dev.azure.com/$(echo "$V3_PATH" | cut -d/ -f2)/$(echo "$V3_PATH" | cut -d/ -f3)/_git/$(echo "$V3_PATH" | cut -d/ -f4)"
  fi
  REMOTE_CLEAN=$(echo "$REMOTE" | sed -E 's|https?://[^@]+@|https://|; s|\.git$||')
  AZURE_HOST=$(echo "$REMOTE_CLEAN" | awk -F/ '{print $3}')
  PATH_PARTS=$(echo "$REMOTE_CLEAN" | awk -F/ '{for (i=4; i<=NF; i++) print $i}')
  GIT_LINE=$(echo "$PATH_PARTS" | grep -nx '_git' | head -1 | cut -d: -f1 || true)
  [ -n "$GIT_LINE" ] || { echo "ERROR: not an Azure DevOps git URL" >&2; exit 1; }
  AZURE_PROJECT=$(echo "$PATH_PARTS" | sed -n "$((GIT_LINE - 1))p")
  AZURE_REPO=$(echo    "$PATH_PARTS" | sed -n "$((GIT_LINE + 1))p")
  if [ "$AZURE_HOST" = "dev.azure.com" ]; then
    AZURE_ORG=$(echo "$PATH_PARTS" | sed -n '1p'); PREFIX_START=2
    HOST_AND_ORG_PATH="https://dev.azure.com/${AZURE_ORG}"
  else
    AZURE_ORG=$(echo "$AZURE_HOST" | cut -d'.' -f1); PREFIX_START=1
    HOST_AND_ORG_PATH="https://${AZURE_HOST}"
  fi
  PROJECT_LINE=$((GIT_LINE - 1))
  if [ "$PROJECT_LINE" -gt "$PREFIX_START" ]; then
    AZURE_COLLECTION=$(echo "$PATH_PARTS" | sed -n "${PREFIX_START},$((PROJECT_LINE - 1))p" | tr '\n' '/' | sed 's|/$||')
    API_BASE="${HOST_AND_ORG_PATH}/${AZURE_COLLECTION}/${AZURE_PROJECT}"
  else
    AZURE_COLLECTION=""
    API_BASE="${HOST_AND_ORG_PATH}/${AZURE_PROJECT}"
  fi
fi
PR_ID="${PR_ID:-${PR_NUMBER:-}}"
if [ -z "$PR_ID" ]; then
  echo "ERROR: PR_ID unset — pass PR number as argument and set PR_NUMBER before posting" >&2
  exit 1
fi
echo "Posting to ${API_BASE}/_git/${AZURE_REPO}/pullrequest/${PR_ID}"

# --- 2. Normalize input files ---
if [ ! -f /tmp/pr_thread_body.md ] && [ -f /tmp/pr_review_summary.md ]; then
  cp /tmp/pr_review_summary.md /tmp/pr_thread_body.md
fi
if [ ! -f /tmp/pr_inline_findings.jsonl ] && [ -f /tmp/pr_findings.jsonl ]; then
  cp /tmp/pr_findings.jsonl /tmp/pr_inline_findings.jsonl
fi
[ -f /tmp/pr_thread_body.md ] || { echo "ERROR: /tmp/pr_thread_body.md missing" >&2; exit 1; }
touch /tmp/pr_inline_findings.jsonl
# Normalize pretty-printed / array / concatenated JSON into one-object-per-line JSONL
python3 - <<'PY'
import json
from pathlib import Path
src = Path('/tmp/pr_inline_findings.jsonl')
text = src.read_text().strip()
out = Path('/tmp/pr_inline_findings.normalized.jsonl')
findings = []
if text:
    try:
        data = json.loads(text)
        if isinstance(data, list):
            findings = data
        elif isinstance(data, dict):
            findings = [data]
    except json.JSONDecodeError:
        dec = json.JSONDecoder()
        i = 0
        while i < len(text):
            while i < len(text) and text[i].isspace():
                i += 1
            if i >= len(text):
                break
            obj, end = dec.raw_decode(text, i)
            findings.append(obj)
            i = end
with out.open('w') as f:
    for item in findings:
        f.write(json.dumps(item) + '\n')
print(f"Normalized {len(findings)} finding(s) for inline posting")
PY
mv /tmp/pr_inline_findings.normalized.jsonl /tmp/pr_inline_findings.jsonl

# --- 3. Map verdict → vote ---
case "${VERDICT}" in
  waitForAuthor|Waiting*|"WAITING FOR AUTHOR") VERDICT="REQUEST CHANGES" ;;
  Rejected|REJECT|"REQUEST_CHANGES"|"CHANGES REQUESTED") VERDICT="REQUEST CHANGES" ;;
  Approved|APPROVED|LGTM) VERDICT="APPROVE" ;;
  COMMENT) VERDICT="NEEDS DISCUSSION" ;;
esac
case "${PR_REVIEWER_BLOCK_ON_CRITICAL:-false}" in
  true|True|TRUE|1|yes|Yes|YES) BLOCK_ON_CRITICAL=true ;;
  *)                              BLOCK_ON_CRITICAL=false ;;
esac
case "${VERDICT}" in
  "APPROVE")                     VOTE=10  ;;
  "APPROVE WITH SUGGESTIONS")    VOTE=5   ;;
  "REQUEST CHANGES")
    if [ "$BLOCK_ON_CRITICAL" = "true" ]; then VOTE=-10; else VOTE=-5; fi
    ;;
  "NEEDS DISCUSSION")            VOTE=-5  ;;
  *)                             echo "WARN: unknown verdict '${VERDICT}' — defaulting to -5" >&2; VOTE=-5 ;;
esac

# --- 4. Cast vote (never abort posting on vote failure) ---
REVIEWER_ID=""
if [ -n "${AZURE_ORG:-}" ]; then
  REVIEWER_ID=$(curl -sS -u ":${AZURE_DEVOPS_TOKEN}" \
    "https://dev.azure.com/${AZURE_ORG}/_apis/connectionData?api-version=7.1-preview.1" \
    | python3 -c "import sys,json
try:
  d=json.load(sys.stdin)
  print((d.get('authenticatedUser') or d.get('authorizedUser') or {}).get('id',''))
except Exception:
  print('')" 2>/dev/null || true)
fi
if [ -z "$REVIEWER_ID" ]; then
  REVIEWER_ID=$(curl -sS -u ":${AZURE_DEVOPS_TOKEN}" \
    "https://app.vssps.visualstudio.com/_apis/profile/profiles/me?api-version=7.1" \
    | python3 -c "import sys,json
try:
  print(json.load(sys.stdin).get('id',''))
except Exception:
  print('')" 2>/dev/null || true)
fi
if [ -z "$REVIEWER_ID" ]; then
  echo "WARN: could not resolve reviewer ID — vote will not be cast; continuing with summary + inline" >&2
else
  VOTE_BODY=$(printf '{"vote": %s, "id": "%s"}' "$VOTE" "$REVIEWER_ID")
  VOTE_RESP=$(curl -sS -w "\nHTTP_STATUS:%{http_code}" \
    -H "Content-Type: application/json" -u ":${AZURE_DEVOPS_TOKEN}" -X PUT \
    -d "$VOTE_BODY" \
    "${API_BASE}/_apis/git/repositories/${AZURE_REPO}/pullRequests/${PR_ID}/reviewers/${REVIEWER_ID}?api-version=7.1" \
    || true)
  VOTE_STATUS=$(echo "$VOTE_RESP" | sed -n 's/^HTTP_STATUS://p')
  if ! echo "${VOTE_STATUS:-}" | grep -qE '^2'; then
    ADD_RESP=$(curl -sS -w "\nHTTP_STATUS:%{http_code}" \
      -H "Content-Type: application/json" -u ":${AZURE_DEVOPS_TOKEN}" -X POST \
      -d "[${VOTE_BODY}]" \
      "${API_BASE}/_apis/git/repositories/${AZURE_REPO}/pullRequests/${PR_ID}/reviewers?api-version=7.1" \
      || true)
    ADD_STATUS=$(echo "$ADD_RESP" | sed -n 's/^HTTP_STATUS://p')
    if echo "${ADD_STATUS:-}" | grep -qE '^2'; then
      echo "Vote ${VOTE} cast via reviewer add (HTTP $ADD_STATUS)"
    else
      echo "WARN: vote failed PUT HTTP ${VOTE_STATUS:-?} and POST HTTP ${ADD_STATUS:-?} — continuing" >&2
    fi
  else
    echo "Vote ${VOTE} cast (HTTP $VOTE_STATUS)"
  fi
fi

# --- 5. Post summary thread ---
# Azure PropertiesCollection expects {"$type","$value"} wrappers. Bare custom strings
# (pr-reviewer.kind / .sha) often 400 the whole create — which is why "in progress"
# (SupportsMarkdown only) succeeds while the summary comment never appears.
# Always embed a body marker too, so re-review detection still works if properties are stripped.
HEAD_SHA=$(git rev-parse HEAD)
export HEAD_SHA
# Embed body marker first (survives property stripping / retry modes)
python3 - <<'PY'
import os, pathlib
sha = os.environ["HEAD_SHA"]
path = pathlib.Path("/tmp/pr_thread_body.md")
body = path.read_text()
marker = f"\n\n<!-- pr-reviewer:v1 kind=summary sha={sha} -->\n"
if "pr-reviewer:v1 kind=summary" not in body:
    path.write_text(body.rstrip() + marker)
PY

# Seed first payload (full PropertiesCollection form), then retry in bash if needed
python3 - <<'PY' > /tmp/pr_thread_payload.json
import json, os, pathlib
sha = os.environ["HEAD_SHA"]
body = pathlib.Path("/tmp/pr_thread_body.md").read_text()
print(json.dumps({
    "comments": [{"content": body, "commentType": 1}],
    "status": "active",
    "properties": {
        "Microsoft.TeamFoundation.Discussion.SupportsMarkdown": {"$type": "System.Int32", "$value": 1},
        "pr-reviewer.kind": {"$type": "System.String", "$value": "summary"},
        "pr-reviewer.sha": {"$type": "System.String", "$value": sha},
    },
}))
PY

post_summary() {
  local label="$1"
  SUM_RESP=$(curl -sS -w "\nHTTP_STATUS:%{http_code}" \
    -H "Content-Type: application/json" -u ":${AZURE_DEVOPS_TOKEN}" -X POST \
    --data @/tmp/pr_thread_payload.json \
    "${API_BASE}/_apis/git/repositories/${AZURE_REPO}/pullRequests/${PR_ID}/threads?api-version=7.1" \
    || true)
  SUM_STATUS=$(echo "$SUM_RESP" | sed -n 's/^HTTP_STATUS://p')
  if echo "${SUM_STATUS:-}" | grep -qE '^2'; then
    echo "Summary thread posted (HTTP $SUM_STATUS, mode=$label)"
    return 0
  fi
  echo "WARN: summary thread failed HTTP ${SUM_STATUS:-curl-error} (mode=$label) — body: $(echo "$SUM_RESP" | sed '$d')" >&2
  return 1
}

if ! post_summary full; then
  python3 - <<'PY' > /tmp/pr_thread_payload.json
import json, pathlib
body = pathlib.Path("/tmp/pr_thread_body.md").read_text()
print(json.dumps({
    "comments": [{"content": body, "commentType": 1}],
    "status": "active",
    "properties": {
        "Microsoft.TeamFoundation.Discussion.SupportsMarkdown": {"$type": "System.Int32", "$value": 1},
    },
}))
PY
  if ! post_summary markdown; then
    python3 - <<'PY' > /tmp/pr_thread_payload.json
import json, pathlib
body = pathlib.Path("/tmp/pr_thread_body.md").read_text()
print(json.dumps({
    "comments": [{"content": body, "commentType": 1}],
    "status": "active",
}))
PY
    post_summary bare || true
  fi
fi

# --- 5b. Re-review: reconcile fixed findings ---
if [ "${REVIEW_MODE}" = "rereview" ] && [ -f /tmp/pr_reconcile.json ]; then
  : > /tmp/pr_resolved.log
  HEAD_SHA=$(git rev-parse HEAD)
  python3 -c "import json; [print(json.dumps(x)) for x in json.load(open('/tmp/pr_reconcile.json')).get('fixed',[])]" \
  | while IFS= read -r f; do
    [ -z "$f" ] && continue
    THREAD_ID=$(echo "$f" | python3 -c "import sys,json; print(json.load(sys.stdin)['thread_ref'])")
    cat > /tmp/pr_resolve_body.md <<BODY
✅ Resolved as of \`${HEAD_SHA}\`. This finding no longer reproduces against the current head.
BODY
    python3 - <<'PY' > /tmp/pr_resolve_payload.json
import json
print(json.dumps({"content": open('/tmp/pr_resolve_body.md').read(), "commentType": 1}))
PY
    curl -sS -o /dev/null -H "Content-Type: application/json" -u ":${AZURE_DEVOPS_TOKEN}" -X POST \
      --data @/tmp/pr_resolve_payload.json \
      "${API_BASE}/_apis/git/repositories/${AZURE_REPO}/pullRequests/${PR_ID}/threads/${THREAD_ID}/comments?api-version=7.1" || true
    RESP=$(curl -sS -w "\nHTTP_STATUS:%{http_code}" -H "Content-Type: application/json" \
      -u ":${AZURE_DEVOPS_TOKEN}" -X PATCH -d '{"status":"fixed"}' \
      "${API_BASE}/_apis/git/repositories/${AZURE_REPO}/pullRequests/${PR_ID}/threads/${THREAD_ID}?api-version=7.1" || true)
    STATUS=$(echo "$RESP" | sed -n 's/^HTTP_STATUS://p')
    if echo "${STATUS:-}" | grep -qE '^2'; then echo ok >> /tmp/pr_resolved.log; else echo "fail $THREAD_ID HTTP ${STATUS:-?}" >> /tmp/pr_resolved.log; fi
  done
  RESOLVED_OK=$(grep -c '^ok' /tmp/pr_resolved.log 2>/dev/null || echo 0)
  RESOLVED_FAIL=$(grep -c '^fail' /tmp/pr_resolved.log 2>/dev/null || echo 0)
  export RESOLVED_OK RESOLVED_FAIL
  echo "Reconciled: ${RESOLVED_OK} prior finding(s) resolved (${RESOLVED_FAIL} failed)"
fi

# --- 5c. Reply on addressed external threads — never resolve ---
EXTERNAL_REPLY_OK=0
EXTERNAL_REPLY_FAIL=0
: > /tmp/pr_external_replies.log
if [ -f /tmp/pr_external_reconcile.json ]; then
  HEAD_SHA=$(git rev-parse HEAD)
  python3 -c "import json; [print(json.dumps(x)) for x in json.load(open('/tmp/pr_external_reconcile.json')).get('addressed',[])]" \
  | while IFS= read -r f; do
    [ -z "$f" ] && continue
    THREAD_ID=$(echo "$f" | python3 -c "import sys,json; print(json.load(sys.stdin).get('thread_ref') or '')")
    [ -n "$THREAD_ID" ] || { echo "fail missing thread_ref" >> /tmp/pr_external_replies.log; continue; }
    cat > /tmp/pr_external_reply_body.md <<BODY
Looks addressed as of \`${HEAD_SHA}\` — leaving this thread open for the original author to resolve.
BODY
    python3 - <<'PY' > /tmp/pr_external_reply_payload.json
import json
print(json.dumps({"content": open('/tmp/pr_external_reply_body.md').read(), "commentType": 1}))
PY
    RESP=$(curl -sS -w "\nHTTP_STATUS:%{http_code}" -H "Content-Type: application/json" \
      -u ":${AZURE_DEVOPS_TOKEN}" -X POST --data @/tmp/pr_external_reply_payload.json \
      "${API_BASE}/_apis/git/repositories/${AZURE_REPO}/pullRequests/${PR_ID}/threads/${THREAD_ID}/comments?api-version=7.1" || true)
    STATUS=$(echo "$RESP" | sed -n 's/^HTTP_STATUS://p')
    if echo "${STATUS:-}" | grep -qE '^2'; then echo ok >> /tmp/pr_external_replies.log; else echo "fail $THREAD_ID HTTP ${STATUS:-?}" >> /tmp/pr_external_replies.log; fi
  done
  EXTERNAL_REPLY_OK=$(grep -c '^ok' /tmp/pr_external_replies.log 2>/dev/null || echo 0)
  EXTERNAL_REPLY_FAIL=$(grep -c '^fail' /tmp/pr_external_replies.log 2>/dev/null || echo 0)
  export EXTERNAL_REPLY_OK EXTERNAL_REPLY_FAIL
  echo "External replies: ${EXTERNAL_REPLY_OK} addressed thread(s) acknowledged (${EXTERNAL_REPLY_FAIL} failed) — threads left open"
fi

# --- 6. Post inline findings ---
INLINE_TOTAL=0
INLINE_OK=0
INLINE_FAIL=0
: > /tmp/pr_inline_failures.log

while IFS= read -r line; do
  [ -z "$line" ] && continue
  INLINE_TOTAL=$((INLINE_TOTAL + 1))
  echo "$line" > /tmp/pr_inline_finding.json
  if ! HEAD_SHA=$(git rev-parse HEAD) python3 - <<'PY' > /tmp/pr_thread_payload.json 2>>/tmp/pr_inline_failures.log
import json, os
f = json.load(open('/tmp/pr_inline_finding.json'))
file_path = f.get("file") or f.get("path") or ""
line_no = int(f.get("line") or f.get("line_number") or 0)
body = f.get("body") or f.get("comment") or ""
fid = f.get("fid") or ""
if not file_path or not line_no or not body:
    raise SystemExit("missing file/line/body in finding")
sha = os.environ["HEAD_SHA"]
if fid and "pr-reviewer:v1 kind=finding" not in body:
    body = body.rstrip() + f"\n\n<!-- pr-reviewer:v1 kind=finding fid={fid} sha={sha} -->\n"
print(json.dumps({
    "comments": [{"content": body, "commentType": 1}],
    "status": "active",
    "properties": {
        "Microsoft.TeamFoundation.Discussion.SupportsMarkdown": {"$type": "System.Int32", "$value": 1},
        "pr-reviewer.kind": {"$type": "System.String", "$value": "finding"},
        "pr-reviewer.fid": {"$type": "System.String", "$value": fid},
        "pr-reviewer.sha": {"$type": "System.String", "$value": sha},
    },
    "threadContext": {
        "filePath": "/" + file_path.lstrip("/"),
        "rightFileStart": {"line": line_no, "offset": 1},
        "rightFileEnd":   {"line": line_no, "offset": 1},
    },
}))
PY
  then
    INLINE_FAIL=$((INLINE_FAIL + 1))
    { echo "---"; echo "finding: $line"; echo "payload build failed"; } >> /tmp/pr_inline_failures.log
    continue
  fi
  RESP=$(curl -sS -w "\nHTTP_STATUS:%{http_code}" \
    -H "Content-Type: application/json" -u ":${AZURE_DEVOPS_TOKEN}" -X POST \
    --data @/tmp/pr_thread_payload.json \
    "${API_BASE}/_apis/git/repositories/${AZURE_REPO}/pullRequests/${PR_ID}/threads?api-version=7.1" \
    || true)
  STATUS=$(echo "$RESP" | sed -n 's/^HTTP_STATUS://p')
  if echo "${STATUS:-}" | grep -qE '^2'; then
    INLINE_OK=$((INLINE_OK + 1))
  else
    # Retry without custom properties (keep file anchor + markdown)
    if ! HEAD_SHA=$(git rev-parse HEAD) python3 - <<'PY' > /tmp/pr_thread_payload.json 2>>/tmp/pr_inline_failures.log
import json, os
f = json.load(open('/tmp/pr_inline_finding.json'))
file_path = f.get("file") or f.get("path") or ""
line_no = int(f.get("line") or f.get("line_number") or 0)
body = f.get("body") or f.get("comment") or ""
fid = f.get("fid") or ""
sha = os.environ["HEAD_SHA"]
if fid and "pr-reviewer:v1 kind=finding" not in body:
    body = body.rstrip() + f"\n\n<!-- pr-reviewer:v1 kind=finding fid={fid} sha={sha} -->\n"
print(json.dumps({
    "comments": [{"content": body, "commentType": 1}],
    "status": "active",
    "properties": {
        "Microsoft.TeamFoundation.Discussion.SupportsMarkdown": {"$type": "System.Int32", "$value": 1},
    },
    "threadContext": {
        "filePath": "/" + file_path.lstrip("/"),
        "rightFileStart": {"line": line_no, "offset": 1},
        "rightFileEnd":   {"line": line_no, "offset": 1},
    },
}))
PY
    then
      INLINE_FAIL=$((INLINE_FAIL + 1))
      { echo "---"; echo "finding: $line"; echo "HTTP ${STATUS:-?}:"; echo "$RESP" | sed '$d'; echo "retry payload build failed"; } >> /tmp/pr_inline_failures.log
      continue
    fi
    RESP2=$(curl -sS -w "\nHTTP_STATUS:%{http_code}" \
      -H "Content-Type: application/json" -u ":${AZURE_DEVOPS_TOKEN}" -X POST \
      --data @/tmp/pr_thread_payload.json \
      "${API_BASE}/_apis/git/repositories/${AZURE_REPO}/pullRequests/${PR_ID}/threads?api-version=7.1" \
      || true)
    STATUS2=$(echo "$RESP2" | sed -n 's/^HTTP_STATUS://p')
    if echo "${STATUS2:-}" | grep -qE '^2'; then
      INLINE_OK=$((INLINE_OK + 1))
      echo "WARN: inline posted without custom properties after HTTP ${STATUS:-?} (fid retained in body marker)" >&2
    else
      INLINE_FAIL=$((INLINE_FAIL + 1))
      { echo "---"; echo "finding: $line"; echo "HTTP ${STATUS:-?} then retry ${STATUS2:-?}:"; echo "$RESP2" | sed '$d'; } >> /tmp/pr_inline_failures.log
    fi
  fi
done < /tmp/pr_inline_findings.jsonl

echo "Inline comments: ${INLINE_OK}/${INLINE_TOTAL} posted (${INLINE_FAIL} failed)"
if [ "$INLINE_FAIL" -gt 0 ]; then
  echo "WARN: see /tmp/pr_inline_failures.log" >&2
  head -40 /tmp/pr_inline_failures.log >&2
fi
export INLINE_OK INLINE_FAIL INLINE_TOTAL
EXTERNAL_REPLY_OK="${EXTERNAL_REPLY_OK:-0}"
echo "Review posted on PR #${PR_ID}: ${VERDICT} — ${INLINE_OK}/${INLINE_TOTAL} inline — ${EXTERNAL_REPLY_OK} external replies — ${API_BASE}/_git/${AZURE_REPO}/pullrequest/${PR_ID}"
