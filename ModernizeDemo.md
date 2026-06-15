# Modernization Demo

## Section 1: Establish a Playwright Baseline

Use Playwright to capture the current behavior of `legacy-upload-demo` before making modernization changes.

### 1. Define baseline scope

- [ ] Identify the current user workflows in `legacy-upload-demo`.
- [ ] Focus only on observable behavior.
- [ ] Do not refactor or change application code.
- [ ] Capture known quirks, bugs, and edge cases as they exist today.
- [ ] Treat the baseline as the regression contract for modernization.

Baseline scope:

- Upload flow
- File validation behavior
- Success and error states
- Required fields and form behavior
- Navigation and page-level expectations
- Any legacy-specific behavior users depend on

### 2. Set up the test environment

From the repository root:

```bash
cd legacy-upload-demo
npm install
npx playwright install
```

Confirm the application can run locally.

```bash
npm start
```

In a separate terminal, confirm Playwright can execute.

```bash
npx playwright test
```

### 3. Define the Playwright test structure

Create a baseline test structure that separates current-state coverage from future modernization tests.

Recommended structure:

```text
legacy-upload-demo/
  tests/
    baseline/
      upload.spec.ts
      validation.spec.ts
      navigation.spec.ts
    fixtures/
      valid-upload-file.*
      invalid-upload-file.*
    artifacts/
```

Guidelines:

- [ ] Keep baseline tests readable and scenario-focused.
- [ ] Name tests after user-visible behavior.
- [ ] Avoid testing implementation details.
- [ ] Use fixtures for repeatable upload cases.
- [ ] Mark unclear behavior with comments for review, not fixes.

### 4. Capture baseline scenarios

Create Playwright tests for the current behavior.

Minimum baseline scenarios:

- [ ] Page loads successfully.
- [ ] Upload form renders with expected fields.
- [ ] Valid file upload completes successfully.
- [ ] Invalid file type shows the current error behavior.
- [ ] Missing file submission shows the current validation behavior.
- [ ] Large file behavior is documented.
- [ ] Cancel or reset behavior is captured if available.
- [ ] Success message or result page is captured.
- [ ] Error message content is captured.
- [ ] Browser console errors are reviewed and noted.

For each scenario, capture:

- User action
- Expected current result
- Screenshots where useful
- Any legacy behavior that may look incorrect but is currently relied on

### 5. Add CI integration expectations

The baseline should run automatically before modernization changes are accepted.

CI expectations:

- [ ] Run Playwright tests on pull requests.
- [ ] Run against the local app in CI.
- [ ] Upload Playwright reports as build artifacts.
- [ ] Review screenshots, traces, videos, and reports for sensitive data before sharing or retaining them.
- [ ] Define artifact retention limits to control storage cost.
- [ ] Fail the build on baseline regression.
- [ ] Preserve screenshots, traces, and videos for failed tests.

Expected command:

```bash
npx playwright test
```

Expected artifacts:

- Playwright HTML report
- Screenshots
- Traces
- Videos for failed tests
- Test result summary

Artifact handling:

- Store only the artifacts needed for review.
- Avoid retaining screenshots, traces, or videos that expose customer data, secrets, file contents, or credentials.
- Set short retention periods for CI artifacts unless longer retention is explicitly required.

### 6. Collect baseline artifacts

Before modernization work begins, collect and save the baseline evidence.

Artifacts to collect:

- [ ] Passing Playwright report
- [ ] Screenshots of key flows
- [ ] Trace files for critical scenarios
- [ ] Known failure list
- [ ] Notes on legacy behavior that should not change without approval
- [ ] CI run link or build summary

Baseline completion criteria:

- [ ] Core upload workflows are covered.
- [ ] Tests run locally.
- [ ] Tests run in CI.
- [ ] Artifacts are available for review.
- [ ] Known gaps are documented.
- [ ] Team agrees this is the modernization safety net.

Artifact review rules:

- Redact or discard artifacts that expose sensitive data.
- Keep failed-test videos and traces only when needed for diagnosis.
- Confirm storage retention settings before enabling artifact upload in CI.

### 7. Introduce the Playwright Orchestrator concept

Present the "Playwright Orchestrator" as a demo concept only.

Do not implement it in this section.

Position it as a workflow layer around Playwright that uses GitHub Copilot custom agents to assist with test generation, analysis, and iteration.

The orchestrator concept should:

- Accept a modernization goal or user workflow.
- Ask a GitHub Copilot custom agent to propose Playwright scenarios.
- Ask a GitHub Copilot custom agent to generate or update Playwright tests.
- Run the Playwright test suite.
- Collect failures, traces, screenshots, and reports.
- Feed results back into the next agent step.
- Keep humans in control of review and approval.

Demo framing:

- Keep Playwright as the execution engine.
- Use GitHub Copilot custom agents to assist with test generation, analysis, and iteration.
- Use the orchestrator to coordinate the workflow.
- The baseline tests are the source of truth.
- No production code changes happen until the baseline is trusted.

Suggested demo flow:

1. Show the existing `legacy-upload-demo` behavior.
2. Show the baseline Playwright scenarios.
3. Explain that custom agents can propose additional coverage.
4. Explain that the orchestrator would coordinate test generation and execution.
5. Run the baseline tests.
6. Review the Playwright report and artifacts.
7. State that modernization work starts only after this safety net is established.
