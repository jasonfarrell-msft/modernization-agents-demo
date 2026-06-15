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
CONTACT_EMAIL="${CONTACT_EMAIL:-}"
ENABLE_FULL_SETUP="${ENABLE_FULL_SETUP:-false}"
SQL_SA_PASSWORD="${SQL_SA_PASSWORD:-}"
OGE_APP_PASSWORD="${OGE_APP_PASSWORD:-}"
GITHUB_RUNNER_URL="${GITHUB_RUNNER_URL:-https://github.com/jasonfarrell-msft/modernization-agents-demo}"
GITHUB_RUNNER_REGISTRATION_TOKEN="${GITHUB_RUNNER_REGISTRATION_TOKEN:-}"
GITHUB_RUNNER_NAME="${GITHUB_RUNNER_NAME:-}"
GITHUB_RUNNER_LABELS="${GITHUB_RUNNER_LABELS:-self-hosted,Windows,X64,iis-deploy}"
SQL_SETUP_BOOTSTRAP_URL="${SQL_SETUP_BOOTSTRAP_URL:-https://go.microsoft.com/fwlink/?linkid=866658}"

usage() {
  cat <<'EOF'
Usage: ./deploy.sh [--resource-group <name>] [--location <region>] [--template-file <path>] [--custom-script-uri <url>] [--contact-email <email>] [--full-setup]

Options:
  --full-setup      Run full post-deploy VM configuration in order:
                    SQL Express install -> DB provision -> IIS/ASP.NET -> runner registration -> optional SSL.
                    Requires SQL_SA_PASSWORD, OGE_APP_PASSWORD, and
                    GITHUB_RUNNER_REGISTRATION_TOKEN environment variables.
  --contact-email   E-mail address for the Let's Encrypt ACME account.
                    When provided, install-ssl.ps1 is run after VM setup to
                    obtain a certificate, bind HTTPS on port 443, and configure
                    the HTTP→HTTPS redirect.  Omit to skip TLS setup.

Example (IIS only):
  ./deploy.sh --resource-group rg-modernization-swc-mx01 --location swedencentral

Example (IIS + TLS):
  ./deploy.sh --resource-group rg-modernization-swc-mx01 --location swedencentral \
              --contact-email ops@yourorg.com

Example (full reproducible setup):
  SQL_SA_PASSWORD='<sa-password>' OGE_APP_PASSWORD='<oge-app-password>' \
  GITHUB_RUNNER_REGISTRATION_TOKEN='<runner-token>' \
  ./deploy.sh --resource-group rg-modernization-swc-mx01 --location swedencentral \
              --full-setup --contact-email ops@yourorg.com
EOF
}

run_vm_script() {
  local script_file="$1"
  shift

  local -a cmd=(
    az vm run-command invoke
    --resource-group "$RESOURCE_GROUP_NAME"
    --name "$VM_NAME"
    --command-id RunPowerShellScript
    --scripts @"$SCRIPT_DIR/$script_file"
  )

  while [[ $# -gt 0 ]]; do
    cmd+=(--parameters "$1")
    shift
  done

  "${cmd[@]}" >/dev/null
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
    --contact-email)
      CONTACT_EMAIL="$2"
      shift 2
      ;;
    --full-setup)
      ENABLE_FULL_SETUP=true
      shift
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

if [[ "$ENABLE_FULL_SETUP" == "true" ]]; then
  if [[ -z "$SQL_SA_PASSWORD" || -z "$OGE_APP_PASSWORD" || -z "$GITHUB_RUNNER_REGISTRATION_TOKEN" ]]; then
    echo "Missing required environment variables for --full-setup." >&2
    echo "Required: SQL_SA_PASSWORD, OGE_APP_PASSWORD, GITHUB_RUNNER_REGISTRATION_TOKEN" >&2
    exit 1
  fi

  printf 'Running full VM setup on %s...\n' "$VM_NAME"
  run_vm_script "install-sql-express.ps1" \
    "SaPassword=$SQL_SA_PASSWORD" \
    "SqlSetupBootstrapUrl=$SQL_SETUP_BOOTSTRAP_URL"
  printf 'SQL Server Express setup completed on %s.\n' "$VM_NAME"

  run_vm_script "provision-legacy-db.ps1" \
    "SaPassword=$SQL_SA_PASSWORD" \
    "OgeAppPassword=$OGE_APP_PASSWORD"
  printf 'Database provisioning completed on %s.\n' "$VM_NAME"

  run_vm_script "install-iis.ps1"
  printf 'IIS + ASP.NET setup completed on %s.\n' "$VM_NAME"

  local_runner_name="$GITHUB_RUNNER_NAME"
  if [[ -z "$local_runner_name" ]]; then
    local_runner_name="$VM_NAME"
  fi
  run_vm_script "register-github-runner.ps1" \
    "RunnerUrl=$GITHUB_RUNNER_URL" \
    "RegistrationToken=$GITHUB_RUNNER_REGISTRATION_TOKEN" \
    "RunnerName=$local_runner_name" \
    "Labels=$GITHUB_RUNNER_LABELS"
  printf 'GitHub runner registration completed on %s.\n' "$VM_NAME"
else
  run_vm_script "install-iis.ps1"
  printf 'IIS setup completed on %s.\n' "$VM_NAME"
fi

if [[ -n "$CONTACT_EMAIL" ]]; then
  printf 'Running SSL setup (install-ssl.ps1) on %s...\n' "$VM_NAME"
  run_vm_script "install-ssl.ps1" "ContactEmail=$CONTACT_EMAIL"
  printf 'SSL setup completed on %s. Site is now available over HTTPS.\n' "$VM_NAME"
else
  printf 'Skipping SSL setup (no --contact-email provided). Run install-ssl.ps1 on the VM to enable HTTPS.\n'
fi
