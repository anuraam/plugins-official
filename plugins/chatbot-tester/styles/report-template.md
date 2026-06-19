# Output Style: Chatbot Test Report

This style guide defines the exact format of the test report posted by the `orchestrator` agent.

---

## Audience

Reports are read by **developers, QA engineers, and product owners**. Write in plain language — describe what was tested and what the chatbot said, not which Playwright API was called.

---

## Report Structure

```markdown
🤖 chatbot-tester — Test Report
URL tested: {TEST_URL}
Overall: {PASSED | PARTIAL | FAILED}

| Category                | Result                          |
|-------------------------|---------------------------------|
| UI Availability         | ✅ PASSED                       |
| Functional Accuracy     | ⚠️ PARTIAL (3/4 passed)         |
| Fallback Handling       | ✅ PASSED                       |
| Response Latency        | ✅ PASSED (avg 1.2s)            |
| Conversation Continuity | ✅ PASSED                       |
| Conversation Flow       | ✅ PASSED (5/5 steps)           |
| Empty Input Handling    | ✅ PASSED                       |
```

Include the **Conversation Flow** row only when `HAS_CONVERSATION_FLOW=true`. When `HAS_CONVERSATION_FLOW=false`, omit the row entirely — do not show `⬜ NOT RUN` for it.

When `HAS_CONVERSATION_FLOW=true`, the **Conversation Continuity** row shows `⬜ NOT RUN`.

After the summary table, append one section per category that has detail to show. Categories that fully PASSED with no Q&A pairs or notable probes may be omitted. Categories with `NOT RUN` status are never expanded.

**Login-blocked report example** (when login fails, all categories are NOT RUN):

```markdown
🤖 chatbot-tester — Test Report
URL tested: {TEST_URL}
Overall: 🔴 BLOCKED — Login failed

| Category                | Result      |
|-------------------------|-------------|
| UI Availability         | ⬜ NOT RUN  |
| Functional Accuracy     | ⬜ NOT RUN  |
| Fallback Handling       | ⬜ NOT RUN  |
| Response Latency        | ⬜ NOT RUN  |
| Conversation Continuity | ⬜ NOT RUN  |
| Empty Input Handling    | ⬜ NOT RUN  |
```

---

## Lite Mode Callout

Include this section immediately after the summary table when `LITE_MODE=true`:

```markdown
---

> ℹ️ **Partial test only** — Functional Accuracy was skipped because no test case was provided.
> To run a full test, create a GitHub issue or Azure DevOps work item with a `chatbot-test` block and re-run:
> ```
> /test-chatbot https://github.com/owner/repo/issues/<n>
> /test-chatbot https://dev.azure.com/org/project/_workitems/edit/<id>
> ```
```

---

## Special Failure Callouts

### Timeout

When any category or Q&A pair has a detail/response value of `90-second selector timeout — chatbot did not respond in time`, render it as a distinct callout in that category's section:

```markdown
> ⏱️ **Timeout** — No response was detected within 90 seconds. This can mean the AI was still generating a response, or the "response done" selector did not match the page.
```

Use this callout in place of the normal **Bot response:** / **Verdict:** block for that item.

### Response capture failed

When a Q&A pair's `actual_response` is `(response capture failed — no matching bot message element found)`, render:

```markdown
> ⚠️ **Response capture failed** — The bot appeared to respond (the "done" indicator fired) but no matching message element was found in the page. The response selector may need updating for this app.
```

### Script crash (log.txt missing or empty)

When the overall result is a `script_crash` BLOCKED entry, render the report as:

```markdown
🤖 chatbot-tester — Test Report
URL tested: {TEST_URL}
Overall: 🔴 BLOCKED — Script crashed before any results were recorded

### Script output (last 20 lines)

```
{last_20_lines_of_execution.log}
```

No test categories ran. Fix the error above and re-run.
```

---

## Functional Accuracy Section

Always include this section regardless of verdict. Show every Q&A pair as a collapsible block.

```markdown
---

### Functional Accuracy

<details>
<summary>✅ PASSED — "What are your opening hours?"</summary>

**Question sent:** What are your opening hours?
**Must contain:** 9am, 5pm, Monday
**Bot response:**
> We are open Monday to Friday, 9am until 5pm.

**Verdict:** PASS
**Judge reasoning:** Response contains all required terms in the correct context.
**Response time:** 1.4s
</details>

<details>
<summary>⚠️ PARTIAL — "How do I reset my password?"</summary>

**Question sent:** How do I reset my password?
**Must contain:** email, reset link
**Bot response:**
> You can reset your password via email.

**Verdict:** PARTIAL — response mentions email but omits reset link detail.
**Judge reasoning:** Response partially addresses the question but is missing required terms.
**Response time:** 2.1s
</details>

<details>
<summary>❌ FAILED — "What is your refund policy?"</summary>

**Question sent:** What is your refund policy?
**Must contain:** 30 days, receipt
**Bot response:**
> Please contact our support team for help with refunds.

**Verdict:** FAIL
**Judge reasoning:** Response deflects to support without mentioning 30 days or receipt.
**Response time:** 1.8s
</details>
```

---

## Fallback Handling Section

Include if any probe failed or for visibility.

```markdown
---

### Fallback Handling

<details>
<summary>✅ PASSED — Gibberish input</summary>

**Input sent:** asdfghjkl zxcvbnm qwerty
**Bot response:**
> I'm sorry, I didn't quite understand that. Could you rephrase your question?

**Verdict:** PASS — graceful fallback, non-empty response, no crash.
</details>

<details>
<summary>✅ PASSED — Out-of-scope question</summary>

**Input sent:** What is the capital of Mars?
**Bot response:**
> I can only help with questions related to our products and services. Is there something I can assist you with?

**Verdict:** PASS — graceful out-of-scope handling.
</details>
```

---

## Conversation Flow Section

Include this section when `HAS_CONVERSATION_FLOW=true`. Always show all steps — including `NOT_RUN` ones (so the chain stop is visible).

```markdown
---

### Conversation Flow

<details>
<summary>✅ PASSED — Step 1: "What equipment is the Alfa Laval technical documentation for?"</summary>

**Step name:** Equipment identity
**Question sent:** What equipment is the Alfa Laval technical documentation for?
**Expected answer:** It is for BREW 250 PLUS, project E-2221.
**Must contain:** BREW 250 PLUS, E-2221
**Bot response:**
> This documentation covers the BREW 250 PLUS centrifugal separator, project E-2221.

**Verdict:** PASS
**Judge reasoning:** Response contains all required terms in the correct context and aligns with the expected answer.
**Response time:** 2.1s
</details>

<details>
<summary>❌ FAILED — Step 2: "What is the serial number for it?" ⛔ Chain stopped here</summary>

**Step name:** Serial number follow-up
**Question sent:** What is the serial number for it?
**Expected answer:** The serial number is 4279261M.
**Must contain:** 4279261M
**Bot response:**
> I don't have the serial number in the documentation provided.

**Verdict:** FAIL
**Judge reasoning:** Response does not contain the required term 4279261M.
**Response time:** 1.8s

> ⛔ **Chain stopped** — remaining steps were not executed because this step failed.
</details>

<details>
<summary>⬜ NOT RUN — Step 3: "What are the inlet requirements for connection 201.1?"</summary>

**Step name:** Connection 201.1 inlet requirements
**Not executed** — chain stopped at step 2.
</details>
```

When all steps pass, omit the chain-stopped callout. When a step times out, use the standard timeout callout in place of the Bot response / Verdict block.

---

## Other Categories

For Conversation Continuity and Empty Input Handling, include a brief block only if the verdict is not PASSED:

```markdown
---

### Conversation Continuity

**Probe sent:** Can you tell me more about that?
**Bot response:**
> I'm not sure what you're referring to. Could you clarify?

**Verdict:** PARTIAL — bot did not retain context from the previous exchange.
```

---

## Verdict Icons

| Verdict | Icon |
|---|---|
| PASSED | ✅ |
| PARTIAL | ⚠️ |
| FAILED | ❌ |
| BLOCKED | 🔴 |
| NOT RUN | ⬜ |

---

## Safety Rules (always enforced)

1. Never include authentication tokens, passwords, API keys, or secrets in any comment
2. Redact credential values as `[REDACTED]` if they appear anywhere in test data
3. The report is always a single comment — never split across multiple comments

---

## Report Boundaries (strictly enforced)

**The report is strictly bounded to the sections defined above.** Never add:

- Suggested fixes or workarounds
- Recommendations or advice
- Root cause analysis
- Next steps or action items
- Code snippets or diffs
- Explanatory commentary beyond the verdict and judge reasoning

The report is a test execution record, not a debugging guide.
