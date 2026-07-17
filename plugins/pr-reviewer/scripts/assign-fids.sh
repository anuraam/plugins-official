#!/usr/bin/env bash
# assign-fids.sh — fill missing fid fields on /tmp/pr_inline_findings.jsonl.
#
# Usage:
#   bash "${CLAUDE_PLUGIN_ROOT}/scripts/assign-fids.sh"
#
# Each finding needs fid = compute-fid(file, issue-summary). Uses `issue` /
# first line of `body` as the issue text when `fid` is absent.

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
FINDINGS="${FINDINGS:-/tmp/pr_inline_findings.jsonl}"
FID_SCRIPT="${SCRIPT_DIR}/compute-fid.sh"

[ -f "$FINDINGS" ] || { echo "ERROR: missing $FINDINGS" >&2; exit 1; }
[ -f "$FID_SCRIPT" ] || { echo "ERROR: missing $FID_SCRIPT" >&2; exit 1; }

if [ ! -s "$FINDINGS" ]; then
  echo "No findings — nothing to assign"
  exit 0
fi

python3 - "$FINDINGS" "$FID_SCRIPT" <<'PY'
import hashlib, json, os, re, subprocess, sys, tempfile

path, fid_script = sys.argv[1:3]

def compute_fid(file_path, issue):
    # Mirror compute-fid.sh normalisation
    p = file_path.strip().lower()
    issue_n = re.sub(r"[^a-z0-9 ]", " ", issue.lower())
    issue_n = re.sub(r"\s+", " ", issue_n).strip()
    return hashlib.sha1(f"{p}|{issue_n}".encode()).hexdigest()[:12]

assigned = 0
kept = []
with open(path, encoding="utf-8", errors="replace") as f:
    for line in f:
        line = line.strip()
        if not line:
            continue
        obj = json.loads(line)
        if not obj.get("fid"):
            file_path = (obj.get("file") or obj.get("path") or "").strip()
            issue = (obj.get("issue") or "").strip()
            if not issue:
                body = obj.get("body") or ""
                # Prefer **Issue:** / ISSUE: line, else first non-empty line
                m = re.search(r"(?:\*\*Issue:\*\*|ISSUE:)\s*(.+)", body, re.I)
                if m:
                    issue = m.group(1).strip().splitlines()[0]
                else:
                    for bl in body.splitlines():
                        bl = bl.strip()
                        if bl and not bl.startswith("#") and not bl.startswith("```"):
                            issue = bl.lstrip("-* ").strip()
                            break
            if file_path and issue:
                obj["fid"] = compute_fid(file_path, issue)
                assigned += 1
        kept.append(obj)

fd, tmp = tempfile.mkstemp(prefix="pr_fid_", suffix=".jsonl")
os.close(fd)
with open(tmp, "w", encoding="utf-8") as out:
    for obj in kept:
        out.write(json.dumps(obj, ensure_ascii=False) + "\n")
os.replace(tmp, path)
print(f"Assigned fid on {assigned}/{len(kept)} findings")
PY
