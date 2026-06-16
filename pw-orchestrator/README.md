# Playwright Orchestrator

A generalized Playwright test orchestration pipeline with pluggable discovery
adapters, currently validated against one ASP.NET MVC legacy app.

## What it does

A single command that runs a complete test pipeline:

```bash
./pw-orchestrator/orchestrate.sh \
  --app-url https://your-app.example.com/ \
  --app legacy-upload-demo \
  --adapter aspnet-mvc \
  --app-source legacy-upload-demo/OgeFieldOps.Web
```

**Pipeline stages:**

| Stage | Name | Action |
|-------|------|--------|
| 1 | Discover | Run adapter against app source to extract routes, extensions, limits, messages |
| 2 | Configure | Write `.env` consumed by Playwright config |
| 3 | Generate | Invoke Copilot coding agent if `--regenerate` is passed |
| 4 | Install | `npm ci` + Playwright browsers |
| 5 | Execute | Run Playwright tests (traces and screenshots on failure only) |
| 6 | Report | Collect artifacts and produce a JSON summary |

## Quick start

All flags are required — there are no hardcoded defaults:

```bash
./pw-orchestrator/orchestrate.sh \
  --app-url https://your-app.example.com/ \
  --app legacy-upload-demo \
  --adapter aspnet-mvc \
  --app-source legacy-upload-demo/OgeFieldOps.Web
```

## Options

```
--app-url URL         Target application URL (running instance) [required]
--app-source PATH     Path to the app source directory (absolute or relative
                      to repo root). Used by the discovery adapter. [required]
--app NAME            App test suite name (matches folder under
                      playwright/apps/) [required]
--adapter NAME        Discovery adapter name (matches file under
                      adapters/) [required]
--regenerate          Force Copilot to regenerate tests
--skip-install        Skip npm install and browser download
--headed              Run tests in headed mode (visible browser)
--help                Show help
```

## Architecture

Three-layer separation:

```
pw-orchestrator/
├── orchestrate.sh                  # Pipeline script (framework)
├── adapters/
│   └── aspnet-mvc.sh               # Pluggable discovery adapter
└── playwright/
    ├── playwright.config.ts         # Playwright config (framework)
    ├── helpers/
    │   ├── discovery.ts             # Reads .env into typed config (framework)
    │   └── test-utils.ts            # Generic test utilities (framework)
    └── apps/
        └── legacy-upload-demo/      # App-specific layer
            ├── app-helpers.ts       # App navigation, selectors, failure signals
            └── tests/               # App test specs
```

**Framework** — reusable across any app. No app-specific knowledge.

**Adapters** — pluggable source code parsers. Output `KEY=VALUE` pairs to stdout,
human-readable logs to stderr. Report discovery confidence (HIGH/MEDIUM/LOW).

**App-specific** — navigation helpers, selectors, and tests for one app.

## Adding a new app

1. Create a discovery adapter in `adapters/` (or reuse an existing one)
2. Create `playwright/apps/<your-app>/app-helpers.ts` with navigation and selectors
3. Create test specs in `playwright/apps/<your-app>/tests/`
4. Run: `./pw-orchestrator/orchestrate.sh --app your-app --adapter your-adapter ...`

## Prerequisites

The target app must have seed data — at least one record with an upload action.
Tests upload files and do not clean up after themselves; use a disposable test
environment.

## Artifacts

After a run, results are collected under `pw-orchestrator/results/`:

```
results/
├── summary.json          # Machine-readable summary with pass/fail counts
├── execution.log         # Full test output
├── adapter.log           # Discovery adapter output
├── html-report/          # Playwright HTML report
├── test-results.json     # Detailed per-test results
└── test-artifacts/       # Traces, screenshots, videos (on failure only)
```

View the HTML report:

```bash
cd pw-orchestrator/playwright && npx playwright show-report ../results/html-report
```

## Test suite (legacy-upload-demo)

Baseline tests cover 6 scenarios:

| Test | What it validates |
|------|-------------------|
| `page-load` | Homepage and list page load without errors |
| `upload-form` | Upload form renders with file input, button, cancel link |
| `valid-upload` | PDF/CSV/TXT uploads succeed and appear in documents table |
| `invalid-extension` | .exe/.bat files are rejected with visible error |
| `missing-file` | Submitting without a file shows validation message |
| `oversized-file` | Files over the limit trigger a failure signal |

## Design principles

- **No hardcoded assumptions**: Framework code has zero app-specific knowledge
- **Pluggable discovery**: Adapters extract config from source with confidence levels
- **Resilient selectors**: Role/semantic locators, no brittle CSS paths
- **Dynamic discovery**: Upload target found via UI navigation, not hard-coded IDs
- **Unique artifacts**: Each test generates unique filenames to avoid collisions
- **Self-contained payloads**: In-memory file buffers, no external fixture dependencies
- **Legacy-tolerant assertions**: Oversized upload accepts multiple valid failure paths
- **Failure-only artifacts**: Traces and screenshots captured only on failure to reduce noise
