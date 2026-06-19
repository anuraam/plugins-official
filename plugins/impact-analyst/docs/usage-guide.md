# Usage Guide

The `impact-analyst` plugin works with **GitHub PRs and Issues**, **Azure DevOps Work Items and PRs**, and **local branches**. This guide explains how to trigger the plugin and what to expect from each entry point.

---

## Entry Points

The plugin accepts four entry point styles. Choose the one that matches what you have at hand.

### Current branch (no argument)

Analyzes the current branch against `main`:

```
/impact-analysis
```

Use this when you are mid-development and want an early read on risk before opening a PR.

### PR number

```
/impact-analysis pr 87
```

Fetches the PR diff and discovers any linked issue or work item for requirements traceability. Works on both GitHub and Azure DevOps.

### GitHub Issue

```
/impact-analysis issue 203
```

Fetches the issue body, labels, and comments, then discovers all pull requests linked to it. Produces a full requirements-to-test-case trace. GitHub only.

### Azure DevOps Work Item

```
/impact-analysis wi 4521
```

Fetches work item fields, acceptance criteria, repro steps (Bug), and all linked PRs. Works with Bug, PBI, Feature, and Issue work item types.

---

## Flags

| Flag | Effect |
|---|---|
| `--no-perf` | Skip Performance test case generation |
| `--no-a11y` | Skip Accessibility & Usability test case generation |

Use `--no-perf` for pure data-layer or infrastructure changes with no throughput surface. Use `--no-a11y` for backend-only changes with no user interface.

Example:

```
/impact-analysis pr 87 --no-perf --no-a11y
```

---

## Work Item Types

The `requirement-collector` agent detects the work item type and adjusts the depth of analysis automatically:

| Type | Detection | What the agent extracts |
|---|---|---|
| **PBI / Feature** | Azure DevOps work item type | Acceptance criteria, description, child items |
| **Bug** | Azure DevOps work item type `Bug` | Repro steps, root cause, expected vs. actual |
| **GitHub Issue** | Any GitHub issue | Issue body, comments, linked PRs |
| **PR only** | No work item found or linked | Sections 6, 7, 8, and 13 render as N/A — test cases anchor to risks and user scenarios |

The plugin works without a work item. When there is no linked issue or work item, requirements traceability sections are skipped and the report focuses on blast radius, feature impact, and risk.

---

## Trivial PR Fast-Path

If all changed files are documentation, tests, or formatting changes **and** the total diff is under 50 lines, the orchestrator skips three of the four Phase 1 agents (`dependency-tracer`, `feature-mapper`, and `requirement-collector`) and flags the report as **Fast-path: Trivial PR**.

The `change-analyst` and `risk-assessor` still run. The report is complete but abbreviated.

---

## Workflow

### GitHub

1. Open or identify a PR or issue
2. Run `/impact-analysis pr <number>` or `/impact-analysis issue <number>`
3. The plugin posts a **markdown summary comment** on the PR or issue
4. The full HTML report is written locally as `impact-analysis-{YYYY-MM-DD}-{id}.html`
5. Open the HTML file in a browser — share it with the QA engineer or product owner

### Azure DevOps

1. Open or identify a Work Item (Bug, PBI, Feature, or Issue)
2. Run `/impact-analysis wi <id>` or `/impact-analysis pr <number>`
3. The plugin **attaches** the HTML report to the work item and posts a notification comment
4. If triggered from a PR, a notification thread is also posted on the PR

### Local / Generic

1. Check out the branch you want to analyze
2. Run `/impact-analysis` (no argument)
3. The HTML report is written locally — no platform API calls are made

---

## Output File

Reports are named `impact-analysis-{YYYY-MM-DD}-{id}.html` and written to the working directory. Repeated runs never overwrite previous reports — each run produces a new timestamped file.

The HTML report is fully self-contained: inline CSS, no external dependencies, and print-ready for A4 and Letter paper sizes.

---

## Prerequisites

- Must be run inside a git repository
- **GitHub:** `gh` CLI installed and authenticated — see `docs/platform-config.md`
- **Azure DevOps:** `AZURE_DEVOPS_TOKEN` environment variable set — see `docs/platform-config.md`

The plugin validates prerequisites before running and will block with an actionable error message if anything is missing.
