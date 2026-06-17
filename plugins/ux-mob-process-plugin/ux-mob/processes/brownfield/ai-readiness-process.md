# Brownfield AI Readiness Process

## Purpose

This process prepares an existing product so AI tools can safely support future brownfield work.

Brownfield AI Readiness is mandatory before:

- Add New Feature
- Complete Revamp
- Improve Existing Feature

The goal is to create or verify the existing product context before AI is used for design, prototyping, or build work.

This process avoids overwhelming the team by starting with a simple product description, checking existing artifacts, and reconstructing only what is missing.

## Core Execution Rules

1. **Chat-First Preview**: Every artifact drafted in this process MUST be previewed in chat before saving.
2. **Explicit Save Approval**: Do not save any artifact to `projects/[project-folder]/outputs/ai-readiness/` until the human explicitly approves saving it.
3. **Phase Approval is Separate**: Phase approval happens only after all required artifacts for that phase are saved.

---

# Final Brownfield AI Readiness Process Map

1. Existing Artifact Check
2. Basic Product Description Capture
3. Domain Analysis
4. User Group & Role Analysis
5. Existing Feature Map Capture / Reconstruction
6. Existing Navigation / IA Map Capture / Reconstruction
7. Existing Journey Reconstruction
8. Design System & Component Context
9. Product Rules, Constraints & Do-Not-Invent List
10. AI Context Pack Assembly
11. AI Readiness Review & Approval

---

# Phase 1 — Existing Artifact Check

## Goal

Check whether the existing product already has the artifacts needed for AI Readiness.

If reliable artifacts already exist, reuse them instead of recreating them.

## Required Inputs

- Project folder
- Any existing docs, files, screenshots, Figma files, route lists, product notes, or prior artifacts available in the project

## Outputs

- `projects/[project-folder]/outputs/ai-readiness/ai-readiness-artifact-audit.md`

## ai-readiness-artifact-audit.md Must Include

- Artifact checklist
- Existing artifact path if available
- Artifact status
- Recommended action
- Human decision
- Notes

## Artifact Checklist

Check for:

- existing-product-brief.md
- domain.md
- user-groups-and-roles.md
- feature-map.md
- navigation-map.md
- current-user-journeys.md
- design-system-context.md
- component-inventory.md
- product-rules.md
- business-rules.md
- constraints-and-debt.md
- do-not-invent-list.md
- ai-context-pack.md

## Artifact Status Values

Use:

- Available
- Missing
- Outdated
- Needs review
- Needs reconstruction
- Approved
- Not applicable

## Activities

- Scan the active project folder and `projects/[project-folder]/outputs/ai-readiness/`.
- Identify existing AI Readiness artifacts.
- Identify related product documentation.
- Identify screenshots, Figma exports, routes, app walkthrough notes, or product specs.
- Classify each artifact.
- If an artifact already exists, the agent MUST offer the human the choice to:
  1. Use existing artifact as approved
  2. Review existing artifact
  3. Revise existing artifact
  4. Recreate artifact from scratch
  5. Skip this artifact as not applicable
- Create `projects/[project-folder]/outputs/ai-readiness/ai-readiness-artifact-audit.md`.

## Key Questions

Ask only what is needed:

- Are there any existing product docs or artifacts I should use?
- Which existing artifacts are current and trustworthy?
- Which artifacts should be ignored?
- Are there screenshots, Figma files, app routes, or walkthrough notes available?

## Notes

Do not recreate artifacts that already exist and are approved.

If an artifact exists but is outdated or unclear, mark it as Needs review or Needs reconstruction.

---

# Phase 2 — Basic Product Description Capture

## Goal

Capture a simple explanation of the existing product before reconstructing detailed context.

## Required Inputs

Ask the human for:

- What is this existing product?
- Who roughly uses it?
- What does the product help them do?
- What brownfield work are we preparing for, if known?

## Outputs

- `projects/[project-folder]/outputs/ai-readiness/existing-product-brief.md`

## existing-product-brief.md Must Include

- Product name
- Product description
- Current users, if known
- Main product purpose
- Main product areas, if known
- Brownfield goal, if known
- Known limitations
- Unknowns
- Assumptions

## Activities

- Ask for a basic product description.
- Summarize the product in plain language.
- Capture known users and goals.
- Mark unknowns clearly.
- Create existing-product-brief.md.

## Key Questions

- What does the product currently do?
- Who uses it today?
- What main jobs does it support?
- What are we preparing the product for?

## Notes

Keep this lightweight.

Do not ask detailed feature, architecture, or design system questions yet.

---

# Phase 3 — Domain Analysis

## Goal

Create domain understanding from the basic product description and any trusted existing artifacts.

## Required Inputs

- existing-product-brief.md
- trusted existing domain docs, if available

## Outputs

- `projects/[project-folder]/outputs/ai-readiness/domain.md`

## domain.md Must Include

- Domain overview
- How the domain works today
- Common workflows
- Domain terminology
- Likely user groups
- Stakeholders
- Domain assumptions
- Domain unknowns
- Questions for the product team/client

## Activities

- Analyze the product domain.
- Identify domain processes.
- Identify terminology.
- Identify likely user groups and stakeholders.
- Mark inferred content clearly.
- Create domain.md.

## Key Questions

- What domain does this product operate in?
- How does this domain usually work?
- What terms or concepts matter?
- What domain assumptions need validation?

## Notes

If domain knowledge is inferred, label it as `Inferred`.

---

# Phase 4 — User Group & Role Analysis

## Goal

Identify current product user groups, roles, permissions, and likely persona segments.

Brownfield products often have roles and permissions, not only personas.

## Required Inputs

- existing-product-brief.md
- domain.md
- existing user docs, permissions docs, screenshots, or team input if available

## Outputs

- `projects/[project-folder]/outputs/ai-readiness/user-groups-and-roles.md`

## user-groups-and-roles.md Must Include

- User group
- Role / permission level
- Main goals
- Common tasks
- Pain points
- Product areas used
- Confidence status
- Notes

## Confidence Status Values

Use:

- Confirmed
- Inferred
- Needs validation

## Activities

- Draft current user groups and roles.
- Identify likely permissions.
- Identify common tasks.
- Ask human to correct or confirm.
- Create user-groups-and-roles.md.

## Key Questions

- Who uses the product today?
- What roles or permission levels exist?
- Which user groups are confirmed?
- Which user groups are inferred?
- Which need validation?

## Notes

Do not treat inferred user groups as confirmed.

---

# Phase 5 — Existing Feature Map Capture / Reconstruction

## Goal

Create or verify the current feature map of the existing product.

## Required Inputs

Any available product evidence:

- Existing feature docs
- Product screenshots
- Figma screens
- App route list
- Navigation/menu labels
- Product walkthrough notes
- Help docs
- Team-provided feature list

## Outputs

- `projects/[project-folder]/outputs/ai-readiness/feature-map.md`

## feature-map.md Must Include

- Existing feature groups
- Existing features
- Related user groups / roles
- Known priority or usage level, if available
- Evidence source
- Confidence status
- Notes

## Activities

- Check whether feature-map.md already exists.
- If approved, reuse it.
- If missing, reconstruct it from available evidence.
- If only a basic description is available, create a candidate feature map marked Inferred / Needs validation.
- Ask human to correct or confirm.
- Create or update feature-map.md.

## Key Questions

- Is there an existing feature map?
- What product evidence can we use to reconstruct the feature map?
- Which features are confirmed?
- Which features are inferred?
- Which features need validation?

## Notes

AI can reconstruct a feature map from screenshots, Figma screens, routes, docs, or walkthrough notes.

If no product evidence is available, the feature map must be marked as candidate / inferred.

---

# Phase 6 — Existing Navigation / IA Map Capture / Reconstruction

## Goal

Create or verify the current navigation and information architecture map.

## Required Inputs

Any available navigation evidence:

- Screenshots of navigation/menu/sidebar/header
- Figma screens
- Site map
- Route list
- App walkthrough notes
- Existing IA docs
- Human-provided navigation list

## Outputs

- `projects/[project-folder]/outputs/ai-readiness/navigation-map.md`

## navigation-map.md Must Include

- Main navigation areas
- Secondary navigation
- Key pages or screens
- Entry points
- Role-specific navigation differences
- Evidence source
- Confidence status
- Notes

## Activities

- Check whether navigation-map.md already exists.
- If approved, reuse it.
- If missing, reconstruct navigation from available evidence.
- If evidence is limited, ask the human to provide the main navigation manually.
- Create or update navigation-map.md.

## Key Questions

- Is there an existing navigation or IA map?
- What navigation evidence is available?
- What are the main product areas?
- Are there role-specific navigation differences?
- Which navigation items are confirmed?
- Which are inferred?

## Notes

AI can reconstruct navigation from screenshots, Figma screens, route lists, or walkthrough notes.

If no evidence is available, ask the human to manually provide the main navigation.

---

# Phase 7 — Existing Journey Reconstruction

## Goal

Reconstruct current-state user journeys from the existing feature map, navigation map, and available product evidence.

## Required Inputs

- feature-map.md
- navigation-map.md
- user-groups-and-roles.md
- screenshots, Figma screens, route list, walkthrough notes, or team input if available

## Outputs

- `projects/[project-folder]/outputs/ai-readiness/current-user-journeys.md`

## current-user-journeys.md Must Include

For each key current journey:

- Journey name
- Related user group / role
- Related feature(s)
- Entry point
- Step-by-step current flow
- Expected outcome
- Known friction / gaps
- Evidence source
- Confidence status
- Notes

## Activities

- Identify key journeys from feature-map.md.
- Use navigation-map.md to understand entry and flow.
- Reconstruct current steps.
- Mark inferred journeys clearly.
- Ask the human to correct or confirm.
- Create current-user-journeys.md.

## Key Questions

- What are the most important existing journeys?
- Which journeys are confirmed?
- Which are inferred?
- What evidence supports each journey?
- What friction or gaps are known?

## Notes

Do not invent detailed flows without evidence.

If the flow is inferred, mark it as Inferred / Needs validation.

---

# Phase 8 — Design System & Component Context

## Goal

Capture the existing design system, component library, patterns, and design constraints.

## Required Inputs

Any available design evidence:

- Figma files
- `.fig` files
- design system docs
- Storybook
- screenshots
- frontend component list
- brand guidelines
- human notes

## Outputs

- `projects/[project-folder]/outputs/ai-readiness/design-system-context.md`
- `projects/[project-folder]/outputs/ai-readiness/component-inventory.md`

## design-system-context.md Must Include

- Design system source
- Brand / visual language
- Color tokens, if available
- Typography, if available
- Layout rules, if available
- Reusable patterns
- Accessibility notes
- Known design debt
- AI design guardrails

## component-inventory.md Must Include

- Component name
- Source
- Usage
- Variants
- Known constraints
- Reuse / extend / avoid recommendation

## Activities

- Check for design system files.
- Capture or reconstruct design system context.
- Inventory available components.
- Mark unknowns clearly.
- Create design-system-context.md and component-inventory.md.

## Key Questions

- Is there a design system?
- Are there Figma or `.fig` files?
- What components already exist?
- What should AI reuse?
- What should AI avoid inventing?

## Notes

If design system artifacts are missing, create a placeholder context marked Needs human input.

---

# Phase 9 — Product Rules, Constraints & Do-Not-Invent List

## Goal

Capture rules and constraints that AI must follow when working inside the existing product.

## Required Inputs

- existing-product-brief.md
- feature-map.md
- current-user-journeys.md
- design-system-context.md
- team input

## Outputs

- `projects/[project-folder]/outputs/ai-readiness/product-rules.md`
- `projects/[project-folder]/outputs/ai-readiness/business-rules.md`
- `projects/[project-folder]/outputs/ai-readiness/constraints-and-debt.md`
- `projects/[project-folder]/outputs/ai-readiness/do-not-invent-list.md`

## Activities

- Extract known product rules.
- Extract business rules.
- Capture technical, design, UX, and operational constraints.
- Capture known debt.
- Create a do-not-invent list.
- Ask human to confirm.

## Key Questions

- What must AI preserve?
- What should AI not change?
- What should AI never invent?
- What product rules are known?
- What business rules are known?
- What constraints or debts matter?

## Notes

This phase prevents AI from confidently redesigning or rebuilding things incorrectly.

---

# Phase 10 — AI Context Pack Assembly

## Goal

Package the approved brownfield context into an AI-ready context pack.

## Required Inputs

Approved or reviewed artifacts from previous phases.

## Outputs

- `projects/[project-folder]/outputs/ai-readiness/ai-context-pack.md`

## ai-context-pack.md Must Include

- Product summary
- Domain summary
- User groups and roles
- Feature map summary
- Navigation map summary
- Current journey summary
- Design system summary
- Component reuse rules
- Product rules
- Business rules
- Constraints and debt
- Do-not-invent rules
- AI-safe assumptions
- Open questions
- Recommended next brownfield process

## Activities

- Review all AI Readiness artifacts.
- Summarize context for AI tools.
- Include links to source artifacts.
- Mark assumptions and unknowns.
- Create ai-context-pack.md.

## Key Questions

- What does AI need to know before working on this product?
- What is approved?
- What is inferred?
- What must AI not invent?
- What is still missing?

## Notes

This becomes the main source of truth for later brownfield work.

---

# Phase 11 — AI Readiness Review & Approval

## Goal

Review whether the existing product is ready for AI-assisted brownfield work.

## Required Inputs

- ai-context-pack.md
- ai-readiness-artifact-audit.md
- human review

## Outputs

- `projects/[project-folder]/outputs/ai-readiness/ai-readiness-approval.md`

## ai-readiness-approval.md Must Include

- Readiness status
- Approved artifacts
- Inferred artifacts
- Missing artifacts
- Open risks
- Human decisions
- Approved next brownfield work type

## Readiness Status Values

Use:

- Ready
- Ready with risks
- Not ready

## Activities

- Review the AI context pack.
- Review missing or inferred items.
- Ask the human if the product is ready to continue.
- Ask which brownfield work type should run next:
  1. Add New Feature
  2. Complete Revamp
  3. Improve Existing Feature
- Create ai-readiness-approval.md.
- Update project-state.json:
  - brownfield_ai_readiness: approved
  - brownfield_work_type: selected work type if selected

## Key Questions

- Is the AI context pack accurate enough?
- Which artifacts are approved?
- Which artifacts are inferred?
- What risks remain?
- Are we ready to proceed?
- Which brownfield work type should run next?

## Notes

Do not unlock Brownfield Add New Feature, Complete Revamp, or Improve Existing Feature until AI Readiness is approved.


## Brownfield Artifact Reconstruction Rule

This rule applies especially to:
- feature-map.md
- navigation-map.md
- current-user-journeys.md
- design-system-context.md
- component-inventory.md

### Reconstruction Evidence
The agent may reconstruct these artifacts from available product evidence, such as:
- screenshots
- Figma screens
- `.fig` files
- product walkthrough notes
- app route lists
- menu labels
- help docs
- product docs
- codebase routes/pages
- Storybook/component docs
- human-provided descriptions

### Confidence Rules
- If reconstructed from direct evidence, mark Confidence as Confirmed or Evidence-backed.
- If reconstructed from partial evidence, mark Confidence as Inferred.
- If reconstructed from only a basic product description, mark Confidence as Candidate / Needs validation.
- Do not present inferred maps as confirmed.

### Manual Input Rule
If there is not enough evidence to reconstruct feature-map.md or navigation-map.md, ask the human to manually provide:
- main product areas
- main navigation items
- key screens/pages
- main user roles
- known important flows

Stop and ask instead of inventing.
