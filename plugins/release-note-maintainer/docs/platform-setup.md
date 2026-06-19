# Platform Setup Guide

The Release Note Maintainer Agent uses **git** for commit history, tag resolution, and repository structure on **all** supported platforms. **GitHub CLI (`gh`)** and the **Azure DevOps REST API** (via `curl`) are used only to list merged PRs in the release window and to publish the generated release notes.

---

## GitHub

### GitHub CLI (`gh`) — required for PR listing and release publishing

```bash
# Install: https://cli.github.com
gh auth login
```

For CI or webhook-driven runs, set **`GH_TOKEN`** or **`GITHUB-TOKEN`** instead of interactive login.

**Token scopes:** `repo` (private repos) or `public_repo` (public repos only).

The plugin uses `gh` for two operations only:
1. `gh pr list` — list merged PRs in the release window (date-bounded)
2. `gh release create` / `gh release edit` — publish the release notes as a GitHub Release

The plugin does **not** use the GitHub MCP server. See `providers/github.md` for full `gh` usage details.

---

## Azure DevOps

### Prerequisites

The Azure DevOps REST API is called directly via `curl` with a Personal Access Token — no `az` CLI is required.

```bash
export AZURE-DEVOPS-TOKEN=<your-pat>
```

Add to `~/.zshrc` or `~/.bashrc` to persist across sessions.

> **Variable-name hygiene (important):** the variable name must be `AZURE-DEVOPS-TOKEN` — **underscores only**. Some CI systems export it with hyphens (`AZURE-DEVOPS-TOKEN`), which bash cannot reference (`$AZURE-DEVOPS-TOKEN` parses as `$AZURE` minus `DEVOPS-TOKEN`), causing `curl -u ":${AZURE-DEVOPS-TOKEN}"` to silently send an empty password and every call to 401. The plugin's `PreToolUse` hook detects this and blocks with an actionable message.

**PAT scopes needed:**
- `Pull Requests` → **Read** — list completed PRs in the release window
- `Wiki` → **Read & Write** — create/update the `/Release-Notes/<tag>` wiki page

### Generating a PAT

1. Go to `https://dev.azure.com/<your-org>/_usersSettings/tokens`
2. Click **New Token**
3. Set scope `Pull Requests` → Read
4. Set scope `Wiki` → Read & Write
5. Copy the token and export it as `AZURE-DEVOPS-TOKEN`

### Wiki Publishing

Release notes are published as a wiki page at path `/Release-Notes/<tag>` in the project wiki. The agent discovers the wiki automatically via `GET .../wiki/wikis`. If no project wiki exists, it falls back to writing `RELEASE_NOTES.md` at the repository root.

---

## Generic / Other Platforms

For remotes that aren't GitHub or Azure DevOps (Bitbucket, self-hosted git, local runs), the plugin writes the generated release notes to `RELEASE_NOTES.md` in the repository root, overwriting it on every run. No additional setup is required beyond a working git installation — see `providers/generic.md`.

---

## Summary

| Platform | PR Listing | Release Note Publishing |
|---|---|---|
| GitHub | `gh pr list --state merged --search "merged:<range>"` | `gh release create/edit <tag> --notes-file ...` |
| Azure DevOps | `curl GET .../pullrequests?searchCriteria.status=completed` | `curl -X PUT .../wiki/wikis/{id}/pages?path=/Release-Notes/<tag>` |
| Generic | — (commits only) | Overwrite `RELEASE_NOTES.md` |

---

## Related

- `docs/git-auth.md` — credential details and PAT scope requirements
- `providers/github.md` — GitHub-specific logic
- `providers/azure-devops.md` — Azure DevOps-specific logic
- `providers/generic.md` — fallback for unsupported platforms
