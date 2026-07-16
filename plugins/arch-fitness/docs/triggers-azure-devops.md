# Automated Triggering — Azure DevOps

This guide shows how to make the **Xianix Agent** run the Architecture Fitness plugin automatically on Azure DevOps, driven by service-hook events. Each example is an **execution block** you add to the `executions` array of your `rules.json`.

For manual/interactive use (`/arch-fitness` in a chat), see the main [README](../README.md). For token setup and scopes, see [`platform-setup.md`](./platform-setup.md#azure-devops).

---

## How Azure DevOps triggering works

Architecture Fitness attaches to an Azure DevOps **Work Item** and posts its report back as a comment on that work item. Unlike PRs, Azure DevOps work-item events **do** carry tag data (`System.Tags`), so the plugin supports two trigger styles:

| Trigger style | How a human starts it |
|---|---|
| **Tag** | Add the `ai-dlc/arch/fitness` tag to a work item |
| **Comment mention** | Comment `@xianix` on a work item with an optional instruction |

| Scenario | Event type | Filter rule |
|---|---|---|
| Tag added to a work item | `workitem.updated` | `resource.fields['System.Tags']` contains `ai-dlc/arch/fitness` |
| Work item created **with** the tag | `workitem.updated` (fired after `workitem.created`) | `resource.fields['System.Tags']` contains `ai-dlc/arch/fitness` |
| User `@xianix` comment on a work item | `workitem.commented` | `resource.fields['System.History']` contains `@xianix` |

> **Why match `workitem.updated`, not `workitem.created`, for the tag trigger?** Azure DevOps fires `workitem.created` followed by `workitem.updated` when a work item is created with tags. Matching only `workitem.updated` covers both "created with tag" and "tag added later" with a single container run — avoiding two concurrent runs racing on the docs PR. The comment trigger uses the dedicated `workitem.commented` event, whose new comment text lands in `System.History`.

The target repository URL and default branch are **constants** on the rule, because work items are project-scoped (not repo-scoped). Deploy one rule per repository you want to cover.

---

## Execution-block shape

| Field | Purpose |
|---|---|
| `name` | Human-readable id for the execution |
| `platform` | `"azuredevops"` — drives which provider the plugin uses |
| `repository.url` / `repository.ref` / `repository.constant` | Constant repository + default branch to check out |
| `match-any` | Array of trigger filters — the first one to match fires the execution |
| `use-inputs` | Values interpolated into the prompt (work item id, title, description) |
| `use-plugins` | The plugin to invoke (optionally with a `slash-command`) |
| `with-envs` | Environment variables sourced from the agent's `secrets.*` store |
| `conversation-key` | Groups repeated events for the same work item into one conversation |
| `model` / `max-budget-usd` | Model and cost cap for the run |
| `execute-prompt` | The prompt sent to the agent. Implicit interpolations: `{{repository-name}}`, plus any `name` from `use-inputs` |

The `AZURE-DEVOPS-TOKEN` secret is injected via `with-envs`; it authenticates the REST calls used to read the work item, fetch PR diffs, open the docs PR, and post the report comment, and the `git push` of the `arch/docs-*` branch. See [`platform-setup.md`](./platform-setup.md#azure-devops) for the exact PAT scopes.

---

## Scenario — Tag added to a work item

The primary opt-in on Azure DevOps: a human adds the `ai-dlc/arch/fitness` tag to a work item, and the agent runs.

```json
{
  "name": "azuredevops-architecture-fitness-tag",
  "platform": "azuredevops",
  "repository": {
    "url": "https://dev.azure.com/<org>/<project>/_git/<repo>",
    "ref": "main",
    "constant": true
  },
  "match-any": [
    {
      "name": "azuredevops-workitem-tagged",
      "rule": "eventType==workitem.updated&&resource.fields.System.Tags*='ai-dlc/arch/fitness'"
    }
  ],
  "use-inputs": [
    { "name": "workitem-id",     "value": "resource.id", "mandatory": true },
    { "name": "workitem-title",  "value": "resource.fields.System.Title" },
    { "name": "workitem-body",   "value": "resource.fields.System.Description" }
  ],
  "use-plugins": [
    {
      "plugin-name": "arch-fitness@xianix-plugins-official",
      "marketplace": "xianix-team/plugins-official"
    }
  ],
  "with-envs": [
    { "name": "AZURE-DEVOPS-TOKEN", "value": "secrets.AZURE-DEVOPS-TOKEN", "mandatory": true }
  ],
  "conversation-key": "resource.id",
  "model": "claude-sonnet-4-5",
  "max-budget-usd": 5,
  "execute-prompt": "You are running an architecture fitness evaluation triggered by work item #{{workitem-id}} titled \"{{workitem-title}}\" in repository {{repository-name}}.\n\nParse the ARCH FITNESS config block (if present) from the work item description below. Run /arch-fitness --workitem {{workitem-id}} with the resolved scope (default: last 30 days of merged PRs).\n\nDiscover or bootstrap docs/architecture/ constraints, open a docs PR against the default branch when docs are created or updated, then evaluate the requested scope against those constraints in the same run. Post the fitness report as a comment on work item #{{workitem-id}} and add the arch-fitness-complete tag.\n\nWork item description:\n{{workitem-body}}"
}
```

> **Changing the tag.** `ai-dlc/arch/fitness` is just the string in the filter rule — change it if your team uses a different tag.

---

## Scenario — User `@xianix` comment on a work item

Lets a human ask for an evaluation ad hoc by mentioning `@xianix` in a work-item comment. On Azure DevOps, a new comment is delivered through the `workitem.commented` event, and its text lands in `System.History`.

```json
{
  "name": "azuredevops-architecture-fitness-comment-instruction",
  "platform": "azuredevops",
  "repository": {
    "url": "https://dev.azure.com/<org>/<project>/_git/<repo>",
    "ref": "main",
    "constant": true
  },
  "match-any": [
    {
      "name": "azuredevops-workitem-agent-instruction-requested",
      "rule": "eventType==workitem.commented&&resource.fields.System.History*='@xianix'"
    }
  ],
  "use-inputs": [
    { "name": "workitem-id",      "value": "resource.id", "mandatory": true },
    { "name": "workitem-title",   "value": "resource.fields.System.Title" },
    { "name": "workitem-body",    "value": "resource.fields.System.Description" },
    { "name": "user-instruction", "value": "resource.fields.System.History" }
  ],
  "use-plugins": [
    {
      "plugin-name": "arch-fitness@xianix-plugins-official",
      "marketplace": "xianix-team/plugins-official",
      "slash-command": "/arch-fitness"
    }
  ],
  "with-envs": [
    { "name": "AZURE-DEVOPS-TOKEN", "value": "secrets.AZURE-DEVOPS-TOKEN", "mandatory": true }
  ],
  "conversation-key": "resource.id",
  "model": "claude-sonnet-4-5",
  "max-budget-usd": 5,
  "execute-prompt": "You are @xianix. Someone mentioned @xianix in a comment on work item #{{workitem-id}} (\"{{workitem-title}}\") in repository {{repository-name}}. The comment: \"{{user-instruction}}\"\n\nFirst, decide whether this comment is actually addressed to you, versus just mentioning your name in passing. If it is NOT addressed to you, do nothing and post no reply.\n\nIf it IS addressed to you, treat the comment as the instruction for an architecture fitness run. Extract any scope from it (a PR id, a branch, or a merged-PR window like \"last 3 months\") and any Focus/Skip/Max-findings/Output hints; fall back to the ARCH FITNESS config block in the work item description when present. Run /arch-fitness --workitem {{workitem-id}} with the resolved scope.\n\nDiscover or bootstrap docs/architecture/ constraints, open a docs PR against the default branch when docs change, then evaluate the requested scope in the same run. You MUST post the fitness report back as a comment on work item #{{workitem-id}} using the Azure DevOps Work Item Comments REST API — your text output alone is not delivered to the user. A run that produces a report but never posts a comment is a failure.\n\nWork item description:\n{{workitem-body}}"
}
```

> **Why the \"is it addressed to me?\" preamble?** A bare substring match on `@xianix` also fires when someone mentions the agent in passing. The prompt makes the agent decide whether it is actually being asked to do something before it acts or replies.

---

## Notes

- **Filter order matters.** Within `match-any`, the first matching rule wins — order the more specific rules first.
- **Tag matching** uses the `*=` (contains) operator against `resource.fields.System.Tags`, which is a semicolon-delimited string.
- **`workitem.commented`** carries the new comment text in `resource.fields['System.History']`; older comments are not re-delivered.
- **`conversation-key`** on `resource.id` groups repeated events for one work item into a single conversation.
- **Token name hygiene:** the secret arrives as `AZURE-DEVOPS-TOKEN` (dashes); the plugin's provider scripts reference it with that exact name. See [`platform-setup.md`](./platform-setup.md#azure-devops).
- These blocks go inside the `executions` array of a rule set. See the [Rules Configuration](/agent-configuration/rules/) guide for the full file structure and filter syntax.
