#!/usr/bin/env bash
###############################################################################
# Discovery adapter: ASP.NET MVC (.NET Framework / Web.config based)
#
# Extracts app signals from source files. Outputs KEY=VALUE pairs to stdout.
# Each discovered value is also reported to stderr for logging.
# Values that could not be discovered are omitted (caller provides defaults).
###############################################################################
set -euo pipefail

APP_SOURCE_DIR="${1:?Usage: aspnet-mvc.sh <app-source-dir>}"

WEB_CONFIG="${APP_SOURCE_DIR}/Web.config"
DISCOVERED=0
FAILED=0

discover() {
  local key="$1" value="$2" source="$3"
  if [[ -n "${value}" ]]; then
    echo "${key}=${value}"
    echo "  ✓ ${key} = ${value}  (from ${source})" >&2
    DISCOVERED=$((DISCOVERED + 1))
  else
    echo "  ✗ ${key} — not found in ${source}" >&2
    FAILED=$((FAILED + 1))
  fi
}

# Web.config appSettings
if [[ -f "${WEB_CONFIG}" ]]; then
  discover "ALLOWED_EXTENSIONS" \
    "$(sed -n 's/.*key="AllowedUploadExtensions" value="\([^"]*\)".*/\1/p' "${WEB_CONFIG}" | head -n1)" \
    "Web.config/AllowedUploadExtensions"

  discover "MAX_UPLOAD_MB" \
    "$(sed -n 's/.*key="MaxUploadSizeMb" value="\([^"]*\)".*/\1/p' "${WEB_CONFIG}" | head -n1)" \
    "Web.config/MaxUploadSizeMb"
else
  echo "  ⚠ Web.config not found at ${WEB_CONFIG}" >&2
  FAILED=$((FAILED + 2))
fi

# Controller — validation messages and routes
CONTROLLERS_DIR="${APP_SOURCE_DIR}/Controllers"
if [[ -d "${CONTROLLERS_DIR}" ]]; then
  # Find the first controller with AddModelError
  for controller in "${CONTROLLERS_DIR}"/*.cs; do
    [[ -f "${controller}" ]] || continue

    validation_msg="$(sed -n 's/.*ModelState.AddModelError("", "\(.*\)").*/\1/p' "${controller}" | head -n1)"
    if [[ -n "${validation_msg}" ]]; then
      discover "VALIDATION_ERROR" "${validation_msg}" "$(basename "${controller}")/ModelState.AddModelError"
      break
    fi
  done

  # Find upload route patterns
  for controller in "${CONTROLLERS_DIR}"/*.cs; do
    [[ -f "${controller}" ]] || continue

    upload_route="$(sed -n 's|.*// GET: \(/[^ ]*[Uu]pload[^ ]*\).*|\1|p' "${controller}" | head -n1)"
    if [[ -n "${upload_route}" ]]; then
      # Normalize numeric IDs to {id} placeholder
      upload_route="$(printf '%s' "${upload_route}" | sed -E 's|/[0-9]+$|/{id}|')"
      discover "UPLOAD_ROUTE" "${upload_route}" "$(basename "${controller}")/route-comment"
      break
    fi
  done
else
  echo "  ⚠ Controllers directory not found at ${CONTROLLERS_DIR}" >&2
fi

# Views — discover form structure hints
VIEWS_DIR="${APP_SOURCE_DIR}/Views"
if [[ -d "${VIEWS_DIR}" ]]; then
  # Find file input fields for upload detection
  upload_views="$(find "${VIEWS_DIR}" -name '*.cshtml' -exec grep -l 'type="file"' {} \; 2>/dev/null | head -n5)"
  if [[ -n "${upload_views}" ]]; then
    view_count="$(echo "${upload_views}" | wc -l | tr -d ' ')"
    echo "  ✓ Found ${view_count} view(s) with file upload forms" >&2
  fi
fi

echo "" >&2
echo "  Discovery: ${DISCOVERED} found, ${FAILED} not found" >&2
