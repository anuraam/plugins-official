# Folder Structure

Here is a quick guide to where everything lives:

- **`ux-mob/processes/`**: Contains the actual step-by-step instructions for the AI for each project type.
- **`ux-mob/templates/`**: Contains the blank forms the AI uses to generate state, artifacts, and registers.
  - **Greenfield Templates:**
    - `greenfield-domain-template.md`
    - `greenfield-personas-template.md`
    - `executable-product-intent-template.md`
    - `client-input-template.md`
    - `intent-gap-template.md`
    - `client-verification-template.md`
    - `mvp-scope-template.md`
    - `feature-map-template.md`
    - `user-journeys-template.md`
    - `units-template.md`
    - `unit-validation-cases-template.md`
    - `design-direction-template.md`
    - `ui-prompt-template.md`
    - `design-review-template.md`
    - `greenfield-handoff-template.md`
  - **Brownfield Templates:**
    - `brownfield-ai-readiness/` (Templates specifically for AI Readiness reconstruction)
- **`ux-mob/docs/`**: These help guides!
- **`.agents/`**: Configuration files for the Antigravity tool.
- **`.claude/`**: Commands for the Claude Code CLI tool.
- **`.cursor/`**: Rules for the Cursor IDE.

**`ux-mob-workspace/` (Generated Artifacts)**
This is a separate directory created alongside your kit where all output artifacts are saved.
- **`projects/`**: This is where all projects are stored. Every project gets its own subfolder `[workspace-root]/projects/[project-folder]/`.
  - **`project-state.json`**: The state of the current process run.
  - **`inputs/`**: E.g., `client-input/`
  - **`outputs/`**: This folder contains generated artifacts like `domain.md`, `personas.md`, `feature-map.md`, `units.md`, etc.
    - **`ai-readiness/`**: Dedicated folder for all Brownfield AI Readiness artifacts (e.g. `domain.md`, `feature-map.md`, `ai-context-pack.md`).
    - **`ui-prompts/`**: UI generation prompts.
    - **`corrective-prompts/`**: AI design corrections.
  - **`phase-artifacts/`**: Artifacts generated during each phase.
  - **`decisions/`**: Tracking registers like `decision-log.md`, `assumption-register.md`, `ai-drift-register.md`.
  - **`skills/`**: Project-specific agent skills.
