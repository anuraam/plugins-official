#!/usr/bin/env bash
# compute-fid.sh — deterministic finding id from file path + issue summary.
#
# Usage:
#   bash "${CLAUDE_PLUGIN_ROOT}/scripts/compute-fid.sh" <file> <issue-text>
#   # or source and call: compute_fid <file> <issue-text>
#
# fid = first 12 hex of sha1( lowercased repo-relative path + "|" + normalised issue text )
# Normalisation: lowercase, keep [a-z0-9 ], collapse runs of whitespace, trim.

set -euo pipefail

compute_fid() {
  python3 - "$1" "$2" <<'PY'
import sys, re, hashlib
path = sys.argv[1].strip().lower()
issue = re.sub(r'[^a-z0-9 ]', ' ', sys.argv[2].lower())
issue = re.sub(r'\s+', ' ', issue).strip()
print(hashlib.sha1(f"{path}|{issue}".encode()).hexdigest()[:12])
PY
}

# When executed (not sourced), require two args and print the fid.
if [ "${BASH_SOURCE[0]}" = "${0}" ]; then
  if [ "$#" -lt 2 ]; then
    echo "Usage: $0 <file> <issue-text>" >&2
    exit 1
  fi
  compute_fid "$1" "$2"
fi
