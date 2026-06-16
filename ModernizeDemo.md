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

## Section 2: Modernize for .NET 10 + Azure Red Hat OpenShift

Use the GitHub Modernization Agent to produce modernization changes only. Do not deploy in this section.

### 1. Set modernization target and constraints

Target state:

- [ ] Application targets **.NET 10**.
- [ ] Application is container-ready for **Azure Red Hat OpenShift (ARO)**.
- [ ] Legacy persistence services are replaced with modern equivalents.

Persistence modernization requirements:

- [ ] Server-local file storage -> Azure Blob Storage (or equivalent object storage abstraction).
- [ ] On-prem SQL persistence -> Azure SQL-compatible managed persistence with secure connectivity.
- [ ] SMTP pickup/drop folders -> managed messaging/notification service integration.
- [ ] Local file-based audit/log persistence -> structured app telemetry + centralized logging.

Security and platform requirements:

- [ ] Managed Identity first; no hardcoded secrets.
- [ ] Secrets/config from secure store and environment-based configuration.
- [ ] HTTPS-only runtime settings.
- [ ] Stateless app behavior compatible with horizontal scaling in containers.

### 2. Send modernization prompt to the GitHub Modernization Agent

Use this prompt:

```text
Modernize legacy-upload-demo for containerized deployment on Azure Red Hat OpenShift.

Requirements:
- Target .NET 10.
- Replace legacy persistence patterns with modern cloud-native equivalents:
  - local file upload storage -> object storage abstraction
  - on-prem SQL access -> managed cloud database access
  - SMTP pickup/file-drop notifications -> managed messaging/notification integration
  - local audit file logging -> centralized structured telemetry/logging
- Remove machine-bound assumptions and make the app stateless for container scale-out.
- Externalize configuration and secrets; use Managed Identity where possible.
- Produce Dockerfile/containerization updates and OpenShift-ready runtime configuration.
- Keep behavior aligned with baseline tests.

Output only:
1) Change plan
2) File-by-file modifications
3) Infrastructure/runtime config changes needed for ARO readiness
4) Risks and any manual follow-up items
```

### 3. Review generated modernization output before applying

Confirm:

- [ ] .NET 10 target is explicit.
- [ ] Persistence replacements are explicitly mapped (old -> new).
- [ ] Containerization artifacts are present and OpenShift-compatible.
- [ ] No plaintext secrets are introduced.
- [ ] Baseline behavior compatibility is called out.

### 4. Apply generated changes and validate against baseline

1. Apply the generated modernization changes.
2. Run the existing baseline Playwright tests.
3. Record pass/fail and gaps.
4. Keep remediation items separate from this section's generated output.
