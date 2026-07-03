#!/usr/bin/env python3
"""resolve-line.py — deterministic diff-position -> post-change file:line resolution.

Why this exists: reviewer sub-agents used to be asked to compute the post-change file line
number themselves from the `@@ -old,+new @@` hunk header math. The docs already documented
this as "the single most common cause of silently dropped inline comments" — it's fiddly
arithmetic an LLM does inconsistently. Sub-agents now report only the line number *within the
diff file they were already given* (trivial and unambiguous — they're reading it top to
bottom), and this script deterministically resolves that to (file, post-change line).

Usage:
    resolve-line.py <diff-file> <diff-line-number>

Prints exactly one line: <repo-relative-file>:<post-change-line>
Exits non-zero with a message on stderr if the target line cannot be resolved at all
(e.g. it points at a `diff --git` header outside any hunk).

Deleted (`-`) lines have no post-change line number of their own — per the existing
documented fallback rule, they resolve to the nearest surviving (`+`/context) line in the
same hunk (forward first, then backward).
"""
import sys


def parse_diff(lines):
    """Returns resolved[i] = (file, new_line_or_None, hunk_id_or_None) for 1-indexed i."""
    resolved = {}
    current_file = None
    new_line = None
    hunk_id = 0
    in_hunk = False

    for idx, raw in enumerate(lines, start=1):
        line = raw.rstrip("\n")

        if line.startswith("diff --git "):
            current_file = None
            in_hunk = False
            resolved[idx] = (None, None, None)
            continue

        if line.startswith("+++ "):
            path = line[4:].strip()
            if path == "/dev/null":
                current_file = None
            elif path.startswith("b/"):
                current_file = path[2:]
            else:
                current_file = path
            in_hunk = False
            resolved[idx] = (current_file, None, None)
            continue

        if line.startswith("--- ") or line.startswith("index "):
            resolved[idx] = (current_file, None, None)
            continue

        if line.startswith("@@"):
            hunk_id += 1
            in_hunk = True
            # @@ -oldStart,oldLen +newStart,newLen @@ optional-context
            try:
                plus_part = line.split("+", 1)[1].split(" ", 1)[0]
                new_start = int(plus_part.split(",")[0])
            except (IndexError, ValueError):
                new_start = 1
            new_line = new_start
            resolved[idx] = (current_file, None, hunk_id)
            continue

        if not in_hunk:
            resolved[idx] = (current_file, None, None)
            continue

        if line.startswith("-"):
            # Deleted line: no new-side line number, still part of this hunk for fallback.
            resolved[idx] = (current_file, None, hunk_id)
            continue

        if line.startswith("+") or line.startswith(" ") or line == "":
            resolved[idx] = (current_file, new_line, hunk_id)
            new_line += 1
            continue

        if line.startswith("\\"):
            # "\ No newline at end of file" — not a content line.
            resolved[idx] = (current_file, None, hunk_id)
            continue

        # Unrecognized line shape inside a hunk — treat as structural, don't advance counter.
        resolved[idx] = (current_file, None, hunk_id)

    return resolved


def resolve(resolved, target, total_lines):
    if target not in resolved:
        return None, f"line {target} is outside the diff file (1..{total_lines})"

    file, new_line, hunk_id = resolved[target]
    if file is None:
        return None, f"line {target} is not inside any file's hunk (diff header/metadata line)"
    if new_line is not None:
        return (file, new_line), None

    if hunk_id is None:
        return None, f"line {target} is not inside any hunk"

    # Fallback: nearest surviving line in the same hunk — forward first, then backward.
    for i in range(target + 1, total_lines + 1):
        f, l, h = resolved.get(i, (None, None, None))
        if h != hunk_id:
            break
        if l is not None:
            return (file, l), None
    for i in range(target - 1, 0, -1):
        f, l, h = resolved.get(i, (None, None, None))
        if h != hunk_id:
            break
        if l is not None:
            return (file, l), None

    return None, f"line {target} is a deleted line with no surviving line in the same hunk"


def main():
    if len(sys.argv) != 3:
        print("usage: resolve-line.py <diff-file> <diff-line-number>", file=sys.stderr)
        sys.exit(2)

    diff_file, target_str = sys.argv[1], sys.argv[2]
    try:
        target = int(target_str)
    except ValueError:
        print(f"ERROR: <diff-line-number> must be an integer, got {target_str!r}", file=sys.stderr)
        sys.exit(2)

    with open(diff_file, "r", errors="replace") as f:
        lines = f.readlines()

    resolved_map = parse_diff(lines)
    result, err = resolve(resolved_map, target, len(lines))

    if err:
        print(f"ERROR: {err}", file=sys.stderr)
        sys.exit(1)

    file, line = result
    print(f"{file}:{line}")


if __name__ == "__main__":
    main()
