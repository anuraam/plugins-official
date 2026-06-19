# PR Description Template

This template defines the structure of the description the orchestrator writes to `/tmp/pr_description.md` and uses to **completely replace** the PR's title and body (see the appropriate `providers/*.md`). Every section is regenerated from the *current, cumulative* diff each run — there is no "changelog of pushes" section and no "Update N" framing.

The orchestrator populates this template from `change-analyst`'s structured findings (`agents/change-analyst.md`) and `knowledge-curator`'s repository profile (`agents/knowledge-curator.md`). Section names below map directly onto `change-analyst`'s output sections — do not rename or reorder them.

---

## Title

A single line, present tense, describing what the PR does as a whole — not a changelog of commits.

- Prefer: `Add response caching to the user lookup endpoint`
- Avoid: `Fix stuff`, `Update UserService.ts`, `WIP`, `PR #42`

If the **existing** PR title (read in orchestrator step 2) already accurately describes the cumulative change, keep it. Otherwise replace it — do not append "(updated)" or similar.

---

## Body Structure

```markdown
## Summary

[1-3 sentences: what this PR does and why, synthesized from change-analyst's
"Change Summary" + "Why". This is the only place "why" appears as prose --
don't repeat it verbatim in "What Changed".]

## What Changed

### [Area/Module name]
- [Plain-language description of what's different now]
- ...

### [Area/Module name]
- ...

[One subsection per area/module from change-analyst's "What Changed",
in the same grouping and order change-analyst produced. If change-analyst
identified only one area, a single subsection is fine -- don't force
multiple headings.]

## How / Approach

[From change-analyst's "How / Approach". Omit this entire section --
heading included -- if change-analyst returned
"No notable implementation notes beyond the change summary."]

## Testing

- **New/updated tests:** [...]
- **Areas without test coverage:** [...] (omit this bullet if change-analyst
  found none)

## Risk & Impact

- **Breaking changes:** [...] (or "None identified")
- **Migration steps:** [...] (omit this bullet if "None")
- **Areas to watch:** [...] (omit this bullet if none beyond what's already
  described above)

## Related Work

- [reference 1]
- [reference 2]
...

[Omit this entire section -- heading included -- if change-analyst found
no references. Every reference change-analyst found in the existing
description or commit log MUST appear here, verbatim, including its
closing keyword (Fixes/Closes/Resolves) if present -- this is the one
piece of continuity a full rewrite must preserve.]
```

---

## Rendering Rules

1. **Idempotent.** Re-running this agent on a PR whose diff hasn't changed should produce essentially the same title and body — same sections, same content, modulo trivial wording variance. Do not include run-specific noise (timestamps, "regenerated at...", run IDs) anywhere in the body.
2. **Cumulative, not incremental.** Describe the PR as it stands now versus the base branch. Never frame a section as "new in this update" or "since last time" — there is no concept of "since last time" in the output.
3. **Omit empty sections entirely** (heading and all) rather than writing "N/A" or "Nothing to report" — except where this template explicitly specifies a fallback phrase (e.g. "None identified").
4. **Confidence carries through.** If `change-analyst` phrased something as an inference, keep it phrased as an inference (e.g. "This appears to...") — do not launder inferences into stated facts.
5. **Knowledge-base notes never appear in the description.** `change-analyst`'s "New Observations for Knowledge Base" section is consumed only by `knowledge-curator` in orchestrator step 8 — it must never be rendered into `/tmp/pr_description.md`.
6. **No verdicts, no severity tags, no checkboxes.** This is a description, not a review — there is no `APPROVE`/`REQUEST CHANGES`, no `CRITICAL`/`WARNING`/`SUGGESTION`, and no `- [ ]` task list items.
7. **Length matches PR size.** Use `change-analyst`'s "Scope" (Small/Medium/Large) as a guide — a Small-scope PR's description should be a few short paragraphs, not a forced multi-section essay. Sections with little to say should be brief, not padded.

See `styles/description-style.md` for tone, formatting, and language conventions.
