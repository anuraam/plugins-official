# UX Matrix Process

# User Experience Matrix & Revamp Scope Process

## Purpose

This document defines a focused UX diagnosis and revamp scoping process for improving an existing product.

It covers:

1. User Experience Matrix & Issue Diagnosis
2. Improvement Opportunity Definition
3. Prioritization & Revamp Scope

The goal is to move from evidence-based UX diagnosis to clear improvement opportunities and a tightly scoped revamp plan.

---

# Phase 1 — User Experience Matrix & Issue Diagnosis

## Goal

Diagnose UX problems systematically across journeys, screens, roles, states, content, channels, and evidence sources.

The User Experience Matrix helps the team identify both journey-specific issues and general product-wide issues.

## Outputs

- User Experience Matrix per key journey
- Journey ID list
- User group / persona mapping
- Flow-step breakdown
- Channel map per journey
- User behavior tracking data notes
- Existing business data notes
- User test and interview notes
- Usability heuristic findings
- Other evidence notes
- Journey-specific issue list
- General issue list
- Issue themes
- Severity / priority notes
- Improvement opportunities

## Activities

- Select one user group or persona.
- Assign a Journey ID.
- Break the journey into flow steps.
- Identify the channel for each step.
- Add user behavior tracking data where available.
- Add existing business data where available.
- Add user test and interview findings.
- Add usability heuristic findings.
- Add other evidence or constraints.
- Capture general issues across the journey.
- Identify repeated issues across steps.
- Identify repeated issues across journeys.
- Separate symptoms from root causes.
- Cluster issues into improvement themes.
- Identify quick wins and larger structural problems.
- Convert findings into improvement opportunities.

## Key Questions

- Where do users get stuck?
- Where do users hesitate?
- Where do users need too much explanation?
- Where is the flow too long?
- Where is the navigation unclear?
- Where is information hard to find?
- Where is the visual hierarchy weak?
- Where is the copy unclear?
- Where are errors poorly handled?
- Where are empty or loading states missing?
- Where are similar patterns inconsistent?
- Which issues happen across multiple journeys?
- Which issues are isolated to one journey?
- Which issues are symptoms?
- Which issues are root causes?
- Which issues create the highest user or business impact?

## Notes

This is the core diagnostic phase of the revamp process.

Do not jump from issue discovery directly to visual redesign. First identify the patterns behind the issues.

---

# User Experience Matrix Template

## Matrix Header

```text
User Experience Matrix

User group & Persona: __________________________

Journey ID: __________________________
```
## Matrix Structure

```text
Flow >              Step 1        Step 2        Step 3        Step 4        Step 5

Channels

Example: Web app

User behaviour
tracking data

Existing
business data

User tests &
interviews

Usability
heuristics test

Other

General issues: ________________________________________________
```

## How to Use the Matrix

### 1. Select one user group or persona

Choose the user group or persona whose journey you are evaluating.

Examples:

```text
Admin user
New customer
Returning customer
Support agent
Field officer
Manager
```

### 2. Assign a Journey ID

Give each journey a stable ID so it can be referenced across documentation, AI prompts, design work, and validation.

Examples:

```text
J01 — New user onboarding
J02 — Submit application
J03 — Track request status
J04 — Resolve customer issue
```

### 3. Break the journey into flow steps

Use the top row to map the main steps in the journey.

Examples:

```text
Discover feature
Open dashboard
Start request
Complete form
Review details
Submit
Receive confirmation
```

### 4. Identify channels

Use the Channels row to capture where each step happens.

Examples:

```text
Web app
Mobile app
Email
SMS
Call center
Admin portal
Offline/manual process
Third-party system
```

### 5. Add user behaviour tracking data

Use this row for analytics and behavioral signals.

Examples:

```text
Drop-off rate
Click-through rate
Time on task
Repeated clicks
Backtracking
Search usage
Form abandonment
Rage clicks
Session recordings
Heatmaps
Funnel data
```

### 6. Add existing business data

Use this row for operational or business evidence.

Examples:

```text
Support ticket volume
Complaint categories
Conversion rate
Completion rate
Processing time
Error rate
Revenue impact
Manual workload
SLA breaches
Refunds or cancellations
Escalations
```

### 7. Add user tests and interview findings

Use this row for qualitative research evidence.

Examples:

```text
User confusion
Misunderstood labels
Unclear next step
Trust concerns
Missing information
Repeated questions
Workarounds
Emotional reactions
Expectations
Decision blockers
```

### 8. Add usability heuristic findings

Use this row for expert UX review.

Examples:

```text
Poor visibility of system status
Mismatch with user expectations
Weak error prevention
Inconsistent patterns
High cognitive load
Poor affordance
Unclear hierarchy
Accessibility issue
Lack of feedback
No recovery path
```

### 9. Add other evidence

Use this row for additional sources that do not fit above.

Examples:

```text
Stakeholder feedback
Sales feedback
Compliance concern
Engineering constraint
Design debt
Content debt
Performance issue
Competitor comparison
Market expectation
```

### 10. Capture general issues

Use the General Issues section for problems that appear across the journey or across multiple steps.

Examples:

```text
Navigation labels are inconsistent.
Users do not understand the difference between draft and submitted states.
Error messages are too technical.
The journey depends too heavily on email confirmation.
Mobile layout causes repeated scrolling.
Users cannot easily recover from failed submissions.
```

## Matrix Output Rules

Each matrix should produce:

```text
Journey-specific issues
General issues
Evidence-backed findings
Root-cause themes
Improvement opportunities
Validation questions
```

## Issue Summary

After completing the matrix, summarize the key issues in a lightweight issue table.

| Issue | Related Step(s) | Evidence Source | Severity | Frequency | Priority | Suggested Improvement |
|---|---|---|---|---|---|---|
|  |  |  | High / Medium / Low | High / Medium / Low | P1 / P2 / P3 |  |

## AI Usage Rule

Before using AI to redesign or improve a journey, provide the AI tool with:

```text
- User group / persona
- Journey ID
- Flow steps
- Matrix findings
- General issues
- Existing design system context
- Improvement scope
- Do-not-change rules
```

AI should only suggest improvements that directly respond to the matrix findings.

---

# Phase 5 — Improvement Opportunity Definition

## Goal

Convert diagnosed UX issues into clear improvement opportunities.

## Outputs

- Improvement opportunity statements
- Problem themes
- Root-cause themes
- Target user segments
- Improvement hypotheses
- Success metrics
- Revamp principles
- Non-goals
- Validation plan

## Activities

- Group User Experience Matrix issues into themes.
- Identify root causes behind repeated issues.
- Write opportunity statements.
- Define which users are affected.
- Define improvement hypotheses.
- Define success metrics.
- Define what the revamp should improve.
- Define what should remain unchanged.
- Define non-goals.
- Create a validation plan.

## Key Questions

- What are the biggest improvement themes?
- Which issues share the same root cause?
- Which user segments are most affected?
- What should be improved first?
- What would a better experience look like?
- What should remain familiar?
- What should not be redesigned?
- What metrics should improve?
- What must be validated?
- What would make this revamp successful?

## Notes

This phase turns diagnosis into direction.

---

# Phase 6 — Prioritization & Revamp Scope

## Goal

Decide what the revamp will address now, later, or not at all.

## Outputs

- Prioritized issue list
- Revamp scope
- Out-of-scope list
- Quick wins
- Strategic improvements
- Dependency map
- Risk map
- Release slicing plan
- MVP improvement scope

## Activities

- Prioritize issues by severity, frequency, impact, and effort.
- Identify quick wins.
- Identify high-impact journey improvements.
- Identify product-wide pattern improvements.
- Separate visual polish from structural UX improvements.
- Define scope for the first revamp cycle.
- Define what will be deferred.
- Define release slices.
- Identify dependencies and risks.
- Align stakeholders.

## Key Questions

- Which issues matter most?
- Which issues affect the most users?
- Which issues block task completion?
- Which issues create business risk?
- Which improvements are quick wins?
- Which improvements require deeper redesign?
- Which improvements depend on engineering changes?
- Which improvements can be shipped separately?
- What is in scope?
- What is out of scope?
- What should not be touched yet?

## Notes

Revamps fail when they try to fix everything at once.

Scope the improvement cycle tightly.

---

# Phase 7 — UX Improvement Design

## Goal

Design improved journeys, flows, IA, states, content, and interaction patterns based on the prioritized UX issues.

## Outputs

- Improved user journeys
- Updated flow diagrams
- Updated IA/navigation model
- Improved screen-level UX plans
- Updated state model
- Updated edge cases
- Updated content rules
- Updated interaction patterns
- Before/after UX rationale

## Activities

- Redesign prioritized journeys.
- Simplify unnecessary steps.
- Improve entry and exit points.
- Improve navigation and IA.
- Improve decision points.
- Improve form flows or task flows.
- Improve empty, loading, error, and success states.
- Improve labels, instructions, and microcopy.
- Improve consistency across repeated patterns.
- Create before/after journey comparisons.
- Document rationale for each change.

## Key Questions

- How can the journey be simplified?
- What steps can be removed?
- What steps can be combined?
- What information should appear earlier?
- What information should appear later?
- What decisions can be made easier?
- What states need improvement?
- What copy needs to change?
- What patterns should become consistent?
- How does the improved journey solve the diagnosed issues?
- What should remain familiar to existing users?

## Notes

This phase improves product behavior before visual design.

---
