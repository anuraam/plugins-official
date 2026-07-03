#!/usr/bin/env bash
# lib/github.sh — GitHub (gh CLI) helpers.
#
# Sourced by gather-context.sh, post-start-comment.sh, and post-review.sh.
# providers/github.md documents *why* — this file is the actual implementation.
#
# All functions run to completion within ONE process, so OWNER/REPO/PR_NUMBER are always
# freshly resolved in the same invocation that uses them.

# gh_parse_remote — sets OWNER, REPO from `git remote get-url origin`.
gh_parse_remote() {
  local remote
  remote=$(git remote get-url origin 2>/dev/null || echo "")
  if [ -z "$remote" ]; then
    echo "ERROR: could not resolve git remote 'origin'." >&2
    return 1
  fi
  _gh_parse_remote_url "$remote"
}

# _gh_parse_remote_url <url> — pure function, no git dependency, directly testable.
_gh_parse_remote_url() {
  local remote="$1"
  OWNER=$(echo "$remote" | sed 's|https://github.com/||;s|git@github.com:||' | cut -d'/' -f1)
  REPO=$(echo "$remote"  | sed 's|https://github.com/||;s|git@github.com:||' | cut -d'/' -f2 | sed 's|\.git$||')
  if [ -z "$OWNER" ] || [ -z "$REPO" ]; then
    echo "ERROR: could not parse owner/repo from remote: $remote" >&2
    return 1
  fi
  export OWNER REPO
}

# gh_resolve_pr_number [explicit-pr-number] — sets PR_NUMBER.
gh_resolve_pr_number() {
  local explicit="${1:-}"
  if [ -n "$explicit" ] && echo "$explicit" | grep -qE '^[0-9]+$'; then
    PR_NUMBER="$explicit"
    export PR_NUMBER
    return 0
  fi

  PR_NUMBER=$(gh pr list --head "$(git rev-parse --abbrev-ref HEAD)" --json number --jq '.[0].number' 2>/dev/null)
  if [ -z "$PR_NUMBER" ]; then
    PR_NUMBER=$(gh pr view --json number --jq '.number' 2>/dev/null)
  fi
  if [ -z "$PR_NUMBER" ]; then
    echo "ERROR: could not resolve a PR number for the current branch." >&2
    return 1
  fi
  export PR_NUMBER
}

# gh_fetch_pr_metadata — sets PR_TITLE, PR_DESC, PR_SOURCE, PR_TARGET, PR_AUTHOR.
gh_fetch_pr_metadata() {
  local json
  json=$(gh pr view "$PR_NUMBER" --json title,body,headRefName,baseRefName,author 2>/dev/null)
  if [ -z "$json" ]; then
    echo "WARN: PR metadata fetch failed — title/description will be blank." >&2
    PR_TITLE=""; PR_DESC=""; PR_SOURCE=""; PR_TARGET=""; PR_AUTHOR=""
  else
    eval "$(echo "$json" | python3 -c "
import sys, json, shlex
d = json.load(sys.stdin)
def esc(v): return shlex.quote(str(v))
print('PR_TITLE=' + esc(d.get('title','')))
print('PR_DESC=' + esc(d.get('body','') or ''))
print('PR_SOURCE=' + esc(d.get('headRefName','')))
print('PR_TARGET=' + esc(d.get('baseRefName','')))
print('PR_AUTHOR=' + esc((d.get('author') or {}).get('login','')))
")"
  fi
  export PR_TITLE PR_DESC PR_SOURCE PR_TARGET PR_AUTHOR
}

# gh_detect_prior_review — writes /tmp/pr_prior_findings.jsonl and sets PRIOR_SUMMARY_SHA
# + DETECTION_STATUS (ok|failed). Same call-in-one-process guarantee as ado_detect_prior_review.
gh_detect_prior_review() {
  gh api graphql -f query='
    query($owner:String!, $repo:String!, $pr:Int!) {
      repository(owner:$owner, name:$repo) {
        pullRequest(number:$pr) {
          reviewThreads(first:100) {
            nodes {
              id
              isResolved
              path
              comments(first:1) { nodes { databaseId body } }
            }
          }
        }
      }
    }' -F owner="$OWNER" -F repo="$REPO" -F pr="$PR_NUMBER" > /tmp/pr_review_threads.json 2>/tmp/pr_review_threads.err

  if [ ! -s /tmp/pr_review_threads.json ] || ! python3 -c "
import json
d = json.load(open('/tmp/pr_review_threads.json'))
assert d.get('data', {}).get('repository', {}).get('pullRequest') is not None
" 2>/dev/null; then
    echo "WARN: prior-review detection query failed or returned no pullRequest — treating as detection failure, not 'no prior review'. Raw response:" >&2
    cat /tmp/pr_review_threads.json >&2 2>/dev/null
    cat /tmp/pr_review_threads.err >&2 2>/dev/null
    DETECTION_STATUS="failed"
    : > /tmp/pr_prior_findings.jsonl
    PRIOR_SUMMARY_SHA=""
    export DETECTION_STATUS PRIOR_SUMMARY_SHA
    return 0
  fi

  python3 - <<'PY' > /tmp/pr_prior_findings.jsonl
import json, re
data = json.load(open('/tmp/pr_review_threads.json'))
threads = data['data']['repository']['pullRequest']['reviewThreads']['nodes']
pat = re.compile(r'<!--\s*pr-reviewer:v1\s+kind=finding\s+fid=(\S+)\s+sha=(\S+)\s*-->')
for t in threads:
    c = (t['comments']['nodes'] or [None])[0]
    if not c:
        continue
    m = pat.search(c['body'] or '')
    if not m:
        continue
    print(json.dumps({
        "fid": m.group(1),
        "status": "resolved" if t['isResolved'] else "open",
        "thread_ref": t['id'],
        "comment_ref": c['databaseId'],
        "file": t.get('path') or '',
    }))
PY

  # Most-recent summary marker sha — check both PR comments and PR reviews.
  PRIOR_SUMMARY_SHA=$(
    {
      gh api "repos/${OWNER}/${REPO}/issues/${PR_NUMBER}/comments" --paginate \
        --jq '.[].body' 2>/dev/null
      gh api "repos/${OWNER}/${REPO}/pulls/${PR_NUMBER}/reviews" --paginate \
        --jq '.[].body' 2>/dev/null
    } | grep -oE 'pr-reviewer:v1 kind=summary[^>]*sha=[0-9a-f]+' \
      | tail -1 | grep -oE 'sha=[0-9a-f]+' | cut -d= -f2
  )
  DETECTION_STATUS="ok"
  export DETECTION_STATUS PRIOR_SUMMARY_SHA
}

# gh_post_pr_comment <body-file> — plain issue-style PR comment (used for the "in progress" note).
gh_post_pr_comment() {
  local body_file="$1"
  gh pr comment "$PR_NUMBER" --body "$(cat "$body_file")"
}

# gh_post_review <flag> <body-file> — posts the PR-level review (summary + verdict), e.g.
# flag one of --approve / --request-changes / --comment.
gh_post_review() {
  local flag="$1" body_file="$2"
  gh pr review "$PR_NUMBER" "$flag" --body "$(cat "$body_file")"
}

# gh_post_inline_finding <body-file> <fid> <repo-relative-file> <line> <head-sha>
gh_post_inline_finding() {
  local body_file="$1" fid="$2" file_path="$3" line="$4" head_sha="$5"
  printf '\n\n<!-- pr-reviewer:v1 kind=finding fid=%s sha=%s -->\n' "$fid" "$head_sha" >> "$body_file"
  gh api "repos/${OWNER}/${REPO}/pulls/${PR_NUMBER}/comments" \
    --method POST \
    --field path="$file_path" \
    --field line="$line" \
    --field side="RIGHT" \
    --field commit_id="$head_sha" \
    --field body="$(cat "$body_file")"
}

# gh_reply_to_comment <comment-id> <body-file>
gh_reply_to_comment() {
  local comment_id="$1" body_file="$2"
  gh api "repos/${OWNER}/${REPO}/pulls/${PR_NUMBER}/comments/${comment_id}/replies" \
    --method POST --field body="$(cat "$body_file")"
}

# gh_resolve_thread <thread-node-id> — GraphQL resolveReviewThread (REST has no equivalent).
gh_resolve_thread() {
  local thread_id="$1"
  gh api graphql -f query='
      mutation($id:ID!) { resolveReviewThread(input:{threadId:$id}) { thread { isResolved } } }' \
      -F id="$thread_id" >/dev/null
}
