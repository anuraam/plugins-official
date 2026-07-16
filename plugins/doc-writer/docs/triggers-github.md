# Automated Triggering — GitHub

This guide shows how to make the **Xianix Agent** run the `doc-writer` plugin automatically on GitHub, driven by webhook events. Each example is an **execution block** you add to the `executions` array of your `rules.json`.

For manual/interactive use (`/update-docs` in a chat), see the main [README](../README.md). For token setup and scopes, see [`platform-setup.md`](./platform-setup.md#github).

---

## How GitHub triggering works

`doc-writer` needs a **PR number** to work against, so every trigger ultimately resolves one and calls `/update-docs <pr-number>`. Three invocation methods are supported:

| Scenario | Webhook event | Filter rule |
|---|---|---|
| `/update-docs` comment on a PR | `issue_comment` | `action==created` and `comment.body` contains `/update-docs` and `issue.pull_request?` |
| Docs label applied to a PR | `pull_request` | `action==labeled` and `label.name=='ai-dlc/docs/update-docs'` |
| PR opened already carrying the docs label | `pull_request` | `action==opened` and `ai-dlc/docs/update-docs` in `pull_request.labels` |
| Issue opened requesting docs (names the PR) | `issues` | `action==opened` and `ai-dlc/docs/update-docs` in `issue.labels` |

---

## Execution-block shape

Every execution block shares this top-level shape:

| Field | Purpose |
|---|---|
| `name` | Human-readable id for the execution |
| `platform` | `"github"` — drives which provider the plugin uses |
| `repository.url` | Webhook path to the repository URL (`repository.clone_url`) |
| `match-any` | Array of trigger filters — the first one to match fires the execution |
| `use-inputs` | The values the prompt needs — usually the PR number (or issue text to resolve one) |
| `use-plugins` | The plugin to invoke (optionally with a `slash-command`) |
| `with-envs` | Required environment variables, sourced from the agent's `secrets.*` store |
| `conversation-key` | Groups repeated events for the same PR into one conversation so re-runs reuse the existing docs branch/PR |
| `model` / `max-budget-usd` | Model and cost cap for the run |
| `execute-prompt` | The prompt sent to the agent. Implicit interpolations: `{{repository-name}}`, plus any `name` from `use-inputs` |

`doc-writer` needs both `GITHUB-TOKEN` (for `gh` — fetching PR data, posting comments, opening the docs PR) and `GITHUB_TOKEN` (for the authenticated `git push` of the docs branch). See [`platform-setup.md`](./platform-setup.md#github) for the exact permissions.

---

## Scenario 1 — Comment on a PR

A reviewer comments `/update-docs` (optionally with an explicit PR number) on the pull request. The `issue.pull_request?` guard ensures the comment is on a PR, not a plain issue.

```json
{
  "name": "github-doc-writer-pr-comment",
  "platform": "github",
  "repository": {
    "url": "repository.clone_url"
  },
  "match-any": [
    {
      "name": "github-doc-writer-comment-requested",
      "rule": "action==created&&comment.body*='/update-docs'&&issue.pull_request?"
    }
  ],
  "use-inputs": [
    { "name": "pr-number", "value": "issue.number", "mandatory": true },
    { "name": "user-instruction", "value": "comment.body" }
  ],
  "use-plugins": [
    {
      "plugin-name": "doc-writer@xianix-plugins-official",
      "marketplace": "xianix-team/plugins-official",
      "slash-command": "/update-docs"
    }
  ],
  "with-envs": [
    { "name": "GITHUB-TOKEN", "value": "secrets.GITHUB-TOKEN", "mandatory": true },
    { "name": "GITHUB_TOKEN", "value": "secrets.GITHUB-TOKEN", "mandatory": true }
  ],
  "conversation-key": "issue.number",
  "model": "claude-sonnet-4-5",
  "max-budget-usd": 5,
  "execute-prompt": "A reviewer commented on pull request #{{pr-number}} in {{repository-name}} requesting a documentation update. The comment: \"{{user-instruction}}\"\n\nAnalyze the modified source files in this PR and bring the project's documentation back in sync, opening a companion documentation PR if any changes are needed. IMPORTANT: your text output alone is not delivered back to the reviewer — you must reply on the PR yourself (e.g. `gh pr comment`) summarizing what you did, including a link to the companion docs PR if one was opened, or stating that no documentation changes were required. A run that finishes without posting that reply is a failure."
}
```

---

## Scenario 2 — Docs label applied (or PR opened with it)

Applying the `ai-dlc/docs/update-docs` label to a PR — or opening a PR that already carries it — triggers the run. Both filters are combined into one block via `match-any`.

```json
{
  "name": "github-doc-writer-pr-tag",
  "platform": "github",
  "repository": {
    "url": "repository.clone_url"
  },
  "match-any": [
    {
      "name": "github-doc-writer-tag-applied",
      "rule": "action==labeled&&label.name=='ai-dlc/docs/update-docs'&&pull_request.state=='open'"
    },
    {
      "name": "github-doc-writer-opened-with-tag",
      "rule": "action==opened&&pull_request.labels.*.name=='ai-dlc/docs/update-docs'&&pull_request.state=='open'"
    }
  ],
  "use-inputs": [
    { "name": "pr-number", "value": "pull_request.number", "mandatory": true }
  ],
  "use-plugins": [
    {
      "plugin-name": "doc-writer@xianix-plugins-official",
      "marketplace": "xianix-team/plugins-official"
    }
  ],
  "with-envs": [
    { "name": "GITHUB-TOKEN", "value": "secrets.GITHUB-TOKEN", "mandatory": true },
    { "name": "GITHUB_TOKEN", "value": "secrets.GITHUB-TOKEN", "mandatory": true }
  ],
  "conversation-key": "pull_request.number",
  "model": "claude-sonnet-4-5",
  "max-budget-usd": 5,
  "execute-prompt": "Pull request #{{pr-number}} in {{repository-name}} has been tagged for documentation updates. Run /update-docs {{pr-number}} to analyze the modified source files and open a companion documentation PR."
}
```

> **Changing the tag.** `ai-dlc/docs/update-docs` is just the string in the filter rule — change it in both the `labeled` and `opened` rules if your team uses a different label. Make sure the label actually exists in the repository's label list so it can be applied.

---

## Scenario 3 — Issue created requesting docs

An issue opened with the `ai-dlc/docs/update-docs` label naming the PR to document (e.g. "Update docs for #42"). Issue payloads don't carry a PR number directly, so the prompt asks the agent to extract one from the issue title/body before running the command.

```json
{
  "name": "github-doc-writer-issue",
  "platform": "github",
  "repository": {
    "url": "repository.clone_url"
  },
  "match-any": [
    {
      "name": "github-doc-writer-issue-opened",
      "rule": "action==opened&&issue.labels.*.name=='ai-dlc/docs/update-docs'&&!issue.pull_request?"
    }
  ],
  "use-inputs": [
    { "name": "issue-number", "value": "issue.number", "mandatory": true },
    { "name": "issue-title", "value": "issue.title" },
    { "name": "issue-body", "value": "issue.body" }
  ],
  "use-plugins": [
    {
      "plugin-name": "doc-writer@xianix-plugins-official",
      "marketplace": "xianix-team/plugins-official",
      "slash-command": "/update-docs"
    }
  ],
  "with-envs": [
    { "name": "GITHUB-TOKEN", "value": "secrets.GITHUB-TOKEN", "mandatory": true },
    { "name": "GITHUB_TOKEN", "value": "secrets.GITHUB-TOKEN", "mandatory": true }
  ],
  "conversation-key": "issue.number",
  "model": "claude-sonnet-4-5",
  "max-budget-usd": 5,
  "execute-prompt": "Issue #{{issue-number}} in {{repository-name}} requests a documentation update. Title: \"{{issue-title}}\". Body:\n{{issue-body}}\n\nIdentify the pull request number this issue refers to (a `#<n>` reference or PR link in the title/body). Then run /update-docs <pr-number> for that PR. If no PR is referenced, post a comment on the issue asking which PR to document and stop."
}
```

> **`!issue.pull_request?` guard.** GitHub represents PRs as issues internally, so this filter excludes PR-authored "issues" — this scenario is for genuine issues only. Use Scenario 1 for PR comments.

---

## Notes

- **Filter order matters.** Within `match-any`, the first matching rule wins — order the more specific rules first.
- **`pull_request.state=='open'`** guards against triggering on labels applied to closed/merged PRs.
- **`conversation-key`** ties every event for the same PR (or issue) to one conversation, so a re-run reuses the existing `docs/pr-<n>-sync` branch and companion docs PR instead of creating a duplicate.
- These blocks go inside the `executions` array of a rule set. See the [Rules Configuration](/agent-configuration/rules/) guide for the full file structure and filter syntax.
