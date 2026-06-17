# AI-DLC Unit Quality Rules

## Purpose

These rules help the agent create useful product units from approved feature-map.md and user-journeys.md.

## Definition of a Unit

A unit is a buildable product capability.

A unit is not:
- a technical foundation task
- an authentication setup task
- a routing task
- a database setup task
- infrastructure setup
- only a UI screen
- a vague theme

## Required Source Trace

Every product unit must trace to:

- one or more approved feature-map.md features
- one or more approved user-journeys.md journeys
- one or more product intent items or persona needs

## Feature Coverage Rule

For every high-priority or in-scope feature in feature-map.md, the agent must either:

1. Create a product unit, or
2. Mark it under Deferred / Not Unitized Yet with a reason.

## Technical Work Rule

Do not create technical foundation units in units.md.

If technical setup work seems necessary, write it as a note for later Prototype Builder or Engineering Preparation.

## Good Unit Criteria

A good unit should:
- deliver a meaningful product capability
- serve a clear persona
- support a clear user journey
- trace to a feature
- trace to product intent
- be buildable
- be testable
- be small enough to execute or group in Bolts
- be large enough to deliver meaningful behavior

## Unit Anti-Patterns

Do not create units that are:
- disconnected from the feature map
- disconnected from user journeys
- invented from architecture
- only technical setup
- just individual UI screens
- vague themes
- too broad to validate
- duplicates of other units

## Bolt Grouping Rules

Suggested Bolt runs should group units only when:
- they share a user flow
- they share data dependencies
- they share core UI patterns
- they must be built together to validate the experience

Do not group unrelated units just to reduce the number of Bolt runs.
