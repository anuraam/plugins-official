# Structured Requirement Template

This template defines the structured requirement comment the orchestrator posts in **Step 10**, after all analysis is complete. It takes the original issue as its starting point and enriches it with findings from the context-analyst and gap-risk-analyst.

**Filling the template:**
- Use analysis outputs to populate each section as concretely as possible.
- Where the issue or analysis does not provide enough information to fill a field, make the most reasonable assumption you can from available context and mark it with a `> **TODO:**` blockquote.
- Assumptions should be specific enough that a human reviewer can confirm or correct them in one sentence — never leave a TODO vague.
- Every `[TODO]` marker is a handoff to the human: state what you assumed, why, and what they need to confirm.

**Skip any section with no findings — never write "None identified."**

---

## Refined Requirement

> This is a structured representation of the original issue, enriched by the elaboration analysis.  
> Items marked **TODO** are agent assumptions — please review and update before pickup.

---

### User Intent

**As a** [primary persona — from context-analyst Personas bullet; if not stated, name the most likely user type and mark TODO]  
**I want to** [user goal — from issue title + context-analyst Intent bullet; restate in action terms]  
**So that** [business value / outcome — from context-analyst Intent or Success bullet]

> **TODO (if persona was assumed):** Confirm the persona with the product owner — assumed from [reasoning].  
> **TODO (if value was assumed):** Confirm the business value — assumed to be [assumption] based on [context].

---

### Functional Requirements

> Derived from the issue body, intent analysis, and gap analysis. Each requirement must be independently testable.

| # | Requirement | Confidence | Notes |
|---|---|---|---|
| FR-1 | [Functional requirement — stated in the issue or clearly implied by intent] | Stated | — |
| FR-2 | [Functional requirement — inferred from analysis; mark Assumed if not explicit] | **Assumed** | [Reasoning and what needs to be confirmed] |

> **TODO:** Review assumed FRs. Add any requirements that are missing. Decompose any FR that describes more than one testable behaviour.

---

### Non-Functional Requirements

> Derived from domain rules, gap analysis, and context (performance, security, accessibility, reliability, etc.). Omit this section only if no NFRs apply.

| # | Category | Requirement | Confidence |
|---|---|---|---|
| NFR-1 | [Category] | [Requirement — with a concrete, measurable target where possible] | Stated / **Assumed** |

> **TODO:** Confirm NFRs with engineering. Add explicit SLAs, performance targets, and compliance requirements where applicable.

---

### User Journey

> The broader flow this requirement belongs to, with the steps scoped to this item. Based on context-analyst Journey bullet and gap-risk-analyst edge cases.

**Entry point:** [How the user arrives at this feature — stated or assumed from journey context]

| Step | User action | System response |
|---|---|---|
| 1 | [Action] | [Response] |
| 2 | … | … |

**Exit point:** [What happens after this flow completes — the user's next step]

**Edge flows:**
- [Alternate path or failure scenario from gap-risk-analyst — one bullet per flow]

> **TODO (if journey was assumed):** Walk through the journey with a user or PO to validate step ordering and edge flows. Assumed from [context-analyst Journey bullet / issue description].

---

### Acceptance Criteria

> Written in Given/When/Then format. Each criterion should be independently verifiable. Start with the happy path, then add failure and edge cases from the gap analysis.

```gherkin
# Happy path
Given [precondition / context]
When  [user action]
Then  [expected outcome]

# Edge case / failure path (add one block per scenario from gap analysis)
Given [precondition]
When  [action]
Then  [expected safe behaviour]
```

> **TODO:** Review and expand ACs. Ensure every CRITICAL and WARNING gap from the analysis is covered by at least one criterion. Add ACs for edge cases not yet captured above.
