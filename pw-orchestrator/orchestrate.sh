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
#   --app-url URL         Override the target app URL
#   --regenerate          Force test regeneration via Copilot coding agent
#   --skip-install        Skip npm install and browser download
#   --headed              Run tests in headed mode
#   --help                Show this help
###############################################################################

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "${SCRIPT_DIR}/.." && pwd)"
PLAYWRIGHT_DIR="${SCRIPT_DIR}/playwright"
RESULTS_DIR="${SCRIPT_DIR}/results"
TARGET_APP_REL="legacy-upload-demo/OgeFieldOps.Web"

APP_URL="https://vm-legacy-swc.swedencentral.cloudapp.azure.com/"
REGENERATE=false
SKIP_INSTALL=false
HEADED=""

usage() {
  sed -n '/^# Usage:/,/^###/p' "$0" | grep -v '^###' | sed 's/^# \?//'
}

while [[ $# -gt 0 ]]; do
  case "$1" in
    --app-url)     APP_URL="${2:?Missing value for --app-url}"; shift 2 ;;
    --regenerate)  REGENERATE=true; shift ;;
    --skip-install) SKIP_INSTALL=true; shift ;;
    --headed)      HEADED="--headed"; shift ;;
    --help|-h)     usage; exit 0 ;;
    *)             echo "Unknown flag: $1" >&2; exit 1 ;;
  esac
done

TARGET_APP_DIR="${REPO_ROOT}/${TARGET_APP_REL}"

###############################################################################
# Stage 1: DISCOVER
###############################################################################
echo ""
echo "══════════════════════════════════════════════════════════════════════════"
echo "  Stage 1/6: DISCOVER — extracting app signals from source"
echo "══════════════════════════════════════════════════════════════════════════"

WEB_CONFIG="${TARGET_APP_DIR}/Web.config"
CONTROLLER="${TARGET_APP_DIR}/Controllers/OutagesController.cs"

if [[ ! -f "${WEB_CONFIG}" ]]; then
  echo "ERROR: Web.config not found at ${WEB_CONFIG}" >&2
  exit 1
fi

allowed_extensions="$(sed -n 's/.*key="AllowedUploadExtensions" value="\([^"]*\)".*/\1/p' "${WEB_CONFIG}" | head -n1)"
max_upload_mb="$(sed -n 's/.*key="MaxUploadSizeMb" value="\([^"]*\)".*/\1/p' "${WEB_CONFIG}" | head -n1)"
validation_error="$(sed -n 's/.*ModelState.AddModelError("", "\(.*\)").*/\1/p' "${CONTROLLER}" | head -n1)"
upload_route="/Outages/Upload/{id}"

: "${allowed_extensions:=.pdf,.csv,.txt,.jpg,.jpeg,.png,.xlsx}"
: "${max_upload_mb:=25}"
: "${validation_error:=Please choose a file to upload.}"

echo "  App URL:            ${APP_URL}"
echo "  Upload route:       ${upload_route}"
echo "  Allowed extensions: ${allowed_extensions}"
echo "  Max upload (MB):    ${max_upload_mb}"
echo "  Validation message: ${validation_error}"

###############################################################################
# Stage 2: CONFIGURE
###############################################################################
echo ""
echo "══════════════════════════════════════════════════════════════════════════"
echo "  Stage 2/6: CONFIGURE — writing .env for Playwright"
echo "══════════════════════════════════════════════════════════════════════════"

cat > "${PLAYWRIGHT_DIR}/.env" <<EOF
APP_URL=${APP_URL}
UPLOAD_ROUTE=${upload_route}
ALLOWED_EXTENSIONS=${allowed_extensions}
MAX_UPLOAD_MB=${max_upload_mb}
VALIDATION_ERROR=${validation_error}
EOF

echo "  Written: ${PLAYWRIGHT_DIR}/.env"

###############################################################################
# Stage 3: GENERATE (optional — invoke Copilot coding agent)
###############################################################################
echo ""
echo "══════════════════════════════════════════════════════════════════════════"
echo "  Stage 3/6: GENERATE — check/create test suite"
echo "══════════════════════════════════════════════════════════════════════════"

TEST_COUNT="$(find "${PLAYWRIGHT_DIR}/tests" -name '*.spec.ts' 2>/dev/null | wc -l | tr -d ' ')"

if [[ "${REGENERATE}" == "true" ]]; then
  echo "  --regenerate requested. Invoking Copilot coding agent..."

  GENERATION_PROMPT="Generate Playwright baseline tests for a legacy ASP.NET MVC upload app.
Target: ${APP_URL}
Upload route: ${upload_route}
Allowed extensions: ${allowed_extensions}
Max upload MB: ${max_upload_mb}
Validation error: ${validation_error}

Requirements:
- Tests under pw-orchestrator/playwright/tests/
- Use role/semantic locators (no brittle CSS selectors)
- Dynamic upload target discovery via UI navigation
- Unique filenames per test
- In-memory file payloads (no fixture files)
- Oversized upload must accept multiple failure paths
- Test isolation: each test is independent

Scenarios: page-load, upload-form-renders, valid-upload, invalid-extension, missing-file, oversized-file"

  if command -v gh &>/dev/null; then
    REPO_NAME="$(gh repo view --json nameWithOwner -q .nameWithOwner 2>/dev/null || echo '')"
    if [[ -n "${REPO_NAME}" ]]; then
      ISSUE_URL="$(gh issue create \
        --repo "${REPO_NAME}" \
        --title "Generate Playwright baseline tests for legacy-upload-demo" \
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
