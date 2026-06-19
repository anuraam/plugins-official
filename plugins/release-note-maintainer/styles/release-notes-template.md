# Release Notes Template

This template defines the section structure for every release notes document produced by the Release Note Maintainer Agent. The agent fills each section based on the `release-analyst` output and the repository's knowledge profile.

---

## Section Order and Content

### 1. Title

```
## <tag> — <human-readable title>
```

Use `Release <tag>` as the default title. Follow the knowledge profile's "Release Note Style Notes" if it specifies a preferred format (e.g. `<product> <version>`).

If the tag is a prerelease (`-(rc|beta|alpha|preview|dev)` suffix), insert a warning line immediately after the title:

```
> **Not recommended for production use.** This is a pre-release build.
```

---

### 2. Release Date

```
**Released:** <YYYY-MM-DD>
```

Use the date the tag was created (`git log -1 --format='%as' "${CURRENT_TAG}"`).

---

### 3. Summary

Two to four sentences. Written for an end-user or operator reading the changelog — state what this release does in plain terms. Do not list every change; do not reference commit hashes or PR numbers here. The knowledge profile's "Release Note Style Notes" may specify a preferred tone.

---

### 4. Breaking Changes

_Omit this section entirely if there are no breaking changes._

```
## Breaking Changes

- **<area or component>:** <what changed and what callers must do differently>
```

One bullet per breaking change. Lead with the affected area in bold, then describe the change in plain terms. Do not use severity tags or risk scores. Always place this section before Features when present.

---

### 5. Features

_Omit this section if there are no new features in this release._

```
## Features

- <one bullet per feature — what it does, not how it's implemented>
```

Group by component or area if five or more features are present.

---

### 6. Bug Fixes

_Omit this section if there are no bug fixes._

```
## Bug Fixes

- <one bullet per fix — the symptom that was fixed, not the root cause>
```

---

### 7. Improvements

_Omit this section if there are no improvements or performance changes._

```
## Improvements

- <one bullet — performance, reliability, observability, or DX improvement>
```

---

### 8. Deprecations

_Omit this section if there are no deprecations._

```
## Deprecations

- **<item>:** Deprecated in <tag>. Use <replacement> instead. Removal is planned for <next major, if known>.
```

---

### 9. Contributors

_Omit if the commit window has only one contributor, or if no contributor data is available._

```
## Contributors

Thanks to <comma-separated display names> for contributions in this release.
```

List all contributors deduped, bots excluded. Do not link to profiles.

---

### 10. Related Work Items

_Omit if no work items, issue references, or ticket IDs were found in the commit window._

```
## Related Work Items

- #<number> / <TICKET-ID>: <title or short description>
```

---

## Rendering Rules

1. **Omit empty sections** — never render a section header with no content.
2. **Past tense** — "Added support for X", "Fixed a crash when Y", not "Adds" or "Fix".
3. **No diffs or code snippets** unless a breaking change requires a migration example.
4. **No internal implementation detail** — callers should not need to know which function changed.
5. **No PR numbers or commit hashes** in the rendered output — work item references are the correct cross-reference mechanism.
6. **Chores are omitted** — dependency bumps, CI config changes, and test-only changes are never shown in the output.
7. **Knowledge profile notes never appear verbatim** in the rendered output — they guide voice and structure only.
