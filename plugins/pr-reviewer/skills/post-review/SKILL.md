---
name: post-review
description: Post the current PR review findings as comments on a pull request. Requires a PR number. Usage: /post-review [pr-number]
argument-hint: [pr-number]
disable-model-invocation: true
---

Post the PR review findings as review comments on PR #$ARGUMENTS.

Do not ask for confirmation at any point. Execute all steps autonomously and proceed immediately from one step to the next.

This skill posts findings **already compiled in this conversation** (e.g. from a prior `/pr-review` run whose posting step didn't complete, or findings you derived some other way). It uses the same deterministic scripts `/pr-review` uses — see `commands/pr-review.md` for the full procedure these are steps 1, 6, and 7 of.

## Steps

1. **Gather context** — resolves platform, PR metadata, base/head, diff, and prior-review state in one atomic call:
   ```bash
   bash "${CLAUDE_PLUGIN_ROOT}/scripts/gather-context.sh" $ARGUMENTS
   ```
   Read `/tmp/pr_review_state.json` for `platform`, `pr_id`/`pr_number`, `review_mode`, `head_sha`.

2. **Ensure findings are on disk.** If `/tmp/pr_findings.json` doesn't already reflect the findings you want to post, write it now: a JSON list of `{"file", "line", "severity", "fid", "body"}`, using `scripts/resolve-line.py` and `scripts/compute-fid.py` for the `line` and `fid` fields respectively (never compute either by hand — see *Comment markers and finding identity* in `commands/pr-review.md`).

3. **Reconcile and get the verdict:**
   ```bash
   python3 "${CLAUDE_PLUGIN_ROOT}/scripts/reconcile.py"
   ```
   Writes `/tmp/pr_reconcile.json` with the bucketed findings and a deterministic verdict — use it as-is, do not invent your own verdict string.

4. **Write the report body** to `/tmp/pr_report_body.md` per `styles/report-template.md`, using the verdict and delta counts from `/tmp/pr_reconcile.json` (see `commands/pr-review.md` step 6 for the exact rules).

5. **Post:**
   ```bash
   bash "${CLAUDE_PLUGIN_ROOT}/scripts/post-review.sh" /tmp/pr_report_body.md
   ```
   This casts the vote/review event, posts the summary with its marker, reconciles any `fixed` threads, posts one inline thread per finding in the `new` bucket, and prints the final confirmation line — echo what it printed, don't self-tally.

If the platform is generic/unknown, `post-review.sh` writes `pr-review-report.md` and prints its own completion line instead.

> **Note:** GitHub posting requires the **`gh` CLI** installed and authenticated. Azure DevOps posting uses `AZURE_DEVOPS_TOKEN` (PAT with Pull Request Threads Read & Write scope). See `docs/platform-setup.md`.
