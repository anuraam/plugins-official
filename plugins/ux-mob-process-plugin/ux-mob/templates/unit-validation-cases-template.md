# unit-validation-cases.md

## Purpose

This file defines how each AI-DLC unit should be validated after UI generation, PO review, prototype building, or Bolt execution.

Validation cases check whether the unit delivers the expected intent, journey behavior, state coverage, data behavior, usability, and user value.

---

## Source Inputs

- executable-product-intent.md
- feature-map.md
- user-journeys.md
- units.md

---

## Validation Summary

| Unit ID | Unit Name | Main Validation Goal | Priority | Status |
|---|---|---|---|---|
| U01 |  |  |  | Pending |

---

# Unit Validation Cases

## U01 — [Unit Name]

### Main Validation Goal

Validate that [persona] can [complete the core capability] so that [expected value / pain relief].

### Intent Check

This unit is valid only if it supports:

- Product intent:
- Pain point / goal / need:
- Expected user value:

### Core Acceptance Checklist

- [ ] User can [core action].
- [ ] User can [secondary action].
- [ ] User receives clear feedback after action.
- [ ] User can recover from error or missing input.
- [ ] The unit supports the intended journey steps.

### Journey Scenario

Given [persona/context]  
When [user performs key action]  
Then [expected outcome happens]  
And [value/feedback is visible]

### Unit State Coverage Checklist

- [ ] Empty state is useful and clear.
- [ ] Loading state is clear.
- [ ] Success state confirms the result.
- [ ] Error state explains the problem and recovery.
- [ ] Permission or unavailable state is handled if relevant.
- [ ] Edit or update state is handled if relevant.
- [ ] Delete, remove, or undo state is handled if relevant.

### Data Behavior Checklist

- [ ] Required data is captured.
- [ ] Required data is displayed.
- [ ] Updated data is saved correctly.
- [ ] Missing data is handled clearly.
- [ ] Invalid data is prevented or explained.
- [ ] Data is preserved when the user returns to the flow, if relevant.

### UX / Usability Checklist

- [ ] The next action is clear.
- [ ] The language is understandable.
- [ ] The flow does not require unnecessary steps.
- [ ] The UI supports the user goal without extra explanation.
- [ ] The unit reduces the intended pain or friction.
- [ ] The experience gives enough confidence or feedback to the user.

### UI Design Validation Checklist

Use this section when reviewing generated UI designs.

- [ ] UI includes the core action.
- [ ] UI supports the required journey steps.
- [ ] UI includes required states.
- [ ] UI shows or captures required data.
- [ ] UI makes success and failure clear.
- [ ] UI does not introduce out-of-scope behavior.
- [ ] UI supports the expected user value.

### Bolt Execution Validation Checklist

Use this section after the unit is built in Bolts.

- [ ] Built unit matches the expected capability.
- [ ] Built unit supports the intended journey.
- [ ] Built unit handles required states.
- [ ] Built unit handles required data.
- [ ] Built unit satisfies the core acceptance checklist.
- [ ] Built unit does not introduce obvious regression or scope drift.

### Open Questions

- Needs human input:

---

## Expected Changes After UI / PO Review

- Unit validation cases may be updated after UI generation.
- Unit validation cases may be updated after PO review.
- Unit validation cases may be updated after prototype planning.
- Unit validation cases may be updated after engineering review.
- Unit validation cases may be updated after Bolt execution.

## Assumptions

- Assumption:

## Needs Human Input

- Needs human input:

## Approval Status

Pending / Approved / Needs Revision
