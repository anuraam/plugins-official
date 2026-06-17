# Phase Dependencies

## Purpose

Phase dependencies prevent the agent from generating downstream artifacts from unapproved or unstable upstream artifacts.

---

# Greenfield Phase Dependencies

| Phase | Phase Name | Cannot Start Until |
|---|---|---|
| 1 | Pre-Client Domain Analysis | Project context as known is provided |
| 2 | User Group & Persona Analysis | domain.md is saved and phase approved |
| 3 | Executable Product Intent | personas.md is saved and phase approved |
| 4 | Client Input Capture | executable-product-intent.md is saved and phase approved |
| 5 | Intent Gap Analysis | executable-product-intent.md and client-input.md are saved |
| 6 | Client Verification & Scope Agreement | intent-gap.md is saved and phase approved |
| 7 | Intent Cleanup / Scope Removal | client-verification.md is saved and human provides removal/change instructions |
| 8 | MVP Scope Suggestion — Optional | executable-product-intent.md is updated and approved |
| 9 | Feature Map | executable-product-intent.md or mvp-scope.md is approved |
| 10 | User Journeys | feature-map.md is saved and phase approved |
| 11 | AI-DLC Unit Definition | feature-map.md and user-journeys.md are saved and approved |
| 12 | Unit Validation Cases | units.md is saved and phase approved |
| 13 | Design Direction | unit-validation-cases.md is saved and phase approved |
| 14 | Journey-Based UI Prompt Generation | user-journeys.md and design.md are saved and approved |
| 15 | Design Review & Corrective Prompts — Optional | AI-generated designs or human review notes are provided |
| 16 | Handoff / Completion | Required greenfield artifacts are saved and approved |

---

# Brownfield Dependency Rules

## Mandatory AI Readiness

For Brownfield projects, no brownfield work type may start until:

brownfield_ai_readiness = approved

This applies to:

- Add New Feature
- Complete Revamp
- Improve Existing Feature

## Brownfield Work Type Unlock

Only after AI Readiness is approved may the agent ask:

Which brownfield work type should we run next?

1. Add New Feature
2. Complete Revamp
3. Improve Existing Feature

---

# Dependency Enforcement Rule

Before starting any phase, the agent must check:

- Are required upstream artifacts present?
- Are required upstream artifacts approved?
- Are required human decisions available?
- Is the current project-state.json consistent?

If any dependency is missing, the agent must stop and ask for the missing input.
