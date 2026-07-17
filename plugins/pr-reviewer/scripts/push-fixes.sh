#!/usr/bin/env bash
# push-fixes.sh — env-scoped credential push for --fix mode.
#
# Why this exists as a real script: agents invent credential helpers that write
# tokens to disk or echo them into the transcript. This scopes the token to one
# git push via GIT_CONFIG_* and never prints the secret.
#
# Usage:
#   bash "${CLAUDE_PLUGIN_ROOT}/scripts/push-fixes.sh"
#
# Inputs:
#   origin remote
#   GITHUB_TOKEN / AZURE_DEVOPS_TOKEN (platform-appropriate)
#
# Outputs:
#   Pushes HEAD to origin. Exit non-zero on failure.
#   Never echoes token values.

set -euo pipefail

REMOTE_URL=$(git remote get-url origin 2>/dev/null || echo "")
[ -n "$REMOTE_URL" ] || { echo "ERROR: no git remote origin" >&2; exit 1; }

REMOTE_HOST=$(echo "$REMOTE_URL" | sed -E 's|^[a-z+]+://||; s|^[^@/]+@||; s|[:/].*$||')

case "$REMOTE_URL" in
  *dev.azure.com*|*visualstudio.com*)
    PUSH_TOKEN="${AZURE_DEVOPS_TOKEN:-}"
    # Re-export dashed alias if needed
    if [ -z "$PUSH_TOKEN" ] && compgen -e | grep -qx 'AZURE-DEVOPS-TOKEN'; then
      PUSH_TOKEN="$(printenv AZURE-DEVOPS-TOKEN)"
      export AZURE_DEVOPS_TOKEN="$PUSH_TOKEN"
    fi
    TOKEN_NAME=AZURE_DEVOPS_TOKEN
    ;;
  *github.com*)
    PUSH_TOKEN="${GITHUB_TOKEN:-${GH_TOKEN:-}}"
    TOKEN_NAME=GITHUB_TOKEN
    ;;
  *)
    echo "ERROR: unknown remote host — cannot choose push token" >&2
    exit 1
    ;;
esac

echo "${TOKEN_NAME}=${PUSH_TOKEN:+yes}"
[ -n "$PUSH_TOKEN" ] || {
  echo "ERROR: ${TOKEN_NAME} unset — required for fix-mode push (see docs/git-auth.md)" >&2
  exit 1
}

echo "Pushing HEAD to origin (host=${REMOTE_HOST})…"
GIT_CONFIG_COUNT=1 \
GIT_CONFIG_KEY_0="url.https://x-access-token:${PUSH_TOKEN}@${REMOTE_HOST}/.insteadOf" \
GIT_CONFIG_VALUE_0="https://${REMOTE_HOST}/" \
git push origin HEAD

echo "Push OK: $(git rev-parse --short HEAD)"
exit 0
