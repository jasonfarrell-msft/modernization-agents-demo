# Modernization Demo

## Section 1: Establish a Playwright Baseline (Prompt-First)

Run this section as an orchestrated workflow, not a manual checklist.

### 1. Generate a baseline run package

From the repository root:

```bash
./pw-orchestrator/orchestrate-baseline.sh
```

Use the Azure-hosted app target, not localhost:

```bash
./pw-orchestrator/orchestrate-baseline.sh --app-url https://vm-legacy-swc.swedencentral.cloudapp.azure.com/
```

Use the generated run folder:

```text
pw-orchestrator/runs/<run-id>/
```

### 2. Execute the generated operator prompt

Preferred: start a new GHCP session, then send the generated prompt from:

```text
pw-orchestrator/runs/<run-id>/operator-prompt.txt
```

It will look like this (values resolved for that run, not placeholders):

```text
Establish a baseline test contract for legacy-upload-demo using Playwright.
Scope current user-visible behavior only.
Generate-only mode: generate or update baseline Playwright tests under pw-orchestrator/playwright.
Do not execute Playwright, unit tests, npm scripts, or shell test commands.
Use legacy-tolerant assertions and avoid hard-coded form-action/id selectors.
For oversized upload, support accepted outcomes: upload-page validation, details/error-page failure signal, or request-level rejection signal.
Pause and return only: scenario matrix (targeted app areas), test file list, coverage intent (planned only), and accepted outcomes with primary/fallback assertions.
Do not modernize application code in this phase.
```

If you stay in the current session, treat it as a new run and use only this run folder's artifacts.

### 3. Confirm generate-only output

After the operator prompt completes:

1. Review generated files under `pw-orchestrator/playwright`.
2. Confirm the output includes only:
   - Scenario matrix (targeted app areas)
   - Playwright test file list
   - Coverage intent (planned, not executed)

### 4. Prerequisites for VS Code test visualization and run

Install and verify:

- [ ] Visual Studio Code
- [ ] **Playwright Test for VS Code** extension
- [ ] Node.js and npm available in terminal

From repo root, prepare Playwright dependencies:

```bash
cd pw-orchestrator/playwright
( [ -f package-lock.json ] && npm ci || npm install )
npx playwright install
```

### 5. Visualize generated tests in VS Code

1. Open folder: `pw-orchestrator/playwright`
2. Open the **Testing** view (beaker icon).
3. Expand the Playwright tree to show:
   - test files
   - suites
   - test cases
4. Use this tree as the visual map of what was generated and what app areas are targeted.

### 6. Run tests from VS Code

1. In **Testing**, click **Run All Tests** (play button), or run a single file/suite/test.
2. Review pass/fail status in the Testing panel.
3. Open failure details from Testing output and Playwright artifacts as needed.
