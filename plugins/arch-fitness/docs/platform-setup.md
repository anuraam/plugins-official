# Platform Setup Guide

The Architecture Fitness plugin discovers or bootstraps architecture constraints, opens a docs PR when needed, then evaluates a changeset scope against those constraints. **Git** is used for diffs and doc commits. **GitHub CLI (`gh`)** and **Azure DevOps REST** (via `curl`) are used for issues/work items, PR listing, docs PR creation, and comments.

---

## GitHub

### GitHub CLI (`gh`)

Install **`gh`** so the plugin can:

- read the trigger issue body (for the `ARCH FITNESS` config block)
- list / fetch PR diffs and merged-PR windows
- open or update the docs PR (`arch/docs-*`)
- post progress and fitness report comments

```bash
# Install: https://cli.github.com
gh auth login
```

For CI or scripted use, set **`GITHUB-TOKEN`** (preferred) or **`GH_TOKEN`** instead of interactive login.

### Token permissions

| Permission | Access | Purpose |
|---|---|---|
| **Contents** | Read & Write | Read repository code, push `arch/docs-*` branches |
| **Metadata** | Read | Resolve repository metadata (default branch, etc.) |
| **Issues** | Read & Write | Read the trigger issue and post fitness comments |
| **Pull requests** | Read & Write | Fetch PR diffs / merged windows; open the docs PR |

Classic tokens: `repo` (private repos) or `public_repo` (public only); `read:org` (org repos).

The plugin does **not** use the GitHub MCP server.

### Credentials for `git push`

The `arch-doc-curator` agent pushes only `arch/docs-*` branches (never the default branch). `GITHUB-TOKEN` is reused as the push credential — `hooks/validate-prerequisites.sh` injects it via `GIT_CONFIG_*` for that push.

```bash
export GITHUB-TOKEN=ghp_your_token_here
```

---

## Azure DevOps

### Prerequisites

The plugin does **not** require the `az` CLI — it uses `curl` against the Azure DevOps REST API for work items, pull requests, and comments.

### Authentication

```bash
export AZURE-DEVOPS-TOKEN=<your-pat>
```

**PAT scopes needed:**

| Scope | Access | Purpose |
|---|---|---|
| **Code** | Read & Write | Fetch PR diffs, push `arch/docs-*` branches, open docs PRs |
| **Work Items** | Read & Write | Read trigger work item; post comments; apply completion tag |
| **Pull Request Threads** | Read & Write | Optional thread updates on the docs PR |

### Credentials for `git push`

The same PAT is injected via `GIT_CONFIG_*` for HTTPS remotes on `dev.azure.com` and `visualstudio.com`.

---

## Generic remotes

No platform token is required. The plugin:

- evaluates scopes via local `git` (branch diffs or `git log --since` for date windows)
- may create a local `arch/docs-*` branch and attempt a push with existing git credentials
- always writes `arch-fitness-report.md` (and `arch-docs-pr-body.md` when docs change)

---

## Environment variables summary

| Variable | Platform | Required | Purpose |
|---|---|---|---|
| `GITHUB-TOKEN` or `GH_TOKEN` | GitHub | Yes (for API + push) | `gh` auth and HTTPS git push |
| `AZURE-DEVOPS-TOKEN` | Azure DevOps | Yes | REST API + HTTPS git push |
| `AZURE_ORG` / `AZURE_PROJECT` / `AZURE_REPO` | Azure DevOps | No | Override values parsed from the remote URL |

The Xianix Agent injects secrets via each rule's `with-envs` block — see [triggers-github.md](./triggers-github.md) and [triggers-azure-devops.md](./triggers-azure-devops.md).
