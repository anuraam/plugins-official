---
name: web-app-test
description: Alias for /test-web-app. Verify web app behaviour for a GitHub PR/Issue or Azure DevOps PR/Bug using the Webwright workflow (Python/Playwright, headless Chromium). Usage: /web-app-test [pr <n> | issue <n> | wi <id>] [--env <name>] [--url <url>] [--role <role>] [--interactive]
argument-hint: [pr <n> | issue <n> | wi <id>] [--env <name>] [--url <url>] [--role <role>] [--interactive]
---

Run automated web app behaviour verification for $ARGUMENTS.

Read and follow `commands/test-web-app.md` exactly — treat this as a direct invocation of `/test-web-app $ARGUMENTS`.
