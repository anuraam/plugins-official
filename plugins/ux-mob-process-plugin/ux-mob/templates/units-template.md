# units.md

## Purpose

This file defines the initial AI-DLC product units to be built later in Bolts.

A unit is a buildable product capability derived from the approved feature map and user journeys.

A unit should describe what product capability needs to be built, who it serves, why it matters, and which journey it supports.

Units are initial and may change after UI generation, PO review, prototype planning, or engineering review.

---

## Source Inputs

- executable-product-intent.md
- feature-map.md
- user-journeys.md

---

## Unit Derivation Rule

Units must be derived from approved features and user journeys.

For each high-priority or in-scope feature in feature-map.md, the agent must either:

1. Create a product unit, or
2. Explicitly mark the feature as deferred / not unitized with a reason.

Do not create technical foundation units in this file.

Technical setup work such as authentication, routing, database schema, infrastructure, or access-control implementation may be noted later during Prototype Builder or Engineering Preparation, but should not become a product unit unless it is explicitly defined as an approved product feature.

---



## Unit List Summary

| Unit ID | Unit Name | One-Line Purpose | Primary Persona | Related Feature(s) | Related Journey | Priority | Suggested Bolt |
|---|---|---|---|---|---|---|---|
| U01 |  |  |  |  |  |  |  |

---

# Product Units

## U01 — [Unit Name]

### Unit Purpose

This unit allows [persona] to [do capability] so they can [achieve value / reduce pain].

### Source Trace

- Feature ID:
- Feature name:
- Journey ID:
- Journey name:
- Product intent item:
- Persona:

### Why This Unit Exists

- Pain point / goal / need addressed:
- User value:
- Business value:

### What Needs To Be Built

- [Capability/action 1]
- [Capability/action 2]
- [Capability/action 3]

### What Is In Scope

- [In-scope item]

### What Is Out of Scope

- [Out-of-scope item]

### UX / UI Expectations

- Key screens or touchpoints:
- Required states:
  - Empty:
  - Loading:
  - Success:
  - Error:
  - Permission / unavailable:

### Data Needs

- Data to collect:
- Data to display:
- Data to update:
- Data to preserve:

### Dependencies

- Depends on:
- Enables:

### Suggested Bolt Execution

- Suggested Bolt:
- Can be grouped with:
- Reason:

### Notes

- Assumption:
- Needs human input:

---

## Deferred / Not Unitized Yet

Use this section for feature-map items that are not becoming product units in the current scope.

| Feature ID | Feature Name | Priority from Feature Map | Reason Not Unitized | Possible Future Unit |
|---|---|---|---|---|

---

## Suggested Bolt Runs

| Bolt Run | Units Included | Reason for Grouping | Dependencies | Notes |
|---|---|---|---|---|

---

## Expected Changes After UI / PO Review

- Units may be split, merged, renamed, reprioritized, or re-grouped after UI generation, PO review, prototype planning, or engineering review.

---

## Assumptions

- Assumption:

## Needs Human Input

- Needs human input:

## Approval Status

Pending / Approved / Needs Revision
