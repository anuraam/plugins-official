# Automated Triggering — Azure DevOps

This guide shows how to make the **Xianix Agent** run the PR Comment Resolver plugin automatically on Azure DevOps, driven by service-hook events. Each example is an **execution block** you add to the `executions` array of your `rules.json`.

For manual/interactive use (`/resolve-comments` in a chat), see [`../commands/resolve-comments.md`](../commands/resolve-comments.md). For token setup and scopes, see [`platform-setup.md`](./platform-setup.md#azure-devops).

---

## How Azure DevOps triggering works

> **Why not labels?** Azure DevOps webhook payloads do **not** include label/tag data (`resource.labels` is absent), so label-driven rules cannot filter on PR tags the way the GitHub trigger does. Instead, the resolver is triggered **on demand** by a **`@xianix resolve` comment mention** on the PR.

| Scenario | Event type | Filter rule |
|---|---|---|
| User asks for resolution in a PR comment | `ms.vss-code.git-pullrequest-comment-event` | `resource.comment.commentType=='text'` and `resource.comment.content` contains `@xianix resolve` |

Comment-mention triggering keeps the resolver **opt-in per PR** — important because resolution pushes commits to the author's branch. If you also run the PR Reviewer plugin's generic `@xianix` comment block, order this more specific `@xianix resolve` rule **before** it in your rule set, since within `match-any` (and across blocks) the first matching rule wins.

---

## Execution-block shape

Every execution block shares this top-level shape:

| Field | Purpose |
|---|---|
| `name` | Human-readable id for the execution |
| `platform` | `"azuredevops"` — drives which provider the plugin uses |
| `repository.url` | Webhook path to the repository URL (`resource.pullRequest.repository.remoteUrl` on comment events) |
| `match-any` | Array of trigger filters — the first one to match fires the execution |
| `use-inputs` | The values the prompt needs — usually just the PR id |
| `use-plugins` | The plugin to invoke (optionally with a `slash-command`) |
| `with-envs` | Required environment variables, sourced from the agent's `secrets.*` store |
| `conversation-key` | Groups repeated events for the same PR into one conversation so follow-up resolution runs share prior context |
| `model` / `max-budget-usd` | Model and cost cap for the run |
| `execute-prompt` | The prompt sent to the agent. Implicit interpolations: `{{repository-name}}`, plus any `name` from `use-inputs` |

The `AZURE-DEVOPS-TOKEN` secret is injected via `with-envs`; it authenticates the REST API calls used to fetch threads, post replies, update thread statuses, and `git push` the applied fixes. See [`platform-setup.md`](./platform-setup.md#azure-devops) for the exact PAT scopes (`Code` and `Pull Request Threads`, both **Read & Write**).

---

## Scenario — `@xianix resolve` comment on a PR

A human asks for resolution by commenting `@xianix resolve` (optionally with extra instructions) on the PR. `resource.comment.commentType=='text'` ensures it's a real user comment, not a system entry.

```json
{
  "name": "azuredevops-pr-comment-resolution",
  "platform": "azuredevops",
  "repository": {
    "url": "resource.pullRequest.repository.remoteUrl"
  },
  "match-any": [
    {
      "name": "azuredevops-pr-resolve-requested",
      "rule": "eventType==ms.vss-code.git-pullrequest-comment-event&&resource.comment.commentType=='text'&&resource.comment.content*='@xianix resolve'"
    }
  ],
  "use-inputs": [
    { "name": "pr-number", "value": "resource.pullRequest.pullRequestId", "mandatory": true },
    { "name": "user-instruction", "value": "resource.comment.content" },
    { "name": "comment-author", "value": "resource.comment.author.displayName" }
  ],
  "use-plugins": [
    {
      "plugin-name": "pr-comment-resolver@xianix-plugins-official",
      "marketplace": "xianix-team/plugins-official",
      "slash-command": "/resolve-comments"
    }
  ],
  "with-envs": [
    { "name": "AZURE-DEVOPS-TOKEN", "value": "secrets.AZURE-DEVOPS-TOKEN", "mandatory": true }
  ],
  "conversation-key": "resource.pullRequest.pullRequestId",
  "model": "claude-sonnet-4-5",
  "max-budget-usd": 3,
  "execute-prompt": "{{comment-author}} asked you to resolve the review comments on pull request #{{pr-number}} in the repository {{repository-name}} with the comment: \"{{user-instruction}}\"\n\nRun /resolve-comments {{pr-number}} to classify every unresolved review thread, apply the actionable ones as commits, reply to the rest, and post the disposition summary. If the comment contains additional scoping instructions (e.g. only certain files or threads), honor them. IMPORTANT: your text output alone is NOT delivered anywhere — the work counts only when the commits are pushed and the comments exist on the PR. Do not end the run until the disposition summary comment has been posted (or a hard error has been reported)."
}
```

> **Changing the trigger phrase.** `@xianix resolve` is just the substring in the filter rule — change it to match your team's convention. Keep it more specific than a bare `@xianix` if the PR Reviewer plugin's comment block is active in the same rule set.

---

## Notes

- **Filter order matters.** Within `match-any`, the first matching rule wins — order the more specific rules first. Put this block **before** any generic `@xianix` comment block.
- **`conversation-key`** groups repeated events for the same PR into one conversation, so a later pass knows what an earlier pass already applied, replied to, or declined.
- **Lifecycle triggers are possible but not recommended.** Azure DevOps vote and update events arrive as `git.pullrequest.updated` with distinguishing `message.text` content (the same mechanism the PR Reviewer's triggers use). Auto-resolving on every reviewer vote would push commits to the author's branch without an explicit request — keep the resolver behind the comment mention.
- **Token name hygiene:** the secret arrives as `AZURE-DEVOPS-TOKEN` (dashes) via `with-envs`; see [`platform-setup.md`](./platform-setup.md#azure-devops) for how the token is referenced at runtime.
- These blocks go inside the `executions` array of a rule set. See the [Rules Configuration](/agent-configuration/rules/) guide for the full file structure and filter syntax.
