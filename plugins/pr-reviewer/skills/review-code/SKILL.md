---
name: review-code
description: Run a focused code quality review on the current branch. Checks readability, naming, duplication, error handling, and design patterns. Usage: /review-code [branch-name]
argument-hint: [branch-name]
disable-model-invocation: true
---

Run a focused code quality review of the current branch changes.

## Steps

1. Gather the diff via **`scripts/pr-setup.sh` as one Bash call** (do not invent a shortened checkout/diff script):
   ```bash
   SETUP="${CLAUDE_PLUGIN_ROOT:+$CLAUDE_PLUGIN_ROOT/scripts/pr-setup.sh}"
   if [ -z "${SETUP:-}" ] || [ ! -f "$SETUP" ]; then
     SETUP=$(find "${CLAUDE_PLUGIN_ROOT:-.}" ~/.claude/plugins -path '*/pr-reviewer/scripts/pr-setup.sh' 2>/dev/null | head -1)
   fi
   # Optional: BRANCH_ARG=<branch-name>
   bash "$SETUP"
   source /tmp/pr_state.env
   ```
   That writes `/tmp/pr_full_diff_numbered.patch` and `/tmp/pr_changed_files.txt`.

2. Launch the **code-reviewer** agent with `"subagent_type": "code-reviewer"` and `"model": "haiku"`. Pass `/tmp/pr_full_diff_numbered.patch` and `/tmp/pr_changed_files.txt` (inline the numbered diff only if ≤ 300 lines). Include the line-number constraint from `commands/pr-review.md` Step 6.

3. Output the code review findings directly. Do not post to any platform — this is a local-only review.

If a branch name is provided, set `BRANCH_ARG` before running `pr-setup.sh`. Otherwise, review the current branch.
