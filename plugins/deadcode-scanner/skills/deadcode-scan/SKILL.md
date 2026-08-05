---
name: deadcode-scan
description: Detect dead code (unused files, exports, types, and dependencies) in a JS/TS repository using Knip. Produces HTML/Markdown/JSON reports with run history and delta tracking. Usage: /deadcode-scan [path] [--fix | --fix-dry-run] [options]
argument-hint: [path] [--fix | --fix-dry-run] [--include-files] [--production] [--config <path>] [--output-dir <path>] [--publish github]
disable-model-invocation: true
---

Detect dead code in the repository at `$ARGUMENTS` (defaults to the current directory).

This skill is a thin alias for the `/deadcode` command. Run the full procedure documented in `commands/deadcode.md` — it dispatches the **orchestrator** agent, which coordinates:

1. **`knip-detector`** — runs Knip and normalizes the results into the canonical findings schema (`schemas/findings.schema.json`). Emits `skipped` on non-JS/TS repos, `partial` when `node_modules` is missing.
2. **`report-writer`** — applies `.deadcode-ignore` suppressions, computes the delta against the prior run, and writes `deadcode-report.html` / `.md` / `.json` under `deadcode-reports/<run-id>/`, mirrored to `deadcode-reports/latest/`.
3. **`fix-writer`** (only with `--fix` / `--fix-dry-run`) — runs `knip --fix` inside an isolated git worktree based on `origin/<default-branch>`, commits on `deadcode-fix/<run-id>`, pushes, and opens a **draft PR**. Preflights with `scripts/detect-platform.sh` and (unless `--fix-dry-run`) `scripts/check-permissions.sh` before doing any real work — see `docs/platform-setup.md` if that check fails.

**Report-only by default.** Without `--fix`, nothing in the repository is modified — the scan is read-only analysis plus report files. With `--fix`, dead code is removed only inside the throwaway worktree and delivered as a draft PR for human review; the current branch and uncommitted work are never touched.

If a path is provided, scan that path. Otherwise scan the current directory. Pass through any flags in `$ARGUMENTS` verbatim (`--fix`, `--fix-dry-run`, `--include-files`, `--production`, `--config`, `--output-dir`, `--publish github`) — see `commands/deadcode.md` for the full flag reference.
