# Platform Setup

`/deadcode` without `--fix` is entirely read-only and needs **no** platform setup — it only runs Knip and writes report files locally.

`--fix` and `--fix-dry-run` install dependencies and run `knip --fix` inside an isolated worktree, which needs no credentials either. Credentials are only needed for the last step of `--fix`: pushing the `deadcode-fix/<run-id>` branch and opening a draft PR. `--fix-dry-run` prints the diff and stops before that step, so it never needs the setup below.

`scripts/check-permissions.sh` runs this checklist automatically at the start of `--fix` and fails fast (before the worktree, install, or `knip --fix` run) if something below is missing.

## GitHub

| Requirement | Notes |
|---|---|
| `gh` CLI installed | https://cli.github.com |
| `gh auth login` completed, **or** `GITHUB_TOKEN` / `GH_TOKEN` set | Either satisfies `gh auth status` |
| Token/session can read and write the repo | Classic PAT: `repo` scope (or `public_repo` for public repos). Fine-grained PAT: `Contents: Read & Write`, `Pull requests: Read & Write` |

Verify locally:

```bash
gh auth status
gh repo view --json nameWithOwner
```

If both succeed, `check-permissions.sh` will pass.

## Azure DevOps

| Requirement | Notes |
|---|---|
| `az` CLI installed | https://learn.microsoft.com/cli/azure/install-azure-cli |
| `az extension add --name azure-devops` | Required for `az repos pr create` |
| `AZURE_DEVOPS_TOKEN` set, **or** `az login` completed | A Personal Access Token with **Code (Read & Write)** and **Pull Request (Read & Write)** scopes is the simplest path in CI |
| `az devops configure --defaults organization=<org-url> project=<project>` | So `az repos pr create` can resolve org/project without extra flags |

Verify locally:

```bash
az account show          # confirms az login / service-principal auth
az repos pr list --status active   # confirms the PAT/session can read PRs
```

## Generic / other hosts

Repos whose `origin` isn't GitHub or Azure DevOps still get the full `--fix` flow up through **pushing the branch** — `git push` uses whatever credential helper or SSH key is already configured for `origin` (same as any other `git push` on your machine). No PR is opened automatically since there's no supported CLI for it; `fix-writer` reports `branch-pushed-no-pr` and prints the pushed branch name so you can open the PR by hand.

## Troubleshooting

| Symptom | Fix |
|---|---|
| `PERMISSIONS CHECK FAILED: 'gh' is not authenticated` | Run `gh auth login`, or export `GITHUB_TOKEN` in the environment `/deadcode --fix` runs in |
| `PERMISSIONS CHECK FAILED: no Azure DevOps auth found` | Export `AZURE_DEVOPS_TOKEN`, or run `az login` in the same environment |
| `PR_STATUS=branch-pushed-no-pr` with a warning about `gh`/`az` | Credentials were valid enough to push but not to create a PR (e.g. missing `Pull Request` scope) — open the PR manually from the printed branch/compare URL |
| Push itself fails after permissions passed | `check-permissions.sh` verifies CLI auth, not git push access specifically (SSH key, HTTPS credential helper) — confirm `git push origin HEAD` works against this repo independently of `/deadcode` |

Report-only scans (`/deadcode` with no flags) are unaffected by any of the above — nothing here blocks the default read-only path.
