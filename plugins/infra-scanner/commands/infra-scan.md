---
name: infra-scan
description: Run an authorized infrastructure security scan. Covers Infrastructure-as-Code misconfigurations (Dockerfile, Terraform, Kubernetes, GitHub Actions), SBOM generation, and optional network port + TLS scanning when a target URL is supplied. Produces infra-report.html, infra-report.md, and infra-report.json locally. Usage: /infra-scan [target-url] --authorized [options]
argument-hint: [target-url] --authorized [--publish <github|azure-devops|slack>]
---

Run an infrastructure security scan against the current repository and (optionally) `$ARGUMENTS`.

## IMPORTANT — Authorization Required

The `--authorized` flag confirms you have permission to scan. Without it the command refuses to run. If a `target-url` is provided, you also confirm permission to network-probe that host.

## What This Does

This command invokes the **orchestrator** agent which coordinates:

| Agent | Focus |
|---|---|
| `iac-scanner` | Dockerfiles, Terraform, Kubernetes manifests, GitHub Actions workflows |
| `sbom-generator` | CycloneDX Software Bill of Materials via trivy or syft |
| `network-scanner` | Open ports, service fingerprinting, TLS certificate validity (only runs when a `target-url` is supplied) |

The **report-writer** then compiles findings into structured reports.

## Usage Examples

```bash
# Full infra scan with network probe
/infra-scan https://staging.myapp.com --authorized

# Code-only scan (no network probe)
/infra-scan --authorized

# Publish summary to GitHub
/infra-scan https://staging.myapp.com --authorized --publish github
```

## Output

- `infra-report.html` — styled HTML report
- `infra-report.md` — Markdown report
- `infra-report.json` — canonical JSON
- `infra-sbom.json` — CycloneDX SBOM (if generator succeeded)
- `infra-evidence/` — raw tool outputs (nmap XML, trivy JSON, hadolint JSON, etc.)

## Prerequisites

### Required

| Tool | Min Version | Notes |
|---|---|---|
| `nmap` | 7.80+ | Only required when scanning a target URL |

### Optional (plugin degrades gracefully if absent)

| Tool | Purpose |
|---|---|
| `hadolint` | Dockerfile linting |
| `tfsec` | Terraform scanning |
| `checkov` | Terraform/k8s scanning |
| `kubesec` | Kubernetes manifest risk scoring |
| `trivy` | SBOM + container config |
| `syft` | SBOM generation (fallback) |

## Related

For web-application penetration testing (OWASP web probes, SAST, secrets, dependency CVEs), see [/pentest](../pentest-agent/commands/pentest.md).

---

Starting infrastructure scan now...
