# UX Mob Agent Guardrails

## Purpose

These guardrails keep the agent safe, consistent, traceable, and useful during AI-native UX mob elaboration.

## Core Rules

1. Work phase by phase.
2. Never proceed without explicit human approval.
3. Show draft artifact content in chat before saving.
4. Save only after explicit artifact save approval.
5. Keep artifact save approval separate from phase approval.
6. Save all project artifacts only under [workspace-root]/projects/[project-folder]/.
7. Do not invent missing product, user, business, domain, design, compliance, or engineering context.
8. Mark assumptions clearly.
9. Mark inferred content clearly.
10. Mark missing information clearly.
11. Do not generate downstream artifacts from unapproved upstream artifacts.
12. Respect in-scope, out-of-scope, not-decided, and future-candidate status.
13. Do not reintroduce removed scope unless the human explicitly restores it.
14. Do not overwrite approved artifacts without human approval.
15. Do not silently edit process files, templates, or agent rules.
16. Do not build a prototype inside the Greenfield mob process.
17. For Brownfield, AI Readiness is mandatory before any brownfield work type.
18. Do not write generated artifacts to the kit repository root.

## Approval Rules

Every phase must have two approval checkpoints:

### Artifact Save Approval

The human approves saving a specific artifact file.

### Phase Approval

The human approves the whole phase as complete.

Saving an artifact does not approve the phase.

## Chat-First Rule

Before saving any generated artifact, the agent must show:

- Artifact name
- Target save path
- Full draft content or agreed section-by-section preview
- Review options

## Project Folder Rule

All generated project artifacts must be saved under:

[workspace-root]/projects/[project-folder]/

If the agent is about to save outside this path, it must stop and ask for correction.

## Human Override Rule

If a human asks to bypass a guardrail, the agent must:

- Confirm the risk
- Record the decision in the decision log
- Mark the risk clearly
- Continue only after explicit confirmation

## Notes

These guardrails apply to Antigravity, Cursor, and Claude Code adapters.


# Unit Validation Traceability Rule

Every validation case in `unit-validation-cases.md` must trace to:
- one unit
and at least one of:
- product intent
- feature
- user journey
- persona pain point / goal / need

If traceability is missing, the agent must mark:
`Needs human input: No traceable source found.`

# Unit Coverage and Restriction Rules

## Feature Coverage Rule
Every high-priority or in-scope feature in feature-map.md must be:
- mapped to a unit, or
- listed under Deferred / Not Unitized Yet with a reason.

## Technical Unit Restriction
The agent must not create technical foundation units in units.md unless they are explicitly listed as approved product features in feature-map.md.


## Context Isolation Rule
For every new mob run, the agent must treat the current project as isolated.
The agent must not use:
- previous mob run outputs
- archived project artifacts
- old Cabin Connect outputs
- previous conversation memory
- inferred prior project decisions
- old drafts
- old phase artifacts
- old generated files outside the active project folder
unless the human explicitly provides or approves them as current inputs.

The only allowed sources are:
1. The selected process file
2. The relevant current template file
3. The active project-state.json
4. Approved upstream artifacts inside [workspace-root]/projects/[project-folder]/
5. Inputs explicitly provided by the human during the current run

## Template Enforcement Rule
Before generating any artifact, the agent must:
1. Open and read the relevant template from ux-mob/templates/
2. Use the template headings exactly
3. Preserve the template structure
4. Fill only what can be supported by approved inputs or current human input
5. Mark missing content as `Needs human input`
6. Mark assumptions as `Assumption`
7. Mark inferred content as `Inferred`

The agent must not replace the template structure with its own structure.

## Source Declaration Rule
Every draft artifact preview must start with:

### Source Declaration
Allowed sources used:
- [source file or human input]

Not used:
- previous mob runs
- archived artifacts
- prior conversation memory
- unapproved drafts

## No Prior Context Rule
If the agent recognizes information from a previous run, it must not reuse it unless the human explicitly says:
"Use previous run context"
or provides the specific file as an approved input.

## Required Phase Input Gate
Before generating a phase artifact, the agent must state:
1. Required inputs for this phase
2. Which required inputs are available
3. Which required inputs are missing
4. Whether the phase can proceed

If required inputs are missing, the agent must ask for them or mark them as `Needs human input`.

## Draft Generation Rule
The agent must not pre-fill templates with confident content unless the source is available and declared.

If content is based on domain reasoning, label it: Evidence: Domain Analysis
If content is inferred, label it: Inferred
If content is uncertain, label it: Needs validation
