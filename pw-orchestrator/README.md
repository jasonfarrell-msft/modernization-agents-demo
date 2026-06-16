# Playwright Orchestrator

Full-pipeline Playwright orchestration for `legacy-upload-demo`.

## What it does

A single command that runs a complete test pipeline:

```
./pw-orchestrator/orchestrate.sh
```

**Pipeline stages:**

| Stage | Name | Action |
|-------|------|--------|
| 1 | Discover | Parse legacy app source for routes, extensions, limits, messages |
| 2 | Configure | Write `.env` consumed by Playwright config |
| 3 | Generate | Invoke Copilot coding agent if no tests exist (or `--regenerate`) |
| 4 | Install | `npm ci` + Playwright browsers |
| 5 | Execute | Run Playwright tests with traces enabled |
| 6 | Report | Collect artifacts and produce a JSON summary |

## Quick start

```bash
./pw-orchestrator/orchestrate.sh
```

Override the app URL:

```bash
./pw-orchestrator/orchestrate.sh --app-url https://your-legacy-app.example.com/
```

## Options

```
--app-url URL         Target application URL
--regenerate          Force Copilot to regenerate tests
--skip-install        Skip npm install and browser download
--headed              Run tests in headed mode (visible browser)
--help                Show help
```

## Artifacts

After a run, results are collected under `pw-orchestrator/results/`:

```
results/
├── summary.json          # Machine-readable summary with pass/fail counts
├── execution.log         # Full test output
├── html-report/          # Playwright HTML report
├── test-results.json     # Detailed per-test results
└── test-artifacts/       # Traces, screenshots, videos
```

View the HTML report:

```bash
cd pw-orchestrator/playwright && npx playwright show-report ../results/html-report
```

## Test suite

Baseline tests cover 6 scenarios:

| Test | What it validates |
|------|-------------------|
| `page-load` | Homepage and outages list load without errors |
| `upload-form` | Upload form renders with file input, button, cancel link |
| `valid-upload` | PDF/CSV/TXT uploads succeed and appear in documents table |
| `invalid-extension` | .exe/.bat files are rejected with visible error |
| `missing-file` | Submitting without a file shows validation message |
| `oversized-file` | Files over the limit trigger a failure signal |

## Design principles

- **Resilient selectors**: Role/semantic locators, no brittle CSS paths
- **Dynamic discovery**: Upload target found via UI navigation, not hard-coded IDs
- **Unique artifacts**: Each test generates unique filenames to avoid collisions
- **Self-contained payloads**: In-memory file buffers, no external fixture dependencies
- **Legacy-tolerant assertions**: Oversized upload accepts multiple valid failure paths
- **Traces always on**: Every run captures full traces for debugging
