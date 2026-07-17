#!/usr/bin/env bash
# lib-resolve.sh — locate pr-reviewer scripts when CLAUDE_PLUGIN_ROOT is unset.
#
# In Xianix Executor / Claude Code Bash tools, CLAUDE_PLUGIN_ROOT is often NOT
# exported (hooks get it; agent Bash often does not). Plugins may live under
# CLAUDE_CONFIG_DIR or /workspace/repo/xianix-claude-config instead of ~/.claude.
#
# Usage (from a Bash tool call):
#   # Prefer sourcing after first discovery writes /tmp/pr_plugin.env
#   # shellcheck disable=SC1091
#   [ -f /tmp/pr_plugin.env ] && source /tmp/pr_plugin.env
#   source "$(…/lib-resolve.sh)"   # only if you already know the path
#
# Or call the exported function after pasting the resolve body from pr-review.md.
#
# Writes /tmp/pr_plugin.env with CLAUDE_PLUGIN_ROOT when a script is found.

resolve_pr_script() {
  local name="$1"
  local cand root

  # 0. Cached root from a prior tool call
  if [ -f /tmp/pr_plugin.env ]; then
    # shellcheck disable=SC1091
    source /tmp/pr_plugin.env
  fi
  if [ -n "${CLAUDE_PLUGIN_ROOT:-}" ] && [ -f "${CLAUDE_PLUGIN_ROOT}/scripts/${name}" ]; then
    echo "${CLAUDE_PLUGIN_ROOT}/scripts/${name}"
    return 0
  fi

  # 1. Direct CLAUDE_PLUGIN_ROOT
  if [ -n "${CLAUDE_PLUGIN_ROOT:-}" ] && [ -f "${CLAUDE_PLUGIN_ROOT}/scripts/${name}" ]; then
    echo "${CLAUDE_PLUGIN_ROOT}/scripts/${name}"
    return 0
  fi

  # 2. Glob plugin caches (Claude Code + Xianix Executor layouts). Prefer highest version via sort -V.
  # shellcheck disable=SC2086
  for cand in \
    ${CLAUDE_CONFIG_DIR:+$CLAUDE_CONFIG_DIR/plugins/cache/*/pr-reviewer/*/scripts/$name} \
    ${HOME:+$HOME/.claude/plugins/cache/*/pr-reviewer/*/scripts/$name} \
    /workspace/repo/xianix-claude-config/plugins/cache/*/pr-reviewer/*/scripts/"$name" \
    /workspace/*/xianix-claude-config/plugins/cache/*/pr-reviewer/*/scripts/"$name"
  do
    [ -f "$cand" ] || continue
    echo "$cand"
    return 0
  done

  # 3. find fallback (bounded roots — avoid walking entire disk)
  cand=$(find \
    ${CLAUDE_PLUGIN_ROOT:+"$CLAUDE_PLUGIN_ROOT"} \
    ${CLAUDE_CONFIG_DIR:+"$CLAUDE_CONFIG_DIR/plugins"} \
    ${HOME:+"$HOME/.claude/plugins"} \
    /workspace/repo/xianix-claude-config/plugins \
    -path "*/pr-reviewer/scripts/${name}" \
    2>/dev/null | sort -V | tail -1)
  if [ -n "${cand:-}" ] && [ -f "$cand" ]; then
    echo "$cand"
    return 0
  fi

  return 1
}

# Persist plugin root next to a resolved script path.
remember_pr_plugin_root() {
  local script_path="$1"
  local root
  root="$(cd "$(dirname "$script_path")/.." && pwd)"
  export CLAUDE_PLUGIN_ROOT="$root"
  printf 'export CLAUDE_PLUGIN_ROOT=%q\n' "$root" > /tmp/pr_plugin.env
  echo "CLAUDE_PLUGIN_ROOT=$root (wrote /tmp/pr_plugin.env)"
}
