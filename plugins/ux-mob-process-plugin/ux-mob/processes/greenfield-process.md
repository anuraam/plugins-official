# AI-Native Product Prototype Process — Greenfield

## Purpose

This process helps teams move from a rough product idea to AI-assisted design prompt preparation in a structured way.

It is designed for greenfield projects where the team may only have a basic project context before the first client meeting.

The goal is to:
- Understand the domain before meeting the client
- Identify likely user groups and persona segments
- Convert pain points, goals, and needs into executable product intent
- Compare AI/domain findings with client-provided requirements
- Agree scope with the client
- Produce feature maps, journeys, design direction, and UI prompts for AI design tools

This process does not build the working prototype. Prototype building should be handled by a separate Prototype Builder workflow after this greenfield process is approved and handed off.

---

# Final Greenfield Process Map

1. Pre-Client Domain Analysis
2. User Group & Persona Analysis
3. Executable Product Intent
4. Client Input Capture
5. Intent Gap Analysis
6. Client Verification & Scope Agreement
7. Intent Cleanup / Scope Removal
8. MVP Scope Suggestion — Optional
9. Feature Map
10. User Journeys
11. AI-DLC Unit Definition
12. Design Direction
13. Journey-Based UI Prompt Generation
14. Design Review & Corrective Prompts — Optional
15. Handoff / Completion

---

# Phase 1 — Pre-Client Domain Analysis

## Goal

Create an initial understanding of the domain before the first client meeting using only the project context currently known.

This phase helps the team avoid entering the client conversation without domain awareness.

## Required Input

- Project context as currently known

Example:

“Project is about building a product to serve people who are using cabins in Norway.”

## Outputs

- domain.md

## domain.md Must Include

- Project context summary
- Domain overview
- How the domain works today
- Current processes and behaviors
- Domain-specific terminology
- Involved user groups
- Possible stakeholders
- Domain assumptions
- Domain unknowns
- Questions to ask the client

## Activities

- Read the limited project context.
- Identify the likely domain.
- Research or infer how the domain currently works.
- Identify domain-specific processes.
- Identify domain-specific terminology.
- Identify involved user groups and stakeholders.
- Identify assumptions and unknowns.
- Prepare questions for the first client meeting.
- Create `domain.md`.

## Key Questions

- What domain are we entering?
- How does this domain work today?
- What current processes, routines, or behaviors exist?
- What terminology is specific to this domain?
- Who are the likely user groups?
- Who are the likely stakeholders?
- What should we not assume yet?
- What questions should we ask the client?

## Notes

This phase happens before the first client meeting.

The agent should clearly mark weak assumptions as `Assumption`.

The agent should clearly mark unknowns as `Needs human input`.

---

**Phase review required.**

Please choose one:

1. Approve and continue
2. Revise this phase
3. Add missing information
4. Pause the process

---

# Phase 2 — User Group & Persona Analysis

## Goal

Analyze the main user groups from the domain analysis and create persona segments for the user groups that are relevant to the project scope.

Some user groups may be eliminated if they are not relevant to the expected product scope.

## Required Inputs

- domain.md
- User groups identified in Phase 1
- Human decision on which user groups are in scope or out of scope

## Outputs

- personas.md

## personas.md Must Include

For each selected persona segment:

- Persona name
- User group
- Segment description
- Demographics and characteristics
- Pain points
- Goals
- Needs
- Current behaviors
- Scope relevance

## Activities

- Review user groups from `domain.md`.
- Ask the human which user groups are in scope.
- Eliminate out-of-scope user groups.
- Create persona segments for each main in-scope user group.
- Identify demographics and characteristics.
- Identify pain points.
- Identify goals.
- Identify needs.
- Create `personas.md`.

## Key Questions

- Which user groups are relevant to this product?
- Which user groups should be excluded from scope?
- What persona segments exist within each user group?
- What are their demographics and characteristics?
- What pain points do they have?
- What goals are they trying to achieve?
- What needs must the product consider?
- Which persona segments are primary?
- Which persona segments are secondary?

## Notes

Persona segments may be inferred at this stage.

Mark inferred personas as `Inferred`.

---

**Phase review required.**

Please choose one:

1. Approve and continue
2. Revise this phase
3. Add missing information
4. Pause the process

---

# Phase 3 — Executable Product Intent

## Goal

Create an executable product intent from persona pain points, goals, and needs.

This artifact becomes the main product intent document that later maps into scope, features, journeys, and UI prompts.

## Required Inputs

- domain.md
- personas.md

## Outputs

- executable-product-intent.md

## executable-product-intent.md Must Include

### Business Goals

- High-level business goals
- Functional goals
- Non-functional goals

At this stage, these may be blank or marked as `Needs client input`.

### Compliance Considerations

- Compliance areas to consider
- Legal, privacy, accessibility, safety, industry, or regional considerations
- Unknown compliance questions

### Persona-Based Product Intent

For each persona segment:

- Persona segment
- Pain point / goal / need
- Why it matters
- High-level feature idea
- Notes / assumptions

The high-level feature idea should be short.

Do not force one-to-one mapping if one feature idea supports multiple pain points, goals, or needs.

## Activities

- Review pain points, goals, and needs from `personas.md`.
- Identify business goals that are already known.
- Mark unknown business goals as `Needs client input`.
- Identify compliance considerations.
- Convert persona pain points, goals, and needs into product intent items.
- Suggest short high-level feature ideas.
- Create `executable-product-intent.md`.

## Key Questions

- What user pain points need to be solved?
- What user goals should the product support?
- What user needs should the product address?
- What high-level feature ideas could support these?
- What business goals are known?
- What business goals are unknown?
- What non-functional goals may matter?
- What compliance considerations may apply?
- What must be clarified with the client?

## Notes

This is not the final scope.

This is the first executable product intent draft.

---

**Phase review required.**

Please choose one:

1. Approve and continue
2. Revise this phase
3. Add missing information
4. Pause the process

---

# Phase 4 — Client Input Capture

## Goal

Capture and structure the information received from the client.

Client input may come from a document, meeting notes, copied text, email, proposal, brief, or conversation.

## Required Input

- Client-provided document or pasted client notes

## Outputs

- client-input.md

## client-input.md Must Include

- Raw client input summary
- Client-stated goals
- Client-stated users
- Client-stated features
- Client-stated constraints
- Client-stated priorities
- Client-stated success measures
- Open questions from client input

## Activities

- Ask the human to paste or provide the client input.
- Summarize the input.
- Extract client-stated goals.
- Extract client-stated users.
- Extract client-stated feature ideas.
- Extract constraints.
- Extract priorities.
- Extract success measures.
- Identify open questions.
- Create `client-input.md`.

## Key Questions

- What did the client explicitly ask for?
- What users did the client mention?
- What features did the client mention?
- What goals did the client state?
- What constraints did the client mention?
- What priorities did the client express?
- What success measures did the client mention?
- What is still unclear?

## Notes

Do not reinterpret client input too aggressively.

Separate what the client explicitly said from what the agent infers.

---

**Phase review required.**

Please choose one:

1. Approve and continue
2. Revise this phase
3. Add missing information
4. Pause the process

---

# Phase 5 — Intent Gap Analysis

## Goal

Compare the executable product intent generated from domain/persona analysis with the client-provided input.

This helps identify alignment, gaps, conflicts, missing opportunities, and scope questions.

## Required Inputs

- executable-product-intent.md
- client-input.md

## Outputs

- intent-gap.md

## intent-gap.md Must Include

- Items found in both AI/domain analysis and client input
- Items found in AI/domain analysis but not mentioned by client
- Items mentioned by client but not found in AI/domain analysis
- Conflicts or mismatches
- Missing business goals
- Missing compliance considerations
- Scope questions
- Recommended client discussion points

## Activities

- Compare `executable-product-intent.md` with `client-input.md`.
- Identify overlaps.
- Identify gaps.
- Identify conflicts.
- Identify missing business goals.
- Identify missing compliance or non-functional concerns.
- Create discussion points for the client.
- Create `intent-gap.md`.

## Key Questions

- What did both sources agree on?
- What did our domain/persona analysis reveal that the client did not mention?
- What did the client mention that we did not identify?
- Are there conflicts between user needs and client expectations?
- What business goals are still missing?
- What compliance concerns are still unclear?
- What must be discussed with the client before scope is agreed?

## Notes

This phase prepares for client verification.

---

**Phase review required.**

Please choose one:

1. Approve and continue
2. Revise this phase
3. Add missing information
4. Pause the process

---

# Phase 6 — Client Verification & Scope Agreement

## Goal

Pause the process for manual client verification.

The team must review domain findings, personas, executable product intent, and intent gaps with the client and agree what remains in scope.

## Required Inputs

- Client feedback
- Client decisions
- Scope agreement notes

## Outputs

- client-verification.md

## client-verification.md Must Include

- Items verified by client
- Items rejected by client
- Items changed by client
- New items added by client
- Agreed scope notes
- Out-of-scope notes
- Open questions
- Approval status

## Activities

- Ask the human to conduct or summarize the client verification discussion.
- Capture client-approved items.
- Capture client-rejected items.
- Capture client changes.
- Capture newly added items.
- Capture agreed scope.
- Capture out-of-scope items.
- Create `client-verification.md`.

## Key Questions

- What did the client confirm?
- What did the client reject?
- What did the client change?
- What new information did the client add?
- What is now agreed as in scope?
- What is explicitly out of scope?
- What remains unresolved?

## Notes

This is a mandatory human verification step.

Do not proceed until the human confirms client verification is complete.

---

**Phase review required.**

Please choose one:

1. Approve and continue
2. Revise this phase
3. Add missing information
4. Pause the process

---

# Phase 7 — Intent Cleanup / Scope Removal

## Goal

Update the executable product intent based on client verification and remove items that are not in scope.

## Required Inputs

- executable-product-intent.md
- client-verification.md
- Human list of items to remove or change

## Outputs

- executable-product-intent.md updated
- executable-product-intent.v1.md archived if needed

## Activities

- Ask the human what should be removed from the executable product intent.
- Ask what should be changed or retained.
- Update `executable-product-intent.md`.
- Preserve a previous version if needed.
- Mark removed items in a short removal summary.

## Key Questions

- What should be removed from the product intent?
- What should be changed?
- What should remain?
- What was confirmed by the client?
- What should be marked out of scope?
- Are there any open items left?

## Notes

This phase creates the agreed executable product intent.

---

**Phase review required.**

Please choose one:

1. Approve and continue
2. Revise this phase
3. Add missing information
4. Pause the process

---

# Phase 8 — MVP Scope Suggestion — Optional

## Goal

Create an AI-suggested MVP scope from the agreed executable product intent.

This phase is optional.

## Required Inputs

- executable-product-intent.md

## Outputs

- mvp-scope.md

## Activities

- Ask the human whether to create an AI-suggested MVP scope.
- If yes, analyze the executable product intent.
- Identify must-have, should-have, could-have, and later items.
- Suggest the smallest useful MVP.
- Create `mvp-scope.md`.
- If no, mark this phase as skipped with human approval.

## Key Questions

- Should we create an MVP scope?
- What is the smallest useful product?
- Which items are essential?
- Which items can wait?
- What should be excluded from MVP?
- What assumptions does this MVP depend on?

## Notes

This phase is optional but recommended when scope is broad.

---

**Phase review required.**

Please choose one:

1. Approve and continue
2. Revise this phase
3. Add missing information
4. Pause the process

---

# Phase 9 — Feature Map

## Goal

Create a feature map from either the agreed executable product intent or the MVP scope.

## Required Inputs

- executable-product-intent.md
- mvp-scope.md if available
- Human decision: use full intent or MVP scope

## Outputs

- feature-map.md

## feature-map.md Must Include

- Feature groups
- Features
- Related persona segments
- Related pain points / goals / needs
- Priority
- Dependencies
- Notes

## Product Entry & Onboarding Check

Before creating feature-map.md, the agent must ask:

“Are any Product Entry & Onboarding features required for this product?”

If yes, add a feature group:

### 0. Product Entry & Onboarding

Possible features:
- Feature 0.1: Landing Page & Product Introduction
- Feature 0.2: Account Access
- Feature 0.3: Role-Based Onboarding
- Feature 0.4: First Cabin Setup
- Feature 0.5: App Shell & Main Navigation
- Feature 0.6: Guest Link Entry

The agent should only include the features that are relevant to the product.

## Activities

- Ask whether to create the feature map from the full executable product intent or MVP scope.
- Ask the Product Entry & Onboarding question.
- Group related product intent items.
- Define feature groups.
- Define features.
- Map features to personas and needs.
- Identify priority and dependencies.
- Create `feature-map.md`.

## Key Questions

- Should the feature map use full intent or MVP scope?
- Are any Product Entry & Onboarding features required for this product?
- What are the natural feature groups?
- What features are needed?
- Which personas does each feature support?
- Which pain points, goals, or needs does each feature address?
- Which features depend on others?
- Which features are core?
- Which features are secondary?

## Notes

The feature map becomes the bridge between product intent and user journeys.

Important distinction regarding technical tasks:
- Product Entry & Onboarding features are allowed because they are user-facing product experiences.
- Technical foundation tasks are not product features unless explicitly approved.
- Do not create technical features such as auth middleware, routing logic, database schema, infrastructure, or access-control implementation in feature-map.md.
- Instead, express user-facing needs like “Account Access”, “Role-Based Entry”, and “First Cabin Setup”.

---

**Phase review required.**

Please choose one:

1. Approve and continue
2. Revise this phase
3. Add missing information
4. Pause the process

---

# Phase 10 — User Journeys

## Goal

Create user journeys for each feature in the feature map.

## Required Inputs

- feature-map.md

## Outputs

- user-journeys.md

## user-journeys.md Must Include

For each feature:

- Feature name
- Related persona segment
- How the user would do it
- Why the user would do it
- Technical delights to ease pains and make things easier
- Key steps
- Important states
- Notes / assumptions

## Activities

- Review the feature map.
- Create user journeys for each feature.
- Describe how the user would complete the journey.
- Explain why the user would do it.
- Suggest technical delights that ease pain or make the experience better.
- Identify key states.
- Create `user-journeys.md`.

## Key Questions

- How would the user use this feature?
- Why would the user use this feature?
- What pain does this journey reduce?
- What need does this journey serve?
- What technical delights could make this easier?
- What steps are required?
- What states matter?
- What assumptions are we making?

## Notes

Focus on practical journeys that can later become UI prompts.

Product Entry & Onboarding Rules:
- If feature-map.md contains a Product Entry & Onboarding feature group, user-journeys.md must include journeys for those features.
- Do not skip onboarding/entry journeys if they are listed in feature-map.md.
- Each Product Entry & Onboarding journey should describe the user-facing experience, not technical implementation.
- User journeys should not describe auth middleware, database schema, infrastructure, or routing implementation.
- They should describe things like:
  - visiting the landing page
  - choosing sign up or login
  - selecting a role
  - creating the first cabin
  - landing in the correct dashboard
  - opening a guest manual link

## Feature Coverage Check

Before completing Phase 10, the agent must ask:

“Does user-journeys.md include journeys for every in-scope feature in feature-map.md, including Product Entry & Onboarding features?”

If any in-scope feature is missing a journey, the agent must stop and ask whether to:
1. Add the missing journey
2. Mark the feature as not requiring a journey
3. Move the feature out of current scope

---

**Phase review required.**

Please choose one:

1. Approve and continue
2. Revise this phase
3. Add missing information
4. Pause the process

---

# Phase 11 — AI-DLC Unit Definition

## Goal

Create an initial list of buildable AI-DLC product units from the approved feature map and user journeys.

Each unit should describe a meaningful product capability that developers can later execute in Bolts.

A unit must clearly explain:
- what product capability it delivers
- who it serves
- why it exists
- what needs to be built
- what is in scope
- what is out of scope
- which feature and journey it supports
- what states and data it needs
- how it may be grouped for Bolt execution

## Required Inputs

- executable-product-intent.md
- feature-map.md
- user-journeys.md

## Outputs

- units.md

## units.md Must Include

- Purpose
- Source inputs
- Unit derivation rule

- Unit list summary
- Product units
- Source trace for every unit
- Why each unit exists
- What needs to be built
- What is in scope
- What is out of scope
- UX / UI expectations
- Data needs
- Dependencies
- Suggested Bolt execution
- Deferred / not unitized features
- Suggested Bolt runs
- Assumptions
- Needs human input
- Approval status

## Activities

- Review executable-product-intent.md.
- Review feature-map.md.
- Review user-journeys.md.
- Identify the high-priority or in-scope features from feature-map.md.
- Match each feature to its related user journey.
- Create product units from approved feature and journey pairs.
- Ensure every unit has a clear source trace.
- Ensure every high-priority or in-scope feature is either unitized or explicitly marked as deferred / not unitized.
- Describe each unit in plain language.
- Explain why each unit exists.
- Define what needs to be built for each unit.
- Define what is in scope and out of scope.
- Identify required states and data needs.
- Identify dependencies between product units.
- Suggest possible Bolt groupings.
- Create units.md using ux-mob/templates/units-template.md.

## Key Questions

- Which approved feature does this unit come from?
- Which user journey does this unit support?
- What is this product capability?
- Who is it for?
- Why does it exist?
- What needs to be built?
- What is included?
- What is excluded?
- What states must be handled?
- What data does it need?
- What does it depend on?
- Can it be built independently?
- Should it be grouped with another product unit in a Bolt run?
- Are any high-priority or in-scope features missing from the unit list?

## Notes

Units must inherit from feature-map.md and user-journeys.md.

If Product Entry & Onboarding features exist in feature-map.md and user-journeys.md, they must be considered for units.

Examples of valid Product Entry units:
- Landing Page & Product Entry
- Account Access
- Role-Based Onboarding
- First Cabin Setup
- App Shell & Main Navigation
- Guest Link Entry

Important:
- These are allowed only when they are user-facing product experiences.
- Do not create technical foundation units.
- Do not create auth middleware, database schema, routing, infrastructure, or access-control implementation units.
- Express the unit as the user-facing capability.

A unit should not be just a UI screen.

A unit should not be a vague theme.

A unit should be a buildable, testable product capability derived from the approved feature map and user journeys.

Do not create units from architecture, authentication, routing, database setup, infrastructure, or implementation concerns unless they are explicitly approved product features in feature-map.md.

Technical setup work belongs later in Prototype Builder or Engineering Preparation, not in this Greenfield units.md.

The agent must show the draft units.md in chat before saving.

The agent must ask for explicit artifact save approval before writing the file.

Do not continue to Unit Validation Cases until units.md is saved and Phase 11 is approved.

## Feature Coverage Check

Before generating units.md, the agent must verify:
- Every in-scope feature in feature-map.md has either:
  1. a related journey and product unit, or
  2. a clear reason for being listed as Deferred / Not Unitized Yet.

If Product Entry & Onboarding features are present in feature-map.md, they must not be silently skipped.

---

**Phase review required.**

Please choose one:

1. Approve and continue
2. Revise this phase
3. Add missing information
4. Pause the process

---

# Phase 12 — Unit Validation Cases

## Goal

Create product-focused validation cases for each AI-DLC unit.

These validation cases help the team verify that each unit delivers the expected product intent, user journey behavior, states, data behavior, and user value after the unit is executed in Bolts.

They also become a review lens for validating AI-generated UI designs before prototype building.

## Required Inputs

- executable-product-intent.md
- feature-map.md
- user-journeys.md
- units.md

## Outputs

- unit-validation-cases.md

## unit-validation-cases.md Must Include

- Source inputs
- Validation strategy
- Unit-by-unit validation cases
- Intent validation
- Journey validation
- State validation
- Data validation
- Experience validation
- Acceptance summary
- Open questions
- Expected changes after UI / PO review

## Activities

- Review executable-product-intent.md.
- Review feature-map.md.
- Review user-journeys.md.
- Review units.md.
- Define intent validation cases.
- Define journey validation cases using Given/When/Then.
- Define state validation cases.
- Define data validation cases.
- Define experience validation cases.
- Ensure every case traces to a unit and at least one core product source.
- Create unit-validation-cases.md.

## Key Questions

- Do these cases validate the intent?
- Do these cases validate the journey?
- Are all states covered?
- Is data collected or displayed properly?
- Is the user value verified?

## Notes

This artifact acts as a bridge between the UX definition and final Bolt execution.
It provides explicit validation logic for the UI designs and the final code.

---

**Phase review required.**

Please choose one:

1. Approve and continue
2. Revise this phase
3. Add missing information
4. Pause the process

---

# Phase 13 — Design Direction

## Goal

Create a basic design flavor prompt for the AI design tool.

The human can either let the design tool decide the visual direction or provide explicit design direction.

## Required Inputs

- Human choice: AI decides design direction or human provides design direction
- If human provides direction:
  - Design philosophy
  - Light or dark theme
  - Primary color
  - Secondary color
  - Tertiary color
  - Fonts, maximum two

## Outputs

- design.md

## design.md Must Include

- Target design tool
- Design philosophy
- Theme preference
- Color direction
- Font direction
- Visual mood
- UI personality
- Accessibility considerations
- Design flavor prompt

## Activities

- Ask which design tool will be used: Stitch, Claude Design, or other.
- Ask whether AI should decide design direction or human will provide it.
- If human provides direction, collect design inputs.
- If AI decides, create a design flavor prompt based on domain, personas, and product intent.
- Create `design.md`.

## Key Questions

- Which design tool are we preparing for?
- Should AI decide the visual direction?
- Does the human want to define the design direction?
- What design philosophy should guide the UI?
- Should the product be light, dark, or adaptive?
- What primary color should be used?
- What secondary and tertiary colors should be used?
- What fonts should be used?
- What should the product feel like?
- What accessibility considerations matter?

## Notes

This phase does not create UI screens.

It prepares the design direction for UI prompt generation.

---

**Phase review required.**

Please choose one:

1. Approve and continue
2. Revise this phase
3. Add missing information
4. Pause the process

---

# Phase 14 — Journey-Based UI Prompt Generation

## Goal

Create UI generation prompts for each user journey, one by one.

The prompts should be tailored to the selected AI design tool.

## Required Inputs

- user-journeys.md
- design.md
- Target design tool: Stitch, Claude Design, or other

## Outputs

- ui-prompts/
- One prompt file per journey

## Activities

- Review `user-journeys.md`.
- Ask which design tool the prompts should target.
- Generate prompts journey by journey.
- Include persona, feature, journey steps, states, design direction, and expected screens.
- Save each prompt as a separate file under `ui-prompts/`.
- Ask for human approval after each prompt or batch.

## Key Questions

- Which journey should we create a UI prompt for first?
- What design tool should this prompt target?
- What screens should the prompt generate?
- What states should be included?
- What must the AI design tool avoid?
- Should prompts be generated one by one or as a batch?

## Notes

Prompts should be specific enough to reduce drift.

---

**Phase review required.**

Please choose one:

1. Approve and continue
2. Revise this phase
3. Add missing information
4. Pause the process

---

# Phase 15 — Design Review & Corrective Prompts — Optional

## Goal

Review AI-generated designs and create corrective prompts or strict prompts where needed.

This phase is optional.

The phase must review generated UI designs against two validation lenses:

1. Usability heuristics
2. unit-validation-cases.md

It must also check alignment with:
- design.md
- user-journeys.md
- units.md
- executable-product-intent.md where relevant

## Required Inputs

- AI-generated designs, screenshots, links, or descriptions
- design.md
- user-journeys.md
- units.md
- unit-validation-cases.md
- Human review notes

## Outputs

- corrective-prompts/
- design-review.md

## design-review.md Must Include

- Designs reviewed
- Related journeys
- Alignment with design.md
- Alignment with user-journeys.md
- Alignment with units.md
- Unit validation coverage
- Usability heuristic review
- Drift found
- Missing states
- Missing validation coverage
- Usability issues
- Corrective prompts index

## Activities

- Ask whether the human wants to review designs.
- Capture screenshots, links, or descriptions of generated designs.
- Review against design.md.
- Review against user-journeys.md.
- Review against units.md.
- Review against unit-validation-cases.md.
- Review against usability heuristics.
- Identify whether the UI supports each relevant unit validation case.
- Identify missing states, missing actions, missing data, or weak validation coverage.
- Identify usability heuristic issues.
- Identify drift, weak hierarchy, poor usability, or inconsistent design.
- Create corrective prompts based on both heuristic issues and unit validation gaps.
- Save prompts under corrective-prompts/.
- Create design-review.md.

## Key Questions

- Should we review the generated designs?
- Which generated design are we reviewing?
- Does it follow the design direction?
- Does it support the intended journey?
- Does it support the related unit?
- Does it satisfy the relevant unit validation cases?
- Does it include the required states?
- Does it collect, display, update, or preserve required data?
- Does it reduce the intended user pain or support the intended need?
- Does it follow usability heuristics?
- Where did the design tool drift?
- What needs to be corrected?
- What strict prompt should be sent back to the design tool?

## Notes

Design review should not only check whether the UI looks good.

It must check whether the UI is usable and whether it supports the intended unit validation cases.

Corrective prompts should be grounded in:
- usability heuristic issues
- unit validation gaps
- journey gaps
- design direction drift
- missing states
- missing data or actions

---

**Phase review required.**

Please choose one:

1. Approve and continue
2. Revise this phase
3. Add missing information
4. Pause the process

---

# Phase 16 — Handoff / Completion

## Goal

Package the greenfield output so the team can move into design execution, prototype building, engineering preparation, or the next workflow.

## Required Inputs

- domain.md
- personas.md
- executable-product-intent.md
- intent-gap.md
- client-verification.md
- feature-map.md
- user-journeys.md
- units.md
- unit-validation-cases.md
- design.md
- ui-prompts/
- corrective-prompts/ if available

## Outputs

- greenfield-handoff.md

## greenfield-handoff.md Must Include

- Final agreed product intent summary
- Feature map summary
- Journey summary
- AI-DLC unit summary
- Unit validation summary
- Suggested Bolt run summary
- Design direction summary
- UI prompt index
- Corrective prompt index if available
- Open questions
- Prototype readiness status
- Recommended next steps
- Note that units.md and unit-validation-cases.md are initial and may change after UI generation, PO review, prototype planning, engineering review, or Bolt execution.
- Recommendation to use units.md and unit-validation-cases.md as inputs for the separate Prototype Builder workflow.

## Activities

- Review all approved artifacts.
- Summarize the agreed product direction.
- Summarize features and journeys.
- Summarize units and validation cases.
- Summarize design direction.
- Index generated prompts.
- Identify open questions.
- Identify whether the project is ready for the separate Prototype Builder workflow.
- Create `greenfield-handoff.md`.

## Key Questions

- Are all required greenfield artifacts complete?
- What is the agreed product intent?
- What features are included?
- What journeys are ready for design?
- What units and validation cases have been defined?
- What prompts are ready to use?
- Is the project ready for prototype building?
- What remains unresolved?
- What should the team do next?

## Notes

This marks the end of the greenfield mob elaboration and design-prompt preparation process.

Prototype building should start through a separate Prototype Builder workflow, not as another greenfield phase.

---

**Phase review required.**

Please choose one:

1. Approve and continue
2. Revise this phase
3. Add missing information
4. Pause the process

---
