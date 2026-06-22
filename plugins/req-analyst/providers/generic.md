# Provider: Generic / Plain Text

Use this provider when:

- The git remote does not match GitHub or Azure DevOps
- The user supplies the requirement as plain text (no remote at all)
- API posting is otherwise not possible

## Behaviour

In generic mode the elaboration is **not posted to a remote platform**. Instead, each lens is written to a local file as a separate section so it can be consumed by an external process, CI system, or human operator.

---

## Writing the Report File

Write the full compiled elaboration to a file in the repository root (or current working directory if there is no repo):

```
requirement-elaboration-report.md
```

The file must be written even if the readiness signal is `GROOMED` — it serves as the audit artifact.

**File format:**

```markdown
# Requirement Elaboration Report

Generated: <ISO 8601 timestamp>
Source: <repo URL or "plain text input">
Item: #<issue number or short title>
Readiness signal: GROOMED | NEEDS CLARIFICATION | NEEDS DECOMPOSITION

---

## Elaboration Summary
<summary and intent decomposition>

---

## Fit with Existing Requirements
<orchestrator's fit note — omit if no requirement docs in the repo>

---

## Context
<5–8 bullets from context-analyst — intent, journey, personas, domain, competitors — omit if no findings>

---

## Open Questions & Gaps
<gap-risk-analyst output — framed as prompts for the team>

---

## Refined Requirement
<structured requirement compiled by the orchestrator in Step 10 — user intent, functional requirements, non-functional requirements, user journey, and acceptance criteria; TODO markers for all assumed values>
```

---

## Output

On completion:

```
Elaboration complete: <signal> — report written to requirement-elaboration-report.md — refined requirement included
```

---

## When to Use

This provider is the correct fallback for:

- **Plain text input** — the user pastes a requirement and wants the elaboration in a file
- Azure Boards (when REST API posting is not configured)
- Jira instances (API posting not yet implemented — use generic)
- Self-hosted issue trackers
- Local or offline runs where no remote API is available
- CI environments where only the report file output is needed
