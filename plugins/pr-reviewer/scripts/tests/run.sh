#!/usr/bin/env bash
# scripts/tests/run.sh — fixture-based assertions for the deterministic pr-reviewer scripts.
# Plain bash + python3, no framework needed. Run from anywhere:
#   bash scripts/tests/run.sh
set -u
TESTS_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
SCRIPTS_DIR="$(dirname "$TESTS_DIR")"
FIXTURES="$TESTS_DIR/fixtures"

PASS=0
FAIL=0

assert_eq() {
  local desc="$1" expected="$2" actual="$3"
  if [ "$expected" = "$actual" ]; then
    PASS=$((PASS + 1))
    echo "ok   - $desc"
  else
    FAIL=$((FAIL + 1))
    echo "FAIL - $desc"
    echo "       expected: $expected"
    echo "       actual:   $actual"
  fi
}

echo "=== ado_parse_remote — all 4 URL shapes ==="
source "$SCRIPTS_DIR/lib/azure-devops.sh"

_ado_parse_remote_url "https://dev.azure.com/contoso/Web/_git/api"
assert_eq "shape 1: org"        "contoso" "$AZURE_ORG"
assert_eq "shape 1: project"    "Web" "$AZURE_PROJECT"
assert_eq "shape 1: repo"       "api" "$AZURE_REPO"
assert_eq "shape 1: collection" "" "$AZURE_COLLECTION"
assert_eq "shape 1: api_base"   "https://dev.azure.com/contoso/Web" "$API_BASE"

_ado_parse_remote_url "https://dev.azure.com/contoso/MyCollection/Web/_git/api"
assert_eq "shape 2: org"        "contoso" "$AZURE_ORG"
assert_eq "shape 2: collection" "MyCollection" "$AZURE_COLLECTION"
assert_eq "shape 2: project"    "Web" "$AZURE_PROJECT"
assert_eq "shape 2: repo"       "api" "$AZURE_REPO"
assert_eq "shape 2: api_base"   "https://dev.azure.com/contoso/MyCollection/Web" "$API_BASE"

_ado_parse_remote_url "https://contoso.visualstudio.com/Web/_git/api"
assert_eq "shape 3: org"        "contoso" "$AZURE_ORG"
assert_eq "shape 3: project"    "Web" "$AZURE_PROJECT"
assert_eq "shape 3: repo"       "api" "$AZURE_REPO"
assert_eq "shape 3: api_base"   "https://contoso.visualstudio.com/Web" "$API_BASE"

_ado_parse_remote_url "https://contoso.visualstudio.com/DefaultCollection/Web/_git/api"
assert_eq "shape 4 (legacy DefaultCollection): org"        "contoso" "$AZURE_ORG"
assert_eq "shape 4 (legacy DefaultCollection): collection" "DefaultCollection" "$AZURE_COLLECTION"
assert_eq "shape 4 (legacy DefaultCollection): project"    "Web" "$AZURE_PROJECT"
assert_eq "shape 4 (legacy DefaultCollection): api_base"   "https://contoso.visualstudio.com/DefaultCollection/Web" "$API_BASE"

# Embedded basic-auth prefix (as injected by CI runners) must be stripped.
_ado_parse_remote_url "https://azureacc02@dev.azure.com/azureacc02/Xianix%20Platform/_git/TestRepo"
assert_eq "auth-prefix: org"     "azureacc02" "$AZURE_ORG"
assert_eq "auth-prefix: project" "Xianix%20Platform" "$AZURE_PROJECT"
assert_eq "auth-prefix: repo"    "TestRepo" "$AZURE_REPO"

echo
echo "=== gh_parse_remote ==="
source "$SCRIPTS_DIR/lib/github.sh"
_gh_parse_remote_url "https://github.com/acme/widgets.git"
assert_eq "https form: owner" "acme" "$OWNER"
assert_eq "https form: repo"  "widgets" "$REPO"
_gh_parse_remote_url "git@github.com:acme/widgets.git"
assert_eq "ssh form: owner" "acme" "$OWNER"
assert_eq "ssh form: repo"  "widgets" "$REPO"

echo
echo "=== compute-fid.py — pinned known-good hash ==="
FID=$(python3 "$SCRIPTS_DIR/compute-fid.py" "src/auth/login.ts" "SQL injection via unescaped user input")
EXPECTED_FID=$(python3 -c "
import hashlib, re
path = 'src/auth/login.ts'.strip().lower()
issue = re.sub(r'[^a-z0-9 ]', ' ', 'SQL injection via unescaped user input'.lower())
issue = re.sub(r'\s+', ' ', issue).strip()
print(hashlib.sha1(f'{path}|{issue}'.encode()).hexdigest()[:12])
")
assert_eq "fid matches independently-computed reference" "$EXPECTED_FID" "$FID"

FID_A=$(python3 "$SCRIPTS_DIR/compute-fid.py" "a.py" "Null pointer on missing user")
FID_B=$(python3 "$SCRIPTS_DIR/compute-fid.py" "a.py" "  NULL   pointer ON missing user!!")
assert_eq "fid is stable under case/punctuation/whitespace normalization" "$FID_A" "$FID_B"

echo
echo "=== resolve-line.py — diff-line to post-change file:line ==="
R=$(python3 "$SCRIPTS_DIR/resolve-line.py" "$FIXTURES/sample.diff" 19)
assert_eq "added import line" "user_service.py:2" "$R"

R=$(python3 "$SCRIPTS_DIR/resolve-line.py" "$FIXTURES/sample.diff" 23)
assert_eq "added API_KEY line" "user_service.py:5" "$R"

R=$(python3 "$SCRIPTS_DIR/resolve-line.py" "$FIXTURES/sample.diff" 30)
assert_eq "added return line" "user_service.py:11" "$R"

R=$(python3 "$SCRIPTS_DIR/resolve-line.py" "$FIXTURES/sample.diff" 29)
assert_eq "deleted line falls back to nearest surviving line" "user_service.py:11" "$R"

R=$(python3 "$SCRIPTS_DIR/resolve-line.py" "$FIXTURES/sample.diff" 9)
assert_eq "added readme line" "README.md:4" "$R"

if python3 "$SCRIPTS_DIR/resolve-line.py" "$FIXTURES/sample.diff" 1 > /dev/null 2>&1; then
  FAIL=$((FAIL + 1)); echo "FAIL - line pointing at a 'diff --git' header should error"
else
  PASS=$((PASS + 1)); echo "ok   - line pointing at a 'diff --git' header should error"
fi

echo
echo "=== reconcile.py — bucket classification + deterministic verdict ==="
WORKDIR=$(mktemp -d)
trap 'rm -rf "$WORKDIR"' EXIT

cat > "$WORKDIR/state.json" <<'EOF'
{"review_mode": "rereview", "push_update_mode": false, "incremental_changed_files": ""}
EOF
cat > "$WORKDIR/findings.json" <<'EOF'
[
  {"file": "a.py", "line": 10, "severity": "critical", "fid": "fid-carried", "body": "still broken"},
  {"file": "b.py", "line": 20, "severity": "warning", "fid": "fid-new", "body": "new issue"}
]
EOF
cat > "$WORKDIR/prior.jsonl" <<'EOF'
{"fid": "fid-carried", "status": "open", "thread_ref": 1, "file": "a.py"}
{"fid": "fid-fixed", "status": "open", "thread_ref": 2, "file": "c.py"}
{"fid": "fid-already-resolved", "status": "resolved", "thread_ref": 3, "file": "d.py"}
EOF

python3 -c "
import importlib.util
spec = importlib.util.spec_from_file_location('reconcile', '$SCRIPTS_DIR/reconcile.py')
mod = importlib.util.module_from_spec(spec)
spec.loader.exec_module(mod)  # runs the module's own top-level assignments first
mod.STATE_FILE = '$WORKDIR/state.json'
mod.FINDINGS_FILE = '$WORKDIR/findings.json'
mod.PRIOR_FINDINGS_FILE = '$WORKDIR/prior.jsonl'
mod.OUTPUT_FILE = '$WORKDIR/reconcile.json'
mod.main()
"
COUNTS=$(python3 -c "
import json
d = json.load(open('$WORKDIR/reconcile.json'))
print(d['counts']['fixed'], d['counts']['carried_over'], d['counts']['new'], d['verdict'])
")
assert_eq "reconcile buckets: fixed=1 carried=1 new=1, verdict=REQUEST CHANGES" "1 1 1 REQUEST CHANGES" "$COUNTS"

echo
echo "=== Summary: $PASS passed, $FAIL failed ==="
[ "$FAIL" -eq 0 ]
