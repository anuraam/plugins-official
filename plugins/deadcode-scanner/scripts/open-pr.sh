#!/usr/bin/env bash
# open-pr.sh — open a draft PR for an already-pushed deadcode-fix branch
# (GitHub / Azure DevOps), or resolve a best-effort compare URL when no
# platform CLI is available or authenticated. Assumes the branch is already
# pushed to origin — this script never pushes.
#
# Usage:
#   bash open-pr.sh <worktree-dir> <default-branch> <branch-name> <title> <body-file>
#
# Outputs (stdout, and written to /tmp/deadcode_pr_result.env as `export` lines):
#   PR_STATUS   pr-opened | branch-pushed-no-pr
#   PR_URL      the draft PR URL, or a best-effort compare URL as a fallback
#               (empty when neither can be determined, e.g. non-GitHub generic)

set -uo pipefail

WORKTREE_DIR="${1:?usage: open-pr.sh <worktree-dir> <default-branch> <branch-name> <title> <body-file>}"
DEFAULT_BRANCH="${2:?}"
BRANCH_NAME="${3:?}"
TITLE="${4:?}"
BODY_FILE="${5:?}"
ENV_FILE="/tmp/deadcode_pr_result.env"

cd "$WORKTREE_DIR" || { echo "ERROR: cannot cd into '$WORKTREE_DIR'" >&2; exit 1; }
[ -f "$BODY_FILE" ] || { echo "ERROR: body file '$BODY_FILE' not found" >&2; exit 1; }

ORIGIN_URL=$(git remote get-url origin 2>/dev/null || true)
case "$ORIGIN_URL" in
  *github.com*)                       PLATFORM=github ;;
  *dev.azure.com*|*visualstudio.com*) PLATFORM=azure-devops ;;
  *)                                  PLATFORM=generic ;;
esac

PR_URL=""
PR_STATUS="branch-pushed-no-pr"

case "$PLATFORM" in
  github)
    if command -v gh >/dev/null 2>&1 && gh auth status >/dev/null 2>&1; then
      if CREATED=$(gh pr create --base "$DEFAULT_BRANCH" --head "$BRANCH_NAME" --draft \
          --title "$TITLE" --body-file "$BODY_FILE" 2>&1); then
        PR_URL=$(echo "$CREATED" | tail -1)
        echo "$PR_URL" | grep -q '^https://' && PR_STATUS="pr-opened"
      else
        echo "gh pr create failed: $CREATED" >&2
      fi
    else
      echo "gh unavailable or unauthenticated — leaving branch pushed only" >&2
    fi
    ;;
  azure-devops)
    if command -v az >/dev/null 2>&1; then
      if CREATED=$(az repos pr create --source-branch "$BRANCH_NAME" --target-branch "$DEFAULT_BRANCH" \
          --title "$TITLE" --description "$(cat "$BODY_FILE")" --draft true --query 'url' -o tsv 2>&1); then
        PR_URL="$CREATED"
        [ -n "$PR_URL" ] && PR_STATUS="pr-opened"
      else
        echo "az repos pr create failed: $CREATED" >&2
      fi
    else
      echo "az unavailable — leaving branch pushed only" >&2
    fi
    ;;
  generic)
    echo "unrecognized platform — leaving branch pushed only" >&2
    ;;
esac

if [ "$PR_STATUS" != "pr-opened" ] && [ "$PLATFORM" = "github" ]; then
  # Best-effort compare URL fallback. Azure DevOps compare URLs need
  # org/project context this script doesn't have without a working `az`.
  REPO_SLUG=$(echo "$ORIGIN_URL" | sed -E 's#(git@|https://)github\.com[:/]##; s#\.git$##')
  PR_URL="https://github.com/${REPO_SLUG}/compare/${DEFAULT_BRANCH}...${BRANCH_NAME}?expand=1"
fi

{
  echo "export PR_STATUS=$(printf %q "$PR_STATUS")"
  echo "export PR_URL=$(printf %q "$PR_URL")"
} > "$ENV_FILE"

echo "PR_STATUS=$PR_STATUS"
echo "PR_URL=${PR_URL:-<none>}"
