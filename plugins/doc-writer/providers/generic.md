# Provider: Generic / Unknown Platform

Use this provider when the git remote does not match GitHub or Azure DevOps — or as a fallback when API posting is not possible.

## Behaviour

In generic mode the plugin cannot fetch PR metadata, open pull requests, or post comments. It does the next best thing:

1. Treats the **current branch** as "the PR's head branch" and uses `git diff origin/<default>...HEAD` as the PR diff.
2. Cuts a new local branch `docs/<head-branch>-sync` off the current branch and applies the documentation edits there.
3. Commits the edits on the docs branch (one `docs:` commit).
4. Pushes the docs branch to `origin` (if a remote is available).
5. Writes a local report file describing what was changed **and** the exact `git merge` / PR-creation commands a human or CI system should run to land the docs PR into the original branch.

---

## Resolving the "PR"

Without a remote PR object, identify the change set as the diff between the current branch and the repository's default branch:

```bash
BASE=$(git symbolic-ref refs/remotes/origin/HEAD 2>/dev/null | sed 's|refs/remotes/origin/||' || echo main)
git fetch origin "${BASE}" 2>/dev/null || true

BRANCH=$(git rev-parse --abbrev-ref HEAD)
HEAD_SHA=$(git rev-parse HEAD)
```

If the current branch *is* the default branch, output a warning and stop — there is no diff to document.

---

## Fetching the Diff

```bash
git diff "origin/${BASE}...HEAD"
git diff --name-status "origin/${BASE}...HEAD"
git log --oneline "origin/${BASE}..HEAD"
```

Use these outputs as the equivalent of the PR diff, file list, and commit messages in Step 5 of the command flow.

---

## Cutting the Docs Branch

Identify the "PR head branch" — the branch the command was invoked on — and cut a dedicated docs branch from it:

```bash
PR_HEAD_BRANCH=$(git rev-parse --abbrev-ref HEAD)
DOCS_BRANCH="docs/${PR_HEAD_BRANCH}-sync"

if git show-ref --verify --quiet "refs/heads/${DOCS_BRANCH}"; then
  git checkout "${DOCS_BRANCH}"
  git reset --hard "${PR_HEAD_BRANCH}"
else
  git checkout -b "${DOCS_BRANCH}" "${PR_HEAD_BRANCH}"
fi
```

All documentation edits live on this branch — the original branch is never modified.

---

## Applying Documentation Changes

Edits are applied locally on `DOCS_BRANCH`:

1. Edit files using `Edit` or `Write`.
2. Commit using `git commit` (a single `docs:` commit covering all doc edits).
3. Push (if a remote is available), authenticating inline with `GIT_TOKEN`:
   ```bash
   git -c "url.https://x-access-token:${GIT_TOKEN}@github.com/.insteadOf=https://github.com/" \
       push -u origin "${DOCS_BRANCH}"
   ```
   For non-GitHub HTTPS remotes, substitute the host in the `insteadOf` key accordingly.

If no remote is configured or the push fails, leave the commit on the local docs branch and note this in the report.

---

## Writing the Documentation Update Report

Write the full report to the repository root:

```
doc-update-report.md
```

**File format:**

```markdown
# Documentation Update Report

Generated: <ISO 8601 timestamp>
PR head branch: <PR_HEAD_BRANCH>
Docs branch:    <DOCS_BRANCH>
Base:           <default branch>
Commit:         <HEAD SHA on DOCS_BRANCH>

---

## How to land these changes

The documentation lives on a separate branch (`<DOCS_BRANCH>`). To merge it into the original branch (`<PR_HEAD_BRANCH>`), run:

```bash
git checkout <PR_HEAD_BRANCH>
git merge --no-ff <DOCS_BRANCH>
git push origin <PR_HEAD_BRANCH>
```

If your platform supports pull requests, open one **from `<DOCS_BRANCH>` into `<PR_HEAD_BRANCH>`** instead of merging locally — that gives reviewers a chance to inspect the doc-only changes before they land.

---

<full documentation summary from styles/report-template.md>
```

Write the report file even if no documentation changes were required — it serves as the audit artifact.

---

## Output

On completion (changes applied):

```
Documentation branch pushed: <DOCS_BRANCH> (merge into <PR_HEAD_BRANCH>) — <N> updated, <N> added, <N> removed, <N> renamed — report written to doc-update-report.md
```

If no documentation changes were required:

```
No documentation updates required — report written to doc-update-report.md
```

---

## When to Use

This provider is the correct fallback for:

- Bitbucket (API posting not yet implemented — use generic)
- Self-hosted GitLab instances
- Gitea, Forgejo, Sourcehut, and other on-premises git servers
- Local or offline runs where no remote API is available
- CI environments where only the report file output is needed
