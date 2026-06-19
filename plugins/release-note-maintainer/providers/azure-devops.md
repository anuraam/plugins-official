# Provider: Azure DevOps

Use this provider when `git remote get-url origin` contains `dev.azure.com` or `visualstudio.com`.

## Prerequisites

The Azure DevOps REST API is called directly via `curl` using a Personal Access Token (PAT).

Required environment variable:

| Variable | Purpose |
|---|---|
| `AZURE-DEVOPS-TOKEN` | Azure DevOps PAT — must have **`Pull Requests (Read)`** and **`Wiki (Read & Write)`** scopes |

> **Note on var-name hygiene:** the variable name must be `AZURE-DEVOPS-TOKEN` (underscores). Some upstream environments export `AZURE-DEVOPS-TOKEN` (hyphens) — bash cannot reference hyphenated names, and `curl -u ":${AZURE-DEVOPS-TOKEN}"` will silently send an empty password. The plugin's `PreToolUse` hook detects this and blocks with a clear message; if you hit it, re-export with underscores.

Optional — used to override values parsed from the remote URL:

| Variable | Default |
|---|---|
| `AZURE_ORG` | Parsed from remote URL |
| `AZURE_PROJECT` | Parsed from remote URL |
| `AZURE_REPO` | Parsed from remote URL |

---

## Parsing the Remote URL

Extract org, project, and repo before making any API calls. Strip any embedded basic-auth (`user@`) component first — it appears in remotes injected by CI runners.

Azure DevOps uses **four** URL shapes. **All must be handled** — the legacy `DefaultCollection` form is common on tenants migrated from on-prem TFS.

| # | Shape | Example |
|---|---|---|
| 1 | `dev.azure.com/{org}/{project}/_git/{repo}` | `https://dev.azure.com/contoso/Web/_git/api` |
| 2 | `dev.azure.com/{org}/{collection}/{project}/_git/{repo}` | rare |
| 3 | `{org}.visualstudio.com/{project}/_git/{repo}` | `https://contoso.visualstudio.com/Web/_git/api` |
| 4 | `{org}.visualstudio.com/{collection}/{project}/_git/{repo}` | `https://contoso.visualstudio.com/DefaultCollection/Web/_git/api` |

Use the parser below — it anchors on the `_git` segment:

```bash
REMOTE=$(git remote get-url origin)
REMOTE_CLEAN=$(echo "$REMOTE" | sed -E 's|https?://[^@]+@|https://|; s|\.git$||')

AZURE_HOST=$(echo "$REMOTE_CLEAN" | awk -F/ '{print $3}')
PATH_PARTS=$(echo "$REMOTE_CLEAN" | awk -F/ '{for (i=4; i<=NF; i++) print $i}')

GIT_LINE=$(echo "$PATH_PARTS" | grep -nx '_git' | head -1 | cut -d: -f1)
[ -z "$GIT_LINE" ] && { echo "ERROR: not an Azure DevOps git URL (no _git segment): $REMOTE_CLEAN" >&2; exit 1; }

AZURE_PROJECT=$(echo "$PATH_PARTS" | sed -n "$((GIT_LINE - 1))p")
AZURE_REPO=$(echo    "$PATH_PARTS" | sed -n "$((GIT_LINE + 1))p")

if [ "$AZURE_HOST" = "dev.azure.com" ]; then
  AZURE_ORG=$(echo "$PATH_PARTS" | sed -n '1p')
  PREFIX_START=2
else
  AZURE_ORG=$(echo "$AZURE_HOST" | cut -d'.' -f1)
  PREFIX_START=1
fi

PROJECT_LINE=$((GIT_LINE - 1))
if [ "$PROJECT_LINE" -gt "$PREFIX_START" ]; then
  AZURE_COLLECTION=$(echo "$PATH_PARTS" \
    | sed -n "${PREFIX_START},$((PROJECT_LINE - 1))p" \
    | tr '\n' '/' | sed 's|/$||')
else
  AZURE_COLLECTION=""
fi

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

case "$AZURE_PROJECT" in
  ""|"_git"|"DefaultCollection"|"https:")
    echo "ERROR: parsed AZURE_PROJECT='${AZURE_PROJECT}' looks wrong from URL: $REMOTE_CLEAN" >&2
    exit 1 ;;
esac

echo "Azure DevOps: org=${AZURE_ORG} project=${AZURE_PROJECT} repo=${AZURE_REPO}"
echo "API_BASE=${API_BASE}"
export AZURE_HOST AZURE_ORG AZURE_COLLECTION AZURE_PROJECT AZURE_REPO API_BASE
```

---

## Listing Completed Pull Requests (orchestrator step 4)

Query PRs completed in the release window, bounded by the timestamp of the previous tag:

```bash
START=$(git log -1 --format='%Y-%m-%dT%H:%M:%SZ' "${PREV_TAG}" 2>/dev/null \
  || echo "1970-01-01T00:00:00Z")

RESP=$(curl -sS -w "\nHTTP_STATUS:%{http_code}" \
  -H "Authorization: Basic $(echo -n ":${AZURE-DEVOPS-TOKEN}" | base64 -w0)" \
  "${API_BASE}/_apis/git/repositories/${AZURE_REPO}/pullrequests?searchCriteria.status=completed&searchCriteria.minTime=${START}&\$top=200&api-version=7.1")

STATUS=$(echo "$RESP" | sed -n 's/^HTTP_STATUS://p')
if echo "$STATUS" | grep -qE '^2'; then
  echo "$RESP" | sed '$d' | python3 -c \
    "import sys,json; prs=json.load(sys.stdin).get('value',[]); \
     print(json.dumps([{'number': p['pullRequestId'], 'title': p['title'], \
     'body': p.get('description',''), 'url': '', \
     'author': p.get('createdBy',{}).get('displayName','')} for p in prs]))" \
    > /tmp/release_prs.json
else
  echo "WARN: PR list returned HTTP $STATUS — falling back to empty list" >&2
  echo "[]" > /tmp/release_prs.json
fi

echo "PRs fetched: $(python3 -c 'import sys,json; print(len(json.load(sys.stdin)))' < /tmp/release_prs.json)"
```

---

## Publishing the Release Notes

Release notes are published as a **wiki page** at `/Release-Notes/${CURRENT_TAG}`. If the project has no wiki, the agent falls back to writing `RELEASE_NOTES.md` (see "Fallback" below).

### 1. Find the project wiki

```bash
WIKI_RESP=$(curl -sS -w "\nHTTP_STATUS:%{http_code}" \
  -H "Authorization: Basic $(echo -n ":${AZURE-DEVOPS-TOKEN}" | base64 -w0)" \
  "${API_BASE}/_apis/wiki/wikis?api-version=7.1")

WIKI_STATUS=$(echo "$WIKI_RESP" | sed -n 's/^HTTP_STATUS://p')
WIKI_ID=""

if echo "$WIKI_STATUS" | grep -qE '^2'; then
  # Prefer "projectWiki" type; fall back to first wiki found
  WIKI_ID=$(echo "$WIKI_RESP" | sed '$d' | python3 -c \
    "import sys,json; wikis=json.load(sys.stdin).get('value',[]); \
     proj=[w for w in wikis if w.get('type')=='projectWiki']; \
     print((proj or wikis)[0]['id'] if (proj or wikis) else '')" 2>/dev/null || echo "")
fi
```

### 2a. Publish to wiki (primary path)

```bash
if [ -n "$WIKI_ID" ]; then
  PAGE_PATH="/Release-Notes/${CURRENT_TAG}"

  python3 - <<'PY' > /tmp/wiki_payload.json
import json, os
content = open('/tmp/release_notes.md').read()
print(json.dumps({"content": content}))
PY

  WIKI_PUT_RESP=$(curl -sS -w "\nHTTP_STATUS:%{http_code}" \
    -H "Content-Type: application/json" \
    -H "Authorization: Basic $(echo -n ":${AZURE-DEVOPS-TOKEN}" | base64 -w0)" \
    -H "If-Match: *" \
    -X PUT \
    --data @/tmp/wiki_payload.json \
    "${API_BASE}/_apis/wiki/wikis/${WIKI_ID}/pages?path=${PAGE_PATH}&api-version=7.1")

  WIKI_PUT_STATUS=$(echo "$WIKI_PUT_RESP" | sed -n 's/^HTTP_STATUS://p')
  if echo "$WIKI_PUT_STATUS" | grep -qE '^2'; then
    echo "Release notes published to wiki page: ${PAGE_PATH} (HTTP ${WIKI_PUT_STATUS})"
    PUBLISHED_URL="${API_BASE}/_wiki/wikis/${WIKI_ID}?pagePath=${PAGE_PATH}"
  else
    echo "WARN: wiki PUT returned HTTP ${WIKI_PUT_STATUS} — falling back to RELEASE_NOTES.md" >&2
    WIKI_ID=""
  fi
fi
```

### 2b. Fallback — write `RELEASE_NOTES.md` if no wiki found or wiki PUT failed

```bash
if [ -z "$WIKI_ID" ]; then
  {
    echo "<!-- Generated: $(date -u +%Y-%m-%dT%H:%M:%SZ) | Tag: ${CURRENT_TAG} -->"
    echo
    cat /tmp/release_notes.md
  } > RELEASE_NOTES.md
  PUBLISHED_URL="RELEASE_NOTES.md (no project wiki found)"
fi
```

---

## Output

On completion:

```
Release notes published for <tag>: Azure DevOps — <PUBLISHED_URL>
```
