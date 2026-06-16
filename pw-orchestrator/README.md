# Playwright Orchestrator Scaffold

This folder provides a runnable scaffold to establish a modernization baseline for `legacy-upload-demo`.

## What it does

`orchestrate-baseline.sh` generates a timestamped baseline package under `pw-orchestrator/runs/<run-id>/`:

- `operator-prompt.txt` — prompt to send to your Playwright Orchestrator custom agent
- `baseline-contract.json` — generation contract/checklist for human review
- `evidence.txt` — discovered app signals (upload route, allowed extensions, size limit)
- `runbook.sh` — execution reminders for the demo operator

## Reliability policy (non-negotiable)

Generated baseline tests must be produced with pass-stability safeguards:

- strict-mode-safe selectors (no ambiguous filename `getByText(...)` assertions)
- dynamic upload target discovery (no fixed outage IDs or exact form action coupling)
- unique per-test upload filenames
- request-level oversized upload detection tolerance (IIS/gateway rejection surfaces included)
- failure-signal-first assertion order for error paths

The prompt and contract templates enforce these rules.

## Generate-only policy

The orchestrator flow is generation-only. Do not execute Playwright, npm scripts, or shell test commands in this step. Human review gates execution.

## Quick start

From repository root:

```bash
./pw-orchestrator/orchestrate-baseline.sh
```

Use the generated `operator-prompt.txt` as the single prompt for your orchestrator workflow.

## Options

```bash
./pw-orchestrator/orchestrate-baseline.sh --help
```

Most useful overrides:

```bash
./pw-orchestrator/orchestrate-baseline.sh \
  --app-url https://vm-legacy-swc.swedencentral.cloudapp.azure.com/
```
