# Provider: Azure DevOps

Use this provider when `git remote get-url origin` contains `dev.azure.com` or `visualstudio.com`.

## Prerequisites

Call the Azure DevOps REST API with `curl` and a Personal Access Token. Do **not** require the `az` CLI.

| Variable | Purpose |
|---|---|
| `AZURE-DEVOPS-TOKEN` | PAT with Code (Read & Write), Work Items (Read & Write), Pull Request Threads (Read & Write) |

Optional overrides: `AZURE_ORG`, `AZURE_PROJECT`, `AZURE_REPO`.

---

## Parsing the remote URL

**Modern:** `https://dev.azure.com/{org}/{project}/_git/{repo}`

```bash
REMOTE=$(git remote get-url origin)
AZURE_ORG=$(echo   "$REMOTE" | sed 's|https://dev.azure.com/||' | cut -d'/' -f1)
AZURE_PROJECT=$(echo "$REMOTE" | sed 's|https://dev.azure.com/||' | cut -d'/' -f2)
AZURE_REPO=$(echo  "$REMOTE" | sed 's|.*/_git/||' | sed 's|\.git$||')
```

**Legacy:** `https://{org}.visualstudio.com/{project}/_git/{repo}`

```bash
AZURE_ORG=$(echo   "$REMOTE" | sed 's|https://||' | cut -d'.' -f1)
AZURE_PROJECT=$(echo "$REMOTE" | cut -d'/' -f4)
AZURE_REPO=$(echo  "$REMOTE" | sed 's|.*/_git/||' | sed 's|\.git$||')
```

```bash
if [[ "$REMOTE" =~ \.visualstudio\.com ]]; then
  API_BASE="https://${AZURE_ORG}.visualstudio.com/${AZURE_PROJECT}"
else
  API_BASE="https://dev.azure.com/${AZURE_ORG}/${AZURE_PROJECT}"
fi
```

---

## Reading the trigger work item

```bash
curl -s -u ":${AZURE-DEVOPS-TOKEN}" \
  "${API_BASE}/_apis/wit/workitems/${WORKITEM_ID}?\$expand=fields&api-version=7.1" \
  | python3 -c "
import sys, json, re, html
wi = json.load(sys.stdin)
desc = wi['fields'].get('System.Description', '') or ''
# Strip simple HTML tags for config parsing
text = re.sub(r'<[^>]+>', '\n', desc)
text = html.unescape(text)
print(json.dumps({
  'id': wi['id'],
  'title': wi['fields']['System.Title'],
  'description': text,
  'tags': wi['fields'].get('System.Tags', '')
}))"
```

Parse the optional `ARCH FITNESS — START` … `ARCH FITNESS — END` block from the stripped description. CLI flags override body values.

---

## Posting the progress comment

```bash
BODY=$(python3 -c "
import json, os
text = '''## Architecture fitness in progress

Evaluating architecture constraints against the requested scope. A fitness report will be posted here when complete.

**Run plan**
- Scope: {scope}
- Docs mode: {docs_mode}
- Focus areas: {focus}
- Skip areas: {skip}
- Max findings: {max_findings}
- Default branch: \`{branch}\`
'''.format(
  scope=os.environ['SCOPE_RESOLVED'],
  docs_mode=os.environ['DOCS_MODE'],
  focus=os.environ.get('FOCUS_RESOLVED', 'none'),
  skip=os.environ.get('SKIP_RESOLVED', 'none'),
  max_findings=os.environ['MAX_FINDINGS'],
  branch=os.environ['DEFAULT_BRANCH'],
)
print(json.dumps({'text': text}))
")

curl -s -u ":${AZURE-DEVOPS-TOKEN}" \
  -X POST \
  -H "Content-Type: application/json" \
  "${API_BASE}/_apis/wit/workitems/${WORKITEM_ID}/comments?format=markdown&api-version=7.1-preview.4" \
  -d "${BODY}"
```

If posting fails, warn once and continue.

---

## Assembling changeset scopes

### Single PR

```bash
curl -s -u ":${AZURE-DEVOPS-TOKEN}" \
  "${API_BASE}/_apis/git/repositories/${AZURE_REPO}/pullrequests/${PR_ID}?api-version=7.1" \
  > /tmp/arch-fitness-pr.json

# Changed files / iterations
curl -s -u ":${AZURE-DEVOPS-TOKEN}" \
  "${API_BASE}/_apis/git/repositories/${AZURE_REPO}/pullrequests/${PR_ID}/iterations?api-version=7.1" \
  > /tmp/arch-fitness-pr-iterations.json

# Prefer git diff against the PR's source/target refs when available locally
SOURCE_REF=$(python3 -c "import json; print(json.load(open('/tmp/arch-fitness-pr.json'))['sourceRefName'].replace('refs/heads/',''))")
TARGET_REF=$(python3 -c "import json; print(json.load(open('/tmp/arch-fitness-pr.json'))['targetRefName'].replace('refs/heads/',''))")
git fetch origin "${SOURCE_REF}" "${TARGET_REF}"
git diff "origin/${TARGET_REF}...origin/${SOURCE_REF}" > /tmp/arch-fitness-pr.diff
```

### Branch vs default

```bash
git fetch origin "${DEFAULT_BRANCH}" "${BRANCH_NAME}"
git diff --name-status "origin/${DEFAULT_BRANCH}...origin/${BRANCH_NAME}"
git diff "origin/${DEFAULT_BRANCH}...origin/${BRANCH_NAME}" > /tmp/arch-fitness-branch.diff
```

### Merged PR window

Azure DevOps completed PRs (merged):

```bash
# minTime / maxTime are ISO-8601; status=3 means completed
curl -s -u ":${AZURE-DEVOPS-TOKEN}" \
  "${API_BASE}/_apis/git/repositories/${AZURE_REPO}/pullrequests?searchCriteria.status=3&searchCriteria.minTime=${START}T00:00:00Z&searchCriteria.maxTime=${END}T23:59:59Z&\$top=200&api-version=7.1" \
  > /tmp/arch-fitness-merged-prs.json
```

Filter client-side to PRs whose `closedDate` falls in the window and whose `mergeStatus` / completion indicates a merge (not abandoned). For each relevant PR, compute the source/target diff via git as above.

---

## Opening / updating the docs PR

After pushing `DOCS_BRANCH`:

### Look up existing PR by source branch

```bash
EXISTING=$(curl -s -u ":${AZURE-DEVOPS-TOKEN}" \
  "${API_BASE}/_apis/git/repositories/${AZURE_REPO}/pullrequests?searchCriteria.sourceRefName=refs/heads/${DOCS_BRANCH}&searchCriteria.status=active&api-version=7.1" \
  | python3 -c "import sys,json; d=json.load(sys.stdin); v=d.get('value') or []; print(v[0]['url'] if v else '')")
```

If non-empty, reuse it (`DOCS_PR_URL="${EXISTING}"`).

### Create new PR

```bash
PAYLOAD=$(python3 -c "
import json, os
body = '''## Summary

{summary}

New and changed constraints are marked \`status: proposed\` and need human ratification before they are treated as project policy.

## Constraint changes

{changes}

## Related

AB#{wi}

---
Generated by the \`arch-fitness\` plugin.
'''.format(
  summary=os.environ['DOCS_SUMMARY'],
  changes=os.environ['CONSTRAINT_CHANGE_LIST'],
  wi=os.environ.get('WORKITEM_ID', ''),
)
print(json.dumps({
  'sourceRefName': 'refs/heads/' + os.environ['DOCS_BRANCH'],
  'targetRefName': 'refs/heads/' + os.environ['DEFAULT_BRANCH'],
  'title': 'docs(architecture): ' + os.environ['DOCS_ACTION'] + ' architecture constraints',
  'description': body,
}))
")

curl -s -u ":${AZURE-DEVOPS-TOKEN}" \
  -X POST \
  -H "Content-Type: application/json" \
  "${API_BASE}/_apis/git/repositories/${AZURE_REPO}/pullrequests?api-version=7.1" \
  -d "${PAYLOAD}" \
  | python3 -c "import sys,json; print(json.load(sys.stdin).get('url',''))"
```

Omit the `AB#` line when there is no work-item attachment. Capture the URL as `DOCS_PR_URL`.

---

## Posting the fitness report comment

Write the rendered markdown to `/tmp/arch-fitness-report.md`, then:

```bash
BODY=$(python3 -c "
import json
text = open('/tmp/arch-fitness-report.md').read()
print(json.dumps({'text': text}))
")

curl -s -u ":${AZURE-DEVOPS-TOKEN}" \
  -X POST \
  -H "Content-Type: application/json" \
  "${API_BASE}/_apis/wit/workitems/${WORKITEM_ID}/comments?format=markdown&api-version=7.1-preview.4" \
  -d "${BODY}"
```

Add the completion tag:

```bash
# Read current tags, append arch-fitness-complete if missing, PATCH
CURRENT_TAGS=$(curl -s -u ":${AZURE-DEVOPS-TOKEN}" \
  "${API_BASE}/_apis/wit/workitems/${WORKITEM_ID}?api-version=7.1" \
  | python3 -c "import sys,json; print(json.load(sys.stdin)['fields'].get('System.Tags',''))")

NEW_TAGS=$(python3 -c "
tags = '''${CURRENT_TAGS}'''
parts = [t.strip() for t in tags.split(';') if t.strip()]
if 'arch-fitness-complete' not in parts:
  parts.append('arch-fitness-complete')
print('; '.join(parts))
")

curl -s -u ":${AZURE-DEVOPS-TOKEN}" \
  -X PATCH \
  -H "Content-Type: application/json-patch+json" \
  "${API_BASE}/_apis/wit/workitems/${WORKITEM_ID}?api-version=7.1" \
  -d "[{\"op\":\"add\",\"path\":\"/fields/System.Tags\",\"value\":\"${NEW_TAGS}\"}]"
```

---

## Chat mode (no work item)

Do not post comments. Print the fitness report to the conversation. Include any docs PR URL in the printed report.
