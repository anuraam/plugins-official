# Platform Setup Guide

The PR Description Agent uses **git** for diffs, commit history, and changed-file lists on **all** supported hosts (including GitHub and Azure DevOps). **GitHub CLI (`gh`)** and the **Azure DevOps REST API** (via `curl`) are used only to resolve the PR, read its current title/description, and **replace** both — not for the core analysis.

---

## GitHub

### GitHub CLI (`gh`) — required to read and replace the PR description

Diffs and logs come from **git**. Install **`gh`** so the plugin can resolve the PR number, read its current title/description, and replace both.

```bash
# Install: https://cli.github.com
gh auth login
```

For CI or webhook-driven runs, set **`GH_TOKEN`** or **`GITHUB-TOKEN`** instead of interactive login.

**Token scopes:** `repo` (private repos) or `public_repo` (public repos only), `read:org` (optional, for org repos).

The plugin does **not** use the GitHub MCP server. See `providers/github.md` for `gh` usage.

---

## Azure DevOps

### Prerequisites

The Azure DevOps REST API is called directly via `curl` with a Personal Access Token — no `az` CLI is required.

```bash
export AZURE-DEVOPS-TOKEN=<your-pat>
```

Add to `~/.zshrc` or `~/.bashrc` to persist across sessions.

> **Variable-name hygiene (important):** the variable name must be `AZURE-DEVOPS-TOKEN` — **underscores only**. Some CI systems export it with hyphens (`AZURE-DEVOPS-TOKEN`), which bash cannot reference (`$AZURE-DEVOPS-TOKEN` parses as `$AZURE` minus `DEVOPS-TOKEN`), causing `curl -u ":${AZURE-DEVOPS-TOKEN}"` to silently send an empty password and every call to 401. The plugin's `PreToolUse` hook detects this and blocks with an actionable message; if you hit it, re-export under the underscore name:
>
> ```bash
> export AZURE-DEVOPS-TOKEN="$(env | sed -n 's/^AZURE-DEVOPS-TOKEN=//p')"
> ```

**PAT scope needed:** `Pull Requests` → **Read & Write** — covers reading the current PR title/description and `PATCH`-ing both.

### Generating a PAT

1. Go to `https://dev.azure.com/<your-org>/_usersSettings/tokens`
2. Click **New Token**
3. Set scope `Pull Requests` → Read & Write
4. Copy the token and export it as `AZURE-DEVOPS-TOKEN`

---

## Generic / Other Platforms

For remotes that aren't GitHub or Azure DevOps (Bitbucket, self-hosted Git), or a recognized platform with no open PR for the current branch, the plugin writes the generated description to `pr-description.md` in the repository root, overwriting it on every run. No additional setup is required beyond a working git installation — see `providers/generic.md`.

---

## Summary

| Platform | Analysis | Resolve + read current PR | Replace title/description |
|---|---|---|---|
| GitHub | `git diff`, `git log`, … | `gh pr view` | `gh pr edit --title ... --body-file ...` |
| Azure DevOps | `git diff`, `git log`, … | `curl GET .../pullrequests/{id}` | `curl -X PATCH .../pullrequests/{id}` |
| Generic | `git diff`, `git log`, … | — | Overwrite `pr-description.md` |

---

## Related

- `docs/git-auth.md` — credential details for the API calls above
- `providers/github.md` — GitHub-specific logic
- `providers/azure-devops.md` — Azure DevOps-specific logic
- `providers/generic.md` — fallback for unsupported platforms / no open PR
