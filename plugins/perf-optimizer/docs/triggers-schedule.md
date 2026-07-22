# Automated Triggering — Schedule (cron)

This guide shows how to make the **Xianix Agent** run the Performance Optimizer on a recurring timer instead of waiting for an issue label or work-item tag. It uses the [Schedule Rule Sets](https://xianix-team.github.io/documentation/agent-configuration/rules/schedules/) trigger type — a `schedule` + `cron` rule set that runs on its own timer with **no webhook payload at all**.

For manual/interactive use (`/perf-optimize` in a chat), see the main [README](../README.md). For token setup and scopes, see [`platform-setup.md`](./platform-setup.md). For the label/tag triggers, see [`triggers-github.md`](./triggers-github.md) and [`triggers-azure-devops.md`](./triggers-azure-devops.md).

---

## How schedule triggering works

A `schedule` rule set has no issue, work item, or webhook payload to read — it just fires on a `cron` timer. Every execution in the rule set runs on **every** tick, so there's no `match-any` / `use-inputs` to configure (see *No payload → no match-any / use-inputs* in the linked doc).

Because there's no issue/work-item title, the run still produces a pull request, but naming and traceability fall back to date + baseline commit instead. More importantly, a scheduled run has a **different objective** from an issue/work-item run — see the callout below.

| | Issue / work-item trigger | Schedule trigger |
|---|---|---|
| Fires on | Label applied / tag added | `cron` tick |
| Objective | Fix the whole reviewable backlog on demand | Drip **one** fix at a time — the highest-impact of the trivially-safe candidates |
| Changes per PR | All selected Quick-wins (one commit each) | **Exactly one** Quick-win (single commit) |
| Scan coverage | Always the full codebase (or the `Scope:` hint) | **Incremental** by default — only files changed since the last scheduled scan, plus their direct callers; full codebase on the first run and on the periodic full-scan day (see below) |
| PR body | Full embedded performance report + analyzer verdicts | **Slim** — the one change's rationale + a short checklist |
| Scope/target hints | Parsed from issue/work-item body | Must be set directly in `execute-prompt` (no body to parse) |
| Branch name | `perf/issue-<n>-<slug>` / `perf/workitem-<id>-<slug>` | `perf/scheduled-<YYYYMMDD>-<short-sha>` |
| PR title | Issue/work-item title, verbatim | `perf: scheduled optimization scan (<date>)` |
| PR traceability | `Closes #<n>` / `Related work item: #<id>` | `Trigger: Scheduled run @ <short-sha>` |
| Link-back comment | Posted on the issue/work item | Not applicable — nothing to comment on |
| Repeat-run safety | One issue → at most one open PR, naturally | **Idempotency guard:** if a `perf/scheduled-*` PR is already open against the default branch, the run stops before doing any analysis (see orchestrator Step 1a) |

> **Why one change at a time?** A scheduled run is unattended and recurring — nobody asked for it right now. If it opened a PR containing every finding plus a full report, the reviewer would have no time to work through it and the PR would rot. Instead, each scheduled run selects in two phases: first a hard **eligibility gate** (High confidence, small/localized diff, obviously behavior-preserving), then, among the survivors, the **highest-impact** one. So it ships the biggest win that is still trivially safe to review — not just any tiny change — with a body a busy reviewer can approve in under a minute. Anything that fails the gate is skipped for this run no matter how high its impact; if nothing passes the gate, no PR is opened. Combined with the idempotency guard, this produces a **steady drip**: the next fix only appears once the current one is merged or closed. The remaining findings aren't lost — they simply surface on later ticks.

The `/perf-optimize` command detects this mode via the `--schedule` flag, which the rule's `execute-prompt` always passes — see `commands/perf-optimize.md`.

---

## Incremental vs. full scans (cost control)

Re-analyzing the whole codebase on every tick is the dominant cost of the schedule flow, and on most days almost none of it has changed. Scheduled runs therefore resolve a **scan mode** (`SCAN_MODE`, orchestrator Step 1b) on every tick:

| Tick | `SCAN_MODE` | Analyzer input |
|---|---|---|
| First-ever scheduled run | `full` | Whole codebase |
| The periodic **full-scan day** — `--full-scan-day <SUN..SAT>`, default `SUN` (UTC) | `full` | Whole codebase — this is the only tick that revisits unchanged code |
| Last scheduled baseline can't be recovered (history rewrite, deleted PRs, unparseable naming) | `full` | Whole codebase — every failure mode degrades to `full`, never to a hard error |
| Any other tick | `incremental` | Only files changed since the last scheduled scan, plus their direct importers/callers (one hop), capped at 50 files |

**No state store is involved.** The previous scan's baseline commit is recovered from artifacts prior runs already created: the `perf/scheduled-<YYYYMMDD>-<short-sha>` branch name (primary) or the PR body's `Trigger: Scheduled run @ <sha>` line (fallback), across open, merged, *and* closed scheduled PRs.

Two consequences worth knowing:

- **Quiet repos skip for free.** If nothing analyzable changed since the last scan, an incremental tick stops before any analysis with `Skipped: no analyzable changes on <branch> since last scheduled scan @ <sha>.` — the second skip message the schedule flow can emit, alongside the open-PR idempotency skip.
- **The PR says what was scanned.** A scheduled PR's slim body carries a `Scan window:` line — `<last-sha>..<baseline-sha>` for an incremental scan, `full @ <baseline-sha>` for a full one — so reviewers always know the coverage behind the fix.

The four analyzer sub-agents also run on a smaller, cheaper model than the orchestrator (see the `model:` frontmatter in `agents/*-analyzer.md`) — pattern-spotting over a confined file set doesn't need the large model; the safety gate and ranking in the orchestrator do.

---

## Cron expression syntax

`cron` is a standard **5-field** expression. Each field, left to right, restricts a different unit of time; a field set to `*` means "every value" (no restriction):

```
 ┌───────────── minute        (0–59)
 │ ┌─────────── hour          (0–23)
 │ │ ┌───────── day-of-month  (1–31)
 │ │ │ ┌─────── month         (1–12, or JAN–DEC)
 │ │ │ │ ┌───── day-of-week   (0–7, where 0 and 7 = Sunday, or SUN–SAT)
 │ │ │ │ │
 * * * * *
```

| Position | Field | Allowed values | `*` means |
|---|---|---|---|
| 1 | minute | `0`–`59` | every minute |
| 2 | hour | `0`–`23` (24-hour clock) | every hour |
| 3 | day-of-month | `1`–`31` | every day of the month |
| 4 | month | `1`–`12` or `JAN`–`DEC` | every month |
| 5 | day-of-week | `0`–`7` (`0`/`7` = Sunday) or `SUN`–`SAT` | every day of the week |

Common value forms in any field:

| Form | Example | Meaning |
|---|---|---|
| Single value | `30` in minute | exactly minute 30 |
| `*` | `*` in day-of-month | every day |
| Step (`*/n`) | `*/5` in minute | every 5 minutes (0, 5, 10, …) |
| List | `1,15` in day-of-month | the 1st and 15th |
| Range | `1-5` in day-of-week | Monday through Friday |

**Worked examples:**

| Expression | Reads as |
|---|---|
| `0 2 * * *` | minute 0, hour 2, every day → **daily at 02:00** |
| `30 17 * * *` | minute 30, hour 17, every day → **daily at 17:30** |
| `0 2 * * 1` | minute 0, hour 2, only day-of-week 1 → **every Monday at 02:00** |
| `*/5 * * * *` | every 5th minute, every hour/day → **every 5 minutes** |
| `0 9 1 * *` | minute 0, hour 9, day-of-month 1 → **09:00 on the 1st of every month** |

Times are always evaluated against the rule set's `timezone` (see below), **not** the server's local time.

---

## Choosing a `cron` expression

Pick a cadence that matches how often you actually want a new optimization PR to review. With incremental scanning, most ticks only analyze the last day's churn (or skip outright when nothing changed), so a nightly cron is cheap — the periodic full-scan day is the only expensive tick. The idempotency guard still means a too-frequent cron mostly just no-ops until the last scheduled PR is merged or closed:

| Cadence | `cron` | `timezone` | When to use it |
|---|---|---|---|
| Nightly | `0 2 * * *` | your team's timezone | Default recommendation — incremental scan of the day's changes each night, full re-scan once a week on the `--full-scan-day` |
| Weekly | `0 2 * * 1` | your team's timezone | Lower-churn repositories, or to reduce PR review load |
| Every 5 minutes (doc example default) | `*/5 * * * *` | — | **Not recommended for this plugin** — included only because it's the schedule-rules doc's illustrative default. At this cadence the idempotency guard will skip nearly every tick once the first scheduled PR is open, which just burns container starts for no benefit. |

`timezone` is optional and defaults to `UTC` when omitted.

:::note
Per the Schedule Rule Sets doc: adding a new `schedule` rule set, or changing an existing one's `cron` / `timezone`, does not take effect until you **deactivate and reactivate the agent** in the Xianix Agent Studio. The scheduler only picks up schedule definitions on agent start.
:::

---

## Rule-set shape

A schedule rule set is a sibling of the `webhook` shape used for the label/tag triggers, with these differences:

| Field | Purpose |
|---|---|
| `schedule` | Human-readable id for the rule set (the cron analogue of `webhook`'s `name`) |
| `cron` | Standard 5-field cron expression controlling how often **every** execution in the rule set runs |
| `timezone` _(optional)_ | IANA timezone the cron expression is evaluated against — defaults to `UTC` |
| `repository` | **Plain literal strings** (no JSON-path payload to resolve against) — `url`, optional `name`, and `ref` (the default branch) |
| `with-envs` (rule-set level) | Declared once as a sibling of `executions`, merged into every execution — the common pattern here since credentials don't vary per tick |
| `executions[].execute-prompt` | Must explicitly pass `--schedule` (and, optionally, `--scope` / `--target` / `--full-scan-day`) since there's no issue/work-item body to parse hints from. Should also reinforce the single-change, slim-PR objective and the incremental-scan behavior (see the example prompts below). |

`match-any` and `use-inputs` are omitted — there's no payload to filter or extract from.

---

## GitHub Schedule Rule

```json
[
  {
    "schedule": "github-performance-optimizer-nightly",
    "cron": "0 2 * * *",
    "timezone": "UTC",
    "with-envs": [
      { "name": "GITHUB-TOKEN", "value": "secrets.GITHUB-TOKEN", "mandatory": true }
    ],
    "executions": [
      {
        "name": "github-performance-optimizer-scheduled",
        "platform": "github",
        "repository": {
          "url": "https://github.com/<org>/<repo>.git",
          "name": "<org>/<repo>",
          "ref": "main"
        },
        "use-plugins": [
          {
            "plugin-name": "perf-optimizer@xianix-plugins-official",
            "marketplace": "xianix-team/plugins-official"
          }
        ],
        "execute-prompt": "You are running a scheduled whole-codebase performance scan for repository {{repository-name}} on branch {{git-ref}}. There is no triggering issue or work item. Run /perf-optimize --schedule. Scan incrementally: analyze only the files changed since the last scheduled scan (recovered from the prior perf/scheduled-* PRs) plus their direct callers, falling back to a full-codebase scan on the first run, on the weekly full-scan day, or if the previous baseline cannot be recovered. If nothing analyzable changed since the last scan, skip the run without opening a PR. Then apply ONLY one optimization, chosen in two phases: first keep only fixes that are high-confidence, small and localized (a few lines in one file), and obviously behavior-preserving; then among those, pick the single HIGHEST-IMPACT one. Open a pull request with just that change. Do not batch multiple fixes and do not embed the full performance report; the PR must be small enough to review and approve in under a minute. If no fix passes the safety gate, open no PR — even if higher-impact but riskier items exist. If a performance PR from a prior scheduled run is still open, detect it and skip this run without opening a duplicate."
      }
    ]
  }
]
```

> **Placeholders.** Replace `<org>/<repo>` in both `repository.url` and `repository.name` with your actual values. `{{repository-name}}` and `{{git-ref}}` are auto-injected structural placeholders (see the linked schedule-rules doc) — no `use-inputs` block is needed to make them available to `execute-prompt`.
>
> **Required secret:** Store a GitHub PAT (`repo` + `workflow` scopes) or an equivalent GitHub App token in the agent's secret store under the key `GITHUB-TOKEN`. Declaring it at the rule-set level (sibling of `executions`) applies it to every execution in the set — there's only one here, but this is the idiomatic place for schedule rule-set credentials per the linked doc.

---

## Azure DevOps Schedule Rule

```json
[
  {
    "schedule": "azuredevops-performance-optimizer-nightly",
    "cron": "0 2 * * *",
    "timezone": "UTC",
    "with-envs": [
      { "name": "AZURE-DEVOPS-TOKEN", "value": "secrets.AZURE-DEVOPS-TOKEN", "mandatory": true }
    ],
    "executions": [
      {
        "name": "azuredevops-performance-optimizer-scheduled",
        "platform": "azuredevops",
        "repository": {
          "url": "https://dev.azure.com/<org>/<project>/_git/<repo>",
          "name": "<org>/<project>/<repo>",
          "ref": "main"
        },
        "use-plugins": [
          {
            "plugin-name": "perf-optimizer@xianix-plugins-official",
            "marketplace": "xianix-team/plugins-official"
          }
        ],
        "execute-prompt": "You are running a scheduled whole-codebase performance scan for repository {{repository-name}} on branch {{git-ref}}. There is no triggering work item. Run /perf-optimize --schedule. Scan incrementally: analyze only the files changed since the last scheduled scan (recovered from the prior perf/scheduled-* PRs) plus their direct callers, falling back to a full-codebase scan on the first run, on the weekly full-scan day, or if the previous baseline cannot be recovered. If nothing analyzable changed since the last scan, skip the run without opening a PR. Then apply ONLY one optimization, chosen in two phases: first keep only fixes that are high-confidence, small and localized (a few lines in one file), and obviously behavior-preserving; then among those, pick the single HIGHEST-IMPACT one. Open a pull request with just that change. Do not batch multiple fixes and do not embed the full performance report; the PR must be small enough to review and approve in under a minute. If no fix passes the safety gate, open no PR — even if higher-impact but riskier items exist. If a performance PR from a prior scheduled run is still open, detect it and skip this run without opening a duplicate."
      }
    ]
  }
]
```

> **Placeholders.** Replace the `<org>`, `<project>`, and `<repo>` placeholders in both `repository.url` and `repository.name` with your actual values. Change `ref` from `main` if your default branch is different.
>
> **Required secret:** Store an Azure DevOps PAT (`Code: Read, Write & Manage`, `Pull Request Threads: Read & Write`) in the agent's secret store under the key `AZURE-DEVOPS-TOKEN`. `Work Items` scope is not needed here — there's no work item to read or comment on.

---

## Scoping a scheduled scan

Since there's no issue/work-item body to parse `Scope:` / `Target:` hints from, set them directly in `execute-prompt` if you don't want a full, untargeted codebase scan every run:

```
"execute-prompt": "... run /perf-optimize --schedule --scope src/api,src/services --target api to scan only the API and services layers, prioritizing request-path bottlenecks. ..."
```

---

## Notes

- **Incremental by default, full weekly.** A scheduled tick analyzes only the changes since the last scheduled scan (plus one hop of direct callers); the whole codebase is only re-scanned on the `--full-scan-day` (default Sunday UTC), on the first run, or when the prior baseline can't be recovered. State lives entirely in the `perf/scheduled-*` branch names and PR bodies — deleting those PRs/branches simply forces the next tick back to a full scan. See *Incremental vs. full scans* above and orchestrator Steps 1a/1b.
- **One change per scheduled PR — by design.** A scheduled run applies exactly one Quick-win and ships a slim body; it never batches fixes or embeds the full report. This is enforced in `agents/orchestrator.md` (Step 8 selection) and `agents/perf-pr-author.md` (single commit + slim body), and reinforced by the `execute-prompt`. To work through more findings, let each scheduled PR merge and wait for the next tick.
- **One tick → one run, always.** Unlike the label/tag triggers, there's no `match-any` to gate on — every tick of the `cron` runs every execution in the rule set. The **idempotency guard** (orchestrator Step 1a) is what keeps a frequent cron from spamming duplicate PRs, not the rule itself.
- **`repository` is a literal, not a payload reference.** There's no webhook body to resolve `repository.clone_url` / `repository.default_branch` against, so `url`, `name`, and `ref` are written as plain strings (or the `{ "value": "...", "constant": true }` form — see the linked doc for both spellings).
- **Reactivate the agent after changing the schedule.** Per the linked Schedule Rule Sets doc, a new or edited `cron` / `timezone` only takes effect after you deactivate and reactivate the agent in the Xianix Agent Studio.
- **`with-envs` at the rule-set level** (sibling of `executions`) is merged into every execution in the set — the idiomatic place to declare `GITHUB-TOKEN` / `AZURE-DEVOPS-TOKEN` for a schedule rule set, since credentials don't vary per tick.
- These blocks are a top-level array entry in your rules configuration — see [Schedule Rule Sets](https://xianix-team.github.io/documentation/agent-configuration/rules/schedules/) and the parent [Rules Configuration](/agent-configuration/rules/) guide for the full file structure.
