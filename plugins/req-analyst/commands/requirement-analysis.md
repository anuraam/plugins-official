---
name: requirement-analysis
description: Surround a backlog item with the context a senior analyst would bring to a refinement session — fit with existing requirements, domain knowledge, competitive insight, user journeys, persona impact, usability and adoption considerations, and open questions. Works with GitHub Issues, Azure DevOps Work Items, or plain text. Usage: /requirement-analysis [issue-number or work-item-id]
argument-hint: [issue-number | work-item-id]
---

Elaborate the backlog item $ARGUMENTS — act as a thinking partner, not a gatekeeper.

## What This Does

This command invokes the **orchestrator** agent. It fetches the item, indexes the repository for product/requirements documents (PRDs, specs, RFCs, ADRs, feature briefs, user stories), reasons about how the new ask fits the existing product context, then runs two analysts in sequence.

**Phase 1 — Context (`context-analyst`):**

A single all-in-one pass returning 5–8 bullets covering intent (the "why"), user journey, personas & adoption, domain knowledge, and competitive patterns.

**Phase 2 — Gap & Risk (`gap-risk-analyst`):**

Open questions, assumptions worth validating, acceptance criteria worth tightening — framed as **prompts for the team**, not blockers.

The orchestrator also reasons explicitly about **fit with existing requirements** — overlaps, dependencies, contradictions, and gaps at the **product/requirements level** (not the code level).

## How to Use

```
/requirement-analysis 42          # Elaborate GitHub issue #42 or Azure DevOps work item #42
```

## Platform Support

The plugin auto-detects the hosting platform from your git remote URL:

| Remote URL contains | Platform | How items are fetched | How elaboration is delivered |
|---|---|---|---|
| `github.com` | GitHub | `gh` CLI | Ordered comments via `gh` CLI |
| `dev.azure.com` / `visualstudio.com` | Azure DevOps | REST API (`curl`) | Ordered comments via REST |
| Anything else | Generic / plain text | User-provided | Written to `requirement-elaboration-report.md` |

## How It Posts

Each section is posted as a **separate comment** on the issue/work item, preserving the original description. The thread looks like:

1. **Elaboration Summary** — a short overview, the readiness signal, and the key takeaways
2. **Fit with Existing Requirements** — overlaps, dependencies, contradictions, gaps with PRDs/specs/ADRs/feature briefs already in the repo *(skipped if no requirement docs exist)*
3. **Context** — the 5–8 bullets returned by context-analyst as-is, under `## Context`. No sub-sections, no expansion.
4. **Open Questions & Gaps** — assumptions to validate, ACs worth tightening — as prompts for the next refinement *(skipped if no findings)*
5. **Refined Requirement** — a structured requirement spec compiled from the full analysis, always posted last

Sections with no findings are **skipped**, not filled with "None identified."

## Readiness Signal (Hint, Not a Gate)

A lightweight label/tag is also applied as a triage hint — but the real value is in the elaboration itself. The team decides what to do next.

| Signal | What it means |
|---|---|
| `GROOMED` | Intent is clear and the elaboration didn't surface critical open questions |
| `NEEDS CLARIFICATION` | Worth a short conversation before development picks it up |
| `NEEDS DECOMPOSITION` | Likely too large — the elaboration suggests how it might split |

## After the Elaboration

The agent outputs:

```
Elaboration posted on issue #<number>: <signal> — <N> comments — <N> open questions — refined requirement posted
```

## Prerequisites

- **GitHub**: `gh` CLI installed and authenticated (see `docs/platform-config.md`)
- **Azure DevOps**: `AZURE-DEVOPS-TOKEN` environment variable set (see `docs/platform-config.md`)
- **Plain text / unknown platform**: nothing — the report is written to a local file

---

Starting elaboration now...
