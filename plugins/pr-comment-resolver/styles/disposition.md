# PR Comment Resolution Output Style Guide

This file defines the formatting and tone conventions for all output produced by the `pr-comment-resolver` plugin.

---

## General Principles

- Be **transparent** — every disposition must include a clear reason
- Be **concise** — replies should be 1–3 sentences maximum
- Be **specific** — reference the file path and line number in every reply
- Avoid filler phrases: "Great point!", "Thanks for the feedback", "As an AI..."
- Never be defensive or apologetic when declining — be neutral and factual

---

## Disposition Labels

Use these labels consistently:

| Label | When to use |
|---|---|
| `APPLY` | Clear, unambiguous code change that was applied and committed |
| `DISCUSS` | Change requires human judgement — design tradeoff, unclear intent, conflicting requirements |
| `DECLINE` | Change is factually incorrect, conflicts with an accepted decision, or is out of scope |
| `DECLINE (non-code)` | Comment does not request a code change (discussion, praise, process question) |

---

## Reply Templates

### Apply reply (posted after committing)

> Applied in commit [<short-sha>](<commit-url>): <one-line description of what was changed>.

`<commit-url>` is the platform commit URL (see the providers' "Linking to Commits" section). On generic remotes, where no URL exists, use the bare short SHA instead. Never wrap the SHA in backticks — that suppresses GitHub's autolinking.

### Discuss reply

> This requires a design decision that goes beyond automated resolution: <one sentence explaining the ambiguity or tradeoff>. Please discuss with the team and update or resolve this thread manually.

### Decline reply

> Declining: <one sentence explaining why — factually incorrect, conflicts with <decision/file>, or out of scope for this PR>.

### Decline (non-code) reply

> This comment does not request a code change and is outside the scope of automated resolution.

### Marker (all replies)

Every reply body ends with `<!-- pr-comment-resolver:v1 reply -->` on its own line. It renders invisibly; later runs use it to skip threads that are already dispositioned. Never omit it.

---

## Summary Comment Format

The summary comment posted at the end must follow the template in `styles/report-template.md` exactly.

---

## Tone

- Use **neutral, technical language** — this is automated output, not a human conversation
- When declining, state the reason without hedging: "This conflicts with the pattern in `auth/middleware.ts`" not "This might potentially conflict..."
- When discussing, be specific about what the human needs to decide: name the tradeoff
- Commit messages use imperative mood: "fix: apply null check" not "fixed null check"
