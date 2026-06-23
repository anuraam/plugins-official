# How to Run the Process

The UX Mob Process is designed to be simple for non-developers to run alongside an AI agent.

1. **Start the Process:** Trigger your AI tool (Antigravity, Cursor, or Claude Code) and ask it to start the UX Mob process.
2. **Initialize Workspace:** The AI will ask you for a Project Name, Project Folder, and a Workspace Root (defaulting to `../ux-mob-workspace/`). This ensures your generated artifacts are kept separate from the process kit.
3. **Answer Questions:** The AI will ask you a few targeted questions for the current phase.
4. **Review the Output:** The AI will generate a phase artifact (a Markdown file) based on your answers.
5. **Pass the Gate:** Review the artifact. If it looks good, tell the AI "Approve and continue". If it needs work, ask the AI to revise it.
6. **Repeat:** The AI will automatically guide you to the next phase.

You can type "Pause" at any time to take a break, and resume later.

## Starting a Fresh Isolated Run
If you are starting a completely new project and want to guarantee that the AI does not reuse context, artifacts, or memories from previous runs, you should start a **Fresh Isolated Run**.

- **Claude Code:** Run `/ux-start-fresh`
- **Other Tools:** Ask the agent to "Start a fresh isolated UX Mob process."

The agent will initialize a clean slate and strictly enforce Context Isolation rules.
