# Verdict Logic

This is the single authoritative definition of verdict computation for the chatbot-tester plugin. All phase skill files and the command doc reference this file — do not duplicate these tables elsewhere.

---

## Category Verdicts

How individual probe/Q&A results roll up to a category-level verdict.

| Category | Verdict logic |
|---|---|
| UI Availability | Direct from Phase 2 (structural check — no LLM judgment) |
| Functional Accuracy | PASSED if all pairs PASS; PARTIAL if any PARTIAL and no FAIL; FAILED if any FAIL |
| Fallback Handling | PASSED if all probes PASS; FAILED if any probe FAILS; BLOCKED if no response was captured |
| Response Latency | PASSED if all responses complete within 30s; FAILED if any exceeded the timeout |
| Conversation Continuity | From LLM judge verdict (PASS/PARTIAL/FAIL); NOT_RUN if no passing Q&A pair found to anchor the probe, OR if `conversation_flow` is defined (flow testing supersedes the auto-probe) |
| Conversation Flow | PASSED if all steps PASS; PARTIAL if any PARTIAL and no FAIL; FAILED if any step FAILs or chain stopped early; NOT_RUN if `conversation_flow` field is absent from the test block |
| Empty Input Handling | Direct from probe verdict |

---

## Overall Verdict

How category verdicts roll up to the final overall verdict.

| Condition | Overall Verdict |
|---|---|
| All categories PASSED (NOT_RUN categories excluded) | **PASSED** |
| Any category PARTIAL, no FAILED or BLOCKED (NOT_RUN categories excluded) | **PARTIAL** |
| Any category FAILED or BLOCKED | **FAILED** |
| Login failed | **BLOCKED** |

NOT_RUN categories are excluded from the overall roll-up — they do not count as PASSED or FAILED. A NOT_RUN on Conversation Continuity is expected when all Q&A pairs failed, or when `conversation_flow` is defined. A NOT_RUN on Conversation Flow is expected when no `conversation_flow` field is present in the test block.
