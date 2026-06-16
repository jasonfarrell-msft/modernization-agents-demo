#!/usr/bin/env bash
set -euo pipefail

###############################################################################
# Playwright Orchestrator — Full Pipeline
#
# Single-command orchestration: discover → configure → generate → install →
# execute → report.
#
# Usage:
#   ./pw-orchestrator/orchestrate.sh [options]
#
# Options:
#   --app-url URL         Target app URL (running instance) [required]
#   --app-source PATH     Path to the app source directory (absolute or
#                         relative to repo root). Used for discovery. [required]
#   --app NAME            App test suite to run (matches folder name under
#                         playwright/apps/) [required]
#   --adapter NAME        Discovery adapter to use. Available adapters are
#                         in the adapters/ directory. [required]
#   --regenerate          Force test regeneration via Copilot coding agent
#   --skip-install        Skip npm install and browser download
#   --headed              Run tests in headed mode
#   --help                Show this help
###############################################################################

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "${SCRIPT_DIR}/.." && pwd)"
PLAYWRIGHT_DIR="${SCRIPT_DIR}/playwright"
RESULTS_DIR="${SCRIPT_DIR}/results"
TARGET_APP_REL=""
APP_NAME=""
ADAPTER=""

APP_URL=""
REGENERATE=false
SKIP_INSTALL=false
HEADED=""

usage() {
  sed -n '/^# Usage:/,/^###/p' "$0" | grep -v '^###' | sed 's/^# \?//'
}

while [[ $# -gt 0 ]]; do
  case "$1" in
    --app-url)      APP_URL="${2:?Missing value for --app-url}"; shift 2 ;;
    --app-source)   TARGET_APP_REL="${2:?Missing value for --app-source}"; shift 2 ;;
    --app)          APP_NAME="${2:?Missing value for --app}"; shift 2 ;;
    --adapter)      ADAPTER="${2:?Missing value for --adapter}"; shift 2 ;;
    --regenerate)   REGENERATE=true; shift ;;
    --skip-install) SKIP_INSTALL=true; shift ;;
    --headed)       HEADED="--headed"; shift ;;
    --help|-h)      usage; exit 0 ;;
    *)              echo "Unknown flag: $1" >&2; exit 1 ;;
  esac
done

# Validate required flags
required_flags=()
[[ -z "${APP_URL}" ]] && required_flags+=("--app-url")
[[ -z "${APP_NAME}" ]] && required_flags+=("--app")
[[ -z "${ADAPTER}" ]] && required_flags+=("--adapter")
[[ -z "${TARGET_APP_REL}" ]] && required_flags+=("--app-source")
if [[ ${#required_flags[@]} -gt 0 ]]; then
  echo "ERROR: Missing required flags: ${required_flags[*]}" >&2
  echo "  Run with --help for usage." >&2
  exit 1
fi

# Validate adapter name (prevent path traversal)
if [[ ! "${ADAPTER}" =~ ^[a-zA-Z0-9_-]+$ ]]; then
  echo "ERROR: Invalid adapter name '${ADAPTER}'. Must be alphanumeric with hyphens/underscores." >&2
  exit 1
fi

# Validate app name (prevent path traversal)
if [[ ! "${APP_NAME}" =~ ^[a-zA-Z0-9_-]+$ ]]; then
  echo "ERROR: Invalid app name '${APP_NAME}'. Must be alphanumeric with hyphens/underscores." >&2
  exit 1
fi

# Resolve app source: support absolute paths or paths relative to repo root
if [[ "${TARGET_APP_REL}" == /* ]]; then
  TARGET_APP_DIR="${TARGET_APP_REL}"
else
  TARGET_APP_DIR="${REPO_ROOT}/${TARGET_APP_REL}"
fi

# Validate app test suite exists
APP_TEST_DIR="${PLAYWRIGHT_DIR}/apps/${APP_NAME}"
if [[ ! -d "${APP_TEST_DIR}" ]]; then
  echo "ERROR: No test suite found for app '${APP_NAME}'" >&2
  echo "  Expected: ${APP_TEST_DIR}" >&2
  echo "  Available apps:" >&2
  ls -1 "${PLAYWRIGHT_DIR}/apps/" 2>/dev/null | sed 's/^/    /' >&2
  exit 1
fi

# Validate adapter exists
ADAPTER_SCRIPT="${SCRIPT_DIR}/adapters/${ADAPTER}.sh"
if [[ ! -f "${ADAPTER_SCRIPT}" ]]; then
  echo "ERROR: No discovery adapter found for '${ADAPTER}'" >&2
  echo "  Expected: ${ADAPTER_SCRIPT}" >&2
  echo "  Available adapters:" >&2
  ls -1 "${SCRIPT_DIR}/adapters/" 2>/dev/null | sed 's/\.sh$//; s/^/    /' >&2
  exit 1
fi

###############################################################################
# Stage 1: DISCOVER
###############################################################################
echo ""
echo "══════════════════════════════════════════════════════════════════════════"
echo "  Stage 1/6: DISCOVER — extracting app signals from source"
echo "══════════════════════════════════════════════════════════════════════════"
echo "  Adapter:    ${ADAPTER}"
echo "  App source: ${TARGET_APP_DIR}"
echo ""

if [[ ! -d "${TARGET_APP_DIR}" ]]; then
  echo "ERROR: App source directory not found: ${TARGET_APP_DIR}" >&2
  exit 1
fi

mkdir -p "${RESULTS_DIR}"

# Run adapter once — capture stdout (KEY=VALUE) and stderr (logs) separately
ADAPTER_OUTPUT="$(bash "${ADAPTER_SCRIPT}" "${TARGET_APP_DIR}" 2>"${RESULTS_DIR}/adapter.log")" || {
  echo "  ERROR: Adapter '${ADAPTER}' failed. Log:" >&2
  cat "${RESULTS_DIR}/adapter.log" >&2
  exit 1
}

# Print adapter log
cat "${RESULTS_DIR}/adapter.log"

# Parse discovered values
allowed_extensions="$(echo "${ADAPTER_OUTPUT}" | sed -n 's/^ALLOWED_EXTENSIONS=//p' | head -n1)"
max_upload_mb="$(echo "${ADAPTER_OUTPUT}" | sed -n 's/^MAX_UPLOAD_MB=//p' | head -n1)"
validation_error="$(echo "${ADAPTER_OUTPUT}" | sed -n 's/^VALIDATION_ERROR=//p' | head -n1)"
upload_route="$(echo "${ADAPTER_OUTPUT}" | sed -n 's/^UPLOAD_ROUTE=//p' | head -n1)"
list_route="$(echo "${ADAPTER_OUTPUT}" | sed -n 's/^LIST_ROUTE=//p' | head -n1)"

# Report which optional values were not discovered (warnings to stderr only)
echo ""
for pair in "ALLOWED_EXTENSIONS:${allowed_extensions}" "MAX_UPLOAD_MB:${max_upload_mb}" "VALIDATION_ERROR:${validation_error}"; do
  key="${pair%%:*}"
  val="${pair#*:}"
  if [[ -z "${val}" ]]; then
    echo "  ⚠ ${key}: not discovered (tests depending on it may be skipped)" >&2
  fi
done

# Verify critical values were discovered
missing=()
[[ -z "${upload_route}" ]] && missing+=("UPLOAD_ROUTE")
[[ -z "${list_route}" ]] && missing+=("LIST_ROUTE")
if [[ ${#missing[@]} -gt 0 ]]; then
  echo ""
  echo "  ERROR: Adapter did not discover required values: ${missing[*]}" >&2
  echo "  Provide them via --app-url or check your adapter and app source path." >&2
  exit 1
fi

echo ""
echo "  Final configuration:"
echo "    App URL:            ${APP_URL}"
echo "    App name:           ${APP_NAME}"
echo "    List route:         ${list_route}"
echo "    Upload route:       ${upload_route}"
echo "    Allowed extensions: ${allowed_extensions:-<not discovered>}"
echo "    Max upload (MB):    ${max_upload_mb:-<not discovered>}"
echo "    Validation message: ${validation_error:-<not discovered>}"

###############################################################################
# Stage 2: CONFIGURE
###############################################################################
echo ""
echo "══════════════════════════════════════════════════════════════════════════"
echo "  Stage 2/6: CONFIGURE — writing .env for Playwright"
echo "══════════════════════════════════════════════════════════════════════════"

# Escape a value for safe inclusion in a .env file (handles #, quotes, newlines)
env_escape() {
  local val="$1"
  # If value contains special chars, wrap in double quotes and escape internal quotes
  if printf '%s' "${val}" | grep -qE '[#"'"'"'\\[:space:]]'; then
    val="$(printf '%s' "${val}" | sed 's/\\/\\\\/g; s/"/\\"/g')"
    printf '"%s"' "${val}"
  else
    printf '%s' "${val}"
  fi
}

cat > "${PLAYWRIGHT_DIR}/.env" <<EOF
APP_URL=$(env_escape "${APP_URL}")
APP_NAME=$(env_escape "${APP_NAME}")
LIST_ROUTE=$(env_escape "${list_route}")
UPLOAD_ROUTE=$(env_escape "${upload_route}")
ALLOWED_EXTENSIONS=$(env_escape "${allowed_extensions}")
MAX_UPLOAD_MB=$(env_escape "${max_upload_mb}")
VALIDATION_ERROR=$(env_escape "${validation_error}")
EOF

echo "  Written: ${PLAYWRIGHT_DIR}/.env"

###############################################################################
# Stage 3: GENERATE (optional — invoke Copilot coding agent)
###############################################################################
echo ""
echo "══════════════════════════════════════════════════════════════════════════"
echo "  Stage 3/6: GENERATE — check/create test suite"
echo "══════════════════════════════════════════════════════════════════════════"

TEST_COUNT="$(find "${APP_TEST_DIR}/tests" -name '*.spec.ts' 2>/dev/null | wc -l | tr -d ' ')"

if [[ "${REGENERATE}" == "true" ]]; then
  echo "  --regenerate requested. Invoking Copilot coding agent..."

  GENERATION_PROMPT="Generate Playwright baseline tests for a web application.
Target: ${APP_URL}
List route: ${list_route}
Upload route: ${upload_route}
Allowed extensions: ${allowed_extensions}
Max upload MB: ${max_upload_mb}
Validation error: ${validation_error}

Requirements:
- Tests under pw-orchestrator/playwright/apps/${APP_NAME}/tests/
- Use generic helpers from helpers/test-utils.ts (uniqueFilename, createFileBuffer, uploadFile, hasVisibleFailureSignal)
- Use app-specific helpers from apps/${APP_NAME}/app-helpers.ts (navigateToUploadPage, uploadPagePattern, detailsPagePattern, hasAppFailureSignal)
- Use discovered config from helpers/discovery.ts (getConfig) — never hardcode routes or validation messages
- Dynamic upload target discovery via UI navigation (no hard-coded IDs)
- Unique filenames per test to avoid cross-run collisions
- In-memory file payloads (no external fixture files)
- Oversized upload must accept multiple legacy failure paths
- Test isolation: each test is independent

Scenarios: page-load, upload-form-renders, valid-upload, invalid-extension, missing-file, oversized-file

STRICT-MODE RULES (non-negotiable):
These rules prevent Playwright strict mode violations. Every generated test MUST follow them.

1. NEVER use broad getByText() to verify a filename after upload. The filename appears in
   BOTH the flash success alert AND the documents table cell, causing strict mode to fail.
   Instead, scope to the documents table:
     const docsTable = page.locator('table').filter({ hasText: 'File' });
     await expect(docsTable.getByRole('cell', { name: fileName })).toBeVisible();

2. NEVER use short generic text patterns that match navigation links, headings, AND content
   text simultaneously. Use specific patterns unique to the content area.

3. Every locator MUST resolve to exactly one element. If a locator could match multiple
   elements, scope it using .locator().filter(), getByRole() with name, or chain locators
   to narrow to a specific container first.

4. Prefer getByRole() and getByLabel() over getByText() for interactive elements.
   Use getByText() only for non-interactive content, and always with patterns specific
   enough to match a single element.

5. After a successful upload, assert against the documents table cell, NOT the flash alert.
   The flash alert is transient and also contains the filename, causing ambiguity.

6. For error assertions, use hasVisibleFailureSignal() from helpers/test-utils.ts and
   hasAppFailureSignal() from apps/${APP_NAME}/app-helpers.ts — they check multiple error
   surfaces with proper timeout handling."

  if command -v gh &>/dev/null; then
    REPO_NAME="$(gh repo view --json nameWithOwner -q .nameWithOwner 2>/dev/null || echo '')"
    if [[ -n "${REPO_NAME}" ]]; then
      ISSUE_URL="$(gh issue create \
        --repo "${REPO_NAME}" \
        --title "Generate Playwright baseline tests for ${APP_NAME}" \
        --body "${GENERATION_PROMPT}" \
        --label "copilot" 2>/dev/null || echo '')"

      if [[ -n "${ISSUE_URL}" ]]; then
        echo "  Issue created: ${ISSUE_URL}"
        echo "  NOTE: Copilot will generate tests in a PR. Using seed tests for this run."
      else
        echo "  Could not create issue. Using seed tests."
      fi
    else
      echo "  No GitHub repo configured. Using seed tests."
    fi
  else
    echo "  gh CLI not available. Using seed tests."
  fi
else
  echo "  Found ${TEST_COUNT} test file(s). Generation not requested (use --regenerate)."
fi

###############################################################################
# Stage 4: INSTALL
###############################################################################
echo ""
echo "══════════════════════════════════════════════════════════════════════════"
echo "  Stage 4/6: INSTALL — dependencies and browsers"
echo "══════════════════════════════════════════════════════════════════════════"

if [[ "${SKIP_INSTALL}" == "true" ]]; then
  echo "  Skipped (--skip-install)."
else
  cd "${PLAYWRIGHT_DIR}"
  if [[ -f package-lock.json ]]; then
    npm ci --quiet
  else
    npm install --quiet
  fi
  npx playwright install chromium --with-deps 2>/dev/null || npx playwright install chromium
  echo "  Dependencies installed."
  cd "${SCRIPT_DIR}"
fi

###############################################################################
# Stage 5: EXECUTE
###############################################################################
echo ""
echo "══════════════════════════════════════════════════════════════════════════"
echo "  Stage 5/6: EXECUTE — running Playwright tests"
echo "══════════════════════════════════════════════════════════════════════════"

rm -rf "${RESULTS_DIR}"
mkdir -p "${RESULTS_DIR}"

cd "${PLAYWRIGHT_DIR}"
set +e
npx playwright test ${HEADED} 2>&1 | tee "${RESULTS_DIR}/execution.log"
TEST_EXIT_CODE=$?
set -e
cd "${SCRIPT_DIR}"

echo ""
if [[ ${TEST_EXIT_CODE} -eq 0 ]]; then
  echo "  ✅ All tests passed."
else
  echo "  ❌ Some tests failed (exit code: ${TEST_EXIT_CODE})."
fi

###############################################################################
# Stage 6: REPORT
###############################################################################
echo ""
echo "══════════════════════════════════════════════════════════════════════════"
echo "  Stage 6/6: REPORT — collecting artifacts and summary"
echo "══════════════════════════════════════════════════════════════════════════"

# Parse test results JSON if available
RESULTS_JSON="${RESULTS_DIR}/test-results.json"
SUMMARY_FILE="${RESULTS_DIR}/summary.json"

if [[ -f "${RESULTS_JSON}" ]]; then
  TOTAL="$(python3 -c "
import json, sys
data = json.load(open('${RESULTS_JSON}'))
suites = data.get('suites', [])
passed = failed = skipped = 0
def count(s):
    global passed, failed, skipped
    for spec in s.get('specs', []):
        for t in spec.get('tests', []):
            status = t.get('status', '')
            if status == 'expected': passed += 1
            elif status in ('unexpected', 'flaky'): failed += 1
            elif status == 'skipped': skipped += 1
    for child in s.get('suites', []):
        count(child)
for s in suites:
    count(s)
print(json.dumps({'passed': passed, 'failed': failed, 'skipped': skipped, 'total': passed+failed+skipped}))
" 2>/dev/null || echo '{"passed":0,"failed":0,"skipped":0,"total":0}')"
else
  TOTAL='{"passed":0,"failed":0,"skipped":0,"total":0}'
fi

# Generate properly escaped JSON summary
export SUMMARY_APP_URL="${APP_URL}"
export SUMMARY_EXIT_CODE="${TEST_EXIT_CODE}"
export SUMMARY_RESULTS="${TOTAL}"
export SUMMARY_EXTENSIONS="${allowed_extensions}"
export SUMMARY_MAX_MB="${max_upload_mb}"
export SUMMARY_VALIDATION="${validation_error}"
export SUMMARY_FILE="${SUMMARY_FILE}"

python3 -c "
import json, sys, os
summary = {
    'timestamp': '$(date -u +%Y-%m-%dT%H:%M:%SZ)',
    'appUrl': os.environ.get('SUMMARY_APP_URL', ''),
    'exitCode': int(os.environ.get('SUMMARY_EXIT_CODE', '1')),
    'results': json.loads(os.environ.get('SUMMARY_RESULTS', '{}')),
    'artifacts': {
        'htmlReport': 'results/html-report/index.html',
        'executionLog': 'results/execution.log',
        'testResults': 'results/test-results.json',
        'traces': 'results/test-artifacts/'
    },
    'config': {
        'allowedExtensions': os.environ.get('SUMMARY_EXTENSIONS', ''),
        'maxUploadMb': os.environ.get('SUMMARY_MAX_MB', ''),
        'validationError': os.environ.get('SUMMARY_VALIDATION', '')
    }
}
with open(os.environ['SUMMARY_FILE'], 'w') as f:
    json.dump(summary, f, indent=2)
" <<< "" || cat > "${SUMMARY_FILE}" <<EOF
{"timestamp":"$(date -u +%Y-%m-%dT%H:%M:%SZ)","exitCode":${TEST_EXIT_CODE},"error":"summary generation failed"}
EOF

echo "  Summary:  ${SUMMARY_FILE}"
echo "  Report:   ${RESULTS_DIR}/html-report/index.html"
echo "  Traces:   ${RESULTS_DIR}/test-artifacts/"
echo "  Log:      ${RESULTS_DIR}/execution.log"
echo ""
echo "══════════════════════════════════════════════════════════════════════════"
echo "  PIPELINE COMPLETE"
echo "══════════════════════════════════════════════════════════════════════════"
echo ""
cat "${SUMMARY_FILE}" | python3 -m json.tool 2>/dev/null || cat "${SUMMARY_FILE}"
echo ""

exit ${TEST_EXIT_CODE}
