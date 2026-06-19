# Provider: GitHub

Use this provider when `git remote get-url origin` contains `github.com`.

## How this fits with the rest of the plugin

- **Reading / analysis** — Use **git** against your base branch (same as Azure DevOps and other hosts): `git diff`, `git log`, etc. See `agents/orchestrator.md` step 3. No `gh` needed to fetch patches or file lists.
- **GitHub-specific** — Use **`gh`** only to resolve the PR number, fetch the PR's current title/description, and to **replace** the title/description.

## Prerequisites

- **GitHub CLI** (`gh`) installed: [https://cli.github.com](https://cli.github.com)
- Authenticated: `gh auth login`, or non-interactive `GH_TOKEN` / `GITHUB-TOKEN`

**Token scopes:** `repo` (private repos) or `public_repo` (public only) — these scopes allow editing a PR's title and description via `gh pr edit`. `read:org` if needed for org repos.

The plugin does **not** use the GitHub MCP server.

---

## Resolving the PR Number

If the user passed a PR number, use it.

Otherwise, for the **current branch**:

```bash
gh pr list --head "$(git rev-parse --abbrev-ref HEAD)" --json number --jq '.[0].number'
```

Or:

```bash
gh pr view --json number --jq '.number'
```

If neither resolves to a PR (e.g. no PR open yet for this branch), fall back to the generic provider — there is nothing to edit.

---

## Fetching Current PR Metadata

Before generating the new description, read the PR's **current** title and body — `change-analyst` needs these to extract any "Related Work" references before they're overwritten:

```bash
gh pr view <pr-number> --json title,body,url \
  --jq '{title: .title, body: .body, url: .url}'
```

Keep `PR_URL` from this call for the final output line.

---

## Replacing the PR Description

This is the agent's only write operation. It **fully replaces** the title and body — `gh pr edit` does not append or merge, it overwrites both fields outright.

```bash
gh pr edit <pr-number> \
  --title "<new title>" \
  --body-file /tmp/pr_description.md
```

- `<new title>` is the title synthesized in orchestrator step 6 — pass it as a literal argument (quote it).
- `/tmp/pr_description.md` is the full rendered body from orchestrator step 6, per `styles/pr-description-template.md`.

If this command fails, output a single error line and stop — do not retry, do not fall back to posting a comment.

---

## Output

On completion:

```
PR description replaced on PR #<number>: GitHub — <url>
```

Use `$PR_URL` from "Fetching Current PR Metadata" for `<url>`.
