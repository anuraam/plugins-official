# Brownfield Add New Feature Process

## Purpose

This process helps teams add a new feature to an existing product using AI-assisted design and development tools.

The goal is not to redesign the product from scratch.  
The goal is to safely introduce a new feature into an existing product system while preserving product logic, user expectations, design consistency, technical integrity, and release stability.

Brownfield work is different from greenfield work because the product already has existing users, journeys, screens, components, design patterns, data models, business rules, and technical constraints.

For brownfield projects, AI tools need strong existing-product context before they generate screens, flows, components, or code.

---

# Brownfield Process

## Phase 1 — Feature Opportunity Definition
### Goal

Define the new feature clearly before mapping its impact or generating solutions.

This phase explains what the feature is, why it matters, who it is for, what it should achieve, and what should stay out of scope.

### Outputs

- Feature problem statement
- Target user segment
- Feature hypothesis
- work-to-be-done
- MVP feature scope
- Out-of-scope list
- Success metrics
- Prototype learning goals
- Validation plan
- Stakeholder expectations

### Activities

- Define the feature idea.
- Identify the target user segment.
- Clarify the user problem and business problem.
- Write the feature hypothesis.
- Define work-to-be-done.
- Define the smallest useful version of the feature.
- Define success metrics.
- Define what the prototype must prove.
- Create a validation plan.
- Align stakeholders on scope and expectations.

### Key Questions

- What new feature are we adding?
- Why does this feature matter now?
- Who is the feature for?
- What user problem does it solve?
- What business problem does it solve?
- What job does the feature help users complete?
- What is the smallest useful version of this feature?
- What should this feature not do?
- What existing product behavior should remain unchanged?
- What must the prototype prove?
- How will we measure whether the feature works?
- What do we need to validate before building further?
- What would make us stop, pivot, or reduce scope?

### Notes

For brownfield projects, both **goals** and **non-goals** are especially important.

Clear goals and non-goals prevent the new feature from turning into an accidental redesign or oversized product expansion.

---

---

**Phase review required.**

Please choose one:

1. Approve and continue
2. Revise this phase
3. Add missing information
4. Pause the process

---

## Phase 2 — Impact & Dependency Mapping
### Goal

Identify where the new feature touches the existing product.

This phase helps the team understand the product, UX, design, data, technical, operational, and release impact before designing or building.

### Outputs

- Impacted screens
- Impacted user journeys
- Impacted navigation areas
- Impacted user roles
- Impacted permissions
- Impacted components
- Impacted design patterns
- Impacted APIs
- Impacted notifications
- Impacted settings or admin areas
- Impacted documentation
- Impacted edge cases
- Dependency map

### Activities

- Map all feature entry points.
- Map all feature exit points.
- Identify existing flows that the feature touches.
- Identify screens that need to change.
- Identify screens that should not change.
- Identify components that can be reused.
- Identify components that may need extension.
- Identify APIs or services affected by the feature.
- Identify permission and role changes.
- Identify analytics or reporting changes.
- Identify notification or communication changes.
- Identify downstream product areas affected by the feature.
- Identify dependencies across teams, systems, or data sources.

### Key Questions

- Where will users enter this feature?
- Where will users exit this feature?
- Which existing flows will change?
- Which existing screens are affected?
- Which existing screens should remain untouched?
- Which existing components will be reused?
- Which components may need to be extended?
- Does this feature require new data?
- Does this feature modify existing data?
- Does this feature require API changes?
- Does this feature affect roles or permissions?
- Does this feature affect analytics or reporting?
- Does this feature affect onboarding, settings, or admin areas?
- Does this feature affect notifications?
- What existing flows might break?
- What dependencies must be resolved before build?
- What is the highest-risk part of this feature?

### Notes

This is the “measure twice, cut once” phase for brownfield work.

Skipping this phase increases the risk of breaking existing product behavior.

---

---

**Phase review required.**

Please choose one:

1. Approve and continue
2. Revise this phase
3. Add missing information
4. Pause the process

---

## Phase 3 — UX Integration Design
### Goal

Design how the new feature fits into the existing product experience.

This phase is not about creating a new UX system. It is about integrating the feature into the current product journeys, navigation, states, and interaction patterns.

### Outputs

- Updated user journeys
- Feature entry points
- Feature exit points
- Updated flow diagrams
- Updated navigation model
- Role-based feature flows
- Updated state model
- Empty states
- Loading states
- Error states
- Success states
- Partial completion states
- Permission-denied states
- Feature-specific edge cases
- Notification behavior
- Content and microcopy rules

### Activities

- Define the natural location of the feature in the existing product.
- Design entry points into the feature.
- Design exit points back to existing flows.
- Update relevant user journeys.
- Update relevant flow diagrams.
- Map role-based differences.
- Define the feature state model.
- Define empty, loading, error, success, and partial states.
- Define permission-denied and unavailable states.
- Define edge cases.
- Define notification behavior, if needed.
- Define content, labels, and microcopy.
- Review whether the feature feels native to the existing product.
- Run a lightweight UX review before visual generation.

### Key Questions

- Where should this feature naturally live?
- How will users discover the feature?
- How will users enter the feature?
- What happens after users complete the feature?
- How does the feature connect back to existing flows?
- What roles need different experiences?
- What states does the feature need?
- What happens when there is no data?
- What happens when data is loading?
- What happens when an action fails?
- What happens when an action succeeds?
- What happens if the user does not have permission?
- What happens if required data is missing?
- What edge cases must be handled?
- What labels and messages need to stay consistent?
- Does the feature feel like part of the existing product?

### Notes

The goal is not novelty.  
The goal is fit.

A brownfield feature should feel like it has always belonged in the product.

---

---

**Phase review required.**

Please choose one:

1. Approve and continue
2. Revise this phase
3. Add missing information
4. Pause the process

---

## Phase 4 — Design System / Pattern Alignment
### Goal

Ensure the feature reuses or extends the existing design system, components, patterns, tokens, accessibility rules, and responsive behavior.

### Outputs

- Existing component reuse plan
- New component needs
- Token usage rules
- Layout alignment rules
- Visual consistency rules
- Interaction pattern alignment
- Accessibility checks
- Responsive behavior alignment
- Design debt notes
- Design system update recommendations

### Activities

- Review the existing design system.
- Review imported `.fig` design system files.
- Identify reusable components.
- Identify reusable layouts and patterns.
- Identify components that need extension.
- Decide whether any new component is truly required.
- Map feature UI needs to existing components.
- Check token usage for color, typography, spacing, and elevation.
- Check responsive behavior.
- Check accessibility expectations.
- Identify deprecated components that should not be used.
- Identify design debt created or exposed by the feature.
- Create design system update recommendations if needed.

### Key Questions

- Which existing components can be reused?
- Which existing patterns should be followed?
- Which components need to be extended?
- Is a new component truly necessary?
- What design tokens should be used?
- What existing layouts should be followed?
- Does the feature match existing spacing, typography, and hierarchy?
- Does the feature match existing interaction behavior?
- Does the feature meet accessibility expectations?
- Does the feature work across required breakpoints?
- Does the feature introduce design debt?
- Are we using any deprecated components?
- Should the design system be updated after this feature?

### Notes

In brownfield work, design consistency is not optional.

The feature should not look like it came from a different product, tool, or generation prompt.

Core principle:

> Reuse before creating. Extend before inventing.

---

---

**Phase review required.**

Please choose one:

1. Approve and continue
2. Revise this phase
3. Add missing information
4. Pause the process

---

## Phase 5 — AI Operating System / Skill File Update
### Goal

Update or create the AI guardrails, skill files, and prompt structures that will guide AI design and build work.

This phase turns the existing product context and feature rules into reusable AI instructions.

### Outputs

- Updated product context skill
- Updated domain context skill
- Updated UX rules skill
- Updated existing product patterns skill
- Updated design system guardian skill
- Updated component usage skill
- Updated feature-specific skill
- Updated build rules skill
- Updated UX reviewer skill
- Updated build reviewer skill
- Updated regression reviewer skill
- Existing product constraints file
- Anti-drift rules
- Anti-regression rules
- Prompt library updates
- AI review checklist

### Activities

- Convert the AI context pack into skill files.
- Add domain context to the AI instructions.
- Add existing product rules to the AI instructions.
- Add feature-specific context.
- Add UX integration rules.
- Add design system and component usage rules.
- Add build rules based on the existing codebase.
- Add anti-drift rules.
- Add anti-regression rules.
- Create or update visual generation prompts.
- Create or update build prompts.
- Create or update review prompts.
- Create or update regression review prompts.
- Define how AI outputs will be reviewed.

### Key Questions

- What should AI know about the existing product?
- What should AI know about the domain?
- What should AI know about the new feature?
- What existing patterns must AI follow?
- What components must AI reuse?
- What should AI never redesign?
- What should AI never invent?
- What design rules must be enforced?
- What build rules must be enforced?
- What regression risks should AI check for?
- What prompts will be reused?
- What outputs need human review?
- How will AI drift be detected?
- How will regression risk be detected?

### Notes

For brownfield projects, AI instruction should be strict:

> Do not redesign the product. Add the feature inside the existing product logic, patterns, components, and constraints.

---

---

**Phase review required.**

Please choose one:

1. Approve and continue
2. Revise this phase
3. Add missing information
4. Pause the process

---

## Phase 6 — AI Visual Generation / Variation
### Goal

Use AI design tools to generate or modify feature screens while staying aligned with the existing product context, UX integration plan, and design system.

This phase should be more constrained than greenfield visual generation.

### Outputs

- Feature screen variations
- Modified existing screens
- New feature states
- Component reuse review
- Pattern consistency review
- UX review
- Usability review
- AI drift review
- Refined feature prototype
- Design handoff notes

### Activities

- Provide AI with the context pack, design system, `.fig` files, and relevant screenshots.
- Generate only the required feature screens or states.
- Modify existing screens only where required.
- Generate feature variations within existing design constraints.
- Generate empty, loading, error, success, and permission states.
- Review component reuse.
- Review pattern consistency.
- Review content and labels.
- Review accessibility basics.
- Review whether AI introduced unnecessary UI.
- Review whether AI redesigned unrelated areas.
- Refine the visual prototype.
- Prepare design handoff notes.

### Key Questions

- What exact screens or states should be generated?
- Which existing screens should be modified?
- What existing layout patterns should be followed?
- What components must be reused?
- Are generated screens consistent with the existing product?
- Are generated screens consistent with the design system?
- Are states and edge cases represented?
- Are labels and content consistent?
- Has AI invented unnecessary UI?
- Has AI redesigned parts of the product that should remain unchanged?
- Has AI introduced new components without need?
- Does the feature feel native to the existing product?
- Is the visual output ready for engineering preparation?

### Notes

If using Stitch, this is where Stitch visual generation happens.

If using Claude or another AI tool with `.fig` context, this is where the existing design system and product screenshots should be used as source material.

Generation rule:

> Constrained variation is safer than open exploration.

---

---

**Phase review required.**

Please choose one:

1. Approve and continue
2. Revise this phase
3. Add missing information
4. Pause the process

---

## Phase 7 — Engineering Integration Preparation
### Goal

Prepare the technical integration plan before AI-assisted building begins.

This phase ensures the new feature can be added safely into the existing codebase, architecture, data model, permissions, analytics, and release process.

### Outputs

- Existing architecture impact summary
- Codebase areas affected
- Data model changes
- API changes
- Migration needs
- Permission updates
- State management updates
- Routing updates
- Analytics updates
- Feature flag plan
- Test scenarios
- Regression test list
- Rollback plan
- Build acceptance criteria
- Technical risk map

### Activities

- Review the existing codebase structure.
- Identify affected modules, routes, services, and components.
- Define where the feature should live in the codebase.
- Define data model changes.
- Define API changes.
- Define migration needs, if any.
- Define role and permission updates.
- Define state management updates.
- Define routing changes.
- Define analytics updates.
- Define feature flag strategy.
- Define test scenarios.
- Define regression test list.
- Define rollback plan.
- Define build acceptance criteria.
- Identify technical risks and dependencies.
- Prepare codebase-aware prompts for AI build execution.

### Key Questions

- Where should this feature live in the existing codebase?
- What existing modules, routes, or services are affected?
- What existing components should be reused?
- What data model changes are required?
- What APIs need to be added or changed?
- Are migrations required?
- Are permission changes required?
- Are routing changes required?
- Are state management changes required?
- Is a feature flag needed?
- What analytics events should be added or updated?
- What test scenarios must pass?
- What existing flows need regression testing?
- What is the rollback plan if the feature causes issues?
- What does “done” mean technically?

### Notes

Brownfield engineering preparation must include regression thinking from the beginning.

The question is not only:

> Can we build it?

The question is:

> Can we build it without breaking the existing product?

---

---

**Phase review required.**

Please choose one:

1. Approve and continue
2. Revise this phase
3. Add missing information
4. Pause the process

---

## Phase 8 — AI Build Execution
### Goal

Use AI development tools to build the feature inside the existing product structure with strict codebase, design, UX, and regression guardrails.

### Outputs

- Codebase-aware implementation prompts
- Built feature
- Updated routes
- Updated components
- Updated states
- Updated permissions
- Updated mock or real data connections
- Updated analytics
- Feature flag implementation
- Acceptance criteria checks
- Regression fixes
- Technical cleanup list

### Activities

- Provide AI with the engineering integration plan.
- Provide AI with codebase constraints.
- Provide AI with relevant existing components.
- Build in the agreed implementation order.
- Add or update data/API layer as needed.
- Add feature flag if needed.
- Reuse existing components.
- Extend existing components only when necessary.
- Add feature entry points.
- Build the core feature flow.
- Add states and edge cases.
- Add role and permission behavior.
- Add analytics.
- Run acceptance criteria checks.
- Run regression checks.
- Fix issues without unrelated refactoring.
- Create a technical cleanup list.

### Key Questions

- Is AI using the existing code structure?
- Is AI reusing existing components?
- Is AI following existing naming conventions?
- Is AI following existing state management patterns?
- Is AI respecting role and permission rules?
- Is AI avoiding unrelated refactors?
- Is AI avoiding duplicate components?
- Is AI preserving existing flows?
- Are edge cases implemented?
- Are analytics implemented correctly?
- Are feature flags working correctly?
- Are acceptance criteria met?
- Are regression checks passing?

### Notes

If using Antigravity, this is where Antigravity building happens.

The AI build should be codebase-aware, not just screen-aware.

Build rule:

> Keep changes scoped to the feature unless a broader change is explicitly approved.

---

---

**Phase review required.**

Please choose one:

1. Approve and continue
2. Revise this phase
3. Add missing information
4. Pause the process

---

## Phase 9 — Regression, Validation & Release Readiness
### Goal

Validate the new feature and confirm that existing product behavior, design consistency, accessibility, analytics, and technical behavior have not been broken.

This phase combines feature validation with regression review and release readiness.

### Outputs

- Feature UX validation
- Task completion review
- Existing flow regression review
- Design consistency review
- Accessibility review
- Technical review
- Analytics verification
- Permission testing
- Edge case testing
- Stakeholder review
- Release checklist
- Known issues list
- Prioritized fixes
- Go / no-go recommendation

### Activities

- Test the new feature with target users or representative users.
- Run task completion review.
- Review whether the feature solves the intended problem.
- Review whether the feature matches success metrics.
- Test impacted existing flows.
- Test role and permission behavior.
- Test empty, loading, error, success, and edge states.
- Review visual and interaction consistency.
- Review accessibility.
- Verify analytics events.
- Verify feature flag behavior.
- Verify rollback plan.
- Review with stakeholders.
- Create known issues list.
- Prioritize fixes.
- Make go / no-go recommendation.

### Key Questions

- Can users complete the new feature flow?
- Does the feature solve the intended problem?
- Does the feature match success metrics?
- Does the feature fit naturally inside the existing product?
- Did we break any existing flows?
- Did we introduce design inconsistencies?
- Did we introduce accessibility issues?
- Did we introduce technical issues?
- Are permissions working correctly?
- Are analytics events firing correctly?
- Are feature flags working correctly?
- Is the rollback plan clear?
- What must be fixed before release?
- What can be safely deferred?

### Notes

Brownfield validation must answer two questions:

> Does the new feature work?

and

> Did we break anything that already worked?

---

---

**Phase review required.**

Please choose one:

1. Approve and continue
2. Revise this phase
3. Add missing information
4. Pause the process

---

## Phase 10 — Evolution
### Goal

Review adoption, improve the feature, reduce debt, update documentation, and prepare the next iteration.

### Outputs

- Post-release learning summary
- Adoption review
- Success metrics review
- User feedback summary
- Feature refinement plan
- UX debt cleanup
- Design debt cleanup
- Technical debt cleanup
- Updated documentation
- Updated design system
- Updated skill files
- Updated prompt library
- Next iteration scope
- Product evolution roadmap

### Activities

- Review adoption and usage data.
- Review success metrics.
- Review user feedback.
- Review support tickets related to the feature.
- Identify what should be improved.
- Identify what should be removed or simplified.
- Identify UX debt introduced by the feature.
- Identify design debt introduced by the feature.
- Identify technical debt introduced by the feature.
- Update documentation.
- Update design system or component registry.
- Update skill files.
- Update prompt library.
- Capture what prompts worked well.
- Capture what prompts caused AI drift.
- Define next iteration scope.
- Plan the next product milestone.

### Key Questions

- Are users adopting the feature?
- Is the feature solving the intended problem?
- What feedback are users giving?
- What should be improved?
- What should be removed?
- What debt did we introduce?
- What should be added to the design system?
- What should be added to documentation?
- What skill files need updating?
- What prompts worked well?
- What prompts caused drift?
- What should we do differently next time?
- What is the next product milestone?

### Notes

Evolution is where the feature becomes more stable, more scalable, and more integrated into the product system.

---

# Simplified Brownfield Process Map

```text
1. Existing Product Understanding
   ↓
2. AI Context Preparation
   ↓
3. Feature Opportunity Definition
   ↓
4. Impact & Dependency Mapping
   ↓
5. UX Integration Design
   ↓
6. Design System / Pattern Alignment
   ↓
7. AI Operating System / Skill File Update
   ↓
8. AI Visual Generation / Variation
   ↓
9. Engineering Integration Preparation
   ↓
10. AI Build Execution
   ↓
11. Regression, Validation & Release Readiness
   ↓
12. Evolution
```

---

**Phase review required.**

Please choose one:

1. Approve and continue
2. Revise this phase
3. Add missing information
4. Pause the process

---

