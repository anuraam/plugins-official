#!/usr/bin/env bash
# validate-prerequisites.sh
# PreToolUse hook for infra-scanner. Hard-blocks if nmap is missing AND a Bash
# command tries to invoke it. Soft-allows all optional tools (the scanners
# degrade gracefully when an optional tool is absent).

set -euo pipefail

INPUT=$(cat)
COMMAND=$(echo "$INPUT" | grep -o '"command":"[^"]*"' | head -1 | cut -d'"' -f4 2>/dev/null || echo "")

if ! echo "$COMMAND" | grep -qE "^(nmap |hadolint |tfsec |checkov |kubesec |trivy |syft |openssl |nslookup |dig )"; then
    exit 0
fi

version_gte() {
    local installed="$1"
    local required="$2"
    [ "$(printf '%s\n%s' "$required" "$installed" | sort -V | head -1)" = "$required" ]
}

# Hard block: nmap is required when invoked
if echo "$COMMAND" | grep -qE "^nmap "; then
    if ! command -v nmap > /dev/null 2>&1; then
        echo '{"decision": "block", "reason": "nmap is required for network scanning but not installed. Install: brew install nmap (macOS), apt install nmap (Linux), winget install nmap (Windows)."}'
        exit 0
    fi
    NMAP_VER=$(nmap --version 2>/dev/null | head -1 | grep -oE '[0-9]+\.[0-9]+' | head -1 || echo "0.0")
    if ! version_gte "$NMAP_VER" "7.80"; then
        echo "{\"decision\": \"block\", \"reason\": \"nmap $NMAP_VER is below minimum required version 7.80. Please upgrade nmap.\"}"
        exit 0
    fi
fi

# Soft block: optional tools — allow but allow scan to proceed when missing
for OPTIONAL in hadolint tfsec checkov kubesec trivy syft; do
    if echo "$COMMAND" | grep -qE "^${OPTIONAL} "; then
        if ! command -v "$OPTIONAL" > /dev/null 2>&1; then
            exit 0
        fi
    fi
done

exit 0
