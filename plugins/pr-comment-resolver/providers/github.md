# Provider: GitHub

Use this provider when `git remote get-url origin` contains `github.com`.

Do **not** use this provider when origin is Azure DevOps (`dev.azure.com` / `visualstudio.com`), even if a `PLATFORM` env hint is unset or holds another value. The executor's Azure DevOps value is `azuredevops` — that maps to `providers/azure-devops.md`, not here. Never call `gh` on an Azure DevOps remote.

## Prerequisites for posting

- **GitHub CLI** (`gh`) installed: [https://cli.github.com](https://cli.github.com)
- Authenticated: `gh auth login`, or non-interactive `GH_TOKEN` / `GITHUB-TOKEN`

**Token permissions required:**

| Permission | Access | Why |
|---|---|---|
| **Contents** | Read & Write | Read repo files, commit changes, push to branches |
| **Metadata** | Read | Access repository metadata |
| **Pull requests** | Read & Write | Fetch threads, post replies, resolve threads, open follow-up PRs |

---

## Parse Owner and Repo

```bash
REMOTE=$(git remote get-url origin)
OWNER=$(echo "$REMOTE" | sed 's|https://github.com/||;s|git@github.com:||' | cut -d'/' -f1)
REPO=$(echo "$REMOTE"  | sed 's|https://github.com/||;s|git@github.com:||' | cut -d'/' -f2 | sed 's|\.git$||')
```

---

## Resolve the PR Number

If the user passed a PR number, use it. Otherwise:

```bash
gh pr list --head "$(git rev-parse --abbrev-ref HEAD)" --json number --jq '.[0].number'
```

Or:

```bash
gh pr view --json number --jq '.number'
```

---

## Comment Markers and Prior-Run Detection

Every comment this plugin posts **must** embed an invisible HTML marker so later runs can find, filter, and update it:

| Comment | Marker |
|---|---|
| Progress comment | `<!-- pr-comment-resolver:v1 progress -->` |
| Disposition summary | `<!-- pr-comment-resolver:v1 summary -->` |
| Thread replies | `<!-- pr-comment-resolver:v1 reply -->` |

Before posting anything, detect a prior run by scanning the PR's issue comments for the markers:

```bash
SUMMARY_COMMENT_ID=$(gh api "repos/${OWNER}/${REPO}/issues/<pr-number>/comments" --paginate \
  --jq '[.[] | select(.body | contains("pr-comment-resolver:v1 summary"))] | last | .id // empty')
PROGRESS_COMMENT_ID=$(gh api "repos/${OWNER}/${REPO}/issues/<pr-number>/comments" --paginate \
  --jq '[.[] | select(.body | contains("pr-comment-resolver:v1 progress"))] | last | .id // empty')
```

Non-empty ids mean this is a **re-run**: update those comments in place (below) instead of posting duplicates. When updating the summary, also fetch its current body first (`gh api repos/${OWNER}/${REPO}/issues/comments/${SUMMARY_COMMENT_ID} --jq '.body'`) so the existing run history can be carried forward.

---

## Posting the "Resolution in Progress" Comment

First run (no `PROGRESS_COMMENT_ID`):

```bash
gh pr comment <pr-number> --body "$(cat <<'EOF'
🔧 **PR comment resolution in progress**

I'm reviewing all unresolved threads and will apply actionable ones as commits, reply to the rest, and post a disposition summary when complete.
<!-- pr-comment-resolver:v1 progress -->
EOF
)"
```

Re-run (`PROGRESS_COMMENT_ID` found) — update the existing comment instead of posting a new one:

```bash
gh api -X PATCH "repos/${OWNER}/${REPO}/issues/comments/${PROGRESS_COMMENT_ID}" \
  -f body="🔧 **PR comment resolution in progress** (run started $(date -u +%Y-%m-%dT%H:%MZ))

I'm reviewing the threads opened since the last resolution run.
<!-- pr-comment-resolver:v1 progress -->"
```

If posting fails, output one warning line and continue.

---

## Fetching Unresolved Threads

Use the GitHub GraphQL API to fetch all review threads with their resolved state:

```bash
gh api graphql -f query='
query($owner: String!, $repo: String!, $pr: Int!) {
  repository(owner: $owner, name: $repo) {
    pullRequest(number: $pr) {
      reviewThreads(first: 100) {
        nodes {
          id
          isResolved
          path
          line
          comments(first: 5) {
            nodes {
              id
              body
              author { login }
              createdAt
            }
          }
          lastComment: comments(last: 1) {
            nodes { body }
          }
        }
      }
    }
  }
}' -F owner="$OWNER" -F repo="$REPO" -F pr=<pr-number>
```

Filter to threads where `isResolved == false`, then apply two **self-exclusion** rules:

1. **Skip the plugin's own threads:** drop any thread whose first comment body contains `pr-comment-resolver:v1` — the plugin never processes its own comments.
2. **Skip already-dispositioned threads:** drop any thread whose `lastComment` body contains `pr-comment-resolver:v1 reply` — a prior run already replied (discuss/decline threads stay unresolved by design), and no human has responded since. If a human **has** commented after the plugin's reply (the last comment is not the plugin's), the thread is back in scope — process it fresh.

For each remaining thread, collect:
- `id` — the thread node ID (for resolving via mutation later)
- `comments.nodes[0].id` — the first comment ID (for posting replies)
- `comments.nodes[0].body` — the reviewer's comment text
- `path` — file path (may be null for top-level PR comments)
- `line` — line number (may be null for top-level PR comments)

If the result has more than 100 threads, paginate using the `after` cursor.

---

## Resolving a Thread

After applying a code change for an **apply** thread, mark the thread as resolved:

```bash
gh api graphql -f query='
mutation($threadId: ID!) {
  resolveReviewThread(input: { threadId: $threadId }) {
    thread { id isResolved }
  }
}' -F threadId="<thread-node-id>"
```

---

## Posting a Reply to a Thread

Reply to the first comment in a thread (for **apply** confirmations, **discuss** explanations, and **decline** justifications). Every reply ends with the reply marker — it is what lets the next run skip already-dispositioned threads:

```bash
gh api repos/${OWNER}/${REPO}/pulls/comments/<first-comment-id>/replies \
  --method POST \
  --field body="<reply text>
<!-- pr-comment-resolver:v1 reply -->"
```

For top-level PR comments (no `path`), post as a general PR comment instead:

```bash
gh pr comment <pr-number> --body "<reply text>
<!-- pr-comment-resolver:v1 reply -->"
```

---

## Linking to Commits

Whenever a reply or the summary references a commit, render it as a markdown link so reviewers can click through:

```bash
COMMIT_SHA=$(git rev-parse HEAD)
SHORT_SHA=$(git rev-parse --short HEAD)
COMMIT_URL="https://github.com/${OWNER}/${REPO}/commit/${COMMIT_SHA}"
# In comment bodies: [${SHORT_SHA}](${COMMIT_URL})
```

Do **not** wrap the SHA in backticks or post it bare — backticks suppress GitHub's autolinking, and an explicit link works regardless of context.

---

## Posting the Disposition Summary

The summary body comes from `styles/report-template.md` and must include the `<!-- pr-comment-resolver:v1 summary -->` marker.

First run (no `SUMMARY_COMMENT_ID`) — post a new comment:

```bash
gh pr comment <pr-number> --body "<full disposition summary from styles/report-template.md>"
```

Re-run (`SUMMARY_COMMENT_ID` found) — **update the existing summary in place** rather than posting a second one. Rebuild the body with cumulative totals, append this run's line to the **Run History** section (carry forward the prior history fetched during prior-run detection), then:

```bash
gh api -X PATCH "repos/${OWNER}/${REPO}/issues/comments/${SUMMARY_COMMENT_ID}" \
  -f body="<updated disposition summary>"
```

Editing does not re-notify participants — that is intentional; the per-thread replies posted this run carry the notifications.

---

## Creating a Follow-up PR (Merged PR Flow)

When the original PR was already merged:

```bash
gh pr create \
  --title "fix: apply review comments from merged PR #<original-pr-number>" \
  --body "Follow-up to #<original-pr-number>. Applies the actionable review comments that were not addressed before merge." \
  --base <base-branch> \
  --head <new-branch-name>
```

---

## Output

On completion:

```
Resolution complete on PR #<number>: <N> applied, <N> discussed, <N> declined — https://github.com/<owner>/<repo>/pull/<number>
```
