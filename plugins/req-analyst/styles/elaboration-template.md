# Elaborated Requirement Template

This template defines the structure for the compiled elaboration. The orchestrator agent must follow this format exactly when compiling findings from sub-agents.

The plugin is a **thinking partner**, not a gatekeeper. Frame everything as observations and prompts the team can react to in the next refinement — not as work that must be done before development can start.

**Skip any section with no findings — never write "None identified."**

---

## Elaborated Requirement

**Issue:** #[number] — [title]
**Type:** Story | Task | Bug | Spike
**Readiness signal (hint):** `GROOMED` | `NEEDS CLARIFICATION` | `NEEDS DECOMPOSITION`

---

### Summary

[3–5 sentences: what this is, the underlying intent (problem being solved), how success is defined, and the most useful thing this elaboration surfaced.]

| Dimension | Detail |
|---|---|
| **Stated need** | [What they asked for] |
| **Underlying intent** | [What problem this solves; what disappears if done] |
| **Success definition** | [How they'll judge it; "this is a win" criteria] |
| **Current workaround** | [What exists today; pain being replaced] |

---

### Fit with Existing Requirements

> Reasoning at the **product / requirements level** about how this item fits the context already documented in the repo (PRDs, specs, RFCs, ADRs, feature briefs, user stories). **Not a code-level analysis.**

- **Overlaps:** [Existing documents that already cover part of this — file path + what they cover]
- **Dependencies:** [Things this assumes are already specified elsewhere]
- **Contradictions:** [Where this conflicts with a previously-agreed requirement, ADR, or feature brief]
- **Gaps:** [What this exposes that the existing requirements don't say]

*(Skip entirely if the repo has no requirement documents. If documents exist but the new ask sits cleanly alongside them, just say so in one line.)*

---

### Context

> 5–8 bullets from the context-analyst covering intent, journey, personas, domain, and competitor patterns. No sub-sections — bullets as-is. Skip this section if no findings.

[Bullet points from context-analyst]

---

### Open Questions & Gaps

> Framed as **prompts for the next refinement**, not as blockers. The team decides what to do with them.

| # | Question / Assumption | Severity | Suggested prompt for the team |
|---|---|---|---|
| 1 | [What's ambiguous or missing] | `CRITICAL` / `WARNING` / `INFO` | [Precise, answerable question] — @[person] |

*(Skip if no genuine gaps were found.)*

---

> After posting these sections, the orchestrator posts the Refined Requirement as a final separate comment using `styles/requirement-template.md`.

