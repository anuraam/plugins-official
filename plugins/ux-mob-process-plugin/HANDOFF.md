# UX Mob Process Claude Code Plugin: Handoff Document

## What This Plugin Does
This plugin serves as an adapter package for Claude Code. It wraps the core UX Mob Process Kit—bringing structured, AI-native UX mob elaboration natively into Claude Code workflows. It orchestrates Greenfield elaboration and Brownfield AI Readiness workflows by strictly enforcing template utilization, context isolation, and chat-first review processes.

## Current Version
**0.1.0 (MVP)**

## What is Included
- `.claude-plugin/plugin.json` (The manifest file that registers the plugin).
- `/commands`: Exposes core slash commands (e.g., `/ux-start`, `/ux-run-ai-readiness`) directly to the Claude CLI.
- `/skills`: Encapsulated instruction sets providing execution context for processes and AI readiness.
- `/agents`: Agent prompt definitions orchestrating the UX facilitation workflows.
- `/ux-mob`: A packaged snapshot of the core kit (docs, governance, templates, and processes).

## What is Not Included
- Active code generation abilities.
- Actual execution implementations for the agent files (they are structural `.md` stubs requiring prompt tuning).
- Global API keys or environment variables (the plugin relies on the environment where Claude Code is invoked).

## How to Install Locally
To install the plugin locally on your machine for testing:
1. Navigate to your local Claude Code configuration directory.
2. Either copy or symlink the entire `plugins/claude-code/ux-mob-process-plugin/` directory into your `.claude/plugins/` folder.
3. Reload your Claude Code session.

## How to Test Locally
1. Initialize Claude Code by typing `claude` (ensure you are logged in via `claude /login`).
2. Verify the plugin loaded by running `/ux-mob-process:ux-status` (or simply triggering `/ux-start`).
3. Proceed through a sample Greenfield setup, validating that templates load and require approval before saving.

## Expected Workspace-Root Behavior
**CRITICAL RULE:** This plugin enforces absolute isolation. It will **never** save generated mob outputs, phase artifacts, or decisions inside the plugin folder itself. All outputs are strictly written to `[workspace-root]/projects/[project-folder]/outputs/` (relative to where Claude Code is launched).

## How the Boss Platform Can Invoke It
The Boss platform can invoke this plugin by wrapping Claude Code commands programmatically. The platform can trigger initialization commands like `/ux-start-fresh` to spin up a structured execution layer, passing context through the terminal instance while allowing the agent to manage its internal loop using the plugin's skills and templates.

## Known Limitations
1. **Empty Agent Stubs:** The agent markdown files currently define structure and goals, but the precise tool definitions and system prompts must be wired into Claude Code's agent API schemas.
2. **Pathing Context:** If Claude Code is run from a strange sub-directory, relative pathing for the `workspace-root` could behave unpredictably.
3. **No Direct UI:** Execution is entirely CLI-based via Claude Code; visual rendering requires inspecting the markdown files externally.

## Next Recommended Integration Steps
1. **Flesh out Agent Stubs:** Translate the rules within `agents/*.md` into executable Claude API schemas/system prompts.
2. **End-to-End Dry Run:** Execute a complete Brownfield AI Readiness pass on a dummy project to test the approval gates.
3. **Boss Automation Hooking:** Define standard programmatic hooks within the Boss platform to watch for the `[workspace-root]/outputs/` file events automatically.
