# Provider: GitHub

Use this provider when `git remote get-url origin` contains `github.com`.

**This file is reference documentation, not instructions to re-implement.** All GitHub mechanics described below are implemented in `scripts/lib/github.sh`, invoked by `scripts/gather-context.sh` and `scripts/post-review.sh` (see `commands/pr-review.md`). This file exists so a maintainer editing the script understands *why* it does what it does — the LLM running a review never needs to write `gh api`/GraphQL calls itself.

## How this fits with the rest of the plugin

- **Reading / analysis** — `git diff`, `git log`, etc., against the base branch, resolved once by `scripts/gather-context.sh`. No `gh` needed to fetch patches or file lists.
- **GitHub-specific** — `gh` is used only to resolve the PR number when not passed in, and to post comments/reviews.

## Prerequisites for posting

- **GitHub CLI** (`gh`) installed: <https://cli.github.com>
- Authenticated: `gh auth login`, or non-interactive `GH_TOKEN`/`GITHUB_TOKEN` (scopes: `repo` for private repos, `public_repo` for public only; `read:org` if needed)

The plugin does **not** use the GitHub MCP server.

---

## Resolving owner/repo and the PR number (`_gh_parse_remote_url` / `gh_resolve_pr_number` in the lib script)

Owner/repo are parsed from the remote URL (handles both `https://github.com/org/repo.git` and `git@github.com:org/repo.git` forms). The PR number is resolved from the current branch via `gh pr list --head ... --json number` (falling back to `gh pr view --json number` for a detached-HEAD-safe branch resolution) unless an explicit number was passed as the command argument. Both run inside `gather-context.sh`, in the same process that later uses them for prior-review detection — see *Detecting a prior review* below for why that matters.

---

## Detecting a prior review (`gh_detect_prior_review` in the lib script)

GitHub's REST review-comments endpoint returns comment bodies and ids but **not** the review-thread node id needed to resolve a thread, so detection uses GraphQL: `reviewThreads(first:100) { nodes { id isResolved path comments(first:1) { nodes { databaseId body } } } }`, filtered by the `<!-- pr-reviewer:v1 kind=finding fid=... sha=... -->` marker regex in the first comment's body. The `path` field (added in this refactor) feeds `reconcile.py`'s "unreviewed carried-over" rule in push-update mode, the same way `threadContext.filePath` does on Azure DevOps.

The most recent summary-marker sha is searched across **both** plain PR comments (`gh pr comment`) and PR review bodies (`gh pr review --comment`) — the marker can live in either, since re-reviews are posted as review events but the very first "in progress" note is a plain comment.

This call runs in the **same process** as `_gh_parse_remote_url`/`gh_resolve_pr_number`, which is the fix for the bug this refactor addresses: previously an LLM re-typed this GraphQL query from a separate `Bash` tool invocation where `OWNER`/`REPO`/`PR_NUMBER` had gone empty (lost across the call boundary), producing a query that returned a null `pullRequest` — silently misread as "no prior review" rather than "the query never ran against the real PR."

If the query fails or returns no `pullRequest` node, the script sets `detection_status: "failed"` — never silently treated as "confirmed no prior review" by `commands/pr-review.md`.

The mode decision (initial vs. rereview) is made by `gather-context.sh` from `PRIOR_SUMMARY_SHA` presence — not from whether the findings file is empty (a clean prior review with zero findings still has a summary marker and must still be detected as a prior review).

---

## Posting the "review in progress" comment (`gh_post_pr_comment`)

A plain `gh pr comment` — not a review event, since the review isn't ready yet. Non-fatal if it fails.

## Posting the final review (`gh_post_review` / `gh_post_inline_finding` in the lib script)

### Verdict → `gh pr review` flag

| Plugin verdict | Flag |
|---|---|
| `APPROVE` / `APPROVE WITH SUGGESTIONS` | `--approve` |
| `REQUEST CHANGES` | `--request-changes` if `PR_REVIEWER_BLOCK_ON_CRITICAL=true`, else `--comment` (non-blocking) |
| `NEEDS DISCUSSION` / anything else | `--comment` |

The verdict itself comes from `reconcile.py` (see `commands/pr-review.md` step 6) — computed from open-finding severities, never free text the LLM invents.

**By default `post-review.sh` runs in advisory / shadow mode**: `--request-changes` is a first-class blocking review on GitHub (blocks the merge button under standard branch protection), so a `REQUEST CHANGES` verdict is posted as `--comment` unless `PR_REVIEWER_BLOCK_ON_CRITICAL=true`.

The summary marker (`<!-- pr-reviewer:v1 kind=summary sha=... -->`) is appended to the report body before posting — this is what lets the *next* run's detection find this review.

### Inline comments (one thread per finding) — MANDATORY when there are findings

`gh_post_inline_finding` posts via `gh api repos/{owner}/{repo}/pulls/{pr}/comments` with `path`/`line`/`side=RIGHT`/`commit_id`, using the file/line already resolved by `resolve-line.py` (see `commands/pr-review.md` step 6) — never a diff-position or old-side line number.

| HTTP | Cause |
|---|---|
| `422` (`line must be part of the diff`) | Line isn't on the diff's right side — should not happen since `resolve-line.py` is the only place line numbers get computed |
| `422` (`commit_id` mismatch) | `commit_id` isn't the PR head — `post-review.sh` always uses `head_sha` from the state file |
| `404` | Wrong owner/repo/PR number, or token lacks `repo` scope |
| `403` | Rate-limited, or a self-review restriction (inline review *comments* are normally allowed on your own PR) |

### Reconciling prior findings (re-review mode only)

`fixed[]` entries get a reply (`gh_reply_to_comment`, using the `comment_ref` REST id) then a GraphQL `resolveReviewThread` mutation (`gh_resolve_thread`, using the `thread_ref` node id — REST has no resolve endpoint). `carried_over[]`/`unreviewed_carried_over[]` get no action.

If `resolveReviewThread` returns a permissions error, that's logged and the run continues — the reply still lands and the verdict still updates.

## Output

`post-review.sh` prints the confirmation line using its own counters — never a number the LLM tallied itself.
