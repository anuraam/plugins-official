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

## Execution Runtimes (mise)

Automated runs via the **Xianix Agent** provision language runtimes on demand with [mise](https://mise.jdx.dev) — see the *Runtime harness* section of the [Executor README](https://github.com/xianix-team/the-agent/tree/main/Executor#runtime-harness). There is **no plugin-specific runtime manifest** (the former `xianix-runtimes.json` format is retired); nothing needs configuring in this plugin:

1. **The repository's own version files are authoritative** — mise reads what the repo already ships: `global.json` (dotnet), `.nvmrc` / `.node-version` (node), `.python-version`, `go.mod`, `.java-version`, `mise.toml`, `.tool-versions`, etc.
2. **On-demand fallback** — if the repo declares nothing and the agent invokes a missing runtime (e.g. `dotnet test` with no `global.json`), the executor auto-installs it at latest on first use.
3. **Optional plugin fallback** — a `.tool-versions` file at the plugin root would act as a lowest-precedence default (repo declarations always win). This plugin deliberately ships none: it runs against arbitrary repositories, so the repo's own declaration is the only correct source.

Local interactive runs use whatever toolchain is already on your machine.

**Why this matters for the resolver:** unlike a read-only reviewer, this plugin *edits code* — **apply** dispositions become real commits pushed to the PR branch. The runtime harness guarantees the repository's toolchain is available in the container so the agent can run the repo's tests to verify applied changes before pushing (see the Verify step in `agents/orchestrator.md`).

### Test verification (`PR_RESOLVER_RUN_TESTS`)

Before committing and pushing applied changes, the orchestrator detects the repository's test suite (from build manifests like `*.sln`/`*.csproj`, `package.json`, `pyproject.toml`, `go.mod`, …) and runs it. Applied changes that introduce **new** test failures (relative to the pre-edit baseline) are reverted and reclassified as **discuss** with the failure output. The plugin's `PreToolUse` hook blocks `git push` until the verification step has recorded a result.

| Variable | Default | Purpose |
|---|---|---|
| `PR_RESOLVER_RUN_TESTS` | `true` | Set to `false` to skip test verification (e.g. suites too slow for the container budget). The skip is recorded and surfaced in the disposition summary. |
