---
name: review-performance
description: Run a focused performance review on the current branch. Identifies bottlenecks, N+1 queries, algorithmic inefficiencies, and resource waste. Usage: /review-performance [branch-name]
argument-hint: [branch-name]
disable-model-invocation: true
---

Run a focused performance review of the current branch changes.

## Steps

1. Gather the diff against the base branch:
   ```bash
   # Always fetch the base branch's current remote tip — a stale local
   # origin/<base> inflates the diff with commits already merged into the target.
   # Write the diff to a file instead of printing it — printing puts the whole
   # diff in your context and then pays for it again when passed to the agent.
   BASE=$(git ls-remote --symref origin HEAD | awk '/^ref:/ {sub("refs/heads/","",$2); print $2}')
   : "${BASE:=main}"
   git fetch origin "refs/heads/${BASE}"
   BASE_SHA=$(git merge-base FETCH_HEAD HEAD)
   git diff ${BASE_SHA}...HEAD > /tmp/pr_full_diff.patch
   git diff --name-only ${BASE_SHA}...HEAD | tee /tmp/pr_changed_files.txt
   wc -l < /tmp/pr_full_diff.patch
   ```

2. Use the **performance-reviewer** agent, passing it the paths `/tmp/pr_full_diff.patch` and `/tmp/pr_changed_files.txt` (inline the diff in the prompt only if it is ≤ 300 lines).

3. Output the performance review findings directly. Do not post to any platform — this is a local-only review.

If a branch name is provided, compare that branch against the freshly fetched remote default branch. Otherwise, review the current branch.
