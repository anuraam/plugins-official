# Provider: Azure DevOps

Use this provider when `git remote get-url origin` contains `dev.azure.com` or `visualstudio.com`.

## Prerequisites

Required environment variable:

| Variable | Purpose |
|---|---|
| `AZURE_DEVOPS_TOKEN` | PAT with `Code (Read & Write)` and `Pull Request Threads (Read & Write)` scopes |

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

curl -s -u ":${AZURE_DEVOPS_TOKEN}" \
  "${API_BASE}/_apis/git/repositories/${AZURE_REPO}/pullrequests?searchCriteria.sourceRefName=refs/heads/${BRANCH}&searchCriteria.status=active&api-version=7.1" \
  | python3 -c "import sys,json; prs=json.load(sys.stdin)['value']; print(prs[0]['pullRequestId'] if prs else '')"
```

Store as `PR_ID`. If empty, the branch has no open PR — output a warning and stop.

---

## Fetching PR Metadata

```bash
curl -s -u ":${AZURE_DEVOPS_TOKEN}" \
  "${API_BASE}/_apis/git/repositories/${AZURE_REPO}/pullrequests/${PR_ID}?api-version=7.1"
```

Extract from the response:

| Field | Use |
|---|---|
| `status` | `active`, `completed`, `abandoned` — `completed` means already merged |
| `sourceRefName` | `refs/heads/<head-branch>` — strip `refs/heads/` for `PR_HEAD_BRANCH` |
| `targetRefName` | `refs/heads/<base-branch>` — strip `refs/heads/` for `PR_BASE_BRANCH` |
| `lastMergeSourceCommit.commitId` | Head commit SHA on the source branch |
| `lastMergeCommit.commitId` | Merge commit SHA (present when `status == completed`) |
| `title` / `description` | PR title and body for context |

---

## Markdown in PR Threads

Post via the **Git Pull Request Threads** API (`.../pullrequests/.../threads`). Set thread `properties` so the web UI renders Markdown:

| Key | Value |
|---|---|
| `Microsoft.TeamFoundation.Discussion.SupportsMarkdown` | `1` (integer) |

Include this `properties` object on **every** `POST .../threads` body.

---

## Posting the Starting Comment

```bash
curl -s -u ":${AZURE_DEVOPS_TOKEN}" \
  -X POST \
  -H "Content-Type: application/json" \
  "${API_BASE}/_apis/git/repositories/${AZURE_REPO}/pullrequests/${PR_ID}/threads?api-version=7.1" \
  -d '{"comments":[{"content":"📝 **Documentation update in progress**\n\nI'\''m analysing the changes in this PR and synchronising the project'\''s documentation. When complete, I'\''ll open a **companion documentation PR** targeting this branch — merge it into this PR'\''s branch before merging this PR, and the docs will land together with the code.","commentType":1}],"status":"active","properties":{"Microsoft.TeamFoundation.Discussion.SupportsMarkdown":1}}'
```

If posting fails, output a single warning line and continue.

---

## Fetching the PR Diff

Azure DevOps does not have an equivalent of `gh pr diff` that streams a unified diff in one call. Use git locally — it is the simplest and most reliable approach once the PR branch is fetched:

```bash
git fetch origin "${PR_HEAD_BRANCH}"
git fetch origin "${PR_BASE_BRANCH}"

# Unified diff
git diff "origin/${PR_BASE_BRANCH}...origin/${PR_HEAD_BRANCH}"

# Per-file status (A/M/D/R)
git diff --name-status "origin/${PR_BASE_BRANCH}...origin/${PR_HEAD_BRANCH}"
```

As a fallback when only an iteration-level view is needed (for example, to identify changed files without the full diff):

```bash
# List iterations
curl -s -u ":${AZURE_DEVOPS_TOKEN}" \
  "${API_BASE}/_apis/git/repositories/${AZURE_REPO}/pullrequests/${PR_ID}/iterations?api-version=7.1"

# Changes for the latest iteration
LATEST_ITERATION=<id from above>
curl -s -u ":${AZURE_DEVOPS_TOKEN}" \
  "${API_BASE}/_apis/git/repositories/${AZURE_REPO}/pullrequests/${PR_ID}/iterations/${LATEST_ITERATION}/changes?api-version=7.1"
```

---

## Fetching the PR Head Branch and Cutting the Docs Branch

Do **not** check out the PR's own branch — cut a new branch off the PR's head instead:

```bash
git fetch origin "${PR_HEAD_BRANCH}"

DOCS_BRANCH="docs/pr-${PR_ID}-sync"
git checkout -b "${DOCS_BRANCH}" "origin/${PR_HEAD_BRANCH}"
```

---

## Pushing the Docs Branch (authenticated)

Authenticate the push inline with `AZURE_DEVOPS_TOKEN`. Pass the credential on the `git push` invocation itself with `-c url.<...>.insteadOf` — do not rely on ambient git config or on the `validate-prerequisites.sh` hook to inject it (the hook only validates that the token is present; it runs in a separate process and cannot alter this command's environment). The same PAT covers both `dev.azure.com` and legacy `*.visualstudio.com` remotes:

```bash
git \
  -c "url.https://x-access-token:${AZURE_DEVOPS_TOKEN}@dev.azure.com/.insteadOf=https://dev.azure.com/" \
  -c "url.https://x-access-token:${AZURE_DEVOPS_TOKEN}@visualstudio.com/.insteadOf=https://visualstudio.com/" \
  push -u origin "${DOCS_BRANCH}"
```

---

## Detecting an Existing Docs PR (Re-runs)

Before opening a new docs PR, check whether a previous run already opened one for this `DOCS_BRANCH`:

```bash
EXISTING=$(curl -s -u ":${AZURE_DEVOPS_TOKEN}" \
  "${API_BASE}/_apis/git/repositories/${AZURE_REPO}/pullrequests?searchCriteria.sourceRefName=refs/heads/${DOCS_BRANCH}&searchCriteria.status=active&api-version=7.1" \
  | python3 -c "import sys,json; prs=json.load(sys.stdin)['value']; print(prs[0]['pullRequestId'] if prs else '')")

if [ -n "${EXISTING}" ]; then
  DOCS_PR_ID="${EXISTING}"
  # The push from Step 8 already updated the existing docs PR — no new PR needed.
else
  # See "Creating the Documentation PR" below to open a new one.
  :
fi
```

---

## Creating the Documentation PR

When no existing docs PR is found, open one. **The target / base is the original PR's head branch** (`PR_HEAD_BRANCH`), not the default branch — this makes the docs PR a candidate to be merged *into* the feature branch:

```bash
DOCS_PR_ID=$(curl -s -u ":${AZURE_DEVOPS_TOKEN}" \
  -X POST \
  -H "Content-Type: application/json" \
  "${API_BASE}/_apis/git/repositories/${AZURE_REPO}/pullrequests?api-version=7.1" \
  -d "$(python3 -c "
import json
print(json.dumps({
  'title': 'docs: sync documentation with PR #${PR_ID}',
  'description': '''Documentation companion for !${PR_ID}. Merge this PR into the \`${PR_HEAD_BRANCH}\` branch before merging the original PR.\n\n<full documentation summary from styles/report-template.md>''',
  'sourceRefName': 'refs/heads/${DOCS_BRANCH}',
  'targetRefName': 'refs/heads/${PR_HEAD_BRANCH}'
}))
")" \
  | python3 -c "import sys,json; print(json.load(sys.stdin).get('pullRequestId',''))")

DOCS_PR_URL="${API_BASE}/_git/${AZURE_REPO}/pullrequest/${DOCS_PR_ID}"
```

Store `DOCS_PR_ID` and `DOCS_PR_URL` — both are referenced in the summary comment posted on the original PR.

---

## Posting the Documentation Summary on the Original PR

After the docs PR is open, post a thread on the **original PR** (`PR_ID`) so reviewers see the summary in the right place:

```bash
curl -s -u ":${AZURE_DEVOPS_TOKEN}" \
  -X POST \
  -H "Content-Type: application/json" \
  "${API_BASE}/_apis/git/repositories/${AZURE_REPO}/pullrequests/${PR_ID}/threads?api-version=7.1" \
  -d "$(python3 -c "
import json, sys
body = sys.stdin.read()
print(json.dumps({
  'comments': [{'content': body, 'commentType': 1}],
  'status': 'active',
  'properties': {'Microsoft.TeamFoundation.Discussion.SupportsMarkdown': 1}
}))
" <<'SUMMARY'
${SUMMARY_BODY}
SUMMARY
)"
```

The summary body **must include a link to `${DOCS_PR_URL}`** so the author knows which PR to merge.

When no documentation changes were required (no docs PR was opened), post the shorter "no-op" variant from `styles/report-template.md` directly on the original PR.

---

## Merged PR Flow — Opening the Follow-up Docs PR

When the original PR is already `completed` (merged), the head branch may be deleted. Target the original PR's base branch (`PR_BASE_BRANCH`) instead of the head branch:

```bash
curl -s -u ":${AZURE_DEVOPS_TOKEN}" \
  -X POST \
  -H "Content-Type: application/json" \
  "${API_BASE}/_apis/git/repositories/${AZURE_REPO}/pullrequests?api-version=7.1" \
  -d "$(python3 -c "
import json
print(json.dumps({
  'title': 'docs: sync documentation with merged PR #${ORIGINAL_PR_ID}',
  'description': 'Follow-up to !${ORIGINAL_PR_ID}. Brings the project documentation in line with the source changes that were merged in that PR.',
  'sourceRefName': 'refs/heads/${DOCS_BRANCH}',
  'targetRefName': 'refs/heads/${PR_BASE_BRANCH}'
}))
")"
```

Then post a back-reference thread on the original (merged) PR linking to the new docs PR.

---

## Output

On completion:

```
Documentation PR opened: #<DOCS_PR_ID> → <PR_HEAD_BRANCH> (companion for PR #<PR_ID>): <N> updated, <N> added, <N> removed, <N> renamed — <DOCS_PR_URL>
```
