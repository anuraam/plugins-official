#!/usr/bin/env python3
"""compute-fid.py — deterministic finding-id hashing.

Verbatim port of the `compute_fid()` helper from commands/pr-review.md (see
"Comment markers and finding identity"). This MUST stay byte-identical to that algorithm:
PRs already in production have fids computed by it, and re-review reconciliation matches
prior vs. current findings by `fid` alone. Any drift here breaks matching against comments
already posted on live PRs.

fid = first 12 hex chars of sha1(lowercased repo-relative path + "|" + normalized issue text)
Normalization: lowercase, keep [a-z0-9 ], collapse whitespace runs, trim.

Usage:
    compute-fid.py <file> <issue-text>
    compute-fid.py --batch < findings.jsonl   # each line: {"file": ..., "issue": ...}
                                                # prints back each line with "fid" added
"""
import sys
import re
import hashlib
import json


def compute_fid(path: str, issue_text: str) -> str:
    path = path.strip().lower()
    issue = re.sub(r"[^a-z0-9 ]", " ", issue_text.lower())
    issue = re.sub(r"\s+", " ", issue).strip()
    return hashlib.sha1(f"{path}|{issue}".encode()).hexdigest()[:12]


def main():
    if len(sys.argv) == 2 and sys.argv[1] == "--batch":
        for line in sys.stdin:
            line = line.strip()
            if not line:
                continue
            obj = json.loads(line)
            obj["fid"] = compute_fid(obj["file"], obj["issue"])
            print(json.dumps(obj))
        return

    if len(sys.argv) != 3:
        print("usage: compute-fid.py <file> <issue-text>", file=sys.stderr)
        print("       compute-fid.py --batch < findings.jsonl", file=sys.stderr)
        sys.exit(2)

    print(compute_fid(sys.argv[1], sys.argv[2]))


if __name__ == "__main__":
    main()
