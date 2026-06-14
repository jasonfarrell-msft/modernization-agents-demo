#!/usr/bin/env bash

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
RESOURCE_GROUP_NAME="${RESOURCE_GROUP_NAME:-rg-modernization-swc-mx01}"
LOCATION="${LOCATION:-swedencentral}"
TEMPLATE_FILE="${TEMPLATE_FILE:-$SCRIPT_DIR/main.bicep}"
PARAMETERS_FILE="${PARAMETERS_FILE:-$SCRIPT_DIR/main.bicepparam}"
GENERATED_PARAMETERS_FILE="${GENERATED_PARAMETERS_FILE:-$SCRIPT_DIR/main.parameters.json}"
VM_NAME="${VM_NAME:-vm-legacy-swc}"
CUSTOM_SCRIPT_URI="${CUSTOM_SCRIPT_URI:-}"

usage() {
  cat <<'EOF'
Usage: ./deploy.sh [--resource-group <name>] [--location <region>] [--template-file <path>] [--custom-script-uri <url>]

Example:
  ./deploy.sh --resource-group rg-modernization-swc-mx01 --location swedencentral
EOF
}

while [[ $# -gt 0 ]]; do
  case "$1" in
    --resource-group)
      RESOURCE_GROUP_NAME="$2"
      shift 2
      ;;
    --location)
      LOCATION="$2"
      shift 2
      ;;
    --template-file)
      TEMPLATE_FILE="$2"
      shift 2
      ;;
    --custom-script-uri)
      CUSTOM_SCRIPT_URI="$2"
      shift 2
      ;;
    -h|--help)
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

bicep build-params "$PARAMETERS_FILE" --outfile "$GENERATED_PARAMETERS_FILE"

az group create --name "$RESOURCE_GROUP_NAME" --location "$LOCATION" >/dev/null
az deployment group create \
  --resource-group "$RESOURCE_GROUP_NAME" \
  --template-file "$TEMPLATE_FILE" \
  --parameters @"$GENERATED_PARAMETERS_FILE" \
  --parameters customScriptUri="$CUSTOM_SCRIPT_URI"

az vm run-command invoke \
  --resource-group "$RESOURCE_GROUP_NAME" \
  --name "$VM_NAME" \
  --command-id RunPowerShellScript \
  --scripts @"$SCRIPT_DIR/install-iis.ps1" >/dev/null

printf 'IIS setup completed on %s.\n' "$VM_NAME"
