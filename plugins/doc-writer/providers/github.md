# Provider: GitHub

Use this provider when `git remote get-url origin` contains `github.com`.

## Prerequisites for posting

- **GitHub CLI** (`gh`) installed: [https://cli.github.com](https://cli.github.com)
- Authenticated: `gh auth login`, or non-interactive `GH_TOKEN` / `GITHUB_TOKEN`

**Token permissions required:**

| Permission | Access | Why |
|---|---|---|
| **Contents** | Read & Write | Read repo files, commit doc changes, push to PR branches |
| **Metadata** | Read | Access repository metadata |
| **Pull requests** | Read & Write | Fetch PR diff and metadata, post the summary comment, open follow-up PRs |

---

## Parse Owner and Repo

```bash
REMOTE=$(git remote get-url origin)
OWNER=$(echo "$REMOTE" | sed 's|https://github.com/||;s|git@github.com:||' | cut -d'/' -f1)
REPO=$(echo "$REMOTE"  | sed 's|https://github.com/||;s|git@github.com:||' | cut -d'/' -f2 | sed 's|\.git$||')
```

---

## Resolving the PR Number

If the user passed a PR number, use it. Otherwise:

```bash
gh pr list --head "$(git rev-parse --abbrev-ref HEAD)" --json number --jq '.[0].number'
```

Or, if you are already on the PR branch:

```bash
gh pr view --json number --jq '.number'
```

---

## Fetching PR Metadata

```bash
gh pr view <pr-number> --json number,title,body,state,mergedAt,headRefName,headRefOid,baseRefName,url,author,labels,files,additions,deletions,commits,mergeCommit
```

Extract:

- `state` — `OPEN` or `MERGED`
- `headRefName` / `headRefOid` — the PR's branch name and head commit
- `baseRefName` — the target branch (used as the base for the follow-up PR in the merged flow)
- `mergeCommit.oid` — the merge commit SHA when `state == MERGED`
- `files` — the list of changed file paths with `additions`/`deletions`
- `body` — the PR description (used as additional context for what docs should change)
- `commits` — commit messages

---

## Posting the "Documentation Update in Progress" Comment

```bash
gh pr comment <pr-number> --body "$(cat <<'EOF'
📝 **Documentation update in progress**

I'm analysing the changes in this PR and synchronising the project's documentation. When complete, I'll open a **companion documentation PR** targeting this branch — merge it into this PR's branch before merging this PR, and the docs will land together with the code.
EOF
)"
```

If posting fails, output one warning line and continue.

---

## Fetching the PR Diff

Call `gh pr diff` to get the **unified diff** of the PR exactly as GitHub sees it (independent of local branch state):

```bash
gh pr diff <pr-number>
```

For the structured per-file view (with rename detection and additions/deletions counts), use:

```bash
gh pr view <pr-number> --json files --jq '.files[] | {path, additions, deletions}'
```

When the PR is very large and `gh pr diff` truncates, fall back to reading the **PR head revision** of each changed file directly:

```bash
gh pr view <pr-number> --json files --jq '.files[].path' | while read -r f; do
  echo "=== $f ==="
  gh api "repos/${OWNER}/${REPO}/contents/${f}?ref=$(gh pr view <pr-number> --json headRefOid --jq '.headRefOid')" \
    --jq '.content' | base64 -d
done
```

---

## Fetching the PR Head Branch Locally

Do **not** check out the PR's own branch — cut a new branch off the PR's head instead. Fetch the head ref and create the docs branch:

```bash
PR_HEAD_BRANCH=$(gh pr view <pr-number> --json headRefName --jq '.headRefName')
git fetch origin "${PR_HEAD_BRANCH}"

DOCS_BRANCH="docs/pr-<pr-number>-sync"
git checkout -b "${DOCS_BRANCH}" "origin/${PR_HEAD_BRANCH}"
```

If the PR is from a fork, `gh pr view` still returns the head ref name (e.g. `feature/x`), but the remote object may not be present on `origin`. In that case use `gh pr checkout <pr-number>` to bring the fork's head into a local branch, then cut the docs branch from `HEAD`:

```bash
gh pr checkout <pr-number>
git checkout -b "${DOCS_BRANCH}"
```

---

## Pushing the Docs Branch (authenticated)

Authenticate the push inline with `GITHUB_TOKEN`. Pass the credential on the `git push` invocation itself with `-c url.<...>.insteadOf` — do not rely on ambient git config or on the `validate-prerequisites.sh` hook to inject it (the hook only validates that the token is present; it runs in a separate process and cannot alter this command's environment):

```bash
git -c "url.https://x-access-token:${GITHUB_TOKEN}@github.com/.insteadOf=https://github.com/" \
    push -u origin "${DOCS_BRANCH}"
```

---

## Detecting an Existing Docs PR (Re-runs)

Before opening a new docs PR, check whether a previous run already opened one for this `DOCS_BRANCH`:

```bash
gh pr list --head "${DOCS_BRANCH}" --state open --json number,url --jq '.[0]'
```

If the result is non-empty, reuse the returned PR number — the authenticated `git push -u origin "${DOCS_BRANCH}"` in Step 8 will already have updated it. Optionally refresh its body:

```bash
gh pr edit "${DOCS_PR_NUMBER}" --body "<latest summary from styles/report-template.md>"
```

---

## Opening the Documentation PR

When no existing docs PR is found, open one. **The target / base is the original PR's head branch**, not the repo's default branch — this is what makes the docs PR a candidate to be merged *into* the feature branch:

```bash
DOCS_PR_URL=$(gh pr create \
  --title "docs: sync documentation with PR #<pr-number>" \
  --body "$(cat <<EOF
Documentation companion for #<pr-number>. Merge this PR into the \`${PR_HEAD_BRANCH}\` branch before merging the original PR.

<full documentation summary from styles/report-template.md>
EOF
)" \
  --base "${PR_HEAD_BRANCH}" \
  --head "${DOCS_BRANCH}")

DOCS_PR_NUMBER=$(echo "${DOCS_PR_URL}" | sed 's|.*/||')
```

Store `DOCS_PR_NUMBER` and `DOCS_PR_URL` — both are referenced in the summary comment posted on the original PR.

### Optional Label on the Docs PR

```bash
gh pr edit "${DOCS_PR_NUMBER}" --add-label "documentation" 2>/dev/null || true
```

The `|| true` guard prevents a missing-label error from failing the run.

---

## Posting the Documentation Summary on the Original PR

After the docs PR is open, post a comment on the **original PR** so reviewers see the summary in the right place:

```bash
gh pr comment <pr-number> --body "$(cat <<EOF
<full documentation summary from styles/report-template.md — must include a link to ${DOCS_PR_URL}>
EOF
)"
```

When no documentation changes were required (no docs PR was opened), post the shorter "no-op" variant from `styles/report-template.md` directly on the original PR — there is no docs PR link to include.

---

## Merged PR Flow — Opening the Follow-up Docs PR

When the original PR was already merged, the head branch may be deleted. In that case the docs PR must target the original PR's base branch (e.g. `main`) instead of the head branch:

```bash
gh pr create \
  --title "docs: sync documentation with merged PR #<original-pr-number>" \
  --body "Follow-up to #<original-pr-number>. Brings the project documentation in line with the source changes that were merged in that PR." \
  --base "${PR_BASE_BRANCH}" \
  --head "${DOCS_BRANCH}"
```

After creating the follow-up PR, post a back-reference comment on the original PR (GitHub allows comments on merged PRs):

```bash
gh pr comment <original-pr-number> --body "📝 Documentation follow-up opened: #${DOCS_PR_NUMBER}"
```

---

## Optional Label on the Original PR

If your repository uses a label like `documentation-updated` to mark original PRs that already have a companion docs PR, apply it after posting the summary:

```bash
gh pr edit <pr-number> --add-label "documentation-updated" 2>/dev/null || true
```

The `|| true` guard prevents a missing-label error from failing the run.

---

## Output

On completion:

```
Documentation PR opened: #<DOCS_PR_NUMBER> → <PR_HEAD_BRANCH> (companion for PR #<number>): <N> updated, <N> added, <N> removed, <N> renamed — <DOCS_PR_URL>
```
