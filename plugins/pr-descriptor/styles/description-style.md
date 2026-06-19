# PR Description Style Guide

This file defines tone, formatting, and language conventions for the description body produced by `agents/orchestrator.md` per `styles/pr-description-template.md`. It applies on every platform (GitHub, Azure DevOps, generic).

---

## General Principles

- **Describe the change, not the author.** Write about what the code now does, not what "you" did. Avoid second person entirely — a PR description is read by reviewers and future maintainers, not just the author.
  - Prefer: "User lookups now fall back to a cache before hitting the database."
  - Avoid: "I added a cache to user lookups." / "You should review the new cache logic."
- **Present tense, active voice.** Describe the resulting behavior, not the historical sequence of edits.
  - Prefer: "Failed webhook deliveries are retried up to 3 times with backoff."
  - Avoid: "Added retry logic that will retry failed deliveries." / "This commit adds..."
- **Plain language over code mechanics.** A reader who hasn't seen the diff should understand what changed. Name files/functions only when it adds clarity, not as the primary description.
  - Prefer: "Order creation and cancellation are now handled by separate endpoints."
  - Avoid: "Refactored OrderController.cs."
- **Concise.** Most bullets are one sentence. A paragraph is the exception, not the default. Don't pad short sections to look more thorough.
- **No filler.** No "This PR...", no "As part of this change...", no "Great improvement!", no apologies, no meta-commentary about the agent itself.

---

## What This Is Not

This plugin generates **descriptions**, not reviews. The output must never include:

- Verdicts (`APPROVE`, `REQUEST CHANGES`, `NEEDS DISCUSSION`, or anything similar)
- Severity tags (`CRITICAL` / `WARNING` / `SUGGESTION` / `POSITIVE`)
- Risk-rating emoji (🔴 🟡 🟢) or any emoji used as a status indicator
- Checkboxes (`- [ ]`) — these read as action items for a reviewer, which is not this agent's role
- Inline "fix" code blocks (before/after snippets proposing a change) — the code in this PR is the final state, not a draft to be corrected

If `change-analyst` ever surfaces something that reads like a review finding (e.g. "this looks like it could deadlock"), the orchestrator phrases it as a **risk to be aware of** in "Risk & Impact" — informational, not a request for changes.

---

## Markdown Conventions

- Headings use `##` for top-level body sections (matching `styles/pr-description-template.md`) and `###` for area/module subsections under "What Changed".
- Use `-` for bullet lists (not `*`).
- Use inline code spans for file paths, identifiers, config keys, and commands: `` `src/auth/login.ts` ``, `` `MAX_RETRIES` ``.
- Use fenced code blocks **only when a short snippet materially clarifies the change** — e.g. a new config key's shape, a new CLI invocation, a new API request/response shape. Do not include diff-style before/after blocks (see "What This Is Not").
- When a code block is used, tag it with the language of the file it's drawn from (` ```ts `, ` ```go `, ` ```yaml `, etc.) — this plugin is language-agnostic, so never default to a specific language.
- Tables are used sparingly — only where `styles/pr-description-template.md` specifies one (none currently do by default; `knowledge-curator`'s "Description Style Notes" may add one if a team's convention calls for it).

---

## Referencing Issues and Work Items ("Related Work")

Preserve every reference `change-analyst` extracted, in its original form:

- GitHub: `#123`, `owner/repo#123`, or with a closing keyword — `Fixes #123`, `Closes #123`, `Resolves #123`
- Azure DevOps: `AB#123`
- Jira-style: `PROJ-456`

Do not reformat these into links or change `Fixes` to `Closes` or vice versa — carry the original token forward exactly.

---

## Adapting to Team Conventions

If `knowledge-curator` returns "Description Style Notes" from the repository profile (e.g. "this team always links the Jira ticket from the branch name in the first line", "this team keeps descriptions under 5 bullets"), follow them **in addition to**, not instead of, the rules above — team conventions can add structure but cannot reintroduce verdicts, severity tags, or second-person language.
