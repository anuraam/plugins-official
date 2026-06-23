# Source of Truth Map

## Purpose

The source-of-truth map prevents artifact drift by defining which approved artifact should guide each downstream output.

---

# Greenfield Source Chain

| Artifact | Source of Truth |
|---|---|
| domain.md | Project context as known |
| personas.md | domain.md |
| executable-product-intent.md | domain.md + personas.md |
| client-input.md | Client-provided document, notes, or pasted input |
| intent-gap.md | executable-product-intent.md + client-input.md |
| client-verification.md | Client discussion and human-provided verification notes |
| updated executable-product-intent.md | previous executable-product-intent.md + client-verification.md + human removal/change instructions |
| mvp-scope.md | approved executable-product-intent.md |
| feature-map.md | approved executable-product-intent.md or approved mvp-scope.md |
| user-journeys.md | approved feature-map.md |
| units.md | approved executable-product-intent.md + approved feature-map.md + approved user-journeys.md |
| unit-validation-cases.md | approved executable-product-intent.md + approved feature-map.md + approved user-journeys.md + approved units.md |
| design.md | approved domain.md + personas.md + executable-product-intent.md + user-journeys.md + human design input |
| ui-prompts/ | approved user-journeys.md + approved design.md |
| corrective-prompts/ | AI-generated designs + design.md + user-journeys.md + human review notes |
| greenfield-handoff.md | all approved greenfield artifacts |

---

# Source Rule

The agent must state which source artifacts it used when generating every artifact.

Every artifact must include:

## Source Inputs

- [source artifact]
- [source artifact]

---

# Drift Prevention Rule

If an artifact conflicts with its source of truth, the agent must stop and ask the human which source should win.

The agent must not silently resolve major conflicts.


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
