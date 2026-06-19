# Infrastructure Security Scan Report

**Target:** {{target_url}}
**Scanned at:** {{scan_timestamp}}
**Authorization:** {{authorization_text}}

## Summary

| Severity | Count |
|---|---|
| 🔴 Critical | {{summary.critical}} |
| 🟠 High | {{summary.high}} |
| 🟡 Medium | {{summary.medium}} |
| 🟢 Low | {{summary.low}} |
| ℹ️ Info | {{summary.info}} |

## Agent Status

| Agent | Status | Notes |
|---|---|---|
{{#each agent_statuses}}
| {{key}} | {{status}} | {{reason}} |
{{/each}}

## Findings

Findings ordered Critical → Info. Each finding includes location (file:line or host:port), description, remediation, and evidence.

{{#each findings}}
### [{{severity}}] {{title}}

- **ID:** `{{id}}`
- **Category:** {{category}}
- **Location:** `{{location}}`
- **Description:** {{description}}
- **Remediation:** {{remediation}}
{{#if evidence}}- **Evidence:** `{{evidence}}`{{/if}}
{{#if cve}}- **CVE:** {{cve}}{{/if}}
{{#if cvss}}- **CVSS:** {{cvss.score}} ({{cvss.vector}}){{/if}}
{{/each}}

## Suppressed Findings

{{#if suppressed}}
Findings matched by `.infra-ignore` rules. Excluded from the active count above; listed here for audit purposes.

{{#each suppressed}}
- [{{severity}}] {{title}} (`{{id}}`)
{{/each}}
{{else}}
None.
{{/if}}

## Delta vs Prior Scan

{{#if delta.has_prior}}
- **+{{delta.new_count}} new** findings since last scan
- **-{{delta.resolved_count}} resolved** since last scan
- **·{{delta.persisting_count}} persisting** findings
{{else}}
No prior scan to compare against.
{{/if}}
