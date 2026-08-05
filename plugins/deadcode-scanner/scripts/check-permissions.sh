#!/usr/bin/env bash
# check-permissions.sh — preflight auth + capability check for fix-writer.
#
# Run BEFORE creating the worktree, installing dependencies, or running
# `knip --fix` — so a missing/unauthenticated gh/az CLI is caught immediately
# instead of surfacing at PR-creation time after the expensive work is done.
# Only relevant when a real PR will be opened; skip entirely for
# FIX_DRY_RUN=true (dry-run never pushes or creates a PR).
#
# Usage:
#   bash check-permissions.sh <repo-path>
#
# Inputs:
#   origin remote (authoritative platform)
#   gh auth / az account   — platform CLI authentication
#
# Outputs:
#   /tmp/deadcode_permissions.env   — PLATFORM, AUTH_OK, PERMISSIONS_WARNINGS
#   exit 0 = safe to proceed to the worktree + fix + PR flow
#   exit 1 = hard failure (stop fix-writer; see docs/platform-setup.md)

set -uo pipefail

REPO="${1:?usage: check-permissions.sh <repo-path>}"
ENV_FILE="/tmp/deadcode_permissions.env"
WARNINGS=""

warn() { WARNINGS="${WARNINGS}${WARNINGS:+; }$1"; echo "WARN: $1"; }
fail() {
  echo "PERMISSIONS CHECK FAILED: $1 (see docs/platform-setup.md)" >&2
  {
    echo "export PLATFORM=$(printf %q "${PLATFORM:-unknown}")"
    echo "export AUTH_OK=false"
    echo "export PERMISSIONS_WARNINGS=$(printf %q "$WARNINGS")"
  } > "$ENV_FILE"
  exit 1
}

if ! git -C "$REPO" rev-parse --is-inside-work-tree >/dev/null 2>&1; then
  fail "'$REPO' is not a git working tree"
fi
cd "$REPO" || fail "cannot cd into '$REPO'"

ORIGIN_URL=$(git remote get-url origin 2>/dev/null || true)
[ -n "$ORIGIN_URL" ] || fail "no 'origin' remote configured"

case "$ORIGIN_URL" in
  *github.com*)                       PLATFORM=github ;;
  *dev.azure.com*|*visualstudio.com*) PLATFORM=azure-devops ;;
  *)                                  PLATFORM=generic ;;
esac
echo "PLATFORM=$PLATFORM (from origin)"

case "$PLATFORM" in
  github)
    if ! command -v gh >/dev/null 2>&1; then
      fail "'gh' CLI not installed — required to open the draft PR"
    fi
    if ! gh auth status >/dev/null 2>&1; then
      fail "'gh' is not authenticated — run 'gh auth login' or set GITHUB_TOKEN/GH_TOKEN"
    fi
    echo "OK: gh CLI present and authenticated"
    if ! gh repo view --json nameWithOwner >/dev/null 2>&1; then
      warn "'gh' authenticated but cannot read this repo's metadata — PR creation may fail"
    fi
    ;;
  azure-devops)
    if ! command -v az >/dev/null 2>&1; then
      fail "'az' CLI not installed — required to open the draft PR"
    fi
    if ! az extension show --name azure-devops >/dev/null 2>&1; then
      warn "'az devops' extension not detected — install with 'az extension add --name azure-devops'"
    fi
    if [ -z "${AZURE_DEVOPS_TOKEN:-}" ] && ! az account show >/dev/null 2>&1; then
      fail "no Azure DevOps auth found — set AZURE_DEVOPS_TOKEN or run 'az login'"
    fi
    echo "OK: az CLI present and authenticated"
    ;;
  generic)
    warn "origin is neither GitHub nor Azure DevOps — the branch will be pushed but no PR can be opened automatically"
    ;;
esac

{
  echo "export PLATFORM=$(printf %q "$PLATFORM")"
  echo "export AUTH_OK=true"
  echo "export PERMISSIONS_WARNINGS=$(printf %q "$WARNINGS")"
} > "$ENV_FILE"

echo "PERMISSIONS CHECK PASSED (platform=$PLATFORM)"
[ -n "$WARNINGS" ] && echo "Warnings: $WARNINGS"
exit 0
