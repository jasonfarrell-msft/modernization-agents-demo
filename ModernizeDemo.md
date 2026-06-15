# Modernization Demo

## Section 1: Establish a Playwright Baseline (Prompt-First)

Run this section as an orchestrated workflow, not a manual checklist.

### 1. Use the operator prompt

Start with a single prompt to the Playwright Orchestrator:

```text
Establish a baseline test contract for legacy-upload-demo using Playwright.
Scope current user-visible behavior only.
Use GitHub Copilot custom agents to propose scenarios and generate baseline tests.
Run the baseline suite, collect artifacts, and return a gap summary with risks.
Do not modernize application code in this phase.
```

### 2. Run the orchestrator phases

Require these phases in order:

1. Scope current behavior.
2. Generate baseline scenarios.
3. Generate or update baseline Playwright tests.
4. Execute the baseline Playwright suite.
5. Collect reports and diagnostics.
6. Produce a baseline summary and known gaps.
7. Pause for human approval.

### 3. Enforce baseline scope rules

- [ ] Test user-visible behavior only.
- [ ] Do not refactor app code.
- [ ] Preserve known legacy quirks unless explicitly approved to change.
- [ ] Treat baseline output as the regression contract for modernization.

### 4. Set baseline scenario minimums

Require these scenarios at minimum:

- [ ] Page loads successfully.
- [ ] Upload form renders expected fields.
- [ ] Valid file upload succeeds.
- [ ] Invalid file type shows current error behavior.
- [ ] Missing file submission shows current validation behavior.
- [ ] Large file behavior is captured.
- [ ] Cancel/reset behavior is captured (if present).
- [ ] Success outcome is captured.
- [ ] Error outcome is captured.

### 5. Set artifact and security rules

Collect:

- Playwright HTML report
- Screenshots
- Traces
- Videos for failures
- Gap summary

Enforce:

- [ ] Review artifacts for sensitive data before sharing.
- [ ] Redact or discard sensitive artifacts.
- [ ] Keep only required artifacts.
- [ ] Set short CI retention unless longer retention is explicitly required.

### 6. Set CI baseline gate expectations

- [ ] Run baseline Playwright tests on pull requests.
- [ ] Fail PRs on baseline regressions.
- [ ] Upload approved diagnostics for failed runs.
- [ ] Keep retention and access controls aligned with security policy.

Baseline command:

```bash
npx playwright test
```

### 7. Position the Playwright Orchestrator in the demo

Use this narrative:

1. Playwright is the test execution engine.
2. GitHub Copilot custom agents handle scenario/test generation and analysis.
3. The orchestrator coordinates the end-to-end loop.
4. Humans approve the baseline contract before modernization starts.

### 8. Use fallback environment setup only when needed

Use manual setup only if the environment is not ready for orchestrated execution.

Fallback setup:

```bash
cd legacy-upload-demo
npm install
npx playwright install
```
