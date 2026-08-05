#!/usr/bin/env bash
# detect-platform.sh — resolve hosting platform, default branch, and any
# existing open deadcode-fix/* PR/branch for a repo.
#
# Usage:
#   bash detect-platform.sh <repo-path>
#   source /tmp/deadcode_platform.env   # after running, to pick up exports
#
# Outputs (stdout, and written to /tmp/deadcode_platform.env as `export` lines):
#   PLATFORM        github | azure-devops | generic
#   DEFAULT_BRANCH  resolved default branch of origin
#   OPEN_FIX_REF    non-empty ref/branch name if a deadcode-fix/* PR or branch
#                   already exists (caller should skip Phase 3 in that case)
#
# Exit non-zero only when the repo/origin cannot be resolved at all — an
# unrecognized platform is not a failure, it resolves to "generic".

set -uo pipefail

REPO="${1:?usage: detect-platform.sh <repo-path>}"
ENV_FILE="/tmp/deadcode_platform.env"

if ! git -C "$REPO" rev-parse --is-inside-work-tree >/dev/null 2>&1; then
  echo "ERROR: '$REPO' is not a git working tree" >&2
  exit 1
fi
cd "$REPO" || exit 1

ORIGIN_URL=$(git remote get-url origin 2>/dev/null || true)
if [ -z "$ORIGIN_URL" ]; then
  echo "ERROR: no 'origin' remote configured on '$REPO'" >&2
  exit 1
fi

case "$ORIGIN_URL" in
  *github.com*)                       PLATFORM=github ;;
  *dev.azure.com*|*visualstudio.com*) PLATFORM=azure-devops ;;
  *)                                  PLATFORM=generic ;;
esac

DEFAULT_BRANCH=$(git symbolic-ref refs/remotes/origin/HEAD 2>/dev/null | sed 's|refs/remotes/origin/||')
if [ -z "$DEFAULT_BRANCH" ]; then
  DEFAULT_BRANCH=$(git remote show origin 2>/dev/null | grep "HEAD branch" | awk '{print $NF}')
fi
[ -z "$DEFAULT_BRANCH" ] && DEFAULT_BRANCH="main"

# One deadcode-fix PR at a time. Prefer the platform CLI (it distinguishes
# open vs. closed/merged); fall back to a plain remote-branch check when the
# CLI is missing or unauthenticated, since a pushed branch is still evidence
# of a prior run worth surfacing to the caller.
OPEN_FIX_REF=""
case "$PLATFORM" in
  github)
    if command -v gh >/dev/null 2>&1; then
      OPEN_FIX_REF=$(gh pr list --state open --json headRefName --jq '.[].headRefName' 2>/dev/null | grep '^deadcode-fix/' | head -1 || true)
    fi
    ;;
  azure-devops)
    if command -v az >/dev/null 2>&1; then
      OPEN_FIX_REF=$(az repos pr list --status active --query "[?starts_with(sourceRefName, 'refs/heads/deadcode-fix/')].sourceRefName | [0]" -o tsv 2>/dev/null || true)
    fi
    ;;
esac
if [ -z "$OPEN_FIX_REF" ]; then
  OPEN_FIX_REF=$(git ls-remote --heads origin 'deadcode-fix/*' 2>/dev/null | awk '{print $2}' | sed 's|refs/heads/||' | head -1 || true)
fi

{
  echo "export PLATFORM=$(printf %q "$PLATFORM")"
  echo "export DEFAULT_BRANCH=$(printf %q "$DEFAULT_BRANCH")"
  echo "export OPEN_FIX_REF=$(printf %q "$OPEN_FIX_REF")"
} > "$ENV_FILE"

echo "PLATFORM=$PLATFORM  DEFAULT_BRANCH=$DEFAULT_BRANCH  OPEN_FIX_REF=${OPEN_FIX_REF:-<none>}"
echo "Wrote $ENV_FILE"
