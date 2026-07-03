#!/usr/bin/env python3
"""reconcile.py — deterministic reconciliation of current findings against prior findings,
plus a deterministic verdict. Implements the bucket rules from commands/pr-review.md §7
("Reconcile against the prior review") verbatim, and the report-template.md verdict mapping
table made fully mechanical (any open CRITICAL -> REQUEST CHANGES; else any open WARNING ->
NEEDS DISCUSSION; else any SUGGESTION -> APPROVE WITH SUGGESTIONS; else APPROVE).

Inputs:
    /tmp/pr_review_state.json     (from gather-context.sh)
    /tmp/pr_findings.json         (written by the LLM after verifying sub-agent findings —
                                    a JSON list of {file, line, severity, fid, body, issue})
    /tmp/pr_prior_findings.jsonl  (from gather-context.sh's prior-review detection;
                                    one JSON object per prior marked finding thread:
                                    {fid, status(open|resolved), thread_ref[, comment_ref], file})

Output:
    /tmp/pr_reconcile.json:
    {
      "verdict": "APPROVE" | "APPROVE WITH SUGGESTIONS" | "REQUEST CHANGES" | "NEEDS DISCUSSION",
      "fixed": [...],                  # prior findings to reply-and-resolve
      "carried_over": [...],           # prior findings still open, no action
      "unreviewed_carried_over": [...],# prior findings not re-reviewed this push, no action
      "new": [...],                    # current findings to post as new inline threads
      "counts": {"fixed": N, "carried_over": N, "unreviewed_carried_over": N, "new": N}
    }

In initial mode (no prior review), every current finding is "new" and there is no delta —
this script still runs (fixed/carried_over/unreviewed_carried_over are simply empty), so the
caller never has to special-case initial vs. rereview when reading the output.
"""
import json
import sys

STATE_FILE = "/tmp/pr_review_state.json"
FINDINGS_FILE = "/tmp/pr_findings.json"
PRIOR_FINDINGS_FILE = "/tmp/pr_prior_findings.jsonl"
OUTPUT_FILE = "/tmp/pr_reconcile.json"


def load_jsonl(path):
    items = []
    try:
        with open(path) as f:
            for line in f:
                line = line.strip()
                if line:
                    items.append(json.loads(line))
    except FileNotFoundError:
        pass
    return items


def compute_verdict(open_findings):
    severities = {f.get("severity", "").lower() for f in open_findings}
    if "critical" in severities:
        return "REQUEST CHANGES"
    if "warning" in severities:
        return "NEEDS DISCUSSION"
    if "suggestion" in severities:
        return "APPROVE WITH SUGGESTIONS"
    return "APPROVE"


def main():
    with open(STATE_FILE) as f:
        state = json.load(f)

    try:
        with open(FINDINGS_FILE) as f:
            current_findings = json.load(f)
    except FileNotFoundError:
        current_findings = []

    prior_findings = load_jsonl(PRIOR_FINDINGS_FILE)

    current_fids = {f["fid"] for f in current_findings if f.get("fid")}
    prior_by_fid = {f["fid"]: f for f in prior_findings if f.get("fid")}

    push_update_mode = bool(state.get("push_update_mode"))
    incremental_files = set()
    if push_update_mode and state.get("incremental_changed_files"):
        try:
            with open(state["incremental_changed_files"]) as f:
                incremental_files = {line.strip() for line in f if line.strip()}
        except FileNotFoundError:
            pass

    fixed, carried_over, unreviewed_carried_over = [], [], []

    for fid, prior in prior_by_fid.items():
        if prior.get("status") == "resolved":
            continue  # already-resolved: ignore, no action
        if fid in current_fids:
            carried_over.append(prior)  # still flagged: leave open, don't duplicate
            continue
        # Open prior finding, not present in current findings.
        prior_file = prior.get("file", "")
        was_rereviewed = (not push_update_mode) or (prior_file in incremental_files) or not prior_file
        if was_rereviewed:
            fixed.append(prior)
        else:
            unreviewed_carried_over.append(prior)

    new = [f for f in current_findings if f.get("fid") not in prior_by_fid]

    # Verdict reflects the finding set at HEAD after reconciliation: carried-over + new
    # (fixed findings no longer count; unreviewed carried-over findings are still open).
    carried_over_fids = {p["fid"] for p in carried_over} | {p["fid"] for p in unreviewed_carried_over}
    open_findings = [f for f in current_findings if f.get("fid") in current_fids] + [
        p for p in prior_by_fid.values() if p["fid"] in carried_over_fids
    ]
    # carried_over/unreviewed_carried_over prior entries don't carry severity — pull it from
    # the matching current finding when available (carried_over only; unreviewed have none by
    # definition, so they're treated as at most a WARNING-level open item to stay conservative).
    severity_lookup = {f["fid"]: f.get("severity", "") for f in current_findings if f.get("fid")}
    normalized_open = []
    for f in current_findings:
        if f.get("fid") in current_fids:
            normalized_open.append(f)
    for p in unreviewed_carried_over:
        normalized_open.append({"severity": severity_lookup.get(p["fid"], "warning")})

    verdict = compute_verdict(normalized_open)

    result = {
        "verdict": verdict,
        "fixed": fixed,
        "carried_over": carried_over,
        "unreviewed_carried_over": unreviewed_carried_over,
        "new": new,
        "counts": {
            "fixed": len(fixed),
            "carried_over": len(carried_over),
            "unreviewed_carried_over": len(unreviewed_carried_over),
            "new": len(new),
        },
    }

    with open(OUTPUT_FILE, "w") as f:
        json.dump(result, f, indent=2)

    summary = dict(result["counts"])
    summary["verdict"] = verdict
    print(json.dumps(summary, indent=2))


if __name__ == "__main__":
    main()
