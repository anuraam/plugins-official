# Release Notes Style Guide

This guide defines the voice, tense, and formatting conventions for release notes produced by the Release Note Maintainer Agent.

---

## Voice and Perspective

Write for the **end-user or operator** who consumes the software — not for the engineer who built it.

- **Past tense** — changes have already shipped. "Added support for X." "Fixed a crash when Y." Never "Adds" or "fix".
- **End-user perspective** — describe the observable behaviour change, not the internal implementation. "File uploads now resume after a network interruption" is correct; "Rewrote the upload pipeline to use chunked streaming" is not.
- **Active, plain English** — short declarative sentences. No jargon unless the audience is a developer audience and the knowledge profile confirms it.
- **No hedging** — do not write "may have", "could potentially", or "seems to". State what changed.

---

## What This Is Not

- **No severity tags** — do not write `[Critical]`, `[High]`, `[P1]`, or any risk score next to a fix.
- **No checklist or task-list format** — no `- [ ]` or `- [x]` items.
- **No diffs or raw code blocks** — exception: a breaking change that requires a migration snippet.
- **No implementation detail** — PR numbers, commit hashes, branch names, and function names do not belong in the output. Work item references (issue numbers, ticket IDs) are the only cross-reference format.
- **No verdicts on PR quality** — do not rate, score, or editorialize about how well a change was made.
- **No internal developer notes** — knowledge profile content is never included verbatim.

---

## Prerelease Note

When `IS_PRERELEASE=true`, place this line immediately after the title, before any other content:

```
> **Not recommended for production use.** This is a pre-release build.
```

---

## Markdown Conventions

- Use `##` for section headings (title is also `##`).
- Use `-` for bullet lists, not `*`.
- Bold with `**…**` only for: breaking-change area labels, deprecated item names, and the prerelease warning.
- No inline HTML.
- No trailing whitespace.
- End each bullet with a period.
- One blank line between sections.

---

## Length

- **Summary**: 2–4 sentences maximum.
- **Bullets**: one line per change where possible; two lines maximum if a migration note is needed.
- **Total document**: aim for under 80 lines for a typical minor release. A large major release with many breaking changes may be longer — prefer clarity over brevity in those cases.

---

## Related Work Item Formats

Accept any of:

| Format | Example |
|---|---|
| GitHub issue | `#123` |
| GitHub PR (only when no issue exists) | `#456` |
| Azure DevOps work item | `AB#789` |
| Jira | `PROJ-123` |
| Linear | `TEAM-456` |

List each as `- #<id>: <short description>` under "Related Work Items". Do not embed URLs — the work item ID is the stable reference.
