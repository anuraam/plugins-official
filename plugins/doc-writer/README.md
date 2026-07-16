# doc-writer

Automated documentation updater. Given a pull request number, `doc-writer` analyses the modified source files and brings the project's documentation back in sync — updating drifted entries, creating new ones for newly added public surfaces, removing entries for removed behaviour, and sweeping the doc tree for renamed symbols. It commits the doc-only changes on a **separate docs branch** and opens a **companion documentation PR** whose target is the original PR's head branch — so the doc updates can be reviewed and merged into the feature branch independently of the original PR.

Works with **GitHub**, **Azure DevOps**, and any git repository (via a local report fallback).

---

## Quick Start

```bash
# Update docs for the open PR on the current branch
/update-docs

# Update docs for a specific PR
/update-docs 42
```

The plugin is intended to be triggered automatically by the Xianix Agent — on a **PR comment**, a **PR tag/label**, or a newly created **issue / work item** — with a prompt like:

> Pull request #{{pr-number}} in {{repository-name}} (branch: {{git-ref}}) has been tagged for documentation updates.
>
> Run `/update-docs {{pr-number}}` to analyze the modified source files and update the relevant documentation in the codebase.

See [Automated Triggering (Xianix Agent)](#automated-triggering-xianix-agent) for copy-pasteable `rules.json` execution blocks.

---

## What it does

`/update-docs` is executed by the top-level agent directly — it runs the whole flow itself rather than handing off to a background agent:

```
/update-docs <pr-number>
    │
    ├── Step 0: Index the codebase
    ├── Step 1: Detect platform from git remote
    ├── Step 2: Resolve PR number (bare number / PR URL / API URL) and check state (open / merged)
    ├── Step 3: Post "documentation update in progress" comment on the original PR
    ├── Step 4: Fetch the PR head and cut a fresh docs branch (docs/pr-<n>-sync)
    │           + inventory documentation surfaces + detect conventions
    ├── Step 5: Fetch PR diff and classify changed files
    ├── Step 6: Map each source change to documentation entries (UPDATE / ADD / REMOVE / RENAME / NO-OP)
    ├── Step 7: Apply documentation edits on the docs branch
    ├── Step 8: Commit and push the docs branch (push authenticated inline via GITHUB_TOKEN / AZURE_DEVOPS_TOKEN)
    ├── Step 9: Open a companion documentation PR targeting the original PR's head branch
    └── Step 10: Post the documentation summary on the original PR (linking the new docs PR)
```

| State of the original PR | Docs PR target / base branch |
|---|---|
| **Open** | The original PR's **head** branch (merging the docs PR brings the docs into the feature branch) |
| **Already merged** | The original PR's **base** branch (the head branch may no longer exist) |

Re-running the plugin on the same PR re-uses the existing `docs/pr-<n>-sync` branch and the existing docs PR — new commits are simply pushed on top.

---

## Dispositions per documentation entry

| Disposition | When applied | Action |
|---|---|---|
| `UPDATE` | Existing doc entry describes the symbol/feature, but the PR changed its signature, default, behaviour, or example | Edit the entry |
| `ADD` | The PR adds a new public surface (symbol, command, env var, route, page) with no existing doc home | Create a new entry in the natural location |
| `REMOVE` | The PR removes a public surface that is documented today | Delete or mark deprecated |
| `RENAME` | The PR renames an exported symbol, command, env var, route, or page | Sweep all references |
| `NO-OP` | The change is internal, refactor, test, or build only | Record rationale, produce no edit |

A `CHANGELOG.md` entry is added under `[Unreleased]` whenever the PR introduces a user-visible change and the repo follows a Keep-a-Changelog–style convention.

---

## Scope — what counts as "documentation"

The plugin treats the following as documentation surfaces (and only these are eligible for edit):

- `README.md`, `README.*` at any depth
- `docs/`, `doc/`, `documentation/`, `wiki/` directories
- `CHANGELOG.md`, `CHANGES.md`, `HISTORY.md`, `RELEASE*.md`
- API reference files: `*.api.md`, `*-api.md`, OpenAPI / Swagger / AsyncAPI (`openapi.yaml`, `swagger.json`)
- `*.mdx` documentation site sources (Docusaurus, Nextra, Astro, VitePress, MkDocs)
- ADRs (`docs/adr/*.md`, `docs/decisions/*.md`)
- Inline reference docs (JSDoc / TSDoc / docstrings / GoDoc / Rustdoc / XML doc comments) — **only inside source files the PR already touched**
- `package.json` / plugin-manifest `description` fields when they summarise user-visible behaviour

The plugin never modifies source files, tests, lockfiles, build configuration, or generated artefacts. Every edit must trace back to a specific change in the PR diff.

---

## Platform Support

| Remote URL | Platform | Delivery |
|---|---|---|
| `github.com` | GitHub | Companion docs PR opened via `gh pr create --base <PR head>` + summary comment on the original PR |
| `dev.azure.com` / `visualstudio.com` | Azure DevOps | Companion docs PR opened via REST (`POST .../pullrequests` with `targetRefName=<PR head>`) + summary thread on the original PR |
| Anything else | Generic | Docs branch pushed (if a remote exists); report with manual merge instructions written to `doc-update-report.md` |

See [`docs/platform-setup.md`](docs/platform-setup.md) for detailed credential setup.

---

## Prerequisites

- Must be run inside a git repository with a remote configured
- **GitHub**: `gh` CLI installed and authenticated (`gh auth login`)
- **Azure DevOps**: `AZURE_DEVOPS_TOKEN` environment variable set
- **Pushing commits**: `GITHUB_TOKEN` (GitHub) or `AZURE_DEVOPS_TOKEN` (Azure DevOps)

---

## Output

On completion, the plugin prints a single confirmation line:

```
Documentation PR opened: #<docs-pr-number> → <pr-head-branch> (companion for PR #<number>): <N> updated, <N> added, <N> removed, <N> renamed — <docs-pr-url>
```

Or, if no docs needed updating (no docs PR is opened):

```
No documentation updates required on PR #<number> — all changes are internal/refactor/test-only.
```

A structured summary comment is posted on the **original PR** using the template in [`styles/report-template.md`](styles/report-template.md). The comment includes the link to the new docs PR so the author knows exactly what to merge.

---

## Automated Triggering (Xianix Agent)

Add execution blocks to your `rules.json` so the Xianix Agent runs `doc-writer` automatically when a webhook fires. The plugin needs a **PR number** to work against, so every trigger ultimately resolves one and calls `/update-docs <pr-number>`.

Three invocation methods are supported on each platform:

1. **Commenting on a PR** — a reviewer types a `/update-docs` comment on the PR.
2. **Tagging a PR** — on GitHub, applying the `ai-dlc/docs/update-docs` label; on Azure DevOps (whose webhooks carry no label data), adding the agent as a reviewer is the equivalent opt-in.
3. **Creating an issue / work item** — a GitHub issue (or Azure DevOps work item) that names the PR to document; the agent extracts the PR number from the issue/work-item text.

Full, copy-pasteable execution blocks for every scenario live in dedicated per-platform guides:

- **[Automated Triggering — GitHub](./docs/triggers-github.md)** — `/update-docs` PR comment, docs label applied / PR opened with it, and issue-opened.
- **[Automated Triggering — Azure DevOps](./docs/triggers-azure-devops.md)** — `/update-docs` PR comment, agent added as a reviewer, and work-item-created.

### Trigger matrix

| Platform | Scenario | Webhook event | Filter rule |
|---|---|---|---|
| GitHub | `/update-docs` comment on a PR | `issue_comment` | `action==created` and `comment.body` contains `/update-docs` and `issue.pull_request?` |
| GitHub | Docs label applied / PR opened with it | `pull_request` | `action==labeled\|opened` and `ai-dlc/docs/update-docs` in `pull_request.labels` |
| GitHub | Issue opened requesting docs | `issues` | `action==opened` and `ai-dlc/docs/update-docs` in `issue.labels` |
| Azure DevOps | `/update-docs` comment on a PR | `ms.vss-code.git-pullrequest-comment-event` | `resource.comment.commentType=='text'` and content contains `/update-docs` |
| Azure DevOps | Agent added as reviewer (tag equivalent) | `git.pullrequest.updated` | `message.text` contains `changed the reviewer list` and `xianix-agent@99x.io` in `resource.reviewers` |
| Azure DevOps | Work item created requesting docs | `workitem.created` | `resource.fields.'System.Tags'` contains `update-docs` |

The `GITHUB-TOKEN` + `GITHUB_TOKEN` (GitHub) / `AZURE-DEVOPS-TOKEN` (Azure DevOps) secrets are injected via each block's `with-envs`. The Azure secret arrives dash-cased (`AZURE-DEVOPS-TOKEN`) and the executor re-exports it as the underscored `AZURE_DEVOPS_TOKEN` the plugin reads (see [`docs/platform-setup.md`](docs/platform-setup.md)). `conversation-key` groups repeated events for the same PR so re-runs reuse the existing `docs/pr-<n>-sync` branch and docs PR. See the per-platform guides for the details.

:::note
These blocks go inside the `executions` array of a rule set. See [Rules Configuration](/agent-configuration/rules/) for the full file structure and filter syntax.
:::

---

## Key design decisions

- **The PR's own branch is never touched.** All documentation work happens on a dedicated `docs/pr-<n>-sync` branch and is delivered as a separate, reviewable PR. Protected branches, fork PRs, and active review cycles on the feature branch are all undisturbed.
- **Source code is read-only.** The plugin only edits files inside the documentation inventory. Inline reference doc comments inside source files are touched only when the surrounding source file is already in the PR diff.
- **Every edit is traceable.** No "drive-by" doc improvements for unchanged code.
- **Existing conventions win.** Heading levels, table styles, code-block language tags, link styles, and CHANGELOG formats are mirrored, not normalised.
- **One commit, one PR.** All documentation edits ship in a single `docs:` commit on the docs branch, delivered via one companion PR.
- **Idempotent re-runs.** Running the plugin again on the same PR reuses the same docs branch and the same companion PR — new commits are simply pushed on top.
- **Merged-PR safe.** When the original PR is already merged, the companion docs PR targets the original PR's base branch instead of its (possibly deleted) head branch.
- **Gaps are surfaced, not invented.** When there is no natural home for a new doc entry, the plugin reports the gap in the summary instead of creating speculative files.
