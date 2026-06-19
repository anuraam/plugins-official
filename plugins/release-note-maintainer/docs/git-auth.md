# API Credentials — Publishing Release Notes

The Release Note Maintainer Agent's only write operations are **publishing release notes to the platform** (GitHub Release or Azure DevOps Wiki page) and **reading merged PR metadata** for the release window. It never commits, never pushes, and never injects git credentials into the working tree.

---

## GitHub

| Variable | Used by | Purpose |
|---|---|---|
| `gh auth login` (or `GH_TOKEN` / `GITHUB-TOKEN`) | `gh pr list`, `gh release create`, `gh release edit` | List merged PRs in the release window; create or update the GitHub Release |

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
| `AZURE-DEVOPS-TOKEN` | `curl` (REST API) | List completed PRs in the release window; create or update the wiki page |

**PAT scopes:**
- `Pull Requests` → **Read** (to list merged PRs)
- `Wiki` → **Read & Write** (to create/update the `/Release-Notes/<tag>` wiki page)

> **Variable-name hygiene (important):** the variable name must be `AZURE-DEVOPS-TOKEN` — **underscores only**. Bash cannot reference a hyphenated name (`$AZURE-DEVOPS-TOKEN` parses as `$AZURE` minus `DEVOPS-TOKEN`), so `curl -u ":${AZURE-DEVOPS-TOKEN}"` would silently send an empty password and every call would 401. The plugin's `PreToolUse` hook detects a hyphenated export and blocks with an actionable message; if you hit it, re-export under the underscore name:
>
> ```bash
> export AZURE-DEVOPS-TOKEN="$(env | sed -n 's/^AZURE-DEVOPS-TOKEN=//p')"
> ```

**Generating a PAT:**
1. Go to `https://dev.azure.com/<your-org>/_usersSettings/tokens`
2. Click **New Token**
3. Set scope `Pull Requests` → Read
4. Set scope `Wiki` → Read & Write
5. Copy the token and export it as `AZURE-DEVOPS-TOKEN`

---

## Generic / Other Platforms

No credentials are required. The agent writes `RELEASE_NOTES.md` at the repository root — a file operation that uses only the local git toolchain.

---

## Passing Credentials at Runtime

```bash
# GitHub
GH_TOKEN=ghp_xxx claude

# Azure DevOps
AZURE-DEVOPS-TOKEN=<pat> claude
```

Or export in your shell or a project-local `.env` (never committed):

```bash
export GH_TOKEN=ghp_xxx
export AZURE-DEVOPS-TOKEN=<pat>
```

Each repository can use its own token — credentials are read from the environment at invocation time and are never written to `~/.gitconfig` or any file in the repository.

---

## What Happens If a Token Is Missing

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
| GitHub | `gh auth` / `GH_TOKEN` / `GITHUB-TOKEN` | `repo` or `public_repo` | List merged PRs; create/edit GitHub Release |
| Azure DevOps | `AZURE-DEVOPS-TOKEN` | `Pull Requests (Read)`, `Wiki (Read & Write)` | List merged PRs; PUT wiki page |
| Generic | — | — | No API; release notes written to `RELEASE_NOTES.md` |
