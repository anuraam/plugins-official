# Automated Triggering — Azure DevOps

This guide shows how to make the **Xianix Agent** run the `doc-writer` plugin automatically on Azure DevOps, driven by service-hook events. Each example is an **execution block** you add to the `executions` array of your `rules.json`.

For manual/interactive use (`/update-docs` in a chat), see the main [README](../README.md). For token setup and scopes, see [`platform-setup.md`](./platform-setup.md#azure-devops).

---

## How Azure DevOps triggering works

> **Why not labels?** Azure DevOps webhook payloads do **not** include label/tag data on pull requests, so the "tag a PR" method used on GitHub has no direct equivalent. Instead, **adding the agent as a reviewer** is the opt-in trigger. Work items *do* support tags, so the issue-equivalent trigger uses a tagged work item instead.

| Scenario | Event type | Filter rule |
|---|---|---|
| `/update-docs` comment on a PR | `ms.vss-code.git-pullrequest-comment-event` | `resource.comment.commentType=='text'` and content contains `/update-docs` |
| Agent added as a reviewer (tag equivalent) | `git.pullrequest.updated` | `message.text` contains `changed the reviewer list` and `xianix-agent@99x.io` in `resource.reviewers` |
| Work item created requesting docs | `workitem.created` | `resource.fields.'System.Tags'` contains `update-docs` |

The reviewer identity `xianix-agent@99x.io` is the agent's Azure DevOps account — replace it with whatever account your agent authenticates as.

---

## Execution-block shape

Every execution block shares this top-level shape:

| Field | Purpose |
|---|---|
| `name` | Human-readable id for the execution |
| `platform` | `"azuredevops"` — drives which provider the plugin uses |
| `repository.url` | Webhook path to the repository URL (varies by event type — see each scenario) |
| `match-any` | Array of trigger filters — the first one to match fires the execution |
| `use-inputs` | The values the prompt needs — usually the PR id (or work item text to resolve one) |
| `use-plugins` | The plugin to invoke (optionally with a `slash-command`) |
| `with-envs` | Required environment variables, sourced from the agent's `secrets.*` store |
| `conversation-key` | Groups repeated events for the same PR into one conversation so re-runs reuse the existing docs branch/PR |
| `model` / `max-budget-usd` | Model and cost cap for the run |
| `execute-prompt` | The prompt sent to the agent. Implicit interpolations: `{{repository-name}}`, plus any `name` from `use-inputs` |

The `AZURE-DEVOPS-TOKEN` secret is injected via `with-envs`; it authenticates the REST API calls used to fetch PR data, post comments/threads, and open the companion docs PR, plus the authenticated `git push` of the docs branch. See [`platform-setup.md`](./platform-setup.md#azure-devops) for the exact PAT scopes.

---

## Scenario 1 — Comment on a PR

A reviewer comments `/update-docs` on the pull request. `commentType=='text'` ensures it is a real user comment, not a system entry.

```json
{
  "name": "azuredevops-doc-writer-pr-comment",
  "platform": "azuredevops",
  "repository": {
    "url": "resource.pullRequest.repository.remoteUrl"
  },
  "match-any": [
    {
      "name": "azuredevops-doc-writer-comment-requested",
      "rule": "eventType==ms.vss-code.git-pullrequest-comment-event&&resource.comment.commentType=='text'&&resource.comment.content*='/update-docs'"
    }
  ],
  "use-inputs": [
    { "name": "pr-number", "value": "resource.pullRequest.pullRequestId", "mandatory": true },
    { "name": "user-instruction", "value": "resource.comment.content" }
  ],
  "use-plugins": [
    {
      "plugin-name": "doc-writer@xianix-plugins-official",
      "marketplace": "xianix-team/plugins-official",
      "slash-command": "/update-docs"
    }
  ],
  "with-envs": [
    { "name": "AZURE-DEVOPS-TOKEN", "value": "secrets.AZURE-DEVOPS-TOKEN", "mandatory": true }
  ],
  "conversation-key": "resource.pullRequest.pullRequestId",
  "model": "claude-sonnet-4-5",
  "max-budget-usd": 5,
  "execute-prompt": "A reviewer commented on pull request #{{pr-number}} in {{repository-name}} requesting a documentation update. The comment: \"{{user-instruction}}\"\n\nAnalyze the modified source files in this PR and bring the project's documentation back in sync, opening a companion documentation PR if any changes are needed. IMPORTANT: your text output alone is not delivered back to the reviewer — you must post a reply thread on the PR yourself (via the Azure DevOps REST API) summarizing what you did, including a link to the companion docs PR if one was opened, or stating that no documentation changes were required. A run that finishes without posting that reply is a failure."
}
```

---

## Scenario 2 — Agent added as a reviewer (tag equivalent)

The cleanest opt-in on Azure DevOps: a human adds `xianix-agent@99x.io` to the PR's reviewer list, and the agent updates the docs. This replaces the label trigger used on GitHub.

```json
{
  "name": "azuredevops-doc-writer-reviewer-added",
  "platform": "azuredevops",
  "repository": {
    "url": "resource.repository.remoteUrl"
  },
  "match-any": [
    {
      "name": "azuredevops-doc-writer-agent-added-as-reviewer",
      "rule": "eventType==git.pullrequest.updated&&message.text*='changed the reviewer list'&&resource.reviewers.*.uniqueName=='xianix-agent@99x.io'&&resource.status=='active'"
    }
  ],
  "use-inputs": [
    { "name": "pr-number", "value": "resource.pullRequestId", "mandatory": true }
  ],
  "use-plugins": [
    {
      "plugin-name": "doc-writer@xianix-plugins-official",
      "marketplace": "xianix-team/plugins-official"
    }
  ],
  "with-envs": [
    { "name": "AZURE-DEVOPS-TOKEN", "value": "secrets.AZURE-DEVOPS-TOKEN", "mandatory": true }
  ],
  "conversation-key": "resource.pullRequestId",
  "model": "claude-sonnet-4-5",
  "max-budget-usd": 5,
  "execute-prompt": "Pull request #{{pr-number}} in {{repository-name}} has been tagged for documentation updates (the docs agent was added as a reviewer). Run /update-docs {{pr-number}} to analyze the modified source files and open a companion documentation PR."
}
```

> **Reviewer identity.** `xianix-agent@99x.io` is the `uniqueName` of the account your agent authenticates as (the same account the `AZURE-DEVOPS-TOKEN` PAT belongs to). Change it to match your agent's account, or the reviewer-list match will not line up.

---

## Scenario 3 — Work item created requesting docs

A work item created with the `update-docs` tag naming the PR to document. Because work item payloads carry no repository URL, set `repository.url` to the target repo's clone URL explicitly.

```json
{
  "name": "azuredevops-doc-writer-workitem",
  "platform": "azuredevops",
  "repository": {
    "url": "https://dev.azure.com/<org>/<project>/_git/<repo>"
  },
  "match-any": [
    {
      "name": "azuredevops-doc-writer-workitem-created",
      "rule": "eventType==workitem.created&&resource.fields.'System.Tags'*='update-docs'"
    }
  ],
  "use-inputs": [
    { "name": "workitem-id", "value": "resource.id", "mandatory": true },
    { "name": "workitem-title", "value": "resource.fields.'System.Title'" },
    { "name": "workitem-description", "value": "resource.fields.'System.Description'" }
  ],
  "use-plugins": [
    {
      "plugin-name": "doc-writer@xianix-plugins-official",
      "marketplace": "xianix-team/plugins-official",
      "slash-command": "/update-docs"
    }
  ],
  "with-envs": [
    { "name": "AZURE-DEVOPS-TOKEN", "value": "secrets.AZURE-DEVOPS-TOKEN", "mandatory": true }
  ],
  "conversation-key": "resource.id",
  "model": "claude-sonnet-4-5",
  "max-budget-usd": 5,
  "execute-prompt": "Work item #{{workitem-id}} in {{repository-name}} requests a documentation update. Title: \"{{workitem-title}}\". Description:\n{{workitem-description}}\n\nIdentify the pull request number this work item refers to (a `#<n>` / `!<n>` reference or PR link in the title/description). Then run /update-docs <pr-number> for that PR. If no PR is referenced, comment on the work item asking which PR to document and stop."
}
```

> **Replace the placeholder URL.** Unlike the PR-based scenarios, this block's `repository.url` is a literal string, not a payload path — set it to the actual repo you want `doc-writer` to run against, since a work item can reference a PR in any repository in the project.

---

## Notes

- **Filter order matters.** Within `match-any`, the first matching rule wins — order the more specific rules first.
- **`resource.status=='active'`** guards against triggering on abandoned/completed PRs.
- **`message.text` matching** (`*=`) is how Azure DevOps update events are distinguished, since a single `git.pullrequest.updated` event type covers many kinds of PR changes.
- **`conversation-key`** ties every event for the same PR (or work item) to one conversation, so a re-run reuses the existing `docs/pr-<n>-sync` branch and companion docs PR instead of creating a duplicate.
- **Token name hygiene:** the secret arrives as `AZURE-DEVOPS-TOKEN` (dashes); the executor re-exports it as the underscored `AZURE_DEVOPS_TOKEN` the plugin references. See [`platform-setup.md`](./platform-setup.md#azure-devops).
- These blocks go inside the `executions` array of a rule set. See the [Rules Configuration](/agent-configuration/rules/) guide for the full file structure and filter syntax.
