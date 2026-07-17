#!/usr/bin/env bash
# reconcile-prior-findings.sh — classify current vs prior findings by fid (step 7).
#
# Why this exists as a real script: fid set-ops are deterministic; agents invent
# incomplete buckets or re-post carried-over findings as duplicates.
#
# Usage:
#   bash "${CLAUDE_PLUGIN_ROOT}/scripts/reconcile-prior-findings.sh"
#
# Inputs:
#   /tmp/pr_inline_findings.jsonl   — current findings (must include fid)
#   /tmp/pr_prior_findings.jsonl    — from detect-review-mode / *-detect-prior
#   /tmp/pr_state.env               — REVIEW_MODE, HEAD_SHA, RANGE_BASE
#   /tmp/pr_open_threads.jsonl      — optional; for line±5 dedup
#
# Outputs:
#   /tmp/pr_reconcile.json          — {fixed, carried_over, new}
#   Rewrites /tmp/pr_inline_findings.jsonl to only the New bucket (re-review)
#   Dedup may also drop findings overlapping open threads (DEDUP_SUPPRESSED)
#   Prints summary counts; appends RECONCILE_* to /tmp/pr_state.env
#
# Note: external-thread "addressed vs still_open" judgment stays with the agent
# (needs reading code). This script only does fid buckets + line±5 dedup.

set -euo pipefail

# shellcheck disable=SC1091
[ -f /tmp/pr_state.env ] && source /tmp/pr_state.env

CURRENT="${CURRENT:-/tmp/pr_inline_findings.jsonl}"
PRIOR="${PRIOR:-/tmp/pr_prior_findings.jsonl}"
OPEN="${OPEN:-/tmp/pr_open_threads.jsonl}"
OUT="${OUT:-/tmp/pr_reconcile.json}"
REVIEW_MODE="${REVIEW_MODE:-initial}"
HEAD_SHA="${HEAD_SHA:-}"
RANGE_BASE="${RANGE_BASE:-}"

[ -f "$CURRENT" ] || { echo "ERROR: missing $CURRENT" >&2; exit 1; }
[ -f "$PRIOR" ] || : > "$PRIOR"
[ -f "$OPEN" ] || : > "$OPEN"

python3 - "$CURRENT" "$PRIOR" "$OPEN" "$OUT" "$REVIEW_MODE" "${HEAD_SHA:-}" "${RANGE_BASE:-}" <<'PY'
import json, os, sys, tempfile

current_path, prior_path, open_path, out_path, mode, head_sha, range_base = sys.argv[1:8]

def load_jsonl(path):
    rows = []
    if not os.path.isfile(path) or os.path.getsize(path) == 0:
        return rows
    with open(path, encoding="utf-8", errors="replace") as f:
        for line in f:
            line = line.strip()
            if not line:
                continue
            try:
                rows.append(json.loads(line))
            except json.JSONDecodeError:
                continue
    return rows

current = load_jsonl(current_path)
prior = load_jsonl(prior_path)
open_threads = load_jsonl(open_path)

# Enrich prior rows missing file/line from open_threads (same thread_ref)
threads_by_ref = {}
for t in open_threads:
    ref = t.get("thread_ref") or t.get("thread_id")
    if ref is not None:
        threads_by_ref[ref] = t
for p in prior:
    if p.get("file") or p.get("path"):
        continue
    ref = p.get("thread_ref") or p.get("thread_id")
    t = threads_by_ref.get(ref) if ref is not None else None
    if t:
        p["file"] = t.get("file") or t.get("path") or ""
        if p.get("line") is None:
            p["line"] = t.get("line")

current_by_fid = {}
for c in current:
    fid = c.get("fid")
    if fid:
        current_by_fid[fid] = c

prior_by_fid = {}
for p in prior:
    fid = p.get("fid")
    if not fid:
        continue
    # Skip already-resolved prior findings for the Fixed bucket
    status = (p.get("status") or p.get("thread_status") or "open").lower()
    prior_by_fid[fid] = {**p, "_status": status}

fixed, carried, new = [], [], []

if mode == "rereview" and prior_by_fid:
    for fid, p in prior_by_fid.items():
        if p.get("_status") in ("resolved", "fixed", "wontfix", "closed"):
            continue  # Already-resolved — ignore
        if fid in current_by_fid:
            carried.append({
                "fid": fid,
                "file": p.get("file") or p.get("path"),
                "line": p.get("line"),
                "thread_ref": p.get("thread_ref") or p.get("thread_id") or p.get("node_id"),
                "comment_ref": p.get("comment_ref") or p.get("comment_id") or p.get("id"),
            })
        else:
            fixed.append({
                "fid": fid,
                "file": p.get("file") or p.get("path"),
                "line": p.get("line"),
                "thread_ref": p.get("thread_ref") or p.get("thread_id") or p.get("node_id"),
                "comment_ref": p.get("comment_ref") or p.get("comment_id") or p.get("id"),
            })
    for fid, c in current_by_fid.items():
        if fid not in prior_by_fid:
            new.append(c)
    # Current findings without fid — treat as new
    for c in current:
        if not c.get("fid"):
            new.append(c)
else:
    # initial mode: everything is new
    new = list(current)
    carried = []
    fixed = []

# Dedup new findings against open threads (file + line±5)
dedup_suppressed = 0
surviving = []
for c in new:
    cfile = (c.get("file") or c.get("path") or "").strip()
    try:
        cline = int(c.get("line") or 0)
    except (TypeError, ValueError):
        cline = 0
    overlap = False
    for t in open_threads:
        tfile = (t.get("file") or t.get("path") or "").strip()
        if not cfile or not tfile or cfile != tfile:
            continue
        try:
            tline = int(t.get("line") or 0)
        except (TypeError, ValueError):
            tline = 0
        if cline and tline and abs(cline - tline) <= 5:
            # In rereview, carried-over plugin threads are already excluded from new;
            # still suppress duplicates against any open thread.
            overlap = True
            break
    if overlap:
        dedup_suppressed += 1
        continue
    surviving.append(c)

new = surviving

report = {
    "fixed": fixed,
    "carried_over": carried,
    "new": [
        {
            "fid": n.get("fid"),
            "file": n.get("file") or n.get("path"),
            "line": n.get("line"),
        }
        for n in new
    ],
    "dedup_suppressed": dedup_suppressed,
    "review_mode": mode,
    "head_sha": head_sha,
    "range_base": range_base,
}

with open(out_path, "w", encoding="utf-8") as f:
    json.dump(report, f, indent=2)
    f.write("\n")

# In re-review, rewrite findings JSONL to New bucket only (what posting should send)
if mode == "rereview":
    fd, tmp = tempfile.mkstemp(prefix="pr_new_", suffix=".jsonl")
    os.close(fd)
    with open(tmp, "w", encoding="utf-8") as out:
        for n in new:
            out.write(json.dumps(n, ensure_ascii=False) + "\n")
    os.replace(tmp, current_path)

print(
    f"Reconcile ({mode}): fixed={len(fixed)} carried_over={len(carried)} "
    f"new={len(new)} dedup_suppressed={dedup_suppressed}"
)
print(f"Wrote {out_path}")

# Emit shell-friendly counts on last lines for the wrapper
print(f"FIXED_COUNT={len(fixed)}")
print(f"CARRIED_COUNT={len(carried)}")
print(f"NEW_COUNT={len(new)}")
print(f"DEDUP_SUPPRESSED={dedup_suppressed}")
PY

FIXED_COUNT=$(python3 -c "import json; d=json.load(open('$OUT')); print(len(d.get('fixed',[])))")
CARRIED_COUNT=$(python3 -c "import json; d=json.load(open('$OUT')); print(len(d.get('carried_over',[])))")
NEW_COUNT=$(python3 -c "import json; d=json.load(open('$OUT')); print(len(d.get('new',[])))")
DEDUP_SUPPRESSED=$(python3 -c "import json; d=json.load(open('$OUT')); print(d.get('dedup_suppressed',0))")

{
  echo "export FIXED_COUNT=$(printf %q "$FIXED_COUNT")"
  echo "export CARRIED_COUNT=$(printf %q "$CARRIED_COUNT")"
  echo "export NEW_COUNT=$(printf %q "$NEW_COUNT")"
  echo "export DEDUP_SUPPRESSED=$(printf %q "$DEDUP_SUPPRESSED")"
} >> /tmp/pr_state.env

# Optional re-review delta stub for the report body
if [ "$REVIEW_MODE" = "rereview" ]; then
  COMMIT_COUNT=0
  if [ -n "${RANGE_BASE:-}" ] && [ -n "${HEAD_SHA:-}" ]; then
    COMMIT_COUNT=$(git rev-list --count "${RANGE_BASE}..${HEAD_SHA}" 2>/dev/null || echo 0)
  fi
  cat > /tmp/pr_rereview_delta.md <<EOF
### Re-review delta
Reviewed ${COMMIT_COUNT} new commit(s) since the last review (\`${RANGE_BASE}\`..\`${HEAD_SHA}\`).
- ✅ Fixed: ${FIXED_COUNT} previously-flagged issue(s) resolved
- ⏳ Still open: ${CARRIED_COUNT} carried-over issue(s)
- 🆕 New: ${NEW_COUNT} issue(s) introduced since the last review
EOF
  echo "Wrote /tmp/pr_rereview_delta.md"
fi

exit 0
