# Automated Triggering — GitHub

This guide shows how to make the **Xianix Agent** run the PR Comment Resolver plugin automatically on GitHub, driven by webhook events. Each example is an **execution block** you add to the `executions` array of your `rules.json`.

For manual/interactive use (`/resolve-comments` in a chat), see [`../commands/resolve-comments.md`](../commands/resolve-comments.md). For token setup and scopes, see [`platform-setup.md`](./platform-setup.md#github).

---

## How GitHub triggering works

GitHub webhook payloads **include label data**, so the plugin uses **label-based** triggering: apply the `ai-dlc/pr/resolve-comments` label to a PR and the agent resolves its unresolved review threads — applying actionable ones as commits, replying to the rest, and posting a disposition summary.

| Scenario | Webhook event | Filter rule |
|---|---|---|
| Resolve label applied to a PR | `pull_request` | `action==labeled` and `label.name=='ai-dlc/pr/resolve-comments'` |
| Review submitted requesting changes on a labeled PR | `pull_request_review` | `action==submitted` and `review.state=='changes_requested'` and `ai-dlc/pr/resolve-comments` in `pull_request.labels` |

> **Why label-driven and not "every review"?** Resolving comments pushes commits to the author's branch. Gating on an explicit label keeps that opt-in per PR — a reviewer requesting changes on an unlabeled PR does nothing.

---

## Execution-block shape

Every execution block shares this top-level shape:

| Field | Purpose |
|---|---|
| `name` | Human-readable id for the execution |
| `platform` | `"github"` — drives which provider the plugin uses |
| `repository.url` | Webhook path to the repository URL (`repository.clone_url`) |
| `match-any` | Array of trigger filters — the first one to match fires the execution |
| `use-inputs` | The values the prompt needs — usually just the PR number |
| `use-plugins` | The plugin to invoke (optionally with a `slash-command`) |
| `with-envs` | Required environment variables, sourced from the agent's `secrets.*` store |
| `conversation-key` | Groups repeated events for the same PR into one conversation so follow-up resolution runs share prior context |
| `model` / `max-budget-usd` | Model and cost cap for the run |
| `execute-prompt` | The prompt sent to the agent. Implicit interpolations: `{{repository-name}}`, plus any `name` from `use-inputs` |

The `GITHUB-TOKEN` secret is injected via `with-envs` and authenticates `gh` for fetching review threads, posting replies, resolving threads, and pushing the fix commits. See [`platform-setup.md`](./platform-setup.md#github) for the exact permissions (Contents and Pull requests need **Read & Write** — the resolver commits and pushes, unlike a read-only reviewer).

---

## Recommended: one block covering label + changes-requested

In production, both triggers are best combined into a **single execution block** using `match-any`. The `conversation-key` on `pull_request.number` ties every event for a PR to the same conversation, so a second resolution pass on the same PR reconciles against what was already applied instead of starting cold.

```json
{
  "name": "github-pr-comment-resolution",
  "platform": "github",
  "repository": {
    "url": "repository.clone_url"
  },
  "match-any": [
    {
      "name": "github-pr-resolve-tag-applied",
      "rule": "action==labeled&&label.name=='ai-dlc/pr/resolve-comments'&&pull_request.state=='open'"
    },
    {
      "name": "github-pr-changes-requested-with-tag",
      "rule": "action==submitted&&review.state=='changes_requested'&&pull_request.labels.*.name=='ai-dlc/pr/resolve-comments'&&pull_request.state=='open'"
    }
  ],
  "use-inputs": [
    { "name": "pr-number", "value": "pull_request.number", "mandatory": true }
  ],
  "use-plugins": [
    {
      "plugin-name": "pr-comment-resolver@xianix-plugins-official",
      "marketplace": "xianix-team/plugins-official"
    }
  ],
  "with-envs": [
    { "name": "GITHUB-TOKEN", "value": "secrets.GITHUB-TOKEN", "mandatory": true }
  ],
  "conversation-key": "pull_request.number",
  "model": "claude-sonnet-4-5",
  "max-budget-usd": 3,
  "execute-prompt": "You are resolving the review comments on pull request #{{pr-number}} in the repository {{repository-name}}. Run /resolve-comments {{pr-number}} to classify every unresolved review thread, apply the actionable ones as commits, reply to the rest, and post the disposition summary. IMPORTANT: your text output alone is NOT delivered anywhere — the work counts only when the commits are pushed and the comments exist on the PR. Do not end the run until the disposition summary comment has been posted (or a hard error has been reported)."
}
```

The scenarios below break the same behavior into standalone blocks if you prefer separate budgets or prompts per event.

---

## Scenario 1 — Resolve label applied to a PR (tag trigger)

A human (or another rule) adds the `ai-dlc/pr/resolve-comments` label to an open PR. This is the on-demand "resolve the comments now" trigger.

```json
{
  "name": "github-pr-resolve-tag-applied",
  "platform": "github",
  "repository": {
    "url": "repository.clone_url"
  },
  "match-any": [
    {
      "name": "github-pr-resolve-tag-applied",
      "rule": "action==labeled&&label.name=='ai-dlc/pr/resolve-comments'&&pull_request.state=='open'"
    }
  ],
  "use-inputs": [
    { "name": "pr-number", "value": "pull_request.number", "mandatory": true }
  ],
  "use-plugins": [
    {
      "plugin-name": "pr-comment-resolver@xianix-plugins-official",
      "marketplace": "xianix-team/plugins-official"
    }
  ],
  "with-envs": [
    { "name": "GITHUB-TOKEN", "value": "secrets.GITHUB-TOKEN", "mandatory": true }
  ],
  "conversation-key": "pull_request.number",
  "model": "claude-sonnet-4-5",
  "max-budget-usd": 3,
  "execute-prompt": "You are resolving the review comments on pull request #{{pr-number}} in the repository {{repository-name}}. Run /resolve-comments {{pr-number}} to classify every unresolved review thread, apply the actionable ones as commits, reply to the rest, and post the disposition summary. IMPORTANT: your text output alone is NOT delivered anywhere — the work counts only when the commits are pushed and the comments exist on the PR. Do not end the run until the disposition summary comment has been posted (or a hard error has been reported)."
}
```

> **Changing the tag.** The trigger phrase `ai-dlc/pr/resolve-comments` is just the string in the filter rule — change it in both rules if your team uses a different label. Make sure the label actually exists in the repository's label list so it can be applied.

---

## Scenario 2 — Review submitted requesting changes on a labeled PR

When a reviewer submits a **changes requested** review on a PR that carries the resolve label, the agent immediately works through the new threads. Pairs naturally with the PR Reviewer plugin: its review lands, and the resolver picks up the actionable findings.

```json
{
  "name": "github-pr-resolve-on-changes-requested",
  "platform": "github",
  "repository": {
    "url": "repository.clone_url"
  },
  "match-any": [
    {
      "name": "github-pr-changes-requested-with-tag",
      "rule": "action==submitted&&review.state=='changes_requested'&&pull_request.labels.*.name=='ai-dlc/pr/resolve-comments'&&pull_request.state=='open'"
    }
  ],
  "use-inputs": [
    { "name": "pr-number", "value": "pull_request.number", "mandatory": true }
  ],
  "use-plugins": [
    {
      "plugin-name": "pr-comment-resolver@xianix-plugins-official",
      "marketplace": "xianix-team/plugins-official"
    }
  ],
  "with-envs": [
    { "name": "GITHUB-TOKEN", "value": "secrets.GITHUB-TOKEN", "mandatory": true }
  ],
  "conversation-key": "pull_request.number",
  "model": "claude-sonnet-4-5",
  "max-budget-usd": 3,
  "execute-prompt": "A reviewer requested changes on pull request #{{pr-number}} in the repository {{repository-name}}. Run /resolve-comments {{pr-number}} to classify the unresolved review threads, apply the actionable ones as commits, reply to the rest, and post the disposition summary. IMPORTANT: your text output alone is NOT delivered anywhere — the work counts only when the commits are pushed and the comments exist on the PR. Do not end the run until the disposition summary comment has been posted (or a hard error has been reported)."
}
```

> **Loop guard.** If the PR Reviewer plugin re-reviews on `synchronize` (new commits) and this block resolves on `changes_requested`, the two can ping-pong: resolve → push → re-review → new findings → resolve. Keep the reviewer's default **non-blocking** mode (it posts `--comment`, not `changes_requested`) or drop this scenario and rely on the label trigger alone.

---

## Notes

- **Filter order matters.** Within `match-any`, the first matching rule wins — order the more specific rules first.
- **`pull_request.state=='open'`** guards against triggering on labels applied to closed/merged PRs. (Merged-PR resolution — where the plugin cuts a follow-up branch and PR — is still available interactively via `/resolve-comments <pr-number>`.)
- **`conversation-key`** groups repeated events for the same PR into one conversation, so a later pass knows what an earlier pass already applied, replied to, or declined.
- These blocks go inside the `executions` array of a rule set. See the [Rules Configuration](/agent-configuration/rules/) guide for the full file structure and filter syntax.
