# Automated Triggering — Azure DevOps

This guide shows how to make the **Xianix Agent** run the Performance Optimizer plugin automatically on Azure DevOps, driven by service-hook events. The example below is an **execution block** you add to the `executions` array of your `rules.json`.

For manual/interactive use (`/perf-optimize` in a chat), see the main [README](../README.md). For token setup and scopes, see [`platform-setup.md`](./platform-setup.md#azure-devops).

---

## How Azure DevOps triggering works

The Performance Optimizer is **tag-driven** on Azure DevOps: add the `ai-dlc/perf/optimize` tag to a work item and the agent runs a whole-codebase review, opens a PR against the default branch, and links it back to the work item.

| Scenario | Event type | Filter rule |
|---|---|---|
| Tag added to an existing work item | `workitem.updated` | `resource.fields['System.Tags']` contains `ai-dlc/perf/optimize` |
| Work item created **with** the tag | `workitem.updated` (fired after `workitem.created`) | `resource.fields['System.Tags']` contains `ai-dlc/perf/optimize` |

> **Why not also match `workitem.created`?** Azure DevOps fires `workitem.created` followed by a separate `workitem.updated` when a work item is created with tags already attached. Matching both would spawn **two** concurrent containers for the same work item, which then race on `git push` and PR creation. Matching only `workitem.updated` covers "created with tag" and "tag added later" with a single container — this is intentional, not an oversight.

---

## Execution-block shape

Every execution block shares this top-level shape:

| Field | Purpose |
|---|---|
| `name` | Human-readable id for the execution |
| `platform` | `"azuredevops"` — drives which provider the plugin uses |
| `repository.url` / `repository.ref` | **Constants** on the rule, not read from the event payload — work items are project-scoped, not repo-scoped, so the target repository and default branch must be declared explicitly |
| `match-any` | Array of trigger filters — the first one to match fires the execution |
| `use-inputs` | The values the prompt needs — work-item id, title, body, repository name, default branch |
| `use-plugins` | The plugin to invoke |
| `with-envs` | Required environment variables, sourced from the agent's `secrets.*` store |
| `execute-prompt` | The prompt sent to the agent, with the run's scope/target parsing and PR/branch contract spelled out |

The `AZURE-DEVOPS-TOKEN` secret is injected via `with-envs` and authenticates the REST API calls used to read the work item, open the pull request, and post the link-back comment; it also covers the `git push` for the new branch. See [`platform-setup.md`](./platform-setup.md#azure-devops) for the exact PAT scopes.

---

## Azure DevOps Rule

Deploy one rule per repository you want to cover.

```json
{
  "name": "azuredevops-performance-optimizer",
  "platform": "azuredevops",
  "repository": {
    "url": "https://dev.azure.com/<org>/<project>/_git/<repo>",
    "ref": "main",
    "constant": true
  },
  "match-any": [
    {
      "name": "azuredevops-workitem-tagged",
      "rule": "eventType==workitem.updated&&resource.fields.System.Tags*='ai-dlc/perf/optimize'"
    }
  ],
  "use-inputs": [
    { "name": "workitem-id",     "value": "resource.id" },
    { "name": "workitem-title",  "value": "resource.fields.System.Title" },
    { "name": "workitem-body",   "value": "resource.fields.System.Description" },
    { "name": "repository-name", "value": "<org>/<project>/<repo>", "constant": true },
    { "name": "default-branch",  "value": "main", "constant": true }
  ],
  "use-plugins": [
    {
      "plugin-name": "perf-optimizer@xianix-plugins-official",
      "marketplace": "xianix-team/plugins-official"
    }
  ],
  "with-envs": [
    {
      "name": "AZURE-DEVOPS-TOKEN",
      "value": "secrets.AZURE-DEVOPS-TOKEN",
      "mandatory": true
    }
  ],
  "execute-prompt": "You are running a whole-codebase performance review for repository {{repository-name}} triggered by work item #{{workitem-id}} titled \"{{workitem-title}}\".\n\nFetch the default branch ({{default-branch}}), parse any `Scope:` / `Target:` hints from the work item description below, and run /perf-optimize across the selected scope (default: entire codebase).\n\nApply only low-risk optimizations on a new branch named `perf/workitem-{{workitem-id}}-<slug>` and open a pull request against {{default-branch}}. The PR body MUST embed the full performance report and reference work item #{{workitem-id}}. After opening the PR, post a comment on the work item linking to it.\n\nWork item description:\n{{workitem-body}}"
}
```

> **Placeholders.** Replace the `<org>`, `<project>`, and `<repo>` placeholders in both `repository.url` and the `repository-name` input with your actual values. Change `ref` from `main` if your default branch is different.
>
> **Required secret:** Store an Azure DevOps PAT (`Work Items: Read & Write`, `Code: Read, Write & Manage`) in the agent's secret store under the key `AZURE-DEVOPS-TOKEN`. The rule exposes it inside the container as the env var `AZURE-DEVOPS-TOKEN`, consumed by both `curl` REST calls and `git push` to `dev.azure.com` / `visualstudio.com`.

---

## Notes

- **Filter order matters.** Within `match-any`, the first matching rule wins — order the more specific rules first.
- **`repository.ref` is the analysis baseline**, not a PR head — the run always checks out the default branch fresh before analyzing.
- **One user action → one container.** The rule deliberately matches only `eventType==workitem.updated`. Do **not** add a second clause for `eventType==workitem.created` — see the note above.
- **`with-envs` is rule-level, not plugin-level** — declared once per rule and applied to every plugin the rule runs. `mandatory: true` makes the runtime fail-fast before the container starts if the secret is missing.
- These blocks go inside the `executions` array of a rule set. See the [Rules Configuration](/agent-configuration/rules/) guide for the full file structure and filter syntax.
- Want the agent to run without waiting for a tag at all? See [`triggers-schedule.md`](./triggers-schedule.md) for a `cron`-driven rule set.
