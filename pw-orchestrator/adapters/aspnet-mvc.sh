#!/usr/bin/env bash
###############################################################################
# Discovery adapter: ASP.NET MVC (.NET Framework / Web.config based)
#
# Extracts app signals from source files. Outputs KEY=VALUE pairs to stdout.
# Each discovered value is also reported to stderr for logging.
# Values that could not be discovered are omitted (caller provides defaults).
#
# Route discovery strategy (tried in order):
#   1. Route comments: // GET: /Controller/Action/5
#   2. Action method signatures: public ActionResult Upload(int id)
#   3. Convention inference: controller name → /{ControllerName}
#
# Confidence levels:
#   HIGH   — found explicit route comment or attribute
#   MEDIUM — inferred from action method name + MVC convention
#   LOW    — fallback inference only
###############################################################################
set -euo pipefail

APP_SOURCE_DIR="${1:?Usage: aspnet-mvc.sh <app-source-dir>}"

WEB_CONFIG="${APP_SOURCE_DIR}/Web.config"
DISCOVERED=0
FAILED=0
CONFIDENCE="NONE"

discover() {
  local key="$1" value="$2" source="$3" confidence="${4:-HIGH}"
  if [[ -n "${value}" ]]; then
    echo "${key}=${value}"
    echo "  ✓ ${key} = ${value}  (from ${source}, confidence: ${confidence})" >&2
    DISCOVERED=$((DISCOVERED + 1))
    # Track lowest confidence
    if [[ "${confidence}" == "LOW" ]] || \
       [[ "${confidence}" == "MEDIUM" && "${CONFIDENCE}" != "LOW" ]] || \
       [[ "${confidence}" == "HIGH" && "${CONFIDENCE}" == "NONE" ]]; then
      CONFIDENCE="${confidence}"
    fi
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

  # Strategy 1: Route comments (// GET: /Controller/Action/5) — HIGH confidence
  upload_route=""
  route_source=""
  for controller in "${CONTROLLERS_DIR}"/*.cs; do
    [[ -f "${controller}" ]] || continue

    route_from_comment="$(sed -n 's|.*// GET: \(/[^ ]*[Uu]pload[^ ]*\).*|\1|p' "${controller}" | head -n1)"
    if [[ -n "${route_from_comment}" ]]; then
      upload_route="$(printf '%s' "${route_from_comment}" | sed -E 's|/[0-9]+$|/{id}|')"
      route_source="$(basename "${controller}")/route-comment"
      break
    fi
  done

  # Strategy 2: Action method name + MVC conventions — MEDIUM confidence
  if [[ -z "${upload_route}" ]]; then
    for controller in "${CONTROLLERS_DIR}"/*.cs; do
      [[ -f "${controller}" ]] || continue

      # Look for: public ActionResult Upload(int id)
      action_match="$(sed -n 's/.*public\s\+ActionResult\s\+\([Uu]pload\)\s*(.*int\s\+id.*/\1/p' "${controller}" | head -n1)"
      if [[ -n "${action_match}" ]]; then
        # Derive controller name from filename: OutagesController.cs → Outages
        ctrl_name="$(basename "${controller}" .cs | sed 's/Controller$//')"
        upload_route="/${ctrl_name}/${action_match}/{id}"
        route_source="$(basename "${controller}")/action-method-convention"
        echo "  ℹ No route comment found; inferred from action method signature" >&2
        break
      fi
    done
  fi

  if [[ -n "${upload_route}" ]]; then
    local_confidence="HIGH"
    [[ "${route_source}" == *"convention"* ]] && local_confidence="MEDIUM"
    discover "UPLOAD_ROUTE" "${upload_route}" "${route_source}" "${local_confidence}"

    # Derive list route: the controller's base path (first segment)
    controller_base="$(printf '%s' "${upload_route}" | sed -E 's|^(/[^/]+).*|\1|')"
    discover "LIST_ROUTE" "${controller_base}" "derived from UPLOAD_ROUTE" "${local_confidence}"
  fi
else
  echo "  ⚠ Controllers directory not found at ${CONTROLLERS_DIR}" >&2
fi

# Views — discover form structure hints
VIEWS_DIR="${APP_SOURCE_DIR}/Views"
if [[ -d "${VIEWS_DIR}" ]]; then
  upload_views="$(find "${VIEWS_DIR}" -name '*.cshtml' -exec grep -l 'type="file"' {} \; 2>/dev/null | head -n5)"
  if [[ -n "${upload_views}" ]]; then
    view_count="$(echo "${upload_views}" | wc -l | tr -d ' ')"
    echo "  ✓ Found ${view_count} view(s) with file upload forms" >&2
  fi
fi

echo "" >&2
echo "  Discovery: ${DISCOVERED} found, ${FAILED} not found (confidence: ${CONFIDENCE})" >&2
