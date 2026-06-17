# Unit Validation Rules

## Purpose

These rules ensure unit-validation-cases.md connects AI-DLC units back to product intent, user journeys, expected states, data behavior, and user value.

---

# Required Traceability

Every validation case must trace to:

- One unit

And at least one approved source:

- Product intent
- Feature
- User journey
- Persona pain point / goal / need

If traceability is missing, mark:

Needs human input: No traceable source found.

---

# Validation Case Types

Each unit should include:

1. Intent validation
2. Journey validation
3. State validation
4. Data validation
5. Experience validation

---

# Intent Validation

Checks whether the unit satisfies the original product intent.

---

# Journey Validation

Checks whether the unit supports the expected user journey behavior.

Use Given / When / Then where useful.

---

# State Validation

Checks required states such as:

- Empty
- Loading
- Success
- Error
- Permission denied
- Edit
- Delete / remove
- Partial completion
- Offline / unavailable, if relevant

---

# Data Validation

Checks whether the unit collects, displays, updates, preserves, or prevents invalid data correctly.

---

# Experience Validation

Checks whether the unit reduces the intended pain, supports the intended need, or creates the intended user value.

---

# UI Review Usage

During Design Review, generated UIs must be reviewed against unit-validation-cases.md.

The agent must identify:

- Covered validation cases
- Partially covered validation cases
- Missing validation cases
- UI gaps that prevent validation
- Corrective prompts needed

---

# Bolt Execution Usage

During later Bolt execution or prototype building, unit-validation-cases.md should be used as an acceptance and validation reference.
