# Output Style: Bug Verification Report (verify mode)

This style guide defines the exact format of the bug verification comment posted by the `orchestrator` agent when running in **verify mode** (`/verify-bug`). It is the verify-mode counterpart of `report-template.md` and follows the same philosophy: a strictly bounded, factual record — nothing else.

---

## Audience

The comment is posted **on the bug itself** (Azure DevOps work item or GitHub issue) and is read by the bug's reporter, the assigned developer, and QA. Write step descriptions in plain business language — describe what was done in the app, not which Playwright API was called.

---

## The Three Verdicts

| Verdict | Meaning |
|---|---|
| ❌ **STILL REPRODUCIBLE** | The decisive check ran and the bug's reported behaviour (`BUG_SIGNAL`) was observed |
| ✅ **NOT REPRODUCIBLE — appears fixed** | Every plan step executed AND the decisive check positively observed the expected behaviour (`FIXED_SIGNAL`) |
| ⚪ **INCONCLUSIVE** | Anything else — a step was BLOCKED before the decisive check, auth or environment failure, neither signal observed, a precondition was missing, or the outcome was ambiguous |

Wording rules:

- Always "appears fixed" / "not reproducible on {env}" — **never** an unqualified "fixed".
- A blocked run is never reported as fixed. If the path to the decisive check did not fully execute, the verdict is INCONCLUSIVE regardless of what was seen.

---

## Comment Structure

```markdown
🤖 web-app-tester — Bug Verification Report
Verdict: {❌ STILL REPRODUCIBLE | ✅ NOT REPRODUCIBLE — appears fixed | ⚪ INCONCLUSIVE}
Environment: {env name or URL} | Role: {role, or "none (unauthenticated)"} | Verified: {ISO 8601 UTC timestamp}
{IF read-only} ⚠️ Environment is read-only — mutating steps were skipped.{END IF}

**Decisive observation:** {one sentence: at step N, expected "<FIXED_SIGNAL>", observed "<what was actually seen>"}
{embedded decisive screenshot — Azure DevOps only; GitHub: the observation sentence carries the evidence}

<details><summary>Executed steps ({X}/{N} passed)</summary>

{one line per step: Step N — ✅/❌/🔴 {business-language description} ({duration}s)}

</details>
```

Field rules:

- **Verdict** — exactly one of the three values above, with the matching emoji.
- **Environment** — the environment name when the URL came from `.web-app-tester.json` (e.g. `staging`); otherwise the URL tested.
- **Role** — the storage-state role used, or `none (unauthenticated)` when no storage state was applied.
- **Decisive observation** — one sentence naming the step number, the expected signal, and what was observed. This is the single load-bearing line of the report; it must be specific enough to stand alone.
- **Decisive screenshot** — Azure DevOps: uploaded via the attachments API and embedded as `![decisive](<url>)`. GitHub: no attachment support via the CLI — the decisive observation is described inline instead.
- **Executed steps** — every step from the verification plan, in order, one line each, inside the collapsed `<details>` block. Use the same three status emoji as test mode (✅ passed / ❌ failed / 🔴 blocked).

For an **INCONCLUSIVE** verdict posted autonomously, use the brief neutral form instead of the full template:

```markdown
🤖 web-app-tester — automated verification could not run: {reason}
```

---

## Report Boundaries (strictly enforced — identical to report-template.md)

✅ **Allowed and required:**

- The verdict, environment, role, and timestamp
- The decisive observation — expected signal vs. observed outcome, factually stated
- One factual line per executed step

❌ **Prohibited anywhere in the comment:**

- Suggested fixes, workarounds, or "you should try…" statements
- Root cause analysis, or speculation about **why** the bug is or is not fixed
- Recommendations, next steps, or action items
- Code snippets, diffs, stack traces, selectors, or snapshot dumps
- Unqualified "fixed" claims
- Credentials, tokens, cookie values, or storage-state contents — under any circumstances

The comment is always a **single comment** — never split across multiple comments.
