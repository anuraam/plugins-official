# API Credentials — Replacing PR Descriptions

The PR Description Agent's only write operation against a pull request is **completely replacing its title and description**. It never commits, never pushes, and never injects git credentials into the working tree. The credentials below are used purely for the platform API calls that read the current PR metadata and replace the description.

---

## GitHub

| Variable | Used by | Purpose |
|---|---|---|
| `gh auth login` (or `GH_TOKEN` / `GITHUB-TOKEN`) | `gh pr view`, `gh pr edit` | Read the current PR title/description, then replace both |

**Token scopes:** `repo` (private repos) or `public_repo` (public repos only).

**Generating a GitHub PAT:**
1. Go to [github.com/settings/tokens](https://github.com/settings/tokens)
2. Click **Generate new token (classic)**
3. Select scope `repo` (or `public_repo` for public-only repos)
4. For org repos, ensure SSO authorisation if required

Interactive sessions can instead run `gh auth login` once. Non-interactive runs (CI, webhook-driven) should set `GH_TOKEN` or `GITHUB-TOKEN` in the environment.

---

## Azure DevOps

| Variable | Used by | Purpose |
|---|---|---|
| `AZURE-DEVOPS-TOKEN` | `curl` (REST API) | Read the current PR title/description, then `PATCH` both |

**PAT scope:** `Pull Requests` → **Read & Write**.

> **Variable-name hygiene (important):** the variable name must be `AZURE-DEVOPS-TOKEN` — **underscores only**. Bash cannot reference a hyphenated name (`$AZURE-DEVOPS-TOKEN` parses as `$AZURE` minus `DEVOPS-TOKEN`), so `curl -u ":${AZURE-DEVOPS-TOKEN}"` would silently send an empty password and every call would 401. The plugin's `PreToolUse` hook detects a hyphenated export and blocks with an actionable message; if you hit it, re-export under the underscore name:
>
> ```bash
> export AZURE-DEVOPS-TOKEN="$(env | sed -n 's/^AZURE-DEVOPS-TOKEN=//p')"
> ```

**Generating a PAT:**
1. Go to `https://dev.azure.com/<your-org>/_usersSettings/tokens`
2. Click **New Token**
3. Set scope `Pull Requests` → Read & Write
4. Copy the token and export it as `AZURE-DEVOPS-TOKEN`

---

## Passing Credentials at Runtime

```bash
# GitHub
GH_TOKEN=ghp_xxx claude

# Azure DevOps
AZURE-DEVOPS-TOKEN=<pat> claude
```

Or export in your shell, or a project-local `.env` (never committed):

```bash
export GH_TOKEN=ghp_xxx
export AZURE-DEVOPS-TOKEN=<pat>
```

Each repository can use its own token — credentials are read from the environment at invocation time and are never written to `~/.gitconfig` or any file in the repository.

---

## What happens if a token is missing

The `validate-prerequisites.sh` hook blocks the relevant call before it runs:

**GitHub** (no `gh` auth available):
```
blocked: GitHub CLI (gh) is not installed or not in PATH. Install: https://cli.github.com — see docs/platform-setup.md
```

**Azure DevOps:**
```
blocked: AZURE-DEVOPS-TOKEN is not set. Pass it at runtime: AZURE-DEVOPS-TOKEN=<pat> claude ... (see docs/platform-setup.md)
```

---

## Summary

| Platform | Credential | Scope | Used for |
|---|---|---|---|
| GitHub | `gh auth` / `GH_TOKEN` / `GITHUB-TOKEN` | `repo` or `public_repo` | Read + replace PR title/description |
| Azure DevOps | `AZURE-DEVOPS-TOKEN` | `Pull Requests` (Read & Write) | Read + `PATCH` PR title/description |
| Generic | — | — | No API; description written to `pr-description.md` |
