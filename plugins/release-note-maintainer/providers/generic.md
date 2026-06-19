# Provider: Generic / Unknown Platform

Use this provider when `git remote get-url origin` does not contain `github.com`, `dev.azure.com`, or `visualstudio.com` — or when the repository has no git remote at all.

## Behaviour

There is no releases API or wiki to publish to. Instead, the generated release notes are written to `RELEASE_NOTES.md` at the repository root. This file is **completely overwritten on every run** — same full-replace semantics as the other providers, just targeting a file instead of an API.

---

## Writing `RELEASE_NOTES.md`

Write the full rendered release notes (from orchestrator step 7, `/tmp/release_notes.md`) to `RELEASE_NOTES.md` at the repository root, prefixed with a metadata header:

```markdown
<!-- Generated: <ISO 8601 timestamp> | Tag: <CURRENT_TAG> | Prev: <PREV_TAG> | Commits: <COMMIT_COUNT> -->

<full rendered release notes body from /tmp/release_notes.md>
```

```bash
{
  echo "<!-- Generated: $(date -u +%Y-%m-%dT%H:%M:%SZ) | Tag: ${CURRENT_TAG} | Prev: ${PREV_TAG:-none} | Commits: ${COMMIT_COUNT} -->"
  echo
  cat /tmp/release_notes.md
} > RELEASE_NOTES.md
```

This file is **not** committed or pushed by this agent — it is left in the working tree for whatever local or CI process invoked the agent to pick up.

---

## Output

On completion:

```
Release notes written to RELEASE_NOTES.md (no release API available for this remote)
```

---

## When to Use

This provider is the correct path for:

- Bitbucket, GitLab, Gitea, and other hosts without a dedicated provider in this plugin
- Self-hosted or on-premises git servers
- Local or offline runs where no remote API is available
- Any recognized platform where the wiki/release API is unavailable or returns an error
