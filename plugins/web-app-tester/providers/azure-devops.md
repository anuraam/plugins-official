# Provider: Azure DevOps

Use this provider when `git remote get-url origin` contains `dev.azure.com` or `visualstudio.com`.

## How This Fits with the Rest of the Plugin

- **Reading** — Use `curl` + `AZURE-DEVOPS-TOKEN` to fetch PR metadata, PR threads (comments), and work item details.
- **Posting** — Post the test execution report as a PR thread comment. For `wi` entry points, also post a notification comment on the work item.

Azure DevOps PR threads support markdown, so the report format is identical to the GitHub version.

## Prerequisites

Required environment variable:

| Variable | Purpose |
|---|---|
| `AZURE-DEVOPS-TOKEN` | Azure DevOps Personal Access Token (PAT) |

### Token Permissions

| Permission | Access | Why it's needed |
|---|---|---|
| **Work Items** | Read & Write | Fetch bug repro steps and linked PRs; post notification comment |
| **Code** | Read | Access PR metadata, threads, and linked work items |
| **Pull Requests** | Read & Write | Fetch PR description, comments; post test execution report as PR thread |

Optional overrides:

| Variable | Default |
|---|---|
| `AZURE_ORG` | Parsed from remote URL |
| `AZURE_PROJECT` | Parsed from remote URL |
| `AZURE_REPO` | Parsed from remote URL |

---

## Parsing the Remote URL

**HTTPS format:** `https://dev.azure.com/{org}/{project}/_git/{repo}`

```bash
REMOTE=$(git remote get-url origin)
AZURE_ORG=$(echo "$REMOTE"     | sed 's|https://dev.azure.com/||' | cut -d'/' -f1)
AZURE_PROJECT=$(echo "$REMOTE" | sed 's|https://dev.azure.com/||' | cut -d'/' -f2)
AZURE_REPO=$(echo "$REMOTE"    | sed 's|.*/_git/||' | sed 's|\.git$||')
```

**Legacy HTTPS format:** `https://{org}.visualstudio.com/{project}/_git/{repo}`

```bash
AZURE_ORG=$(echo "$REMOTE"     | sed 's|https://||' | cut -d'.' -f1)
AZURE_PROJECT=$(echo "$REMOTE" | cut -d'/' -f4)
AZURE_REPO=$(echo "$REMOTE"    | sed 's|.*/_git/||' | sed 's|\.git$||')
```

### API Base URL

```bash
if [[ "$REMOTE" =~ \.visualstudio\.com ]]; then
  API_BASE="https://${AZURE_ORG}.visualstudio.com/${AZURE_PROJECT}"
else
  API_BASE="https://dev.azure.com/${AZURE_ORG}/${AZURE_PROJECT}"
fi
```

---

## Entry Point: PR (`pr`)

### Fetching PR Details

```bash
curl -s -u ":${AZURE-DEVOPS-TOKEN}" \
  "${API_BASE}/_apis/git/repositories/${AZURE_REPO}/pullrequests/${PR_ID}?api-version=7.1"
```

Extracts: title, description, source/target branch, status, author, created date.

### Fetching PR Threads (Comments)

Used by `gather-test-context` to scan for testable URLs and existing test plans.

```bash
curl -s -u ":${AZURE-DEVOPS-TOKEN}" \
  "${API_BASE}/_apis/git/repositories/${AZURE_REPO}/pullrequests/${PR_ID}/threads?api-version=7.1"
```

Each thread has a `comments` array. Extract the `content` field from each comment. Concatenate all thread comment contents (in chronological order) for URL and test plan scanning.

### Discovering Linked Work Items from a PR

```bash
curl -s -u ":${AZURE-DEVOPS-TOKEN}" \
  "${API_BASE}/_apis/git/repositories/${AZURE_REPO}/pullrequests/${PR_ID}/workitems?api-version=7.1"
```

Returns a list of linked work item IDs. Fetch each work item to extract acceptance criteria or context:

```bash
curl -s -u ":${AZURE-DEVOPS-TOKEN}" \
  "${API_BASE}/_apis/wit/workitems/${WI_ID}?api-version=7.1&\$expand=all"
```

---

## Entry Point: Work Item (`wi`)

### Fetching Work Item Details

```bash
curl -s -u ":${AZURE-DEVOPS-TOKEN}" \
  "${API_BASE}/_apis/wit/workitems/${WORK_ITEM_ID}?api-version=7.1&\$expand=all"
```

**Auto-detect work item type** from `fields.System.WorkItemType`:

- `Bug` → extract `Microsoft.VSTS.TCM.ReproSteps` (repro steps), `Microsoft.VSTS.Common.RootCause` (root cause analysis), `System.Description`
- `Product Backlog Item`, `User Story`, `Feature` → extract `Microsoft.VSTS.Common.AcceptanceCriteria`, `System.Description`

Always extract: `System.Title`, `System.State`, `Microsoft.VSTS.Common.Severity`, `Microsoft.VSTS.Common.Priority`, `System.Tags`, `System.AssignedTo`.

The repro steps (Bug) or acceptance criteria (PBI/Feature) serve as the **primary source for test plan generation** in `gather-test-context`.

### Fetching Work Item Comments

```bash
curl -s -u ":${AZURE-DEVOPS-TOKEN}" \
  "${API_BASE}/_apis/wit/workitems/${WORK_ITEM_ID}/comments?api-version=7.1-preview.4"
```

Scan comments for testable URLs (same URL pattern as the rest of the plugin).

### Discovering Linked PRs from a Work Item

Fetch the work item with `$expand=relations` and parse the `relations` array for `ArtifactLink` entries whose `url` matches `vstfs:///Git/PullRequestId/...`:

```bash
curl -s -u ":${AZURE-DEVOPS-TOKEN}" \
  "${API_BASE}/_apis/wit/workitems/${WORK_ITEM_ID}?\$expand=relations&api-version=7.1"
```

Extract the PR ID from each matching relation URL (`vstfs:///Git/PullRequestId/<project-id>/<repo-id>/<pr-id>`). Then fetch each linked PR:

```bash
curl -s -u ":${AZURE-DEVOPS-TOKEN}" \
  "${API_BASE}/_apis/git/repositories/${AZURE_REPO}/pullrequests/${PR_ID}?api-version=7.1"
```

Also fetch each linked PR's threads to scan for deployment URLs:

```bash
curl -s -u ":${AZURE-DEVOPS-TOKEN}" \
  "${API_BASE}/_apis/git/repositories/${AZURE_REPO}/pullrequests/${PR_ID}/threads?api-version=7.1"
```

Store the first active (non-abandoned) linked PR ID as `LINKED_PR_ID` — it is used for posting the report.

---

## Posting the Starting Comment

Post a starting comment on the entry artefact immediately after platform detection so the author knows the web app test run has started and that it can take several minutes (Playwright install + browser session) to complete.

**PR entry — post on the PR thread:**

```bash
curl -s -u ":${AZURE-DEVOPS-TOKEN}" \
  -X POST \
  -H "Content-Type: application/json" \
  "${API_BASE}/_apis/git/repositories/${AZURE_REPO}/pullrequests/${PR_ID}/threads?api-version=7.1" \
  -d '{"comments":[{"content":"🤖 **Web app test in progress**\n\nInstalling Playwright if needed, launching a browser session, and executing the test plan against the deployed app. The full test execution report will be posted as a comment when complete — this may take a few minutes.","commentType":1}],"status":"active","properties":{"Microsoft.TeamFoundation.Discussion.SupportsMarkdown":1}}'
```

**Work item entry — post on the work item discussion:**

```bash
curl -s -u ":${AZURE-DEVOPS-TOKEN}" \
  -X POST \
  -H "Content-Type: application/json" \
  "${API_BASE}/_apis/wit/workitems/${WORK_ITEM_ID}/comments?format=markdown&api-version=7.1-preview.4" \
  -d '{"text":"🤖 **Web app test in progress**\n\nInstalling Playwright if needed, launching a browser session, and executing the test plan against the deployed app. The full test execution report will be posted as a comment when complete — this may take a few minutes."}'
```

**Verify mode (`MODE=verify`) — post the verification variant on the bug work item:**

```bash
curl -s -u ":${AZURE-DEVOPS-TOKEN}" \
  -X POST \
  -H "Content-Type: application/json" \
  "${API_BASE}/_apis/wit/workitems/${WORK_ITEM_ID}/comments?format=markdown&api-version=7.1-preview.4" \
  -d '{"text":"🤖 **Bug verification in progress**\n\nReplaying the repro steps against the deployed environment and running a decisive check against the expected result. A STILL REPRODUCIBLE / NOT REPRODUCIBLE / INCONCLUSIVE verdict will be posted here when complete — this may take a few minutes."}'
```

If posting the starting comment fails, output a single warning line and continue — do not stop the run.

---

## Posting the "No URL Found" Comment

**PR entry — post on the PR thread:**
```bash
curl -s -u ":${AZURE-DEVOPS-TOKEN}" \
  -X POST \
  -H "Content-Type: application/json" \
  "${API_BASE}/_apis/git/repositories/${AZURE_REPO}/pullrequests/${PR_ID}/threads?api-version=7.1" \
  -d '{"comments":[{"content":"🤖 web-app-tester could not run — no testable URL was found.\nAdd a comment with the URL (e.g. `Preview URL: https://...`) and re-trigger.","commentType":1}],"status":"active","properties":{"Microsoft.TeamFoundation.Discussion.SupportsMarkdown":1}}'
```

**Work item entry — post on the work item:**
```bash
curl -s -u ":${AZURE-DEVOPS-TOKEN}" \
  -X POST \
  -H "Content-Type: application/json" \
  "${API_BASE}/_apis/wit/workitems/${WORK_ITEM_ID}/comments?format=markdown&api-version=7.1-preview.4" \
  -d '{"text":"🤖 web-app-tester could not run — no testable URL was found.\nAdd a comment with the URL (e.g. `Preview URL: https://...`) on the linked PR and re-trigger."}'
```

---

## Posting the Auto-Generated Plan Comment

**PR entry:**
```bash
curl -s -u ":${AZURE-DEVOPS-TOKEN}" \
  -X POST \
  -H "Content-Type: application/json" \
  "${API_BASE}/_apis/git/repositories/${AZURE_REPO}/pullrequests/${PR_ID}/threads?api-version=7.1" \
  -d "$(python3 -c "
import json
body = '''🤖 web-app-tester — No test plan found. Auto-generated plan, executing now:

${AUTO_GENERATED_STEPS}'''
print(json.dumps({'comments':[{'content': body,'commentType':1}],'status':'active','properties':{'Microsoft.TeamFoundation.Discussion.SupportsMarkdown':1}}))
")"
```

**Work item entry with linked PR — post on the linked PR thread:**
```bash
# Use LINKED_PR_ID discovered from the work item relations
curl -s -u ":${AZURE-DEVOPS-TOKEN}" \
  -X POST \
  -H "Content-Type: application/json" \
  "${API_BASE}/_apis/git/repositories/${AZURE_REPO}/pullrequests/${LINKED_PR_ID}/threads?api-version=7.1" \
  -d "$(python3 -c "
import json
body = '''🤖 web-app-tester — No test plan found (derived from bug #${WORK_ITEM_ID} repro steps). Auto-generated plan, executing now:

${AUTO_GENERATED_STEPS}'''
print(json.dumps({'comments':[{'content': body,'commentType':1}],'status':'active','properties':{'Microsoft.TeamFoundation.Discussion.SupportsMarkdown':1}}))
")"
```

**Work item entry without linked PR — post directly on the work item:**
```bash
curl -s -u ":${AZURE-DEVOPS-TOKEN}" \
  -X POST \
  -H "Content-Type: application/json" \
  "${API_BASE}/_apis/wit/workitems/${WORK_ITEM_ID}/comments?format=markdown&api-version=7.1-preview.4" \
  -d "$(python3 -c "
import json
body = '''🤖 web-app-tester — No test plan found (derived from bug #${WORK_ITEM_ID} repro steps). Auto-generated plan, executing now:

${AUTO_GENERATED_STEPS}'''
print(json.dumps({'text': body}))
")"
```

---

## Posting the Test Execution Report

### PR entry — post on the PR thread

```bash
curl -s -u ":${AZURE-DEVOPS-TOKEN}" \
  -X POST \
  -H "Content-Type: application/json" \
  "${API_BASE}/_apis/git/repositories/${AZURE_REPO}/pullrequests/${PR_ID}/threads?api-version=7.1" \
  -d "$(python3 -c "
import json, sys
body = sys.stdin.read()
print(json.dumps({'comments':[{'content': body,'commentType':1}],'status':'active','properties':{'Microsoft.TeamFoundation.Discussion.SupportsMarkdown':1}}))
" <<'REPORT'
${REPORT_BODY}
REPORT
)"
```

### Work item entry with linked PR — post on the linked PR thread + notification on the work item

Use this path when `LINKED_PR_ID` is set.

**Step 1: Post full report on the linked PR thread**

```bash
curl -s -u ":${AZURE-DEVOPS-TOKEN}" \
  -X POST \
  -H "Content-Type: application/json" \
  "${API_BASE}/_apis/git/repositories/${AZURE_REPO}/pullrequests/${LINKED_PR_ID}/threads?api-version=7.1" \
  -d "$(python3 -c "
import json, sys
body = sys.stdin.read()
print(json.dumps({'comments':[{'content': body,'commentType':1}],'status':'active','properties':{'Microsoft.TeamFoundation.Discussion.SupportsMarkdown':1}}))
" <<'REPORT'
${REPORT_BODY}
REPORT
)"
```

**Step 2: Post notification comment on the work item**

```bash
curl -s -u ":${AZURE-DEVOPS-TOKEN}" \
  -X POST \
  -H "Content-Type: application/json" \
  "${API_BASE}/_apis/wit/workitems/${WORK_ITEM_ID}/comments?format=markdown&api-version=7.1-preview.4" \
  -d "$(python3 -c "
import json
body = '''## 🤖 Web App Test Executed

**Overall Result:** ${OVERALL_RESULT}
**Steps:** ${PASSED}/${TOTAL} passed | ❌ ${FAILED} failed | 🔴 ${BLOCKED} blocked
**URL Tested:** ${TEST_URL}

Full test execution report posted on PR #${LINKED_PR_ID}.'''
print(json.dumps({'text': body}))
")"
```

### Work item entry without linked PR — post full report directly on the work item

Use this path when `LINKED_PR_ID` is empty.

```bash
curl -s -u ":${AZURE-DEVOPS-TOKEN}" \
  -X POST \
  -H "Content-Type: application/json" \
  "${API_BASE}/_apis/wit/workitems/${WORK_ITEM_ID}/comments?format=markdown&api-version=7.1-preview.4" \
  -d "$(python3 -c "
import json, sys
body = sys.stdin.read()
print(json.dumps({'text': body}))
" <<'REPORT'
${REPORT_BODY}
REPORT
)"
```

---

## Uploading an Attachment (verify mode)

Used by `post-verdict-report` to attach the decisive screenshot (and any failure screenshots) as evidence on the bug.

```bash
curl -s -u ":${AZURE-DEVOPS-TOKEN}" \
  -X POST \
  -H "Content-Type: application/octet-stream" \
  --data-binary "@_wat_run/screenshots/decisive.png" \
  "${API_BASE}/_apis/wit/attachments?fileName=decisive.png&api-version=7.1"
```

The response contains the attachment `url`. Embed it in the markdown work item comment as:

```markdown
![decisive](<attachment url>)
```

---

## Posting the Verdict Comment (verify mode)

Post the rendered verdict template (see `styles/verdict-template.md`) as a markdown comment **on the bug work item** — the same comment API as the other work item posts:

```bash
curl -s -u ":${AZURE-DEVOPS-TOKEN}" \
  -X POST \
  -H "Content-Type: application/json" \
  "${API_BASE}/_apis/wit/workitems/${WORK_ITEM_ID}/comments?format=markdown&api-version=7.1-preview.4" \
  -d "$(python3 -c "
import json, sys
body = sys.stdin.read()
print(json.dumps({'text': body}))
" <<'VERDICT'
${VERDICT_BODY}
VERDICT
)"
```

No PR posting in verify mode — the verdict always lands on the bug itself.

---

## Updating Work Item State (interactive verify only)

Only after the user explicitly confirms the offered transition — never in autonomous mode. Target state names differ per process template (Agile: `Active`/`Resolved`; Scrum: `Committed`/`Done`; CMMI: `Active`/`Resolved`; custom templates vary) — the orchestrator must present the choice to the user, never guess.

```bash
curl -s -u ":${AZURE-DEVOPS-TOKEN}" \
  -X PATCH \
  -H "Content-Type: application/json-patch+json" \
  "${API_BASE}/_apis/wit/workitems/${WORK_ITEM_ID}?api-version=7.1" \
  -d '[{"op":"add","path":"/fields/System.State","value":"<state>"}]'
```

---

## Output

On completion:
```
MODE=test:   web-app-tester complete for {ENTRY_TYPE} #{ENTRY_ID}: {OVERALL_RESULT} — {PASSED}/{TOTAL} test cases passed
MODE=verify: verify-bug complete for {ENTRY_TYPE} #{ENTRY_ID}: {VERDICT}
```
