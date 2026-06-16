#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "${SCRIPT_DIR}/.." && pwd)"
TARGET_APP_REL="legacy-upload-demo/OgeFieldOps.Web"
APP_URL="https://vm-legacy-swc.swedencentral.cloudapp.azure.com/"
OUTPUT_ROOT="${SCRIPT_DIR}/runs"

usage() {
  cat <<'EOF'
Usage:
  ./pw-orchestrator/orchestrate-baseline.sh [options]

Options:
  --repo-root PATH            repository root (default: parent of script dir)
  --target-app-rel PATH       app path relative to repo root
                              (default: legacy-upload-demo/OgeFieldOps.Web)
  --app-url URL               app URL to embed in generated assets
                              (default: https://vm-legacy-swc.swedencentral.cloudapp.azure.com/)
  --output-root PATH          output folder for generated runs
                              (default: ./pw-orchestrator/runs)
  --help                      show help
EOF
}

require_value() {
  local flag="$1"
  local value="${2:-}"
  if [[ -z "${value}" || "${value}" == --* ]]; then
    echo "Missing value for ${flag}" >&2
    exit 1
  fi
}

json_escape() {
  printf '%s' "$1" \
    | sed -e 's/\\/\\\\/g' \
          -e 's/"/\\"/g'
}

sed_escape() {
  printf '%s' "$1" | sed -e 's/[&|]/\\&/g'
}

sanitize_value() {
  printf '%s' "$1" | tr '\r\n\t' '   '
}

while [[ $# -gt 0 ]]; do
  case "$1" in
    --repo-root)
      require_value "$1" "${2:-}"
      REPO_ROOT="${2:-}"
      shift 2
      ;;
    --target-app-rel)
      require_value "$1" "${2:-}"
      TARGET_APP_REL="${2:-}"
      shift 2
      ;;
    --app-url)
      require_value "$1" "${2:-}"
      APP_URL="${2:-}"
      shift 2
      ;;
    --output-root)
      require_value "$1" "${2:-}"
      OUTPUT_ROOT="${2:-}"
      shift 2
      ;;
    --help|-h)
      usage
      exit 0
      ;;
    *)
      echo "Unknown argument: $1" >&2
      usage >&2
      exit 1
      ;;
  esac
done

TARGET_APP_DIR="${REPO_ROOT}/${TARGET_APP_REL}"
CONTROLLER_FILE="${TARGET_APP_DIR}/Controllers/OutagesController.cs"
UPLOAD_VIEW_FILE="${TARGET_APP_DIR}/Views/Outages/Upload.cshtml"
FILE_SERVICE_FILE="${TARGET_APP_DIR}/Services/FileStorageService.cs"
WEB_CONFIG_FILE="${TARGET_APP_DIR}/Web.config"

if [[ ! -d "${TARGET_APP_DIR}" ]]; then
  echo "Required directory not found: ${TARGET_APP_DIR}" >&2
  exit 1
fi
for required_file in "${CONTROLLER_FILE}" "${UPLOAD_VIEW_FILE}" "${FILE_SERVICE_FILE}" "${WEB_CONFIG_FILE}"; do
  if [[ ! -f "${required_file}" ]]; then
    echo "Required file not found: ${required_file}" >&2
    exit 1
  fi
done

RUN_ID="$(date -u +%Y%m%dT%H%M%SZ)-${RANDOM}"
RUN_DIR="${OUTPUT_ROOT}/${RUN_ID}"
mkdir -p "${RUN_DIR}"

allowed_extensions="$(sed -n 's/.*key="AllowedUploadExtensions" value="\([^"]*\)".*/\1/p' "${WEB_CONFIG_FILE}" | head -n1)"
max_upload_mb="$(sed -n 's/.*key="MaxUploadSizeMb" value="\([^"]*\)".*/\1/p' "${WEB_CONFIG_FILE}" | head -n1)"
upload_route_raw="$(sed -n 's|.*// GET: \(/Outages/Upload[^ ]*\).*|\1|p' "${CONTROLLER_FILE}" | head -n1)"
validation_error_line="$(sed -n "s/.*ModelState.AddModelError(\"\", \"\(.*\)\").*/\1/p" "${CONTROLLER_FILE}" | head -n1)"

if [[ -z "${allowed_extensions}" ]]; then
  allowed_extensions=".pdf,.csv,.txt,.jpg,.jpeg,.png,.xlsx"
fi
if [[ -z "${max_upload_mb}" ]]; then
  max_upload_mb="25"
fi
if [[ -z "${upload_route_raw}" ]]; then
  upload_route="/Outages/Upload/{id}"
else
  upload_route="$(printf '%s' "${upload_route_raw}" | sed -E 's|/[0-9]+$|/{id}|')"
fi
if [[ -z "${validation_error_line}" ]]; then
  validation_error_line="Please choose a file to upload."
fi

allowed_extensions="$(sanitize_value "${allowed_extensions}")"
max_upload_mb="$(sanitize_value "${max_upload_mb}")"
upload_route="$(sanitize_value "${upload_route}")"
validation_error_line="$(sanitize_value "${validation_error_line}")"

operator_prompt_template="${SCRIPT_DIR}/templates/operator-prompt.txt"
contract_template="${SCRIPT_DIR}/templates/baseline-contract.template.json"

if [[ ! -f "${operator_prompt_template}" || ! -f "${contract_template}" ]]; then
  echo "Template files not found under ${SCRIPT_DIR}/templates." >&2
  exit 1
fi

prompt_app_url="$(sed_escape "${APP_URL}")"
prompt_upload_route="$(sed_escape "${upload_route}")"
prompt_allowed_extensions="$(sed_escape "${allowed_extensions}")"
prompt_max_upload_mb="$(sed_escape "${max_upload_mb}")"
prompt_validation_error="$(sed_escape "${validation_error_line}")"

sed \
  -e "s|{{APP_URL}}|${prompt_app_url}|g" \
  -e "s|{{UPLOAD_ROUTE}}|${prompt_upload_route}|g" \
  -e "s|{{ALLOWED_EXTENSIONS}}|${prompt_allowed_extensions}|g" \
  -e "s|{{MAX_UPLOAD_MB}}|${prompt_max_upload_mb}|g" \
  -e "s|{{VALIDATION_ERROR}}|${prompt_validation_error}|g" \
  "${operator_prompt_template}" > "${RUN_DIR}/operator-prompt.txt"

json_run_id="$(json_escape "${RUN_ID}")"
json_app_url="$(json_escape "${APP_URL}")"
json_target_app_rel="$(json_escape "${TARGET_APP_REL}")"
json_upload_route="$(json_escape "${upload_route}")"
json_allowed_extensions="$(json_escape "${allowed_extensions}")"
json_max_upload_mb="$(json_escape "${max_upload_mb}")"
json_validation_error="$(json_escape "${validation_error_line}")"

sed \
  -e "s|{{RUN_ID}}|$(sed_escape "${json_run_id}")|g" \
  -e "s|{{APP_URL}}|$(sed_escape "${json_app_url}")|g" \
  -e "s|{{TARGET_APP_REL}}|$(sed_escape "${json_target_app_rel}")|g" \
  -e "s|{{UPLOAD_ROUTE}}|$(sed_escape "${json_upload_route}")|g" \
  -e "s|{{ALLOWED_EXTENSIONS}}|$(sed_escape "${json_allowed_extensions}")|g" \
  -e "s|{{MAX_UPLOAD_MB}}|$(sed_escape "${json_max_upload_mb}")|g" \
  -e "s|{{VALIDATION_ERROR}}|$(sed_escape "${json_validation_error}")|g" \
  "${contract_template}" > "${RUN_DIR}/baseline-contract.json"

cat > "${RUN_DIR}/evidence.txt" <<EOF
run_id=${RUN_ID}
target_app=${TARGET_APP_REL}
app_url=${APP_URL}
upload_route_hint=${upload_route}
allowed_extensions=${allowed_extensions}
max_upload_mb=${max_upload_mb}
validation_error_text=${validation_error_line}
controller=${CONTROLLER_FILE}
upload_view=${UPLOAD_VIEW_FILE}
file_service=${FILE_SERVICE_FILE}
web_config=${WEB_CONFIG_FILE}
EOF

cat > "${RUN_DIR}/runbook.sh" <<'EOF'
#!/usr/bin/env bash
set -euo pipefail

echo "1) Send operator-prompt.txt to your Playwright Orchestrator custom agent."
echo "2) Generate only. Do not run Playwright, npm scripts, or shell test commands."
echo "3) Keep output under pw-orchestrator/playwright only."
echo "4) Enforce strict-mode-safe selectors (no ambiguous filename getByText assertions)."
echo "5) Enforce oversized upload tolerance for inline validation, redirect failure surfaces, and request-level rejection."
echo "6) Require failure-signal-first assertion order before page-structure checks."
echo "7) Pause for human review before any execution."
EOF
chmod +x "${RUN_DIR}/runbook.sh"

echo "Generated baseline package: ${RUN_DIR}"
echo "  - operator-prompt.txt"
echo "  - baseline-contract.json"
echo "  - evidence.txt"
echo "  - runbook.sh"
