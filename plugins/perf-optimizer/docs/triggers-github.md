# Automated Triggering — GitHub

This guide shows how to make the **Xianix Agent** run the Performance Optimizer plugin automatically on GitHub, driven by webhook events. The example below is an **execution block** you add to the `executions` array of your `rules.json`.

For manual/interactive use (`/perf-optimize` in a chat), see the main [README](../README.md). For token setup and scopes, see [`platform-setup.md`](./platform-setup.md#github).

---

## How GitHub triggering works

The Performance Optimizer is **label-driven** on GitHub: apply the `ai-dlc/perf/optimize` label to an issue and the agent runs a whole-codebase review, opens a PR against the default branch, and links it back to the issue.

| Scenario | Webhook event | Filter rule |
|---|---|---|
| Label applied to an existing issue | `issues` `action==labeled` | `label.name=='ai-dlc/perf/optimize'` |
| Issue created **with** the label already on it | `issues` `action==labeled` (fired by GitHub after `opened`) | `label.name=='ai-dlc/perf/optimize'` |

> **Why not also match `action==opened`?** GitHub fires both `issues.opened` **and** a separate `issues.labeled` event when an issue is created with labels already attached. Matching both would spawn **two** concurrent containers for the same issue, which then race on `git push` and PR creation. Matching only `labeled` covers "created with label" and "label added later" with a single container — this is intentional, not an oversight.

---

## Execution-block shape

Every execution block shares this top-level shape:

| Field | Purpose |
|---|---|
| `name` | Human-readable id for the execution |
| `platform` | `"github"` — drives which provider the plugin uses |
| `repository.url` / `repository.ref` | Webhook paths to the repository clone URL and default branch — analysis runs against the default branch, not a PR head |
| `match-any` | Array of trigger filters — the first one to match fires the execution |
| `use-inputs` | The values the prompt needs — issue number, title, body, repository name, default branch |
| `use-plugins` | The plugin to invoke |
| `with-envs` | Required environment variables, sourced from the agent's `secrets.*` store |
| `execute-prompt` | The prompt sent to the agent, with the run's scope/target parsing and PR/branch contract spelled out |

The `GITHUB-TOKEN` secret is injected via `with-envs` and authenticates `gh` for reading the issue, pushing the new branch, and opening/commenting on the PR. See [`platform-setup.md`](./platform-setup.md#github) for the exact permissions.

---

## GitHub Rule

```json
{
  "name": "github-performance-optimizer",
  "platform": "github",
  "repository": {
    "url": "repository.clone_url",
    "ref": "repository.default_branch"
  },
  "match-any": [
    {
      "name": "github-issue-label-applied",
      "rule": "action==labeled&&label.name=='ai-dlc/perf/optimize'"
    }
  ],
  "use-inputs": [
    { "name": "issue-number",    "value": "issue.number" },
    { "name": "issue-title",     "value": "issue.title" },
    { "name": "issue-body",      "value": "issue.body" },
    { "name": "repository-name", "value": "repository.full_name" },
    { "name": "default-branch",  "value": "repository.default_branch" }
  ],
  "use-plugins": [
    {
      "plugin-name": "perf-optimizer@xianix-plugins-official",
      "marketplace": "xianix-team/plugins-official"
    }
  ],
  "with-envs": [
    {
      "name": "GITHUB-TOKEN",
      "value": "secrets.GITHUB-TOKEN",
      "mandatory": true
    }
  ],
  "execute-prompt": "You are running a whole-codebase performance review for repository {{repository-name}} triggered by issue #{{issue-number}} titled \"{{issue-title}}\".\n\nFetch the default branch ({{default-branch}}), parse any `Scope:` / `Target:` hints from the issue body below, and run /perf-optimize across the selected scope (default: entire codebase).\n\nApply only low-risk optimizations on a new branch named `perf/issue-{{issue-number}}-<slug>` and open a pull request against {{default-branch}}. The PR body MUST embed the full performance report and include `Closes #{{issue-number}}`. After opening the PR, post a comment on issue #{{issue-number}} linking to it.\n\nIssue body:\n{{issue-body}}"
}
```

> **Required secret:** Store a GitHub PAT (`repo` + `workflow` scopes) or an equivalent GitHub App token in the agent's secret store under the key `GITHUB-TOKEN`. The rule exposes it inside the container as the env var `GITHUB-TOKEN`, which `validate-prerequisites.sh` consumes for both `gh` calls and `git push` over HTTPS.

---

## Notes

- **Filter order matters.** Within `match-any`, the first matching rule wins — order the more specific rules first.
- **`repository.ref` is the analysis baseline**, not a PR head — the run always checks out the default branch fresh before analyzing.
- **One user action → one container.** The rule deliberately matches only `action==labeled`. Do **not** add a second clause for `action==opened` — see the note above.
- These blocks go inside the `executions` array of a rule set. See the [Rules Configuration](/agent-configuration/rules/) guide for the full file structure and filter syntax.
- Want the agent to run without waiting for a label at all? See [`triggers-schedule.md`](./triggers-schedule.md) for a `cron`-driven rule set.
