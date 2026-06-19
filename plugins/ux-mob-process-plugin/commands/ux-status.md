---
name: ux-status
description: Summarize the current project status, including active phase, saved artifacts, and pending approvals.
argument-hint: "[project-folder]"
---

# Command: ux-status

**Purpose:** Summarize the current project status.

## Instructions
- Read `project-state.json` in the active project directory.
- Provide a clear summary to the user including:
  - Project Name
  - Main Category
  - Brownfield AI Readiness Status
  - Brownfield Work Type
  - Active Process File
  - Current Phase
  - Completed Phases
  - Open Questions
  - Needs Human Input
