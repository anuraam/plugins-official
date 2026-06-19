# Report Guide

The `impact-analyst` plugin produces a **self-contained 14-section HTML report** written to `impact-analysis-{YYYY-MM-DD}-{id}.html`. This guide explains each section, the risk and badge system, and how to act on the output.

---

## Opening the Report

The report opens in any browser — no server required. It is print-ready for A4 and Letter paper sizes.

```
impact-analysis-2025-04-22-pr87.html
```

---

## Risk Levels

Every report carries an overall **risk badge** set by the `risk-assessor` agent. The orchestrator never overrides it.

| Badge | Level | Meaning |
|---|---|---|
| 🔴 **Critical** | 4 | High-confidence failure scenario, no test coverage, wide blast radius |
| 🟠 **High** | 3 | Multiple risk dimensions elevated, significant user exposure |
| 🟡 **Medium** | 2 | Moderate complexity or integration surface, some coverage gaps |
| 🟢 **Low** | 1 | Narrow blast radius, strong coverage, low complexity |

Risk is rated across **8 dimensions**: change impact, implementation complexity, change frequency, test coverage, integration density, data sensitivity, user exposure, and blast radius.

---

## Section Reference

### 1 — Summary

The at-a-glance view: overall risk badge, test case counts per category, blast radius label, linked PRs, and a fast-path label if the trivial PR shortcut was applied.

Use this to decide how much QA effort to allocate before reading the rest of the report.

### 2 — Context Gathered

Everything the plugin found and used: linked PRs, child work items, referenced documentation files, and commit messages. This section makes the analysis auditable — you can verify that the agent saw what it should have.

### 3 — Code Changes Overview

A card per changed file showing: file path, change category, change magnitude, and per-file risk rating. Categories include `logic`, `data-model`, `api-contract`, `config`, `ui`, `test`, `docs`, and `infra`.

Use this to quickly locate the highest-risk files before reading the dependency map.

### 4 — Blast Radius & Dependency Map

Produced by `dependency-tracer`. Contains:

- **Direct callers table** — functions and modules that call into the changed code
- **Data flow table** — data moving through the changed code (inputs, transformations, outputs)
- **External integrations** — third-party services, queues, or APIs touched by the changes
- **Blast radius label** — `Isolated`, `Moderate`, or `Wide`

A `Wide` blast radius means many callers or data flows cross module or service boundaries. This section informs the scope of regression testing.

### 5 — Affected Features & User Journeys

Produced by `feature-mapper`. Lists:

- API routes and HTTP methods affected
- UI pages and components affected
- Named user journeys that pass through the changed code
- Business workflows impacted
- Features confirmed safe (confirmed-not-affected list)

Use this with product owners to agree on the QA scope before sprint testing.

### 6 — Requirements Coverage

Maps each requirement or acceptance criterion to the code changes that implement it. Requires a linked work item or issue. Renders as **N/A** when the plugin is run against a PR with no linked work item.

A requirement listed here with **no linked code change** is flagged in section 8.

### 7 — Developer Changes Requiring Clarification

Unexplained changes — modified code that does not map to any requirement or acceptance criterion. Each entry has a category badge (`logic`, `data-model`, etc.) and a plain-language description of what changed.

Bring these items to the developer before testing. They may be intentional refactors, or they may be unintended changes.

### 8 — Missing Requirement Coverage

Requirements or acceptance criteria with no corresponding code change found. Requires a linked work item. Renders as **N/A** when there is no work item.

These are gaps — either the implementation is incomplete, or the requirement was addressed in a different PR.

### 9 — Business Risk Assessment

The full risk matrix from `risk-assessor`:

- Risk rating per dimension (1–4) with a plain-language justification
- Critical and high-priority test scenarios (named business scenarios, not just test IDs)
- Edge cases that are likely to fail under real usage
- Regression risks — areas likely to break from indirect effects
- Data integrity concerns for changes that touch storage or data flows

This section is written for **product owners and non-technical stakeholders**. Avoid paraphrasing it in Jira tickets — link the HTML report directly.

### 10 — Test Cases

Structured test cases across up to seven categories, each in `TC-NNN` format:

| Field | Content |
|---|---|
| ID | `TC-001`, `TC-002`, … |
| Title | Plain-language test objective |
| Priority | `P0` (critical), `P1` (high), `P2` (medium) |
| Linked requirement | The acceptance criterion or risk this case covers |
| Preconditions | State required before the test can run |
| Steps | Numbered, executable steps |
| Test data | Specific values, accounts, or payloads needed |
| Expected result | Observable outcome that passes the test |

**Categories and when they appear:**

| Category | Condition |
|---|---|
| 🟢 Functional | Always |
| 🔵 Performance | Service, query, or pipeline changes (omit with `--no-perf`) |
| 🔴 Security | Auth, input validation, API, or permission changes |
| 🟡 Privacy & PII | Personal, financial, or health data handling |
| 🟣 Accessibility & Usability | Any UI change (omit with `--no-a11y`) |
| ⚪ Resilience | Service calls, queues, external dependencies |
| 🟤 Compatibility | Public APIs, shared schemas, integration contracts |

Categories with no realistic surface in the change set are skipped automatically.

### 11 — Coverage Map

Two cross-reference tables:

- **Requirement → Test Cases** — which TCs cover each acceptance criterion
- **Risk → Test Cases** — which TCs address each identified risk

Includes an **out-of-scope** list: risks or requirements that were deliberately excluded from test case generation, with a reason.

Use this to confirm that every acceptance criterion has at least one test case before sign-off.

### 12 — Impacted Areas

A summary table of all areas of the system affected by the change, rated High / Medium / Low with a brief rationale. Written in business language, not file paths.

Use this as the basis for deciding which environments to regression test and which SMEs to loop in.

### 13 — Environment & Assignment

Produced from `requirement-collector` data. Contains:

- Assigned developer and tester
- Iteration / sprint
- Test data requirements (accounts, datasets, environment state)
- Environment prerequisites (feature flags, configuration, service versions)

Renders as **N/A** when there is no linked work item.

### 14 — QA Sign-off

Interactive checkboxes — one per test case category. Check each category as testing completes. The checkboxes are part of the HTML document and persist within the browser tab.

Print the signed-off report as a PDF to attach to the work item for audit purposes.

---

## Fast-Path Reports

When the trivial PR fast-path is applied, sections 4, 5, 6, 7, 8, and 11 are abbreviated or empty. The report notes this in the Summary section with a **Fast-path: Trivial PR** label. Only `change-analyst` and `risk-assessor` ran — blast radius and feature impact were not computed.

---

## Sharing the Report

| Platform | How the report is delivered |
|---|---|
| GitHub | Markdown summary comment posted to the PR or issue; full HTML written locally |
| Azure DevOps | HTML attached to the work item; notification comment posted |
| Generic | HTML written locally only |

To share on platforms that do not support file attachments, open the HTML file and use **File → Print → Save as PDF** in the browser, then attach the PDF.
