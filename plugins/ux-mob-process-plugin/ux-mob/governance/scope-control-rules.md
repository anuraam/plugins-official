# Scope Control Rules

## Purpose

Scope control prevents removed, rejected, or unverified ideas from drifting back into later artifacts.

---

# Scope Statuses

Every significant product idea, feature, journey, or unit should be treated as one of:

- In scope
- Out of scope
- Not decided
- Future candidate
- Needs client decision
- Removed
- Rejected by client

---

# Removal Rule

If an item is removed from executable-product-intent.md, the agent must not reintroduce it into:

- mvp-scope.md
- feature-map.md
- user-journeys.md
- units.md
- design.md
- ui-prompts/
- greenfield-handoff.md

unless the human explicitly restores it.

---

# Client Rejection Rule

If the client rejects an item, mark it as:

Rejected by client

Do not include it in downstream scope unless the human explicitly overrides the rejection.

---

# Future Candidate Rule

Future candidate items may be listed in notes or backlog sections, but they must not be included in MVP, feature map, units, or UI prompts unless approved.

---

# Out-of-Scope Rule

Out-of-scope items may be referenced only in:

- Out-of-scope notes
- Decision log
- Handoff open questions
- Future backlog

They must not be treated as active product requirements.

---

# Scope Traceability Rule

Every feature, journey, and unit must trace back to at least one approved product intent item.

If it cannot be traced, mark it as:

Needs human input: No approved product intent source found.
