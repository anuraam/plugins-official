---
name: review-tests
description: Run a focused test coverage review on the current branch. Identifies missing tests, coverage gaps, and test quality issues. Usage: /review-tests [branch-name]
argument-hint: [branch-name]
disable-model-invocation: true
---

Run a focused test coverage review of the current branch changes.

## Steps

1. Gather the diff via **`scripts/pr-setup.sh` as one Bash call** (set `BRANCH_ARG` when a branch name is provided). Do not invent a shortened checkout/diff script — see `skills/review-code/SKILL.md` step 1 for the resolve+run block.

2. Launch the **test-reviewer** agent with `"subagent_type": "test-reviewer"` and `"model": "haiku"`. Pass `/tmp/pr_full_diff_numbered.patch` and `/tmp/pr_changed_files.txt` (inline the numbered diff only if ≤ 300 lines). Include the line-number constraint from `commands/pr-review.md` Step 6.

3. Output the test review findings directly. Do not post to any platform — this is a local-only review.

If a branch name is provided, set `BRANCH_ARG` before running `pr-setup.sh`. Otherwise, review the current branch.
