# UX Mob Process Claude Code Plugin

## Purpose
This plugin packages the UX Mob Process Kit for Claude Code and platform integration.

## Supports
- Greenfield UX mob elaboration
- Brownfield AI Readiness
- Brownfield Add New Feature, Complete Revamp, and Improve Existing Feature after AI Readiness approval
- Artifact guardrails
- Context isolation
- Template enforcement
- Human approval gates

## Core commands
- `/ux-mob-process:ux-start`
- `/ux-mob-process:ux-start-fresh`
- `/ux-mob-process:ux-run-ai-readiness`
- `/ux-mob-process:ux-resume`
- `/ux-mob-process:ux-status`
- `/ux-mob-process:ux-validate-guardrails`

## Architecture
- The root kit remains the source of truth.
- This plugin is an adapter package.
- Generated mob outputs should go to a workspace root outside the plugin.

## Installation Notes
To install, either copy or symlink this folder directly into your `.claude/plugins/` directory, or register it within your `.claude.json` configuration file, then reload Claude Code.

## Testing Notes
You can verify the plugin is active by running `/ux-mob-process:ux-status`. It's recommended to run a test Greenfield setup to ensure the artifact routing works as expected.

## Workspace Output Rule
**CRITICAL:** This plugin should *never* store generated project outputs inside the plugin folder. All generated artifacts and project files must strictly be saved to a workspace root outside the plugin directory.

## Boss Platform Integration Note
This plugin acts as a bridge adapter to integrate the core UX Mob elaboration workflow into the Boss platform ecosystem, allowing for scalable, standardized AI-native prototyping.
