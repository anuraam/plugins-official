#!/usr/bin/env bash
# compute-fid.sh — deterministic finding id from file path + on-disk snippet.
#
# Usage:
#   bash "${CLAUDE_PLUGIN_ROOT}/scripts/compute-fid.sh" <file> <snippet-text> <occurrence-index>
#   # or source and call: compute_fid <file> <snippet-text> <occurrence-index>
#
# fid = first 12 hex of sha1( lowercased repo-relative path + "|" + normalised
#       on-disk snippet text + "|" + occurrence-index )
# Normalisation: lowercase, keep [a-z0-9 ], collapse runs of whitespace, trim.
#
# Snippet is the literal on-disk text at the finding's flagged line (not the
# LLM-authored issue sentence — that's regenerated per run and unstable across
# re-reviews). occurrence-index is the 1-based rank of this finding among all
# findings in the same run sharing (file, normalised snippet), used to
# disambiguate duplicate lines. Both are deterministic and reproducible from
# disk content alone, which is what makes reconcile-prior-findings.sh's Gate B
# possible — see that script for the re-verification that depends on this.

set -euo pipefail

compute_fid() {
  python3 - "$1" "$2" "$3" <<'PY'
import sys, re, hashlib
path = sys.argv[1].strip().lower()
snippet = re.sub(r'[^a-z0-9 ]', ' ', sys.argv[2].lower())
snippet = re.sub(r'\s+', ' ', snippet).strip()
occurrence = sys.argv[3].strip()
print(hashlib.sha1(f"{path}|{snippet}|{occurrence}".encode()).hexdigest()[:12])
PY
}

# When executed (not sourced), require three args and print the fid.
if [ "${BASH_SOURCE[0]}" = "${0}" ]; then
  if [ "$#" -lt 3 ]; then
    echo "Usage: $0 <file> <snippet-text> <occurrence-index>" >&2
    exit 1
  fi
  compute_fid "$1" "$2" "$3"
fi
