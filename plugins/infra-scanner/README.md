# infra-scanner

Authorized infrastructure security scanning plugin. Companion to [pentest-agent](../pentest-agent/README.md) — covers the infrastructure surface (IaC, SBOM, network ports/TLS) that pentest-agent v3.0+ deliberately leaves out so it can focus on web-application pentesting.

## What It Does

| Category | Tools Used | What It Checks |
|---|---|---|
| IaC Security | `hadolint`, `tfsec`, `checkov`, `kubesec` | Dockerfile, Terraform, Kubernetes, GitHub Actions misconfigurations |
| SBOM Generation | `trivy`, `syft` | CycloneDX Software Bill of Materials for supply-chain compliance |
| Network Scanning | `nmap`, `openssl` | Open ports, service versions, TLS certificate validity and expiry |

## Quick Start

```bash
# Full infra scan with network probe
/infra-scan https://staging.myapp.com --authorized

# Code-only scan (no network probe — no URL needed)
/infra-scan --authorized
```

The `--authorized` flag is **required**.

## Output

| File | Description |
|---|---|
| `infra-report.html` | Styled HTML with severity grid |
| `infra-report.md` | Plain Markdown |
| `infra-report.json` | Machine-readable canonical output |
| `infra-sbom.json` | CycloneDX SBOM (if trivy or syft is installed) |
| `infra-evidence/` | Raw tool outputs (nmap XML, trivy JSON, hadolint JSON, etc.) |

## Architecture

```
orchestrator
├── Phase 0: Authorization gate + setup
├── Phase 1 (parallel):
│   ├── iac-scanner       Dockerfile, Terraform, k8s, GHA misconfigs
│   ├── sbom-generator    CycloneDX SBOM via trivy/syft
│   └── network-scanner   nmap + TLS check (only when target URL given)
└── Phase 2:
    └── report-writer     Merges JSON, applies suppression, writes reports
```

## Suppressing Findings (`.infra-ignore`)

```
# Exact ID
IAC-DOCKER-LATEST-TAG

# Wildcard
IAC-GHA-*
```

## Prerequisites

### Required (only when scanning a network target)

- `nmap` 7.80+

### Optional

- `hadolint`, `tfsec`, `checkov`, `kubesec`, `trivy`, `syft` — install whichever match the IaC types in your repo

## Related

For **web application** penetration testing — OWASP Top 10 probes, SAST, secrets detection, dependency CVEs, and source-code recon that drives the URL probing — install [pentest-agent](../pentest-agent/README.md). The two plugins are designed to be used together when you need both infra and web coverage.

## License

MIT — Copyright (c) Xianix
