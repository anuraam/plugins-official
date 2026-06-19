# Provider: Generic / Unknown Platform

Use this provider when the git remote does not match GitHub or Azure DevOps — or as a fallback when no PR is found for the current branch on a recognized platform.

## Behaviour

There is no PR object to read or write. Instead, the generated description is written to a file at the repository root, which is **completely overwritten on every run** — the same full-replace semantics as the GitHub and Azure DevOps providers, just targeting a file instead of an API.

There is no "existing title/description" to read here (orchestrator step 2 is skipped for this provider), so `change-analyst`'s "Related Work" extraction relies solely on commit messages and branch name for this provider.

---

## Writing the Description File

Write the full rendered description (from orchestrator step 6, `/tmp/pr_description.md`) to:

```
pr-description.md
```

at the repository root, prefixed with a small header:

```markdown
<!--
Generated: <ISO 8601 timestamp>
Branch: <CURRENT_BRANCH>
Base: <BASE>
Commit: <HEAD_SHA>
-->

<full rendered description body from /tmp/pr_description.md>
```

```bash
{
  echo "<!--"
  echo "Generated: $(date -u +%Y-%m-%dT%H:%M:%SZ)"
  echo "Branch: ${CURRENT_BRANCH}"
  echo "Base: ${BASE}"
  echo "Commit: ${HEAD_SHA}"
  echo "-->"
  echo
  cat /tmp/pr_description.md
} > pr-description.md
```

This file is **not** committed or pushed by this agent — it is left in the working tree for whatever local/CI process invoked the agent to pick up.

---

## Output

On completion:

```
PR description written to pr-description.md (no PR API available for this remote)
```

---

## When to Use

This provider is the correct fallback for:

- Bitbucket and other hosts without a dedicated provider in this plugin
- Self-hosted GitLab instances
- Any on-premises git server
- Local or offline runs where no remote API is available
- A recognized platform (GitHub/Azure DevOps) where no open PR exists for the current branch
