# Platform Setup Guide

The Performance Optimizer analyzes the repository's **default branch** with plain `git` on every supported host. **GitHub CLI (`gh`)** and **Azure DevOps REST** (via `curl`) are used only to read the trigger issue / work item (skipped for scheduled runs — see `docs/triggers-schedule.md`), open the pull request, and post the link-back comment (also skipped for scheduled runs) — not for the core analysis.

---

## GitHub

### GitHub CLI (`gh`) — required to read issues and open PRs

Install **`gh`** so the plugin can:

- read the trigger issue body (for optional `Scope:` / `Target:` hints)
- post a "review in progress" comment on the issue
- open the performance PR against the default branch
- post a link-back comment on the issue once the PR is open

```bash
# Install: https://cli.github.com
gh auth login
```

For CI or scripted use, set **`GITHUB-TOKEN`** (preferred) or **`GH_TOKEN`** instead of interactive login.

### Token permissions

| Permission | Access | Purpose |
|---|---|---|
| **Contents** | Read & Write | Read repository code on the default branch, push the new `perf/issue-*` branch |
| **Metadata** | Read | Resolve repository metadata (default branch, clone URL, etc.) |
| **Issues** | Read & Write | Read the trigger issue body / scope hints and post the link-back comment. Unused for scheduled runs — there's no issue. |
| **Pull requests** | Read & Write | Open the performance PR, update it with the report, and (scheduled runs) list open PRs for the dedupe check |

Classic tokens: `repo` (private repos) or `public_repo` (public only); `read:org` (org repos).

The plugin does **not** use the GitHub MCP server.

### Credentials for `git push`

The `perf-pr-author` agent pushes the new `perf/issue-<number>-<slug>` (or `perf/scheduled-<date>-<sha>` for scheduled runs) branch — never the default branch. The `GITHUB-TOKEN` is reused as the push credential — the `hooks/validate-prerequisites.sh` PreToolUse hook injects it into git via `GIT_CONFIG_*` environment variables just for that one push. No separate `GITHUB_TOKEN` is required.

Pass it at runtime:

```bash
GITHUB-TOKEN=ghp_your_token_here claude ...
```

Or export in your shell:

```bash
export GITHUB-TOKEN=ghp_your_token_here
```

---

## Azure DevOps

### Prerequisites

Install the Azure CLI if you want to use the same PAT for other tooling:

```bash
# https://learn.microsoft.com/en-us/cli/azure/install-azure-cli
az extension add --name azure-devops
```

The plugin itself does **not** require the `az` CLI — it uses `curl` against the Azure DevOps REST API for work items, pull requests, and comments.

### Authentication

**Personal Access Token**

```bash
export AZURE-DEVOPS-TOKEN=<your-pat>
```

Add to `~/.zshrc` or `~/.bashrc` to persist.

**PAT scopes needed:**

| Scope | Access | Purpose |
|---|---|---|
| **Code** | Read & Write | Read repository code on the default branch, push the new `perf/workitem-*` / `perf/scheduled-*` branch |
| **Work Items** | Read & Write | Read the trigger work item description / tags and post the link-back comment. Unused for scheduled runs — there's no work item. |
| **Pull Request Threads** | Read & Write | Open the performance PR, maintain its discussion thread, and (scheduled runs) query open PRs for the dedupe check |

### Credentials for `git push`

The plugin reuses `AZURE-DEVOPS-TOKEN` for `git push` credential injection automatically — no separate token is needed.

### Generating a PAT

1. Go to `https://dev.azure.com/<your-org>/_usersSettings/tokens`.
2. Click **New Token**.
3. Set the scopes listed above.
4. Copy the token and export it as `AZURE-DEVOPS-TOKEN`.

---

## Unsupported platforms

GitHub and Azure DevOps are the two platforms the issue-driven and scheduled flows support end-to-end. The `/perf-optimize` command can still run locally against any git remote — the analyzer pipeline is host-agnostic — but PR creation is only automated on the two platforms above. On any other remote, the PreToolUse hook will refuse the push and you will need to open the PR manually on your host.

---

## Summary

| Platform | Trigger | Analysis input | PR opening | Push token |
|---|---|---|---|---|
| GitHub | Issue label `ai-dlc/perf/optimize` | `git ls-files` on the default branch | `gh pr create` | `GITHUB-TOKEN` |
| Azure DevOps | Work item tag `ai-dlc/perf/optimize` | `git ls-files` on the default branch | REST (`curl`) per `providers/azure-devops.md` | `AZURE-DEVOPS-TOKEN` |
| GitHub / Azure DevOps | `schedule` rule set (`cron`, `--schedule`) | `git ls-files` on the default branch | Same as above, minus the issue/work-item read + link-back | Same tokens as above |

---

## Related

- `providers/github.md` — GitHub-specific issue reads, PR creation, and comment logic
- `providers/azure-devops.md` — Azure DevOps-specific work-item reads, PR creation, and comment logic
- `docs/triggers-github.md` — Xianix Agent rule for label-driven execution on GitHub
- `docs/triggers-azure-devops.md` — Xianix Agent rule for tag-driven execution on Azure DevOps
- `docs/triggers-schedule.md` — Xianix Agent rule for cron-driven execution with no issue/work item
