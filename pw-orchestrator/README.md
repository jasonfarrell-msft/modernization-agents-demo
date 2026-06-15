# Playwright Orchestrator Scaffold

This folder provides a runnable scaffold to establish a modernization baseline for `legacy-upload-demo`.

## What it does

`orchestrate-baseline.sh` generates a timestamped baseline package under `pw-orchestrator/runs/<run-id>/`:

- `operator-prompt.txt` — prompt to send to your Playwright Orchestrator custom agent
- `baseline-contract.json` — baseline contract template to fill with run results
- `evidence.txt` — discovered app signals (upload route, allowed extensions, size limit)
- `runbook.sh` — execution reminders for the demo operator

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
  --app-url http://localhost:5000 \
  --mode scaffold
```

## Optional execute mode

`--mode execute` will try to run Playwright in `pw-orchestrator/playwright` if that project exists.

In execute mode, Playwright failures return a non-zero exit code.

It is safe to start with `scaffold` mode for demo preparation.
