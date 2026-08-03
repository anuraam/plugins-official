# Provider: Azure DevOps

Use this provider when `git remote get-url origin` contains `dev.azure.com` or `visualstudio.com`.

## Prerequisites

Required environment variable:

| Variable | Purpose |
|---|---|
| `AZURE-DEVOPS-TOKEN` | PAT with `Code (Read & Write)` and `Pull Request Threads (Read & Write)` scopes |

Optional overrides:

| Variable | Default |
|---|---|
| `AZURE_ORG` | Parsed from remote URL |
| `AZURE_PROJECT` | Parsed from remote URL |
| `AZURE_REPO` | Parsed from remote URL |

---

## Parsing the Remote URL

**HTTPS format:** `https://dev.azure.com/{org}/{project}/_git/{repo}`

```bash
REMOTE=$(git remote get-url origin)
AZURE_ORG=$(echo "$REMOTE"     | sed 's|https://dev.azure.com/||' | cut -d'/' -f1)
AZURE_PROJECT=$(echo "$REMOTE" | sed 's|https://dev.azure.com/||' | cut -d'/' -f2)
AZURE_REPO=$(echo "$REMOTE"    | sed 's|.*/_git/||' | sed 's|\.git$||')
```

**Legacy format:** `https://{org}.visualstudio.com/{project}/_git/{repo}`

```bash
AZURE_ORG=$(echo "$REMOTE"     | sed 's|https://||' | cut -d'.' -f1)
AZURE_PROJECT=$(echo "$REMOTE" | cut -d'/' -f4)
AZURE_REPO=$(echo "$REMOTE"    | sed 's|.*/_git/||' | sed 's|\.git$||')
```

### API Base URL

```bash
if [[ "$REMOTE" =~ \.visualstudio\.com ]]; then
  API_BASE="https://${AZURE_ORG}.visualstudio.com/${AZURE_PROJECT}"
else
  API_BASE="https://dev.azure.com/${AZURE_ORG}/${AZURE_PROJECT}"
fi
```

Use `${API_BASE}` in every API call below.

---

## Resolving the PR Number

If no PR number was passed as an argument:

```bash
BRANCH=$(git rev-parse --abbrev-ref HEAD)

curl -s -u ":${AZURE-DEVOPS-TOKEN}" \
  "${API_BASE}/_apis/git/repositories/${AZURE_REPO}/pullrequests?searchCriteria.sourceRefName=refs/heads/${BRANCH}&searchCriteria.status=active&api-version=7.1" \
  | python3 -c "import sys,json; prs=json.load(sys.stdin)['value']; print(prs[0]['pullRequestId'] if prs else '')"
```

Store as `PR_ID`. If empty, the branch has no open PR — output a warning and stop.

---

## Markdown in PR Threads

Post via the **Git Pull Request Threads** API (`.../pullrequests/.../threads`). Set thread `properties` so the web UI renders Markdown:

| Key | Value |
|---|---|
| `Microsoft.TeamFoundation.Discussion.SupportsMarkdown` | `1` (integer) |

Include this `properties` object on **every** `POST .../threads` body.

---

## Comment Markers and Prior-Run Detection

Every comment this plugin posts **must** embed an invisible HTML marker so later runs can find, filter, and update it:

| Comment | Marker |
|---|---|
| Starting (progress) comment | `<!-- pr-comment-resolver:v1 progress -->` |
| Disposition summary | `<!-- pr-comment-resolver:v1 summary -->` |
| Thread replies | `<!-- pr-comment-resolver:v1 reply -->` |

Before posting anything, detect a prior run by scanning the PR's threads (one fetch — reuse it for the unresolved-thread step) for the markers in each thread's **first** comment:

```bash
curl -s -u ":${AZURE-DEVOPS-TOKEN}" \
  "${API_BASE}/_apis/git/repositories/${AZURE_REPO}/pullrequests/${PR_ID}/threads?api-version=7.1" \
  | python3 -c "
import sys, json
data = json.load(sys.stdin)
for kind in ('summary', 'progress'):
    for t in data.get('value', []):
        cs = t.get('comments', [])
        if cs and f'pr-comment-resolver:v1 {kind}' in (cs[0].get('content') or ''):
            print(f'{kind.upper()}_THREAD_ID={t[\"id\"]} {kind.upper()}_COMMENT_ID={cs[0][\"id\"]}')
"
```

Non-empty ids mean this is a **re-run**: update those comments in place (below) instead of posting duplicates. When updating the summary, keep its current `content` at hand so the existing run history can be carried forward.

---

## Posting the Starting Comment

First run (no prior progress thread):

```bash
curl -s -u ":${AZURE-DEVOPS-TOKEN}" \
  -X POST \
  -H "Content-Type: application/json" \
  "${API_BASE}/_apis/git/repositories/${AZURE_REPO}/pullrequests/${PR_ID}/threads?api-version=7.1" \
  -d '{"comments":[{"content":"🔧 **PR comment resolution in progress**\n\nI'\''m reviewing all unresolved threads and will apply actionable ones as commits, reply to the rest, and post a disposition summary when complete.\n<!-- pr-comment-resolver:v1 progress -->","commentType":1}],"status":"active","properties":{"Microsoft.TeamFoundation.Discussion.SupportsMarkdown":1}}'
```

Re-run (`PROGRESS_THREAD_ID` / `PROGRESS_COMMENT_ID` found) — update the existing comment instead:

```bash
curl -s -u ":${AZURE-DEVOPS-TOKEN}" \
  -X PATCH \
  -H "Content-Type: application/json" \
  "${API_BASE}/_apis/git/repositories/${AZURE_REPO}/pullrequests/${PR_ID}/threads/${PROGRESS_THREAD_ID}/comments/${PROGRESS_COMMENT_ID}?api-version=7.1" \
  -d '{"content":"🔧 **PR comment resolution in progress** (new run)\n\nI'\''m reviewing the threads opened since the last resolution run.\n<!-- pr-comment-resolver:v1 progress -->"}'
```

If posting fails, output a single warning line and continue.

---

## Fetching Unresolved Threads

```bash
curl -s -u ":${AZURE-DEVOPS-TOKEN}" \
  "${API_BASE}/_apis/git/repositories/${AZURE_REPO}/pullrequests/${PR_ID}/threads?api-version=7.1"
```

Parse the response with python3. For each thread where `status != "fixed"` and `status != "byDesign"` and `isDeleted != true`, applying two **self-exclusion** rules — skip the plugin's own threads (first comment carries any `pr-comment-resolver:v1` marker) and skip threads a prior run already dispositioned (last comment carries the `reply` marker with no human response after it; if a human commented after the plugin's reply, the thread is back in scope):

```python
import sys, json

data = json.load(sys.stdin)
for thread in data.get('value', []):
    if thread.get('isDeleted'):
        continue
    status = thread.get('status', '')
    if status in ('fixed', 'byDesign', 'wontFix'):
        continue
    thread_id = thread['id']
    comments = thread.get('comments', [])
    if not comments:
        continue
    if 'pr-comment-resolver:v1' in (comments[0].get('content') or ''):
        continue  # the plugin's own progress/summary/reply thread
    live = [c for c in comments if not c.get('isDeleted')]
    if live and 'pr-comment-resolver:v1 reply' in (live[-1].get('content') or ''):
        continue  # already dispositioned by a prior run, no human follow-up since
    first_comment = comments[0]
    body = first_comment.get('content', '')
    comment_id = first_comment.get('id')
    thread_context = thread.get('threadContext') or {}
    file_path = thread_context.get('filePath', '')
    line = (thread_context.get('rightFileStart') or {}).get('line')
    print(f"thread_id={thread_id} comment_id={comment_id} file={file_path} line={line}")
    print(f"body={body}")
```

Collect each thread's `id`, first comment `id`, `content`, `filePath`, and `line` for classification.

---

## Updating Thread Status (After Applying)

For **apply** threads — mark as resolved (`"fixed"`):

```bash
curl -s -u ":${AZURE-DEVOPS-TOKEN}" \
  -X PATCH \
  -H "Content-Type: application/json" \
  "${API_BASE}/_apis/git/repositories/${AZURE_REPO}/pullrequests/${PR_ID}/threads/${THREAD_ID}?api-version=7.1" \
  -d '{"status": "fixed"}'
```

---

## Posting a Reply to a Thread

Reply to an existing thread with a follow-up comment. Every reply ends with the reply marker — it is what lets the next run skip already-dispositioned threads:

```bash
curl -s -u ":${AZURE-DEVOPS-TOKEN}" \
  -X POST \
  -H "Content-Type: application/json" \
  "${API_BASE}/_apis/git/repositories/${AZURE_REPO}/pullrequests/${PR_ID}/threads/${THREAD_ID}/comments?api-version=7.1" \
  -d "$(python3 -c "
import json
print(json.dumps({
  'content': '${REPLY_TEXT}' + '\n<!-- pr-comment-resolver:v1 reply -->',
  'commentType': 1
}))
")"
```

---

## Linking to Commits

Azure DevOps does **not** autolink commit SHAs in PR comments — always render them as explicit markdown links:

```bash
COMMIT_SHA=$(git rev-parse HEAD)
SHORT_SHA=$(git rev-parse --short HEAD)
COMMIT_URL="${API_BASE}/_git/${AZURE_REPO}/commit/${COMMIT_SHA}"
# In comment bodies: [${SHORT_SHA}](${COMMIT_URL})
```

Markdown rendering requires the `Microsoft.TeamFoundation.Discussion.SupportsMarkdown` thread property (see "Markdown in PR Threads" above) — without it the link syntax shows as literal text.

---

## Posting the Disposition Summary

The summary body comes from `styles/report-template.md` and must include the `<!-- pr-comment-resolver:v1 summary -->` marker. Post it with thread status `closed` — the summary is informational, not a discussion to resolve, and an `active` summary thread shows up as an unresolved item in the PR UI.

First run (no prior summary thread) — post as a new thread:

```bash
curl -s -u ":${AZURE-DEVOPS-TOKEN}" \
  -X POST \
  -H "Content-Type: application/json" \
  "${API_BASE}/_apis/git/repositories/${AZURE_REPO}/pullrequests/${PR_ID}/threads?api-version=7.1" \
  -d "$(python3 -c "
import json, sys
body = sys.stdin.read()
print(json.dumps({
  'comments': [{'content': body, 'commentType': 1}],
  'status': 'closed',
  'properties': {'Microsoft.TeamFoundation.Discussion.SupportsMarkdown': 1}
}))
" <<'SUMMARY'
${SUMMARY_BODY}
SUMMARY
)"
```

Re-run (`SUMMARY_THREAD_ID` / `SUMMARY_COMMENT_ID` found) — **update the existing summary in place** rather than posting a second one. Rebuild the body with cumulative totals, append this run's line to the **Run History** section (carry forward the prior history captured during prior-run detection), then:

```bash
curl -s -u ":${AZURE-DEVOPS-TOKEN}" \
  -X PATCH \
  -H "Content-Type: application/json" \
  "${API_BASE}/_apis/git/repositories/${AZURE_REPO}/pullrequests/${PR_ID}/threads/${SUMMARY_THREAD_ID}/comments/${SUMMARY_COMMENT_ID}?api-version=7.1" \
  -d "$(python3 -c "
import json, sys
print(json.dumps({'content': sys.stdin.read()}))
" <<'SUMMARY'
${UPDATED_SUMMARY_BODY}
SUMMARY
)"
```

Editing does not re-notify participants — that is intentional; the per-thread replies posted this run carry the notifications.

---

## Creating a Follow-up PR (Merged PR Flow)

When the original PR was already merged:

```bash
curl -s -u ":${AZURE-DEVOPS-TOKEN}" \
  -X POST \
  -H "Content-Type: application/json" \
  "${API_BASE}/_apis/git/repositories/${AZURE_REPO}/pullrequests?api-version=7.1" \
  -d "$(python3 -c "
import json
print(json.dumps({
  'title': 'fix: apply review comments from merged PR #${ORIGINAL_PR_ID}',
  'description': 'Follow-up to !${ORIGINAL_PR_ID}. Applies the actionable review comments that were not addressed before merge.',
  'sourceRefName': 'refs/heads/${NEW_BRANCH}',
  'targetRefName': 'refs/heads/${BASE_BRANCH}'
}))
")"
```

---

## Output

On completion:

```
Resolution complete on PR #<id>: <N> applied, <N> discussed, <N> declined — ${API_BASE}/_git/<repo>/pullrequest/<id>
```
