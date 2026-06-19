# Provider: Azure DevOps

Use this provider when `git remote get-url origin` contains `dev.azure.com` or `visualstudio.com`.

## Prerequisites

The Azure DevOps REST API is called directly via `curl` using a Personal Access Token (PAT).

Required environment variable:

| Variable | Purpose |
|---|---|
| `AZURE-DEVOPS-TOKEN` | Azure DevOps PAT — must have the **`Pull Requests (Read & Write)`** scope |

> **Note on var-name hygiene:** the variable name must be `AZURE-DEVOPS-TOKEN` (underscores). Some upstream environments export `AZURE-DEVOPS-TOKEN` (hyphens) — bash cannot reference hyphenated names, and `curl -u ":${AZURE-DEVOPS-TOKEN}"` will silently send an empty password. The plugin's `PreToolUse` hook detects this case and blocks with a clear message; if you hit it, re-export with underscores.

Optional — used to override values parsed from the remote URL:

| Variable | Default |
|---|---|
| `AZURE_ORG` | Parsed from remote URL |
| `AZURE_PROJECT` | Parsed from remote URL |
| `AZURE_REPO` | Parsed from remote URL |

---

## Parsing the Remote URL

Extract org, project, and repo from the remote URL before making any API calls. Strip any embedded basic-auth (`user@`) component first — it appears in remotes injected by CI runners.

Azure DevOps uses **four** URL shapes in the wild. **All must be handled** — the legacy `DefaultCollection` form is common in tenants that migrated from on-prem TFS, and getting it wrong means the PATCH call 4xxs against the wrong project.

| # | Shape | Example |
|---|---|---|
| 1 | `dev.azure.com/{org}/{project}/_git/{repo}` | `https://dev.azure.com/contoso/Web/_git/api` |
| 2 | `dev.azure.com/{org}/{collection}/{project}/_git/{repo}` | rare — usually only seen on imported orgs |
| 3 | `{org}.visualstudio.com/{project}/_git/{repo}` | `https://contoso.visualstudio.com/Web/_git/api` |
| 4 | `{org}.visualstudio.com/{collection}/{project}/_git/{repo}` | `https://contoso.visualstudio.com/DefaultCollection/Web/_git/api` |

Use the parser below — it anchors on the `_git` segment (always exactly one position before the repo and one position after the project), so it works for all four shapes:

```bash
REMOTE=$(git remote get-url origin)

# Strip optional "user@" basic-auth prefix and any trailing .git
REMOTE_CLEAN=$(echo "$REMOTE" | sed -E 's|https?://[^@]+@|https://|; s|\.git$||')

# Extract host and the path-after-host
AZURE_HOST=$(echo "$REMOTE_CLEAN" | awk -F/ '{print $3}')
PATH_PARTS=$(echo "$REMOTE_CLEAN" | awk -F/ '{for (i=4; i<=NF; i++) print $i}')

# Anchor on the _git segment. project = segment immediately before, repo = immediately after.
GIT_LINE=$(echo "$PATH_PARTS" | grep -nx '_git' | head -1 | cut -d: -f1)
if [ -z "$GIT_LINE" ]; then
  echo "ERROR: not an Azure DevOps git URL (no _git segment): $REMOTE_CLEAN" >&2
  return 1 2>/dev/null || exit 1
fi
AZURE_PROJECT=$(echo "$PATH_PARTS" | sed -n "$((GIT_LINE - 1))p")
AZURE_REPO=$(echo    "$PATH_PARTS" | sed -n "$((GIT_LINE + 1))p")

# Determine org and the optional collection prefix (segments between org and project)
if [ "$AZURE_HOST" = "dev.azure.com" ]; then
  AZURE_ORG=$(echo "$PATH_PARTS" | sed -n '1p')
  PREFIX_START=2
else
  # *.visualstudio.com — org is the subdomain
  AZURE_ORG=$(echo "$AZURE_HOST" | cut -d'.' -f1)
  PREFIX_START=1
fi

PROJECT_LINE=$((GIT_LINE - 1))
# Collection exists iff there is ≥1 path segment between the org/host and the project.
if [ "$PROJECT_LINE" -gt "$PREFIX_START" ]; then
  AZURE_COLLECTION=$(echo "$PATH_PARTS" \
    | sed -n "${PREFIX_START},$((PROJECT_LINE - 1))p" \
    | tr '\n' '/' | sed 's|/$||')
else
  AZURE_COLLECTION=""
fi

# API_BASE always includes the project.
HOST_AND_ORG_PATH=$(
  if [ "$AZURE_HOST" = "dev.azure.com" ]; then
    echo "https://dev.azure.com/${AZURE_ORG}"
  else
    echo "https://${AZURE_HOST}"
  fi
)
if [ -n "$AZURE_COLLECTION" ]; then
  API_BASE="${HOST_AND_ORG_PATH}/${AZURE_COLLECTION}/${AZURE_PROJECT}"
else
  API_BASE="${HOST_AND_ORG_PATH}/${AZURE_PROJECT}"
fi

# Sanity-assert the parse — refuse to continue on garbage. Catches the historical bug where
# AZURE_PROJECT silently became "DefaultCollection".
case "$AZURE_PROJECT" in
  ""|"_git"|"DefaultCollection"|"https:")
    echo "ERROR: parsed AZURE_PROJECT='${AZURE_PROJECT}' looks wrong from URL: $REMOTE_CLEAN" >&2
    return 1 2>/dev/null || exit 1
    ;;
esac
[ -z "$AZURE_ORG" ] || [ -z "$AZURE_REPO" ] && {
  echo "ERROR: parsed AZURE_ORG='${AZURE_ORG}' AZURE_REPO='${AZURE_REPO}' from URL: $REMOTE_CLEAN" >&2
  return 1 2>/dev/null || exit 1
}

echo "Azure DevOps target: org=${AZURE_ORG} collection=${AZURE_COLLECTION:-<none>} project=${AZURE_PROJECT} repo=${AZURE_REPO}"
echo "API_BASE=${API_BASE}"

# Export so subsequent python heredocs can read them via os.environ
export AZURE_HOST AZURE_ORG AZURE_COLLECTION AZURE_PROJECT AZURE_REPO API_BASE
```

Use `${API_BASE}` in place of a hardcoded host for **every** API call below.

> **Why this matters:** prior versions used `cut -d'/' -f4` on the legacy URL, which returns `DefaultCollection` when the URL is `https://{org}.visualstudio.com/DefaultCollection/{project}/_git/{repo}`. The resulting `API_BASE` skipped the project segment and the PATCH 404s. The parser above anchors on `_git` so the project is always picked correctly.

---

## Posting Pattern (use this exact form for the PATCH call)

Two rules apply to every write call against the Azure DevOps API:

1. **Always send the body via `--data @file`**, never inline. Heredocs inside `curl -d "$(...)"` produce hard-to-debug quoting bugs.
2. **Always capture HTTP status** with `-w "\nHTTP_STATUS:%{http_code}\n"` and check it. A silent 401/404 is the #1 cause of "the call ran but the PR didn't change".

---

## Resolving the PR ID

If no PR ID was passed as an argument, find the active PR for the current branch.

In a detached-HEAD worktree, `git rev-parse --abbrev-ref HEAD` returns the literal string `HEAD`. Resolve the source branch from `git branch --contains` instead, or pass the branch name explicitly.

```bash
if [ "$(git rev-parse --abbrev-ref HEAD)" = "HEAD" ]; then
  BRANCH=$(git branch --contains "$(git rev-parse HEAD)" \
    | sed 's|^[* ] *||' | grep -v '^(' | head -1)
else
  BRANCH=$(git rev-parse --abbrev-ref HEAD)
fi

PR_ID=$(curl -sS -u ":${AZURE-DEVOPS-TOKEN}" \
  "${API_BASE}/_apis/git/repositories/${AZURE_REPO}/pullrequests?searchCriteria.sourceRefName=refs/heads/${BRANCH}&searchCriteria.status=active&api-version=7.1" \
  | python3 -c "import sys,json; prs=json.load(sys.stdin)['value']; print(prs[0]['pullRequestId'] if prs else '')")
export PR_ID
```

If empty, the branch has no open PR — fall back to the generic provider, there is nothing to edit.

---

## Fetching Current PR Metadata

The PR object is the source of truth for the **current** title, description, source/target branches, and author. **Read it before regenerating** — `change-analyst` needs the current title/description to extract "Related Work" references before they're overwritten.

```bash
PR_JSON=$(curl -sS -u ":${AZURE-DEVOPS-TOKEN}" \
  "${API_BASE}/_apis/git/repositories/${AZURE_REPO}/pullrequests/${PR_ID}?api-version=7.1")

PR_TITLE=$(echo       "$PR_JSON" | python3 -c "import sys,json; d=json.load(sys.stdin); print(d.get('title',''))")
PR_DESC=$(echo        "$PR_JSON" | python3 -c "import sys,json; d=json.load(sys.stdin); print(d.get('description',''))")
PR_SOURCE=$(echo      "$PR_JSON" | python3 -c "import sys,json; d=json.load(sys.stdin); print(d.get('sourceRefName','').replace('refs/heads/',''))")
PR_TARGET=$(echo      "$PR_JSON" | python3 -c "import sys,json; d=json.load(sys.stdin); print(d.get('targetRefName','').replace('refs/heads/',''))")
PR_AUTHOR=$(echo      "$PR_JSON" | python3 -c "import sys,json; d=json.load(sys.stdin); print(d.get('createdBy',{}).get('displayName',''))")

export PR_TITLE PR_DESC PR_SOURCE PR_TARGET PR_AUTHOR
```

Use `$PR_TARGET` as the **base branch** for diffs. Resolve it to a concrete SHA the same way orchestrator step 3 does — try `refs/remotes/origin/${PR_TARGET}` first, then fall back to `refs/heads/${PR_TARGET}` (worktrees may not have remote-tracking refs), then take `git merge-base` against `HEAD`.

---

## Replacing the PR Description

This is the agent's only write operation. It **fully replaces** the title and description fields in a single `PATCH` — Azure DevOps does not merge or append, the JSON body you send becomes the new value of each field outright.

```bash
# 1. Write the new title to a shell variable (from orchestrator step 6)
NEW_TITLE="<new title>"

# 2. Build the JSON payload from the rendered description file (use python so markdown is escaped correctly)
NEW_TITLE="$NEW_TITLE" python3 - <<'PY' > /tmp/pr_update_payload.json
import json, os
description = open('/tmp/pr_description.md').read()
print(json.dumps({
    "title": os.environ["NEW_TITLE"],
    "description": description,
}))
PY

# 3. PATCH and check status
RESP=$(curl -sS -w "\nHTTP_STATUS:%{http_code}" \
  -H "Content-Type: application/json" \
  -H "Authorization: Basic $(echo -n ":${AZURE-DEVOPS-TOKEN}" | base64 -w0)" \
  -X PATCH \
  --data @/tmp/pr_update_payload.json \
  "${API_BASE}/_apis/git/repositories/${AZURE_REPO}/pullrequests/${PR_ID}?api-version=7.1")

STATUS=$(echo "$RESP" | sed -n 's/^HTTP_STATUS://p')
if echo "$STATUS" | grep -qE '^2'; then
  echo "PR description replaced (HTTP $STATUS)"
else
  echo "ERROR: PATCH failed HTTP $STATUS — body: $(echo "$RESP" | sed '$d')" >&2
  exit 1
fi
```

> **Note on the `description` field's size limit:** Azure DevOps truncates PR descriptions at 4000 characters. If `/tmp/pr_description.md` exceeds this, trim the least-essential sections (e.g. shorten "What Changed" bullet detail) rather than truncating mid-sentence — a cut-off description looks broken.

If the PATCH fails, output a single error line and stop — do not retry, do not fall back to posting a comment thread.

---

## Output

On completion:

```
PR description replaced on PR #<id>: Azure DevOps — ${API_BASE}/_git/${AZURE_REPO}/pullrequest/<id>
```

If `STATUS` codes for the PATCH did not start with `2`, do not print this line — print the error line from "Replacing the PR Description" instead.
