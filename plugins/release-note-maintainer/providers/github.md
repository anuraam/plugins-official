# Provider: GitHub

Use this provider when `git remote get-url origin` contains `github.com`.

## How this fits with the rest of the plugin

- **Reading / analysis** — Use **git** for commit history, tag resolution, and file structure. Use **`gh`** to list merged PRs in the release window.
- **Publishing** — Use **`gh release`** to create or update the GitHub Release for the current tag. This is the agent's only write operation.

## Prerequisites

- **GitHub CLI** (`gh`) installed: [https://cli.github.com](https://cli.github.com)
- Authenticated: `gh auth login`, or non-interactive `GH_TOKEN` / `GITHUB-TOKEN`

**Token scopes:** `repo` (private repos) or `public_repo` (public only) — required both to list merged PRs and to create/edit releases.

The plugin does **not** use the GitHub MCP server.

---

## Parsing Owner and Repo

```bash
REMOTE=$(git remote get-url origin)
OWNER=$(echo "$REMOTE" | sed 's|https://github.com/||;s|git@github.com:||' | cut -d'/' -f1)
REPO=$(echo "$REMOTE"  | sed 's|https://github.com/||;s|git@github.com:||' | cut -d'/' -f2 | sed 's|\.git$||')
```

---

## Listing Completed Pull Requests (orchestrator step 4)

Fetch all PRs merged in the release window using the tag timestamps as date bounds:

```bash
START=$(git log -1 --format='%aI' "${PREV_TAG}" 2>/dev/null || echo "1970-01-01T00:00:00Z")
END=$(git log -1 --format='%aI' "${CURRENT_TAG}")

gh pr list --state merged \
  --search "merged:${START%T*}..${END%T*}" \
  --json number,title,body,labels,author,url --limit 200 \
  > /tmp/release_prs.json

echo "PRs fetched: $(python3 -c 'import sys,json; print(len(json.load(sys.stdin)))' < /tmp/release_prs.json)"
```

If the date range yields zero PRs (e.g. a repo that doesn't use PRs), `/tmp/release_prs.json` is `[]` — `release-analyst` falls back to commit messages alone.

---

## Publishing the Release Notes

### 1. Check whether a release already exists for this tag

```bash
if gh release view "${CURRENT_TAG}" --json tagName --jq '.tagName' > /dev/null 2>&1; then
  RELEASE_EXISTS=true
else
  RELEASE_EXISTS=false
fi
```

### 2. Set the release title

```bash
RELEASE_TITLE="Release ${CURRENT_TAG}"
```

The knowledge profile's "Release Note Style Notes" may specify a different title format — follow it if present.

### 3. Prerelease flag

```bash
PRERELEASE_FLAG=""
[ "${IS_PRERELEASE}" = "true" ] && PRERELEASE_FLAG="--prerelease"
```

### 4. Create or edit the release

```bash
if [ "$RELEASE_EXISTS" = "true" ]; then
  gh release edit "${CURRENT_TAG}" \
    --title "${RELEASE_TITLE}" \
    --notes-file /tmp/release_notes.md \
    ${PRERELEASE_FLAG}
else
  gh release create "${CURRENT_TAG}" \
    --title "${RELEASE_TITLE}" \
    --notes-file /tmp/release_notes.md \
    ${PRERELEASE_FLAG}
fi
```

If this command fails, output a single error line and stop — do not fall back to posting a comment.

---

## Output

On completion:

```
Release notes published for <tag>: GitHub — https://github.com/<owner>/<repo>/releases/tag/<tag>
```
