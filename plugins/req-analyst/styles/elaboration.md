# Requirement Elaboration Output Style Guide

Formatting and tone conventions for all `req-analyst` plugin output.

---

## Plugin Stance: Thinking Partner, Not Gatekeeper

The plugin's job is to **expand the team's thinking** — not to judge whether an item is "ready." Frame everything as observations and prompts the team can react to in the next refinement, not as work that must be done before development can start.

A lightweight readiness signal (`GROOMED` / `NEEDS CLARIFICATION` / `NEEDS DECOMPOSITION`) is also applied as a label/tag, but it is a **triage hint** — the real value is in the elaboration itself.

---

## Core Lenses

The context-analyst covers all of these in a single pass and returns them as bullets under `## Context`:

| Lens | Question |
|---|---|
| **Intent** | Why does this exist? What problem disappears if solved? |
| **User journey** | Where does this sit in the broader workflow? Usability touchpoints? Friction risks? |
| **Personas & adoption** | Who is affected? How will they get from today to actually using this? |
| **Domain & competitive** | What domain knowledge, regulations, and competitor approaches apply? |

The orchestrator handles **Fit with existing requirements** and **Open questions** separately.

---

## General Principles

- **Thinking partner first** — observations and prompts, never blockers
- Be **specific and grounded** — every observation, gap, or risk must reference the actual issue content or an existing requirement document
- Be **actionable** — every question must be answerable with a yes/no or concrete decision
- Be **proportionate** — a bug fix should not produce a 500-line elaboration
- Be **concise** — each section must be scannable in under 30 seconds; **skip sections with no findings**
- Bring **domain knowledge and competitive context** — enrich, don't just restate
- Avoid filler: "Great requirement!", "This is interesting", "As an AI…"

---

## Severity Levels (Triage Hints)

| Label | When to use |
|---|---|
| `CRITICAL` | Without a decision here, two people would build two different things — worth a focused conversation before pickup |
| `WARNING` | Worth a quick conversation in refinement; developers will guess otherwise |
| `INFO` | Improves quality; safe to defer |

These are hints — the team decides what blocks them.

---

## Readiness Signal

| Signal | Meaning |
|---|---|
| `GROOMED` | Intent clear; no critical open questions; user context and workflow defined |
| `NEEDS CLARIFICATION` | Critical or warning open questions remain; intent ambiguous |
| `NEEDS DECOMPOSITION` | Likely too large — spans multiple domains or too many open dimensions; the elaboration suggests how it might split |

---

## Open-Question Format

```
| # | Question / Assumption | Severity | Suggested prompt for the team |
|---|---|---|---|
| 1 | [What's ambiguous — reference specific issue content] | CRITICAL | [Precise question] — @[person] |
```

- Questions must be answerable — avoid open-ended "tell me more"
- Tag the appropriate person when posting

---

## Comment Order

Post each as its own comment, in this order:

1. **Elaboration Summary** — readiness signal, key takeaways
2. **Fit with Existing Requirements** *(skip if repo has no requirement docs)*
3. **Context** — 5–8 bullets from context-analyst covering intent, journey, personas, domain, competitors. No sub-sections.
4. **Open Questions & Gaps** — from gap-risk-analyst, framed as prompts
5. **Refined Requirement** — structured spec from `styles/requirement-template.md`, always last

**Skip sections with no findings** rather than writing "None identified."

---

## Risk Rating

| Level | Meaning |
|---|---|
| Low | Unlikely or minor |
| Medium | Possible and noticeable |
| High | Likely or significant |

---

## Tone

- **Neutral, collaborative** — refinement input, not a review
- Gaps are observations: "Error handling is not specified" not "You forgot error handling"
- Concise — bullet points over paragraphs
- Questions must be precise: "Should the system prevent duplicate entries or allow them?" not "What about duplicates?"
- Frame value/priority as observations for the team, not decisions
