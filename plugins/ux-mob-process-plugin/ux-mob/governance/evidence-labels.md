# Evidence Labels


## Standard Labels

When classifying the certainty of information or artifacts (especially in Brownfield projects), the agent must use these explicit labels:

- **Confirmed**: Supported by direct, unambiguous evidence (e.g., provided client docs, live screenshots).
- **Inferred**: Derived from partial evidence but not explicitly stated.
- **Candidate**: Proposed based on basic descriptions without supporting structural evidence.
- **Needs validation**: Unverified information that the human must confirm before it can be trusted.

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
