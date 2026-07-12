---
name: pr-review
description: Run a full PR review. Analyzes code quality, security, tests, and performance. Works with GitHub, Azure DevOps, Bitbucket, and any git repository. Usage: /pr-review [PR number, branch name, or leave blank for current branch]
argument-hint: [pr-number | branch-name]
---

Run a comprehensive pull request review for $ARGUMENTS.

## You are the review lead — run this yourself, do NOT delegate to an orchestrator sub-agent

**Critical execution rule (read first).** You, the top-level agent, perform the orchestration described below directly. The specialized reviews (`code-reviewer`, and whichever of `security-reviewer`, `test-reviewer`, `performance-reviewer` apply per the step 5 gate) are run by spawning those sub-agents **from here, in the main context**.

Do **not** spawn a separate `orchestrator` / "PR review" sub-agent and ask *it* to run the reviewers. A sub-agent cannot spawn further sub-agents — in the Claude Agent SDK that fails with `No such tool available: Task. Task is not available inside subagents`, the parallel review silently degrades, and the report never gets posted. The fan-out in **Step 6** only works when it is emitted from the top-level agent, which is you.

Execute every step below autonomously and in order. Do not ask for confirmation, clarification, or approval at any point. If a step fails, output a single error line describing what failed and stop — except where a step explicitly says "warn and continue".

**Fix mode vs report mode:** if the invocation includes a `--fix` flag or the instruction explicitly says to fix issues, apply fixes and push (see *Applying Fixes*). Otherwise, compile and post the review report only.

**Re-review awareness (first review vs. follow-up review).** Before reviewing, the command checks whether *this plugin* has already reviewed the PR (it stamps every comment it posts with a hidden marker — see *Comment markers* below). If a prior review is found, the run switches to **re-review mode**: it reconciles old findings against the current head (resolving the ones the author fixed, leaving the unresolved ones open without re-posting duplicates), focuses on the commits pushed since the last review, and posts a short re-review delta instead of a brand-new wall of comments. The first review of a PR always runs in **initial mode**. This is automatic; no flag is required. Set `PR_REVIEWER_RECONCILE=false` to force a full, stateless review that ignores prior findings.

## What This Does

This command runs a **cost-tiered** review and posts the results back to the PR. The tier is chosen automatically from the diff (see step 5):

- **Default — low-cost path:** two parallel Haiku finder agents scan the diff for correctness/regression bugs and security/edge-case issues; you then self-verify and keep the strongest findings (capped at 8). This is the path for ordinary PRs and keeps token cost low.
- **Escalated — full specialist path:** when the diff touches a **high-risk surface** (auth/authz, payments/billing, crypto, DB migrations/schema, or public APIs), the dedicated specialized reviewers run instead for deeper coverage. They run on **mixed model tiers** so frontier-model spend goes only where it pays off (see *Model selection* in step 6B):

| Reviewer | Focus | Model tier |
|----------|-------|------------|
| `code-reviewer` | Readability, naming, duplication, error handling, design patterns | quality (cheap, e.g. Haiku) |
| `test-reviewer` | Coverage gaps, test quality, edge cases, missing regression tests | quality (cheap, e.g. Haiku) |
| `security-reviewer` | OWASP Top 10, secrets, injection, auth/authz vulnerabilities | risk (frontier / lead's model) |
| `performance-reviewer` | N+1 queries, O(n²) loops, memory leaks, blocking I/O | risk (frontier / lead's model) |

Either way the outcome is identical downstream: a verdict, a summary comment, and **one inline comment per finding** posted to the detected platform.

## Platform Support

The plugin auto-detects the hosting platform from your git remote URL:

| Remote URL contains | Platform | How review is posted |
|---|---|---|
| `github.com` | GitHub | GitHub CLI (`gh`) — see `providers/github.md` |
| `dev.azure.com` / `visualstudio.com` | Azure DevOps | REST API (`curl`) — see `providers/azure-devops.md` |
| Anything else | Generic | Written to `pr-review-report.md` — see `providers/generic.md` |

## Prerequisites

- Must be run inside a git repository
- The branch under review must have at least one commit ahead of the base branch
- **GitHub**: `gh` CLI installed and authenticated (see `docs/platform-setup.md`)
- **Azure DevOps**: `AZURE_DEVOPS_TOKEN` environment variable set (see `docs/platform-setup.md`)
- **Fix mode**: `GITHUB_TOKEN` (GitHub) or `AZURE_DEVOPS_TOKEN` (Azure DevOps) must be set for `git push`

---

# Comment markers and finding identity (read before posting)

Re-review depends on the plugin being able to recognise its **own** previous comments and match each old finding to the current code. Two pieces of metadata make this possible. Both are written on **every** comment the plugin posts (initial *and* re-review) so that the *next* run can read them.

### 1. The marker (identifies a comment as ours)

Stamp every comment the plugin posts with a hidden marker string:

```
<!-- pr-reviewer:v1 kind=<finding|summary> fid=<finding-id> sha=<HEAD_SHA> -->
```

- `kind` — `finding` for an inline finding thread, `summary` for the PR-level report comment.
- `fid` — the stable finding id (below). Omit for `kind=summary`.
- `sha` — the `HEAD_SHA` the comment was generated against (lets the next run compute the incremental range).

On **GitHub** the marker is an HTML comment appended to the comment body — it renders invisibly. On **Azure DevOps**, HTML comments are *not* reliably hidden, so the same fields are stored as thread **`properties`** (`pr-reviewer.kind`, `pr-reviewer.fid`, `pr-reviewer.sha`) instead of in the body. The provider files show the exact mechanics.

Only comments carrying this marker are ever reconciled, replied to, or resolved by the plugin. Human review comments are never touched.

### 2. The finding id `fid` (matches a finding across revisions)

`fid` must be **deterministic** and **independent of line number** (lines drift as the author edits), so the same logical issue produces the same id on every run. Compute it from the file path plus a normalised issue signature:

```bash
# fid = first 12 hex of sha1( lowercased repo-relative path + "|" + normalised issue text )
# Normalisation: lowercase, keep [a-z0-9 ], collapse runs of whitespace, trim.
compute_fid() {  # args: <file> <issue-text>
  python3 - "$1" "$2" <<'PY'
import sys, re, hashlib
path = sys.argv[1].strip().lower()
issue = re.sub(r'[^a-z0-9 ]', ' ', sys.argv[2].lower())
issue = re.sub(r'\s+', ' ', issue).strip()
print(hashlib.sha1(f"{path}|{issue}".encode()).hexdigest()[:12])
PY
}
```

Use the **issue summary sentence** (not the code snippet, not the line) as the issue text. The same wording each run keeps the id stable; if the reviewer rephrases an issue slightly between runs it may be treated as new — acceptable, since the worst case is one duplicate rather than a missed regression.

---

# Procedure

When invoked with a PR number, branch name, or no argument (defaults to current branch vs main):

## 1. Detect Platform (do this FIRST, before any other tool call)

Run **only** the following to detect which hosting platform is in use:

```bash
git remote get-url origin
```

From the remote URL, determine the platform:
- Contains `github.com` → **GitHub**
- Contains `dev.azure.com` or `visualstudio.com` → **Azure DevOps**
- Contains `bitbucket.org` → **Bitbucket**
- Anything else → **Generic** (report only, no inline posting)

Store the detected platform — it determines every subsequent CLI/API choice. Do **not** assume the platform from the argument or the repo name; the remote URL is authoritative.

### Platform-exclusive CLI rule (mandatory)

After detection, use **only** the platform-appropriate tool for the rest of the run. Mixing them wastes turns and leaks credentials into logs:

| Platform | Allowed for posting / PR API | Forbidden |
|---|---|---|
| GitHub | `gh`, `git` | `curl` to Azure DevOps, `az` |
| Azure DevOps | `curl` + `AZURE_DEVOPS_TOKEN`, `git` | `gh` (will fail with `gh auth login`), `az login` |
| Bitbucket / Generic | `git` only | `gh`, `curl` to private APIs |

Do **not** probe other CLIs ("just to check"). The hook layer will block obvious mismatches; doing it wrong will block the run.

## 2. Post a "Review in Progress" Comment (must be within the first 3 tool calls)

Immediately after platform detection, post a comment so the PR author knows the review has started. **Do not read any files, do not run `find`/`ls`, do not index the codebase before this step.**

Use the platform-appropriate method:
- **GitHub:** `gh pr comment` — see `providers/github.md`
- **Azure DevOps:** REST API — see `providers/azure-devops.md` (Posting the Starting Comment section)
- **Generic / unknown platform:** Skip — no API available

Resolve the PR number from the argument first; only fall back to a CLI lookup (`gh pr list` on GitHub, `pullrequests?searchCriteria.sourceRefName=...` on Azure DevOps) if it was not provided.

If posting the starting comment fails, output a single warning line and continue — do not stop the review.

## 3. Gather PR Context (do this BEFORE indexing the codebase)

The diff is what matters. Resolve the base/head and pull the diff first — for small PRs (≤10 changed files), this is *all* the context the sub-agents need, and the codebase index in step 4 can be skipped entirely.

### Run the setup script (ONE bash call — mandatory)

> **Shell state does not persist between tool calls.** Each `Bash` invocation starts a fresh shell — variables like `HEAD_SHA` from a prior call are **gone**. This script resolves checkout, base/head SHAs, diffs, and the numbered patch in one shot, then writes everything to `/tmp/pr_state.env`. In any later bash block that needs these values, run `source /tmp/pr_state.env` first. Never assume a variable from a prior tool call still exists.

> **Xianix Executor / CI worktrees:** the runner checks out the repo's **default branch** only — it knows nothing about PRs. When a PR number is provided, this script is a **hard gate**. You must see `Checked out PR #<n> at <sha>` (or branch checkout) in the output before proceeding. If `HEAD_SHA` does not match the platform's `headRefOid`, the script exits with an error.

Set `PR_NUMBER` (numeric argument, if any), `PLATFORM` (`github`, `azure`, or `generic`), and `BRANCH_ARG` (branch name argument, if any) before running. Then execute this **entire** script as a single `Bash` call:

```bash
set -euo pipefail

: "${PLATFORM:=github}"
CHECKED_OUT=""

# --- 1. Checkout the revision under review ---
if [ -n "${PR_NUMBER:-}" ]; then
  case "$PLATFORM" in
    azure*) CANDIDATE_REFS="refs/pull/${PR_NUMBER}/merge refs/pull/${PR_NUMBER}/head" ;;
    *)      CANDIDATE_REFS="refs/pull/${PR_NUMBER}/head refs/pull/${PR_NUMBER}/merge" ;;
  esac
  for ref in $CANDIDATE_REFS; do
    if git fetch origin "$ref" 2>/dev/null; then
      git checkout --detach FETCH_HEAD
      CHECKED_OUT="$ref"
      break
    fi
  done
  if [ -z "$CHECKED_OUT" ]; then
    echo "WARN: no synthetic PR ref found — resolving source branch via platform API"
    case "$PLATFORM" in
      azure*)
        echo "ERROR: resolve PR_SOURCE from providers/azure-devops.md and re-run checkout"
        exit 1
        ;;
      *)
        SRC=$(gh pr view "$PR_NUMBER" --json headRefName --jq '.headRefName')
        git fetch origin "refs/heads/${SRC}"
        git checkout --detach FETCH_HEAD
        CHECKED_OUT="refs/heads/${SRC}"
        ;;
    esac
  fi
  echo "Checked out PR #${PR_NUMBER} via ${CHECKED_OUT} at $(git rev-parse HEAD)"
elif [ -n "${BRANCH_ARG:-}" ]; then
  git fetch origin "$BRANCH_ARG"
  git checkout --detach FETCH_HEAD
  CHECKED_OUT="refs/heads/${BRANCH_ARG}"
  echo "Checked out branch ${BRANCH_ARG} at $(git rev-parse HEAD)"
fi

# --- 2. Resolve target branch name ---
if [ -n "${PR_NUMBER:-}" ]; then
  case "$PLATFORM" in
    azure*)
      echo "ERROR: set BASE from PR_TARGET per providers/azure-devops.md before running this script"
      exit 1
      ;;
    *)
      PR_METADATA=$(gh pr view "$PR_NUMBER" --json baseRefName,headRefName,headRefOid,title,body,author)
      BASE=$(echo "$PR_METADATA" | jq -r '.baseRefName')
      PR_HEAD_BRANCH=$(echo "$PR_METADATA" | jq -r '.headRefName')
      PR_TITLE=$(echo "$PR_METADATA" | jq -r '.title')
      PR_BODY=$(echo "$PR_METADATA" | jq -r '.body // ""')
      PR_AUTHOR=$(echo "$PR_METADATA" | jq -r '.author.login')
      EXPECTED_HEAD=$(echo "$PR_METADATA" | jq -r '.headRefOid')
      ;;
  esac
else
  BASE=$(git ls-remote --symref origin HEAD 2>/dev/null | awk '/^ref:/ {sub("refs/heads/","",$2); print $2}')
  : "${BASE:=main}"
  PR_TITLE=""
  PR_BODY=""
  PR_AUTHOR=""
  EXPECTED_HEAD=""
fi

# --- 3. Resolve HEAD_SHA and fetch fresh base tip ---
if [ "${CHECKED_OUT:-}" = "refs/pull/${PR_NUMBER:-}/merge" ]; then
  HEAD_SHA=$(git rev-parse HEAD^2)
else
  HEAD_SHA=$(git rev-parse HEAD)
fi

if [ -n "${PR_NUMBER:-}" ] && [ -n "${EXPECTED_HEAD:-}" ] && [ "$HEAD_SHA" != "$EXPECTED_HEAD" ]; then
  echo "ERROR: checked-out HEAD ($HEAD_SHA) does not match PR headRefOid ($EXPECTED_HEAD) — checkout failed"
  exit 1
fi

if git fetch origin "refs/heads/${BASE}" 2>/dev/null; then
  BASE_TIP=$(git rev-parse FETCH_HEAD)
else
  echo "WARN: could not fetch origin/${BASE} — falling back to local refs, base may be stale"
  BASE_TIP=""
  for candidate in "refs/remotes/origin/${BASE}" "refs/heads/${BASE}"; do
    git show-ref --verify --quiet "$candidate" && { BASE_TIP=$(git rev-parse "$candidate"); break; }
  done
fi
[ -n "$BASE_TIP" ] || { echo "ERROR: could not resolve base branch '${BASE}'"; exit 1; }

BASE_SHA=$(git merge-base "$BASE_TIP" "$HEAD_SHA")
echo "Base: $BASE (tip $BASE_TIP -> merge-base $BASE_SHA)"
echo "Head: $HEAD_SHA"

# --- 4. Sanity check commit count (when PR number available) ---
if [ -n "${PR_NUMBER:-}" ] && [ "$PLATFORM" != "azure" ]; then
  GIT_COMMIT_COUNT=$(git rev-list --count "${BASE_SHA}..${HEAD_SHA}")
  GH_COMMIT_COUNT=$(gh pr view "$PR_NUMBER" --json commits --jq '.commits | length')
  echo "Git commit count: $GIT_COMMIT_COUNT"
  echo "GitHub commit count: $GH_COMMIT_COUNT"
  if [ "$GIT_COMMIT_COUNT" -gt "$GH_COMMIT_COUNT" ]; then
    echo "ERROR: git reports more commits than GitHub — base is stale; re-fetch origin/${BASE} and retry"
    exit 1
  fi
  echo "✓ Commit count OK (git=$GIT_COMMIT_COUNT, github=$GH_COMMIT_COUNT)"
fi

# --- 5. Generate diffs and metadata ---
git log --oneline "${BASE_SHA}..${HEAD_SHA}"
git diff --stat "${BASE_SHA}"..."${HEAD_SHA}"
git diff --name-only "${BASE_SHA}"..."${HEAD_SHA}" | tee /tmp/pr_changed_files.txt
git diff "${BASE_SHA}"..."${HEAD_SHA}" > /tmp/pr_full_diff.patch
git log -1 --format="%an <%ae>" "${HEAD_SHA}"
git log --format="%s%n%b" "${BASE_SHA}..${HEAD_SHA}"

CHANGED_COUNT=$(wc -l < /tmp/pr_changed_files.txt | tr -d ' ')
echo "Changed files: $CHANGED_COUNT"

CURRENT_BRANCH=$(git rev-parse --abbrev-ref HEAD)
if [ "$CURRENT_BRANCH" = "HEAD" ]; then
  CURRENT_BRANCH=$(git branch --contains "$HEAD_SHA" \
    | sed 's|^[* ] *||' | grep -v '^(' | head -1 || true)
fi

# --- 6. Annotate diff with post-change line numbers ---
awk '
  /^@@/ {
    s = substr($0, index($0, "+") + 1); newln = s + 0
    print "      | " $0; next
  }
  /^(diff |index |--- |\+\+\+ |new file|deleted file|similarity|rename |Binary )/ {
    print "      | " $0; next
  }
  /^\+/ { printf "%5d |+%s\n", newln, substr($0, 2); newln++; next }
  /^ /  { printf "%5d | %s\n", newln, substr($0, 2); newln++; next }
  /^-/  { printf "    - |-%s\n", substr($0, 2); next }
  { print "      | " $0 }
' /tmp/pr_full_diff.patch > /tmp/pr_full_diff_numbered.patch
echo "Annotated diff written: $(wc -l < /tmp/pr_full_diff_numbered.patch) lines"

# --- 7. Persist state for later tool calls ---
# Use printf %q so titles/bodies with spaces, quotes, or newlines survive `source`.
{
  echo "HEAD_SHA=$HEAD_SHA"
  echo "BASE_SHA=$BASE_SHA"
  echo "BASE=$BASE"
  echo "BASE_TIP=$BASE_TIP"
  echo "CHANGED_COUNT=$CHANGED_COUNT"
  echo "CHECKED_OUT=$CHECKED_OUT"
  printf 'CURRENT_BRANCH=%q\n' "${CURRENT_BRANCH:-}"
  printf 'PR_TITLE=%q\n' "${PR_TITLE:-}"
  printf 'PR_BODY=%q\n' "${PR_BODY:-}"
  printf 'PR_AUTHOR=%q\n' "${PR_AUTHOR:-}"
  printf 'PR_HEAD_BRANCH=%q\n' "${PR_HEAD_BRANCH:-}"
} > /tmp/pr_state.env
echo "State written to /tmp/pr_state.env"
```

> On **Azure DevOps** the `/merge` ref points at the PR's *merge commit*; its second parent (`HEAD^2`) is the real PR head. The script sets `HEAD_SHA` accordingly when `CHECKED_OUT=refs/pull/<n>/merge`.

Writing the diff to `/tmp/pr_full_diff.patch` lets you pass it by **path** to sub-agents instead of by value — much smaller prompts when the diff is large.

Each kept line in `/tmp/pr_full_diff_numbered.patch` looks like `  147 |+    var x = ParseSubject(dn);` — the number left of the `|` is the exact line to cite. Reviewers must **copy** this number, never recompute it.

> **Anti-pattern:** Do NOT `cat <<'DIFF_EOF' ... DIFF_EOF` the diff back to yourself in a subsequent `Bash` call. The diff is already in your conversation history once you ran the setup script. Echoing it back wastes a turn and tokens.

Use `git show ${HEAD_SHA}:<filepath>` or the `Read` tool to read the full content of any file that requires deeper analysis beyond the patch. Always `source /tmp/pr_state.env` first so `HEAD_SHA` is defined.

**Platform CLIs are not used in this diff step.** Use **`gh`** only when posting to GitHub and **`curl`/Azure DevOps REST** only when posting to Azure DevOps (see the provider docs and "Posting the Review" below).

### Detect a prior review and compute the re-review range

This is the one place reading platform PR comments is required, because it determines whether the run is an **initial** review or a **re-review**. Skip entirely on the generic platform (no API) and when `PR_REVIEWER_RECONCILE=false`.

1. List the existing review comments/threads on the PR and keep only those carrying the plugin marker (`<!-- pr-reviewer:v1 ... -->` on GitHub, or the `pr-reviewer.*` thread properties on Azure DevOps). Use the platform helper:
   - **GitHub** → `providers/github.md` → *Detecting a prior review* (GraphQL: review threads with `id`, `isResolved`, body, fid).
   - **Azure DevOps** → `providers/azure-devops.md` → *Detecting a prior review* (`GET .../threads`, filter by `properties["pr-reviewer.fid"]`).

2. Decide the mode:

```bash
source /tmp/pr_state.env
# /tmp/pr_prior_findings.jsonl is written by the provider helper: one JSON object per
# prior marked finding thread: {fid, status(open|resolved), thread_ref[, comment_ref]}.
# Matching is by fid alone, so file/line are not needed here.
# PRIOR_SUMMARY_SHA is the sha= from the most recent summary marker, or empty.
if [ "${PR_REVIEWER_RECONCILE:-true}" = "false" ] || [ ! -s /tmp/pr_prior_findings.jsonl ]; then
  REVIEW_MODE="initial"
  RANGE_BASE="$BASE_SHA"
else
  REVIEW_MODE="rereview"
  # New commits since the last review; fall back to BASE_SHA if the recorded sha is gone.
  if [ -n "${PRIOR_SUMMARY_SHA:-}" ] && git cat-file -e "${PRIOR_SUMMARY_SHA}^{commit}" 2>/dev/null; then
    RANGE_BASE="$PRIOR_SUMMARY_SHA"
  else
    RANGE_BASE="$BASE_SHA"
  fi
fi
echo "Review mode: $REVIEW_MODE  |  incremental range: ${RANGE_BASE}..${HEAD_SHA}"
export REVIEW_MODE RANGE_BASE
```

3. Capture the **incremental** diff (commits pushed since the last review) in addition to the full PR diff — it is what you skim first in re-review mode and what populates the "changed since last review" line in the delta:

```bash
source /tmp/pr_state.env
if [ "$REVIEW_MODE" = "rereview" ] && [ "$RANGE_BASE" != "$BASE_SHA" ]; then
  git log --oneline ${RANGE_BASE}..${HEAD_SHA}
  git diff ${RANGE_BASE}...${HEAD_SHA} > /tmp/pr_incremental_diff.patch
  echo "Incremental diff: $(wc -l < /tmp/pr_incremental_diff.patch) lines since last review"
fi
```

> **Why review the full PR diff, not just the increment?** The full diff (`/tmp/pr_full_diff.patch`) stays the authoritative input to the reviewers so the *current* finding set is always complete — an unresolved finding in a file the latest commits didn't touch must still be detected so it stays open. The incremental diff focuses your attention and drives the delta summary; it does not replace the full scan. Reconciliation (step 7 / posting) compares the current finding set to the prior one **by `fid`**.

## 4. Index the Codebase (skip on small PRs)

Every line these commands print lands in your context and is paid for on every subsequent turn — keep the index small. The caps below are mandatory, not decorative.

```bash
source /tmp/pr_state.env
if [ "${CHANGED_COUNT:-0}" -le 10 ]; then
  echo "Small PR ($CHANGED_COUNT files) — skipping codebase index, diff alone is enough context."
else
  # Top-level layout
  ls -1

  # Source tree (depth 3, ignore common noise, HARD CAP at 200 lines)
  find . -maxdepth 3 \
    -name .git -prune -o \
    -name node_modules -prune -o \
    -name bin -prune -o \
    -name obj -prune -o \
    -name .vs -prune -o \
    -name dist -prune -o \
    -name build -prune -o \
    -print | sort | head -200

  # Language fingerprint (changed files only — the repo-wide walk is wasted tokens)
  sed 's/.*\.//' /tmp/pr_changed_files.txt | sort | uniq -c | sort -rn | head -10

  # Entry points / build manifests
  ls *.sln *.csproj package.json go.mod Cargo.toml pom.xml build.gradle \
     pyproject.toml setup.py requirements.txt CMakeLists.txt 2>/dev/null || true
fi
```

If indexing was performed, use `Read` on key config/manifest files (`package.json`, `*.csproj`, `go.mod`) and `Grep` to locate patterns such as the main entry point, base classes, or shared utilities referenced by the changed files. Otherwise skip directly to step 5.

## 5. Understand the Change & Choose the Review Tier

Before launching any agents:
- Identify the type of change (feature, bugfix, refactor, config, docs)
- Note which languages/frameworks are involved
- Estimate scope (small/medium/large)

### Decide the tier: default Haiku finders vs. escalated specialists

The review runs on the **cheap Haiku-finder path by default** (step 6A) and only **escalates to the full specialist reviewers** (step 6B) when the diff touches a high-risk surface. Detect high-risk changes from both the file list and the diff content:

```bash
source /tmp/pr_state.env
RISK_PATH_RE='(auth|login|signin|session|password|passwd|secret|token|jwt|oauth|crypto|encrypt|decrypt|payment|billing|charge|invoice|checkout|migration|schema|\.sql$|webhook|/api/|/controllers?/|/routes?/|/handlers?/|iam|rbac|permission)'
RISK_CONTENT_RE='(password|secret|api[_-]?key|private[_-]?key|authorize|authenticate|hashpw|bcrypt|jwt|sql|exec\(|eval\(|subprocess|os\.system|pickle\.loads)'

REVIEW_TIER="haiku"
# 1. High-risk by file path — docs/images can never be a high-risk surface,
#    so exclude them before matching (a filename like docs/token-guide.md must
#    not escalate the whole run to the expensive specialist path).
if grep -ivE '\.(md|markdown|rst|txt|png|jpg|jpeg|gif|svg)$' /tmp/pr_changed_files.txt \
   | grep -qiE "$RISK_PATH_RE"; then
  REVIEW_TIER="specialists"
# 2. High-risk by changed content. '^\+[^+]' matches added lines ONLY — a bare
#    '^\+' also matches '+++ b/<path>' file headers, which escalates PRs whose
#    filenames merely contain words like "token" or "sql".
elif grep -E '^\+[^+]' /tmp/pr_full_diff.patch | grep -qiE "$RISK_CONTENT_RE"; then
  REVIEW_TIER="specialists"
fi

if [ "$REVIEW_TIER" = "specialists" ]; then
  echo "High-risk surface detected — escalating to specialist reviewers."
else
  echo "No high-risk surface — using low-cost Haiku finder path."
fi
export REVIEW_TIER
```

- `REVIEW_TIER=haiku` → go to **step 6A** (two Haiku finders). This is the common case.
- `REVIEW_TIER=specialists` → go to **step 6B** (gated specialist sub-agents).

When genuinely uncertain whether a change is high-risk, prefer **specialists** — a missed vulnerability costs far more than one extra review pass. The heuristic above is intentionally broad for exactly this reason.

## 6. Run the Review (parallel sub-agent calls — MANDATORY)

Run **exactly one** of the two paths below, chosen by `REVIEW_TIER` from step 5. Both paths run **real, parallel, top-level sub-agents** (you are the top-level agent, so `Task` / `Agent` is available here) and both feed the same step 7. The tool is exposed under two equivalent names depending on the Claude Code SDK version (`Task` and/or `Agent`). Use whichever your SDK accepts; if one returns `No such tool available`, immediately retry the same call with the other name.

> **Registered agents.** The four specialist reviewers are registered in `plugin.json` (`code-reviewer`, `security-reviewer`, `test-reviewer`, `performance-reviewer`). Always set `"subagent_type"` to the reviewer name — do **not** hand-write a generic `Agent` prompt without `subagent_type`. If your SDK requires the plugin prefix, use `pr-reviewer:code-reviewer` etc.

> **Agent `model` field — valid slugs only.** The `Task`/`Agent` tool accepts **only** `sonnet`, `opus`, `haiku`, or `fable`. Values like `claude-haiku-4-5` are rejected with `InputValidationError`. Map env overrides to these slugs before passing them (see model-selection block in 6B). For the lead's inherited model, **omit** the `model` field entirely.

**Constraints every sub-agent prompt below must include, verbatim:**

- A reminder: *"Do not re-fetch git data; the annotated diff at /tmp/pr_full_diff_numbered.patch is authoritative. Return findings only."*
- A line-number constraint: *"Every `path/to/file.ext:NN` reference must be the POST-CHANGE file line number, and you must READ it — never compute it. In /tmp/pr_full_diff_numbered.patch every context and added (`+`) line is prefixed with `<lineno> |`; `NN` is exactly that number for the flagged line. Copy it verbatim. Never do hunk-header arithmetic, never report the diff's own line position, and never emit a number larger than the file. Findings on deleted (`-`) lines (marked `- |`) have no post-change line — reference the nearest surviving numbered line instead."*
- A suggestion constraint: *"For findings where the fix is a concrete, drop-in replacement (wrong identifier, missing null guard, insecure call swapped for safe equivalent, etc.), add a native GitHub suggestion block immediately after the `**Fix:**` block. Prefix it with an HTML comment that carries the line range, then a ` ```suggestion ` fenced block containing the verbatim replacement lines with indentation preserved. Example for a single-line fix: `<!-- suggestion: line NN -->` on its own line, then ` ```suggestion `, then the replacement line, then ` ``` `. For multi-line: `<!-- suggestion: lines NN-MM -->`. Do not include this for architectural improvements or fixes requiring author judgment."*

> **Diff size (used by both paths):**
> ```bash
> DIFF_LINES=$(wc -l < /tmp/pr_full_diff.patch)
> echo "Diff size: $DIFF_LINES lines  |  Tier: $REVIEW_TIER"
> ```

---

### 6A. Default path — two parallel Haiku finders (`REVIEW_TIER=haiku`)

Lowest-cost path for ordinary PRs.

**Pre-load context (at most 3 `Read` calls, strict size cap).** From `/tmp/pr_changed_files.txt` pick the **top 3 highest-risk files** (business logic, data access first; skip pure test/generated files unless they are the only changes). For each:
- If the file is **≤ 400 lines**, read it in full.
- If **> 400 lines**, extract only the changed regions: `grep -n '^@@' /tmp/pr_full_diff.patch` to find hunk positions, then `sed -n '<start>,<end>p' <file>` for ±60 lines around each hunk.

Concatenate the snippets into `/tmp/pr_context.txt` (a filepath header before each). **Never read any file in its entirety if it exceeds 400 lines; never read more than 3 files.**

Then emit **both Agent calls in the same assistant turn** (so they run in parallel). Both **must** set `"model": "haiku"`. Neither agent may call `Read`, `Bash`, `Grep`, or any other tool — they work only from the two files named in the prompt.

Both prompts share the same shell and tail. Compose each prompt as: the **shared header**, then the agent's **focus list** (below), then the **shared output-format tail**.

**Shared header (start of both prompts):**

```
Read /tmp/pr_full_diff_numbered.patch then /tmp/pr_context.txt. The numbered diff prefixes every context/added line with its real post-change file line number (`<lineno> |`); use those numbers for LINE — never compute a line number.
```

**Shared output-format tail (end of both prompts, verbatim):**

```
For each finding output exactly:
FILE: <path>
LINE: <the number printed left of the `|` on the flagged line in /tmp/pr_full_diff_numbered.patch — copied verbatim, never computed, never the diff's own line position, never larger than the file>
SEVERITY: CRITICAL | WARNING | SUGGESTION
ISSUE: <one sentence>
SUGGESTION_START_LINE: <line number, only when the fix is a concrete drop-in single-line or consecutive-block replacement; omit otherwise>
SUGGESTION_END_LINE: <last line of the replacement block; same as SUGGESTION_START_LINE for a single-line fix; omit if no suggestion>
SUGGESTION_CODE: <verbatim replacement lines with indentation preserved exactly; omit if no suggestion>

Include SUGGESTION_* fields only when the fix is an unambiguous drop-in swap (wrong value, missing guard, insecure call replaced by its safe equivalent). Omit for architectural or design-level fixes.

If you find nothing, output: NONE
Do not call any tools.
```

**Agent 1 — Correctness & regressions** (`"description": "Correctness & regression finder"`), focus list:

```
Find correctness bugs and behavioural regressions introduced by the diff. Focus on:
- Logic errors in changed code paths
- Changed conditions that now allow or block cases they shouldn't
- Null / empty / zero edge cases on new code paths
- Removed guards that previously protected against a bad state
- Interface/contract mismatches between callers and the changed function
```

**Agent 2 — Security & edge cases** (`"description": "Security & edge-case finder"`), focus list:

```
Find security issues and missing edge-case handling in the diff. Focus on:
- Input not validated before use (injection, path traversal)
- Authentication or authorisation checks removed or weakened
- Sensitive data written to logs
- Exception or error paths that swallow failures silently
- Resource leaks (connections, file handles) on error paths
- Off-by-one errors or boundary conditions in new loops/ranges
```

**Verify and compile (you are the verifier — no extra agents).** For each finding from both agents: (1) confirm the flagged line appears in `/tmp/pr_full_diff_numbered.patch` as a `+` line (new code, not pre-existing) and that the reported `LINE` matches the number printed in that line's margin — **if the line number is missing, does not match the margin, or exceeds the file's length, correct it to the margin number of the flagged code before keeping the finding** (this is the guard against out-of-range citations like `:466` on a 322-line file); (2) discard pre-existing issues, linter/compiler-caught problems, pedantic style, and obvious false positives; (3) merge duplicates and **cap at 8 findings**, ranked CRITICAL → WARNING → SUGGESTION; (4) **preserve the `SUGGESTION_START_LINE` / `SUGGESTION_END_LINE` / `SUGGESTION_CODE` fields verbatim** — they will be extracted in the "Extract suggestion annotations" step before posting and are what enables the GitHub "Commit suggestion" button. Then go to step 7.

---

### 6B. Escalated path — gated specialist sub-agents (`REVIEW_TIER=specialists`)

Deeper coverage for high-risk diffs. Run `code-reviewer` **always**; gate the other three by the changed-file mix so you never spawn a reviewer with nothing to do:

| `subagent_type` | Focus | Model tier | Run when the diff contains… | Skip when… |
|---|---|---|---|---|
| `code-reviewer` | Code quality, readability, maintainability | **quality** (`haiku`) | **always** | never |
| `test-reviewer` | Test coverage and test quality | **quality** (`haiku`) | source code with behaviour (functions/methods/classes) | the diff is **only** docs, config, or pure formatting/rename |
| `security-reviewer` | Vulnerabilities, secrets, input validation | **risk** (omit `model` / inherit) | source code, auth/authz, input handling, dependencies/lockfiles, IaC, any externally-reachable surface | the diff is **only** docs/markdown/images |
| `performance-reviewer` | Bottlenecks, inefficiencies, resource usage | **risk** (omit `model` / inherit) | DB queries/ORM, loops over collections, I/O, hot paths, caching layers, auth handlers with async/DB lookups, large data structures, algorithm changes | the diff is **only** docs/config with no executable code |

`package.json`/`*.csproj`/lockfile changes are **not** docs — they keep `security-reviewer` in scope (dependency risk). Paths matching `auth`, `cache`, or `handler` keep `performance-reviewer` in scope (request-path latency). When uncertain whether a reviewer applies, **run it**. For `REVIEW_TIER=specialists` on auth/security code, expect **four** agent results unless you document a skip reason.

In **one assistant turn**, emit one parallel sub-agent invocation per selected reviewer (between 1 and 4). Each invocation prompt must include, in addition to the two shared constraints above:

- The path `/tmp/pr_full_diff_numbered.patch` (the line-number-annotated diff — the authoritative source for `NN`) and the path `/tmp/pr_changed_files.txt`
- `BASE_SHA` and `HEAD_SHA`
- The PR title and description (from the platform metadata fetched in step 2)
- A file-reading constraint: *"When you need full file context, read only the enclosing function/class (±60 lines around each changed hunk). Do not read any file in its entirety if it exceeds 400 lines — use `Bash(sed -n '<start>,<end>p' <file>)` scoped to the changed region instead. Read at most 3 files beyond the diff."*

> **Pass-by-value vs path:** if `DIFF_LINES ≤ 300`, paste the contents of `/tmp/pr_full_diff_numbered.patch` **inline** in each prompt (cheaper than each sub-agent re-opening a shared file) — inline the *numbered* diff, not the raw one, so the line numbers travel with it; if `DIFF_LINES > 300`, pass the path `/tmp/pr_full_diff_numbered.patch`.

> **Model selection (mixed-model tiering).** The reviewers split into two model tiers so you don't pay frontier-model rates for the cheaper review dimensions. Set each sub-agent's `model` from its tier (per the table above), resolved with this precedence:
>
> 1. **`PR_REVIEWER_MODEL` (override).** If set, it pins **every** reviewer to that one model — backward-compatible escape hatch, ignores the tiers below.
> 2. Otherwise, per tier:
>    - **quality tier** (`code-reviewer`, `test-reviewer`) → `PR_REVIEWER_QUALITY_MODEL` if set, else `haiku`. These are pattern/coverage tasks that a small model handles well.
>    - **risk tier** (`security-reviewer`, `performance-reviewer`) → `PR_REVIEWER_RISK_MODEL` if set, else inherit (omit `model`). Vulnerability and performance reasoning is where frontier accuracy actually pays off — this path was chosen *because* the diff is high-risk.
>
> ```bash
> source /tmp/pr_state.env
> map_model_slug() {
>   case "$1" in
>     inherit|"") echo "" ;;
>     sonnet|opus|haiku|fable) echo "$1" ;;
>     *haiku*) echo "haiku" ;;
>     *sonnet*) echo "sonnet" ;;
>     *opus*) echo "opus" ;;
>     *) echo "haiku" ;;
>   esac
> }
> RISK_MODEL="${PR_REVIEWER_RISK_MODEL:-inherit}"
> QUALITY_MODEL="${PR_REVIEWER_QUALITY_MODEL:-haiku}"
> if [ -n "${PR_REVIEWER_MODEL:-}" ]; then
>   RISK_MODEL="$PR_REVIEWER_MODEL"; QUALITY_MODEL="$PR_REVIEWER_MODEL"
> fi
> QUALITY_SLUG=$(map_model_slug "$QUALITY_MODEL")
> RISK_SLUG=$(map_model_slug "$RISK_MODEL")
> echo "Reviewer models — quality: ${QUALITY_SLUG:-inherit} | risk: ${RISK_SLUG:-inherit}"
> ```
>
> Emit each reviewer in the **same assistant turn** with `subagent_type` set. Pass `"model": "<slug>"` only when the mapped slug is non-empty (`haiku` for quality tier; omit entirely for risk tier when `RISK_SLUG` is empty). **Never** pass `claude-haiku-4-5`, `inherit`, or any other string — those cause `InputValidationError`.
>
> **Invocation template (6B — copy per selected reviewer, adjust `subagent_type` and `model`):**
>
> ```json
> {
>   "subagent_type": "code-reviewer",
>   "model": "haiku",
>   "description": "Code quality review",
>   "prompt": "<shared constraints from step 6> + paths /tmp/pr_full_diff_numbered.patch and /tmp/pr_changed_files.txt + BASE_SHA/HEAD_SHA from /tmp/pr_state.env + PR title/description + file-reading constraint"
> }
> ```
>
> For `security-reviewer` and `performance-reviewer`, omit `"model"` so they inherit the lead's model. Launch all selected reviewers in one turn — never sequentially.

Wait for all selected sub-agents to return, then go to step 7. **Do not** run `sed`/`git show`/`Read` on changed files yourself while waiting — that is simulating the reviewers (see anti-patterns below).

---

### What NOT to do (anti-patterns — apply to both paths)

These look like progress but are actually you **simulating** sub-agents in your own context. They double cost, double latency, and lose the benefit. **Stop the moment you catch yourself doing any of them:**

- ❌ Spawning a single `orchestrator` / "PR review" sub-agent and asking it to run the reviewers. That sub-agent cannot spawn sub-agents — the fan-out fails and the review degrades to a text summary that never gets posted. Run the agents from here.
- ❌ Running `Bash` with `cat <<'ANALYSIS' ... === CODE QUALITY REVIEW === ... ANALYSIS` — that is **you pretending to be a reviewer**, not invoking it. Delete the heredoc and emit a real agent call instead.
- ❌ A long thinking turn (>20 s) followed by directly compiling the report. That pause is internal reasoning that should have been parallel sub-agent work.
- ❌ Sequential `Task` / `Agent` calls — they MUST be in the same assistant turn so the runtime parallelizes them.
- ❌ Launching agents without `"subagent_type"` — hand-written prompts bypass the registered reviewer definitions and lose checklist coverage.
- ❌ Passing `"model": "claude-haiku-4-5"` or `"model": "inherit"` — use `haiku` or omit the field; invalid slugs fail the whole parallel batch.
- ❌ Running `sed`/`git show`/`Read` on changed files **after** launching specialists but **before** step 7 — you are duplicating reviewer work. If you have more than 3 such calls in that window, stop and wait for sub-agent results.
- ❌ Passing a large diff (> 300 lines) inline when `/tmp/pr_full_diff.patch` exists. Pass the path.
- ❌ `cat <<'DIFF_EOF' ... DIFF_EOF` echoing the diff back into the conversation. You already have it. Don't.
- ❌ Printing "Review posted successfully" when `gh pr review` or inline posting failed — check exit codes and `INLINE_OK` first.

### Fallback if sub-agents are genuinely unavailable

If **both** `Task` and `Agent` return `No such tool available` (a stripped-down runtime that exposes neither), do not give up:

1. Perform the review yourself, inline — for the Haiku path do the two finder passes (correctness, security); for the specialist path do one focused pass per selected dimension — using `/tmp/pr_full_diff.patch` as the source of truth.
2. Then **continue to steps 7 and "Posting the Review" exactly as normal** — a degraded analysis path must still post the report and inline comments. Producing a text summary and stopping is a failure.

### Self-check before emitting the report

Before step 7, your conversation history should contain a `Task` (or `Agent`) tool result in the prior turn for the path you ran: **two Haiku finders** (6A) or **one result per selected specialist** (6B). If those results are missing *and* you did not take the documented fallback above, you skipped the review. Go back and do it.

## 7. Compile Final Report

Aggregate all findings into the structured report format defined in `styles/report-template.md`. Read that file and follow its template exactly.

**Guidelines:**
- Reference specific file paths and line numbers for every finding
- Include both the problematic code snippet and a concrete fix example
- Do not flag non-issues — only real problems and genuine improvements
- Tag findings that exist in the base branch (not introduced by this PR) as **pre-existing** — they may warrant a WARNING but must not alone drive a `REQUEST CHANGES` verdict
- Consider the PR's stated intent when evaluating trade-offs
- Group related issues together rather than repeating similar findings

### Validate every finding's line number against the file (MANDATORY — do this before writing the report)

This is the guard that keeps the **summary body** honest. Inline comments get a second chance to be corrected (GitHub `422`, Azure DevOps `400`, and the "Resolve every finding to a post-change file line" step), but the summary embeds the reviewer's `file:NN` text as-is — so an over-shot number like `:466` on a 322-line file sails straight into the report unless you check it here. Do the check **once**, and use the result for **both** the summary and the inline JSONL so they never disagree.

For each finding:

1. Compute the file's new-side length: `LINES=$(git show ${HEAD_SHA}:<file> | wc -l)`.
2. If `NN > LINES`, or the code at `<file>:NN` (`git show ${HEAD_SHA}:<file> | sed -n "${NN}p"`) does not contain the snippet the finding describes, the number is wrong. Re-anchor it: find the flagged line in `/tmp/pr_full_diff_numbered.patch` and use the number printed in its margin. If the finding is genuinely unlocatable in the new file (e.g. it only described deleted code), drop it rather than cite a fabricated line.
3. Carry the corrected `NN` into the report body **and** the inline JSONL — the summary line reference and the inline comment for the same finding must be identical.

A finding whose line cannot be validated to a real, in-range line in the changed file must not appear in the report with a made-up number.

### Assign a `fid` to every current finding

For each finding in the compiled report, compute its `fid` with the `compute_fid` helper (see *Comment markers and finding identity*) from its file path and issue summary sentence. This is required in **both** modes — the markers written this run are what the *next* run reconciles against.

### Reconcile against the prior review (re-review mode only)

When `REVIEW_MODE=rereview`, classify by comparing the current finding set to `/tmp/pr_prior_findings.jsonl` **by `fid`**:

| Bucket | Condition | Posting action (see "Posting the Review") |
|---|---|---|
| **Carried-over** | prior `fid` is still in the current finding set | Leave the existing thread open. **Do not post a duplicate.** |
| **Fixed** | prior `fid` (status `open`) is **absent** from the current finding set | Reply "resolved as of `<HEAD_SHA>`" on the existing thread and mark it resolved. |
| **New** | current `fid` not present in the prior set | Post a new inline thread (with marker). |
| **Already-resolved** | prior `fid` whose thread is already resolved | Ignore — no action. |

Write the three actionable buckets to `/tmp/pr_reconcile.json` (`{"fixed":[...], "carried_over":[...], "new":[...]}`, each entry keyed by `fid` with its `thread_ref`/`comment_ref` from the prior file) so the posting step can act on them without recomputing.

Then prepend a **Re-review delta** block to the report body (above the Summary), using the template's re-review section:

```
### Re-review delta
Reviewed N new commit(s) since the last review (`<RANGE_BASE>`..`<HEAD_SHA>`).
- ✅ Fixed: <count> previously-flagged issue(s) resolved
- ⏳ Still open: <count> carried-over issue(s)
- 🆕 New: <count> issue(s) introduced since the last review
```

In **initial mode** skip reconciliation entirely — every finding is "New" and there is no delta block.

### Recompute the verdict from the *currently open* set

The verdict reflects the finding set at `HEAD` after reconciliation — i.e. carried-over + new findings (fixed ones no longer count). A re-review where the author fixed the last blocker should now produce `APPROVE`.

---

# Applying Fixes (Fix Mode Only)

Only enter this section when running in fix mode (invocation includes `--fix` or explicit fix instruction). Otherwise skip directly to Posting the Review.

### 1. Apply fixes locally

Use `Write` or `Bash` to edit the affected files. Use `git show HEAD:<filepath>` or `Read` to read the full current file content before editing. Only fix CRITICAL and WARNING issues — do not auto-fix suggestions.

### 2. Commit the changes

```bash
git add <file>
git commit -m "fix: <short description of what was fixed>"
```

One commit per logical fix. Commit message format: `fix: <description>`.

### 3. Push to the PR branch

The run executes in a temporary Docker container with no stored git credentials, and the `PreToolUse` hook cannot export variables into your shell (it only validates that the token exists). Carry the token **inline on the push command itself** via env-scoped git config:

```bash
REMOTE_URL=$(git remote get-url origin)
REMOTE_HOST=$(echo "$REMOTE_URL" | sed -E 's|^[a-z+]+://||; s|^[^@/]+@||; s|[:/].*$||')
case "$REMOTE_URL" in
  *dev.azure.com*|*visualstudio.com*) PUSH_TOKEN="${AZURE_DEVOPS_TOKEN}" ;;
  *)                                  PUSH_TOKEN="${GITHUB_TOKEN}" ;;
esac

GIT_CONFIG_COUNT=1 \
GIT_CONFIG_KEY_0="url.https://x-access-token:${PUSH_TOKEN}@${REMOTE_HOST}/.insteadOf" \
GIT_CONFIG_VALUE_0="https://${REMOTE_HOST}/" \
git push origin HEAD
```

The `GIT_CONFIG_*` prefix scopes the credential to this single command — nothing is written to disk or `~/.gitconfig`, and nothing needs to persist in the throwaway container.

### 4. Post a fix summary comment

Post a comment listing:
- Which issues were auto-fixed (with file and line references)
- Which issues still require manual attention

Use the platform-appropriate method from the Posting the Review section below with event `COMMENT`.

---

# Posting the Review

After compiling the report (and applying fixes if in fix mode), post it to the platform detected in Step 1 immediately without waiting for user input. Posting has the sub-steps below; all are mandatory when the platform supports them and the run is incomplete if any are skipped. Sub-step **R** runs only in re-review mode.

| # | Sub-step | GitHub | Azure DevOps | Generic |
|---|---|---|---|---|
| A | Cast the verdict / vote | `gh pr review` flag | `PUT .../reviewers/{id}` with vote | n/a |
| B | Post the full report body (incl. delta) as one PR-level comment, **with the summary marker** | `gh pr review --body` | `POST .../threads` (no `threadContext`) | write to `pr-review-report.md` |
| R | **Re-review only:** reconcile prior findings — resolve **Fixed** threads (with a reply), leave **Carried-over** threads open (no duplicate) | reply + `resolveReviewThread` (GraphQL) | reply + `PATCH .../threads/{id}` `status:fixed` | n/a |
| C | Post **one inline thread per finding** (initial mode: every finding; re-review mode: **only the New bucket**), **each with a finding marker** | `gh api .../pulls/<n>/comments` per finding | `POST .../threads` with `threadContext` per finding | n/a (skip with note) |

**C is not optional** when there are findings to post (initial mode: all findings with `path/to/file.ext:NN`; re-review mode: the New bucket). The whole point of the specialized reviewers is to surface findings inline next to the offending code; collapsing them into the summary thread defeats the plugin's value. If you find yourself about to print "Review posted" without having posted the due inline comments, stop and go back to sub-step C.

**Every comment the plugin posts in B and C must carry its marker** (summary marker on B, finding marker with the finding's `fid` on C — see *Comment markers and finding identity*). A run that posts comments without markers breaks the next re-review (it will re-post everything as duplicates). The provider files show exactly where the marker goes for each call.

### Sub-step R — reconcile prior findings (re-review mode only)

Skip in initial mode and on the generic platform. Drive this from `/tmp/pr_reconcile.json` (built in step 7):

- **Fixed** (`fixed[]`): for each, post a short reply on the existing thread — e.g. `✅ Resolved as of \`<HEAD_SHA>\`` — then mark the thread resolved/fixed. Use the platform mechanics in the provider file's *Reconciling prior findings* section.
- **Carried-over** (`carried_over[]`): take **no** action. The thread is already open; do not reply on every run (avoid notification spam) and never re-post the finding as a new thread.

Track a counter (`RESOLVED_OK` / `RESOLVED_FAIL`) the same way inline posting does, and include resolved-count in the final confirmation line.

### Resolve every finding to a post-change file line (do this before sub-step C)

Both GitHub (`gh api .../comments --field line=NN --field side=RIGHT`) and Azure DevOps (`threadContext.rightFileStart.line`) anchor inline comments to the line number **in the new (post-change) version of the file** — not the line's position within the diff. Mis-anchored comments either land on the wrong line or are rejected (GitHub `422`, Azure DevOps `400`).

In most cases the number is already correct and validated — it was read from the margin of `/tmp/pr_full_diff_numbered.patch` by the reviewers and checked again in step 7's "Validate every finding's line number" step. Do **not** recompute it with hunk arithmetic. Only fall back to manual resolution when a finding somehow arrived without a validated line:

1. Find the flagged line in `/tmp/pr_full_diff_numbered.patch`; the number printed left of the `|` **is** the post-change file line. (The annotator already did the `<newStart>` + offset counting for you, so there is no arithmetic to redo.)
2. If a finding sits on a deleted line (marked `- |`, no surviving `+`/context line), anchor it to the nearest surviving numbered line in the same hunk and note the relocation in the comment body.
3. Confirm the resolved `path` is repo-relative (matches an entry in `/tmp/pr_changed_files.txt`) and the line is within the file's new length (`git show ${HEAD_SHA}:<file> | wc -l`).

### Handle suggestion blocks (enables "Apply suggestion" / "Commit suggestion" button on GitHub)

Sub-agents emit ` ```suggestion ` blocks directly in their finding output (prefixed with an `<!-- suggestion: line NN -->` or `<!-- suggestion: lines NN-MM -->` HTML comment). Include the finding body **verbatim** in the JSONL — the ` ```suggestion ` block is already in the right format for GitHub and no text transformation is needed.

For each finding that contains a suggestion block:

1. Parse the line range from the HTML comment immediately before the ` ```suggestion ` fence:
   - `<!-- suggestion: line NN -->` → single-line: `suggestion_start_line = NN`, `suggestion_end_line = NN`
   - `<!-- suggestion: lines NN-MM -->` → multi-line: `suggestion_start_line = NN`, `suggestion_end_line = MM`
2. Include those values as `suggestion_start_line` / `suggestion_end_line` in the JSONL entry — the posting loop uses them to set `start_line` in the GitHub API call for multi-line suggestions.
3. Copy the **entire finding body verbatim** (including the HTML comment and the ` ```suggestion ` block) into the JSONL `body` field. **Do not strip or transform it.** GitHub renders the ` ```suggestion ` block as the "Commit suggestion" button automatically.

If a finding has no ` ```suggestion ` block, omit `suggestion_start_line` and `suggestion_end_line`. The body is still copied verbatim.

The reviewers were already instructed (step 6) to return post-change line numbers, but verify here — a wrong line number is the single most common cause of silently dropped inline comments.

Read and follow the instructions in the appropriate provider file:
- **GitHub** → `providers/github.md`
- **Azure DevOps** → `providers/azure-devops.md` (sub-step C is the loop in **§4 — MANDATORY**, not the one-off example)
- **Bitbucket or Unknown Platform** → `providers/generic.md`

> **Blocking vs non-blocking on CRITICAL findings:** by **default** a `REQUEST CHANGES` verdict is posted as a *non-blocking* review (GitHub `--comment`, Azure DevOps vote `-5`) so the plugin runs in advisory / shadow mode out of the box. To make `REQUEST CHANGES` *blocking* (GitHub `--request-changes`, Azure DevOps vote `-10`), set `PR_REVIEWER_BLOCK_ON_CRITICAL=true`. Verdict, report body, and inline comments are identical in both modes — only the platform-side review type changes. Provider files contain the exact mapping logic.

### Post-posting self-check (do this before printing the confirmation line)

Determine `EXPECTED_INLINE`: in **initial mode** it is the count of findings in the report with a `path/to/file.ext:NN` reference (sum across Critical Issues, Warnings, Suggestions); in **re-review mode** it is the size of the **New** bucket only (carried-over findings are intentionally not re-posted). Then compare against the inline-thread counter exported by the provider (`INLINE_OK` on Azure DevOps; the count of successful `gh api .../comments` POSTs on GitHub).

- If `INLINE_OK` is `0` and `EXPECTED_INLINE` is `> 0`: posting failed silently. Surface the failure log (`/tmp/pr_inline_failures.log` on Azure DevOps) and treat the run as a partial failure.
- If `INLINE_OK` is much smaller than `EXPECTED_INLINE`: read the failure log and either retry the failed ones or include them in the output diagnostic.

After posting, output a single confirmation line that uses the **actual** inline count, not a hard-coded one. In re-review mode also report the reconciliation outcome:

```
# initial mode
Review posted on PR #<number>: <verdict> — <INLINE_OK>/<EXPECTED_INLINE> inline comments — <URL>

# re-review mode
Re-review posted on PR #<number>: <verdict> — <INLINE_OK>/<EXPECTED_INLINE> new — <RESOLVED_OK> resolved — <carried_over count> still open — <URL>
```

If `INLINE_OK < EXPECTED_INLINE`, append a second line:

```
WARN: <EXPECTED_INLINE - INLINE_OK> inline comment(s) failed to post — see /tmp/pr_inline_failures.log
```

If posting is not possible (generic/unknown platform), output:

```
Review complete: <verdict> — report written to pr-review-report.md
```
