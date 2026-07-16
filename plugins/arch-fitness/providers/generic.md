# Provider: Generic / Plain Git

Use this provider when the git remote does not match GitHub or Azure DevOps, or when API posting is otherwise unavailable.

## Behaviour

- No issue / work-item fetch
- No platform comments
- Docs branch may still be created and pushed when credentials allow
- Fitness output is always written to a local file

---

## Input

Scope comes only from command arguments:

```
/arch-fitness [scope] [--since <date>] [--docs-only | --evaluate-only] [--max-findings <n>]
```

There is no task body config block. If no scope is given:

- Current branch ≠ default → evaluate current branch vs default
- On default branch → evaluate last 30 days of commits (`git log --since`) rather than merged PRs (PR listing APIs are unavailable)

Detect the default branch:

```bash
DEFAULT_BRANCH=$(git symbolic-ref refs/remotes/origin/HEAD 2>/dev/null | sed 's|refs/remotes/origin/||')
DEFAULT_BRANCH=${DEFAULT_BRANCH:-main}
```

---

## Assembling changeset scopes

### Branch / current working tree

```bash
git fetch origin "${DEFAULT_BRANCH}" 2>/dev/null || true
git diff --name-status "origin/${DEFAULT_BRANCH}...HEAD"
git diff "origin/${DEFAULT_BRANCH}...HEAD" > /tmp/arch-fitness-branch.diff
```

### Date window (commits, not PRs)

```bash
git log --since="${START}" --until="${END:-now}" --name-status --pretty=format:'COMMIT %H %ad %s' --date=short \
  > /tmp/arch-fitness-commits.txt
```

Deep-read the highest-signal files from that log when evaluating constraints.

---

## Docs branch + manual PR instructions

When `arch-doc-curator` produces doc changes:

1. Create / reuse branch `arch/docs-<date>-<slug>` from the default branch.
2. Commit and attempt `git push -u origin "${DOCS_BRANCH}"`.
3. If push succeeds, write `arch-docs-pr-body.md` in the repository root with title, summary, and constraint change list so a human can open the PR on their host.
4. If push fails (no credentials / unsupported host), leave the branch local and write the same body file plus a note that the branch was not pushed.

Set `DOCS_PR_URL=` (empty) in the curator handoff; the fitness report should link to `arch-docs-pr-body.md` instead.

---

## Output files

| File | When |
|---|---|
| `arch-fitness-report.md` | Always — full fitness report from `styles/fitness-report.md` |
| `arch-docs-pr-body.md` | When docs were created/updated |
| Path from `Output: file <path>` | When explicitly requested (also keep `arch-fitness-report.md` unless the path is that file) |
| JSON to stdout / file | When `Output: json` |

Never attempt `gh` or Azure DevOps REST calls in generic mode.

---

## Completion message

```
Architecture fitness complete: verdict=<FIT|DRIFTING|AT RISK> findings=<n> report=arch-fitness-report.md
```
