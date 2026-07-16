# Platform Setup

This guide covers how to configure the `doc-writer` plugin for each supported platform.

> **How the plugin runs.** `/update-docs` is executed by the top-level agent itself — there is no separate background "orchestrator" agent. The agent runs every step (git/`gh`/`curl`, doc edits, commit, push, PR creation) directly in its own context.
>
> **How push authentication works.** The token you provide (`GITHUB_TOKEN` for GitHub / generic, `AZURE_DEVOPS_TOKEN` for Azure DevOps) is injected **inline on the `git push` command** via `git -c url.<...>.insteadOf=...`. The `validate-prerequisites.sh` hook only *validates* that the required token is set and blocks the push otherwise — it does not (and cannot) inject the credential into the push itself, because hooks run in a separate process.

---

## GitHub

### Requirements

- **GitHub CLI** (`gh`) installed and authenticated
- `GITHUB_TOKEN` environment variable set (for pushing commits)
- `GITHUB_TOKEN` or `GH_TOKEN` (alternative to interactive `gh auth login`)

### Install GitHub CLI

```bash
# macOS
brew install gh

# Linux (Debian / Ubuntu)
sudo apt install gh

# Windows (winget)
winget install --id GitHub.cli
```

### Authenticate

```bash
gh auth login
```

Or set the token in your environment:

```bash
export GH_TOKEN=ghp_xxxxxxxxxxxxxxxxxxxx
export GITHUB_TOKEN=ghp_xxxxxxxxxxxxxxxxxxxx
```

### Required Token Permissions

| Permission | Access | Why |
|---|---|---|
| **Contents** | Read & Write | Read repo files, commit doc changes, push to PR branches |
| **Metadata** | Read | Access repository metadata |
| **Pull requests** | Read & Write | Fetch PR diff and metadata, post the summary comment, open follow-up PRs |

---

## Azure DevOps

### Requirements

- `AZURE_DEVOPS_TOKEN` environment variable set (PAT)

### Create a Personal Access Token

1. Go to **User Settings → Personal Access Tokens** in Azure DevOps
2. Click **New Token**
3. Set the following scopes:
   - **Code**: Read & Write
   - **Pull Request Threads**: Read & Write

### Set the Token

```bash
export AZURE_DEVOPS_TOKEN=your_pat_here
```

### Optional Environment Variables

These override values parsed from the git remote URL:

| Variable | Purpose |
|---|---|
| `AZURE_ORG` | Azure DevOps organization name |
| `AZURE_PROJECT` | Project name |
| `AZURE_REPO` | Repository name |

---

## Generic / Local

No credentials are required to *read* a generic remote. For *pushing* doc commits, ensure your git remote is configured with credentials via your system credential manager or SSH keys.

When no platform API is available, the plugin writes the documentation summary to `doc-update-report.md` at the repository root instead of posting a PR comment.

---

## Platform Detection

The plugin auto-detects the platform from the git remote URL:

| Remote URL pattern | Platform |
|---|---|
| Contains `github.com` | GitHub |
| Contains `dev.azure.com` or `visualstudio.com` | Azure DevOps |
| Anything else | Generic |

---

## Triggering the Plugin

The plugin is designed to be triggered by an upstream automation (for example, a webhook that fires when a PR is tagged for documentation updates). The expected trigger prompt is:

> Pull request #{{pr-number}} in {{repository-name}} (branch: {{git-ref}}) has been tagged for documentation updates.
>
> Run `/update-docs {{pr-number}}` to analyze the modified source files and update the relevant documentation in the codebase.

The plugin can also be invoked manually from a shell with `gh` or `claude` integrations, or directly inside the Claude / Cursor agent UI by running `/update-docs <pr-number>`.
