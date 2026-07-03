#!/usr/bin/env bash
# lib/platform.sh — detect the hosting platform from the git remote.
#
# Sourced by gather-context.sh. Defines detect_platform(), which sets
# the global PLATFORM to one of: github | azuredevops | bitbucket | generic.
#
# Ported from commands/pr-review.md step 1 — do not duplicate this logic
# elsewhere; every script that needs the platform sources this file.

detect_platform() {
  local remote_url
  remote_url=$(git remote get-url origin 2>/dev/null || echo "")

  if [ -z "$remote_url" ]; then
    echo "ERROR: could not resolve git remote 'origin' — not inside a git repository, or no origin configured." >&2
    return 1
  fi

  if echo "$remote_url" | grep -q "github.com"; then
    PLATFORM="github"
  elif echo "$remote_url" | grep -qE "dev\.azure\.com|visualstudio\.com"; then
    PLATFORM="azuredevops"
  elif echo "$remote_url" | grep -q "bitbucket.org"; then
    PLATFORM="bitbucket"
  else
    PLATFORM="generic"
  fi

  REMOTE_URL="$remote_url"
  export PLATFORM REMOTE_URL
}
