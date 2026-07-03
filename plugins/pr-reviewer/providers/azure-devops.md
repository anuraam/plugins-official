# Provider: Azure DevOps

Use this provider when `git remote get-url origin` contains `dev.azure.com` or `visualstudio.com`.

**This file is reference documentation, not instructions to re-implement.** All Azure DevOps mechanics described below are implemented in `scripts/lib/azure-devops.sh`, invoked by `scripts/gather-context.sh` and `scripts/post-review.sh` (see `commands/pr-review.md`). This file exists so a maintainer editing the script understands *why* it does what it does — the LLM running a review never needs to write ADO `curl` calls itself.

## Prerequisites

The Azure DevOps REST API is called via `curl` using a Personal Access Token (PAT).

| Variable | Purpose |
|---|---|
| `AZURE_DEVOPS_TOKEN` | Azure DevOps PAT — must have `Code (Read)`, `Pull Request Threads (Read & Write)`, and `User Profile (Read)` scopes |

> **Var-name hygiene:** reference the token as `AZURE_DEVOPS_TOKEN` (**underscores**) — bash cannot reference a hyphenated `AZURE-DEVOPS-TOKEN`. The Xianix Executor re-exports any dashed env var as an underscored alias. `scripts/lib/azure-devops.sh`'s `ado_auth_header()` fails with a clear error if the underscored name is empty; the plugin's `PreToolUse` hook additionally blocks direct `curl` usage under the same condition.

Optional — override values parsed from the remote URL: `AZURE_ORG`, `AZURE_PROJECT`, `AZURE_REPO` (not currently read by the scripts; the URL parser below is authoritative — flagged here in case a future override is needed).

---

## Parsing the remote URL (`_ado_parse_remote_url` in `scripts/lib/azure-devops.sh`)

Azure DevOps uses **four** URL shapes in the wild — **all handled**, with fixture tests in `scripts/tests/run.sh`. Getting the legacy `DefaultCollection` form wrong means inline threads silently 4xx (plain threads still post because the repo resolves at collection level — historically "the #1 cause of main comment posts but inline comments don't show up"):

| # | Shape | Example |
|---|---|---|
| 1 | `dev.azure.com/{org}/{project}/_git/{repo}` | `https://dev.azure.com/contoso/Web/_git/api` |
| 2 | `dev.azure.com/{org}/{collection}/{project}/_git/{repo}` | rare — usually only seen on imported orgs |
| 3 | `{org}.visualstudio.com/{project}/_git/{repo}` | `https://contoso.visualstudio.com/Web/_git/api` |
| 4 | `{org}.visualstudio.com/{collection}/{project}/_git/{repo}` | `https://contoso.visualstudio.com/DefaultCollection/Web/_git/api` |

The parser anchors on the `_git` segment (project is always immediately before it, repo immediately after), so it works for all four shapes regardless of whether a collection segment is present. It also strips an embedded `user@` basic-auth prefix (injected by CI runners) before parsing, and refuses to continue (`return 1`) if the parsed `AZURE_PROJECT` looks like garbage (`""`, `"_git"`, `"DefaultCollection"`, `"https:"`) — this catches the historical bug where a naive `cut -d'/' -f4` parser returned `DefaultCollection` as the project on the legacy URL shape, silently producing an `API_BASE` that skipped the project segment.

`API_BASE` always includes the project (and collection, when present) — required for inline threads, since `threadContext.filePath` can't resolve without it.

---

## Posting pattern (`ado_post_comment_thread` / `ado_post_inline_finding` in the lib script)

Two rules the scripts follow on every write call:

1. **Body sent via a JSON payload file**, never inline-interpolated — avoids the quoting bugs that come from embedding markdown inside a shell heredoc inside `curl -d`.
2. **HTTP status is always captured and checked** (`-w "\nHTTP_STATUS:%{http_code}"`). Silent 401/404 responses were historically the #1 cause of "post succeeded but nothing showed up on the PR."

Auth: `-H "Authorization: Basic $(echo -n ":${AZURE_DEVOPS_TOKEN}" | base64 | tr -d '\n')"` (via `ado_auth_header()`).

## Markdown in PR threads

This plugin posts via the **Git** [Pull Request Threads](https://learn.microsoft.com/en-us/rest/api/azure/devops/git/pull-request-threads/create?view=azure-devops-rest-7.1) API — not Work Item Tracking discussion comments, which use a different markdown mechanism. Every thread the scripts post sets `properties["Microsoft.TeamFoundation.Discussion.SupportsMarkdown"] = 1` so the web UI renders markdown instead of showing raw text.

---

## Detecting a prior review (`ado_detect_prior_review` in the lib script)

Azure DevOps has no reliably-hidden HTML-comment mechanism, so the plugin's identity metadata lives in thread **`properties`** instead: `pr-reviewer.kind` (`finding` | `summary`), `pr-reviewer.fid`, `pr-reviewer.sha`. Detection is a single `GET .../threads?$top=1000` call, filtered by `properties["pr-reviewer.fid"]`, run in the **same process** as the URL parsing and PR-id resolution that produced `API_BASE`/`AZURE_REPO`/`PR_ID` — this is the fix for the bug this refactor addresses: the old flow re-typed this `curl` call from a separate `Bash` tool invocation, where those variables had gone empty, producing a malformed URL, an empty response, and a silent (wrong) fallback to "no prior review."

The script also captures `threadContext.filePath` into the `file` field of each prior finding — needed by `reconcile.py` to implement the "unreviewed carried-over" rule in push-update mode (a prior finding in a file this push didn't touch must not be reported as fixed just because it's absent from this run's findings).

If the API call itself fails (empty body, invalid JSON, non-2xx), the script sets `detection_status: "failed"` in the state file rather than silently writing an empty findings file — `commands/pr-review.md` treats that as "detection failed," never as "confirmed no prior review."

The mode decision (initial vs. rereview) is made by `gather-context.sh` based on `PRIOR_SUMMARY_SHA` (the sha= from the most recent summary-marker thread) — **not** on whether the findings file is empty. A clean prior review (zero findings, but a real summary marker) is still a prior review; matching on emptiness instead was a latent bug in the original design, fixed as part of this refactor.

---

## Posting the review (`post-review.sh`)

### 1. Verdict → vote

| Plugin verdict | Azure DevOps vote value |
|---|---|
| `APPROVE` | `10` |
| `APPROVE WITH SUGGESTIONS` | `5` |
| `REQUEST CHANGES` | `-10` if `PR_REVIEWER_BLOCK_ON_CRITICAL=true`, else `-5` |
| `NEEDS DISCUSSION` | `-5` |

The verdict itself is computed deterministically by `reconcile.py` from the open-finding severities (see `commands/pr-review.md` step 6) — there is no "normalize a non-conforming verdict string" step anymore, because the verdict is never free text.

**By default `post-review.sh` runs in advisory / shadow mode**: a `REQUEST CHANGES` verdict casts the non-blocking `-5` vote, not the blocking `-10` Rejected vote (which is treated as blocking by branch policies with "Require a minimum number of reviewers" + self-approval disabled). Set `PR_REVIEWER_BLOCK_ON_CRITICAL=true` to opt into blocking.

### 2. Resolve reviewer id, then vote

`reviewers/me` does **not** work with PAT auth (returns an HTML error page). `ado_cast_vote()` resolves the actual profile id via `https://app.vssps.visualstudio.com/_apis/profile/profiles/me` first.

### 3. Summary comment

Posted with `pr-reviewer.kind=summary` / `pr-reviewer.sha=$HEAD_SHA` properties — the marker the *next* run's detection reads. Each re-review posts a fresh summary thread; the prior one stays as history.

### 4. Inline findings — one thread per finding, MANDATORY when there are any

`ado_post_inline_finding()` sets `threadContext.filePath`/`rightFileStart`/`rightFileEnd` from the already-resolved (via `resolve-line.py`) post-change file line — never a diff-position or old-side line number, which either lands on the wrong line or gets rejected with `400`.

| HTTP | Cause | Where it's handled |
|---|---|---|
| `401` | `AZURE_DEVOPS_TOKEN` empty | `ado_auth_header()` fails fast with a clear message before the request is even sent |
| `404` | `API_BASE` wrong (usually the `DefaultCollection` bug) | Parser sanity-checks `AZURE_PROJECT`, fixture-tested against all 4 URL shapes |
| `400` with `threadContext` | Bad `filePath` or a line past EOF | `resolve-line.py` is the only place file/line get computed — see `commands/pr-review.md` step 6 |

### R. Reconciling prior findings (re-review mode only)

`fixed[]` entries from `reconcile.py`'s output get a reply (`ado_reply_to_thread`) then `status: "fixed"` (`ado_set_thread_status`). `carried_over[]` and `unreviewed_carried_over[]` get no action — no reply spam, no duplicate thread.

## Output

`post-review.sh` prints the confirmation line using its own `INLINE_OK`/`INLINE_TOTAL`/`RESOLVED_OK` counters — never a number the LLM tallied itself.
