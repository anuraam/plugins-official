# Platform Setup

This guide covers how to configure the `pr-comment-resolver` plugin for each supported platform.

For running the plugin automatically via the Xianix Agent (webhook-driven rule blocks in `rules.json`), see the per-platform trigger guides:

- **[Automated Triggering — GitHub](./triggers-github.md)** — label-based triggering (`ai-dlc/pr/resolve-comments`) and resolve-on-changes-requested.
- **[Automated Triggering — Azure DevOps](./triggers-azure-devops.md)** — `@xianix resolve` comment-mention triggering.

---

## GitHub

### Requirements

- **GitHub CLI** (`gh`) installed and authenticated
- `GITHUB_TOKEN` environment variable set (for pushing commits)
- `GITHUB-TOKEN` or `GH_TOKEN` (alternative to interactive `gh auth login`)

### Install GitHub CLI

```bash
# macOS
brew install gh

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

| Permission | Access |
|---|---|
| **Contents** | Read & Write |
| **Metadata** | Read |
| **Pull requests** | Read & Write |

---

## Azure DevOps

### Requirements

- `AZURE-DEVOPS-TOKEN` environment variable set (PAT)

### Create a Personal Access Token

1. Go to **User Settings → Personal Access Tokens** in Azure DevOps
2. Click **New Token**
3. Set the following scopes:
   - **Code**: Read & Write
   - **Pull Request Threads**: Read & Write

### Set the Token

```bash
export AZURE-DEVOPS-TOKEN=your_pat_here
```

---

## Generic / Local

No credentials required for reading. For pushing commits, ensure your git remote is configured with credentials via your system credential manager or SSH keys.

---

## Execution Runtimes (`xianix-runtimes.json`)

The [`xianix-runtimes.json`](../xianix-runtimes.json) manifest at the plugin root declares the language runtimes the **Xianix Agent** provisions inside the execution container before a triggered run starts. It only applies to automated runs via the agent (see the trigger guides above) — local interactive runs use whatever toolchain is already on your machine.

Current manifest:

```json
{
  "runtimes": [
    { "name": "dotnet", "version": "10.0.201" }
  ]
}
```

Each entry declares one runtime:

| Field | Purpose |
|---|---|
| `name` | Runtime identifier (e.g. `dotnet`) |
| `version` | Exact version the executor installs into the container |

**Why the resolver needs this:** unlike a read-only reviewer, this plugin *edits code* — **apply** dispositions become real commits pushed to the PR branch. Having the repository's toolchain available in the container lets the agent build and verify the changes it applies before pushing them. Adjust the entries to match the stack of the repositories the rule set targets (e.g. pin the `dotnet` SDK version to the one in your `global.json`).
