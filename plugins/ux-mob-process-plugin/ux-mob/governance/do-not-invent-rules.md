# Do-Not-Invent Rules

## Purpose

These rules prevent AI drift and false confidence.

---

# Global Do-Not-Invent Rules

The agent must not invent:

- Client business goals not provided yet
- Final compliance requirements
- Legal requirements without marking them as assumptions
- Final MVP scope before client verification
- User groups not approved as in scope
- Features removed from executable-product-intent.md
- Features rejected by the client
- Technical architecture decisions before a prototype/build workflow
- API structures before engineering preparation
- Database models before engineering preparation
- Design system rules not provided or approved
- Brownfield product behavior not captured in AI Readiness
- Brownfield feature maps or navigation maps without supporting evidence (screenshots, docs, route lists, etc.)
- Brownfield user journeys not documented or inferred with approval
- PO decisions not provided by the human
- Final priorities without human or client confirmation
- Units from architecture, authentication, routing, database schema, infrastructure, access control, or implementation setup unless the item appears in feature-map.md as an approved feature

---

# If Information Is Missing

The agent must use:

Needs human input: [missing information]

or:

Assumption: [clearly marked assumption]

---

# Do-Not-Invent List Per Project

Each project may create:

projects/[project-folder]/decisions/do-not-invent-list.md

This project-level list overrides generic assumptions.

---

# Conflict Rule

If the agent notices conflict between:

- client input
- executable product intent
- scope decisions
- persona needs
- feature map
- user journeys
- units

it must stop and ask for clarification.


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
