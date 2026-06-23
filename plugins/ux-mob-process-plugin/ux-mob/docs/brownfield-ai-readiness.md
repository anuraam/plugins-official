# Brownfield AI Readiness

This document describes the Brownfield AI Readiness process.

Brownfield AI Readiness is the **mandatory starter** for any Brownfield project. Before an AI agent can assist with adding features, improving existing ones, or doing a complete revamp, the agent and the human team must align on the existing context of the product.

## The 11-Phase Process

1. **Existing Artifact Check:** Check if required artifacts already exist. Offer to use, review, revise, recreate, or skip them.
2. **Basic Product Description Capture:** Ask for a basic explanation of the existing product.
3. **Domain Analysis:** Draft/reconstruct the domain.
4. **User Group & Role Analysis:** Draft/reconstruct user groups and roles.
5. **Existing Feature Map Capture / Reconstruction:** Draft/reconstruct feature map.
6. **Existing Navigation / IA Map Capture / Reconstruction:** Draft/reconstruct navigation/IA map.
7. **Existing Journey Reconstruction:** Reconstruct current user journeys.
8. **Design System & Component Context:** Inventory existing design system and components.
9. **Product Rules, Constraints & Do-Not-Invent List:** Define rules, business rules, constraints/debt, and what the AI should NOT invent.
10. **AI Context Pack Assembly:** Compile the approved artifacts into a context pack.
11. **AI Readiness Review & Approval:** Human approves readiness to move to execution phases.

## Core Rules

1. **Reconstruction Rule**: The Feature map and navigation map may be AI-reconstructed only from evidence (existing docs, screenshots, Figma screens, route lists, app walkthrough notes, menu labels, help docs, codebase routes/pages, human-provided descriptions).
2. **Evidence Labels**: If evidence is weak, mark outputs as **Inferred**, **Candidate**, or **Needs validation**. Do NOT present inferred maps as confirmed.
3. **Output Path Strictness**: All artifacts generated during this process MUST be saved to:
   `projects/[project-folder]/outputs/ai-readiness/`
   Do not save them to the root `outputs/` folder.
4. **Chat-First Preview**: Every artifact must be previewed in chat before saving.
5. **Explicit Approval**: Save only after explicit artifact save approval. Phase approval is separate from artifact approval.
