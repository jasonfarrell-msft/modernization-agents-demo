# Main Demo: Reverse-Engineering App Behavior into Playwright Tests

> Execution steps only. For call-outs, talking points, and rationale, see `NOTES.md`.

## Expected Outcome (Definition of Done)
When these steps are complete, we will have:
- A set of **unit tests** and **Playwright UI tests** that capture the app's *current* behavior as a regression baseline.
- The **unit tests gating the main workflow** (`.github/workflows/deploy-legacy-web.yml`) — they run in the build job and block deploy on failure.
- A **new, manually-triggered Playwright workflow** (`.github/workflows/e2e-playwright.yml`, `workflow_dispatch`) that runs the UI suite on demand and publishes traces.

> Stack note: this is a .NET Framework 4.8 web app (`OgeFieldOps.Web`) built with MSBuild/NuGet and deployed to IIS. Unit tests use the .NET toolchain; Playwright runs via Node against the running site.

## Prerequisites
1. Pin tooling versions: Node and Playwright are pinned in `package.json`.
2. Seed the database/test data to a known state.
3. Start the app on a fixed port and confirm it loads:
   ```bash
   # start the app (adjust to this repo's start command)
   npm start
   # in a second terminal, verify it responds
   curl -s -o /dev/null -w "%{http_code}\n" http://localhost:<port>
   ```
4. Have the `demo-known-good` fallback branch ready with tests pre-committed.

## Part 1 — Unit Tests (agent-authored)

### Step 1: Generate unit tests
Prompt the agent:
> "Map the existing functionality of the OgeFieldOps.Web app and generate a .NET unit
> test project that asserts current behavior (characterization tests). Cover the core
> logic/controllers. Don't change application code."

### Step 2: Run unit tests locally (confirm green)
```bash
dotnet test
# .NET Framework alternative:
# vstest.console.exe <TestProject>.dll
```

### Step 3: Add unit tests to the MAIN workflow as a gate
Prompt the agent:
> "Update the main workflow `.github/workflows/deploy-legacy-web.yml` to restore, build,
> and run the unit test suite in the build job. Fail the build (and therefore block the
> deploy job) if any test fails."

### Step 4: Verify the pipeline change
```bash
git diff .github/workflows/deploy-legacy-web.yml
```

## Part 2 — Playwright UI Tests (agent-authored, CI-run)

### Step 5: Discover behavior (build the inventory)
Prompt the agent:
> "Explore the running app at `http://localhost:<port>`. Map the primary user journeys,
> forms, and visible states. List each journey as: trigger → steps → expected observable
> outcome. Don't write tests yet — just produce the behavior inventory."

### Step 6: Generate Playwright tests from the inventory
Prompt the agent:
> "For each journey in the inventory, generate a Playwright test that asserts the current
> observed behavior. Use role-based locators (`getByRole`, `getByText`), avoid brittle CSS
> selectors, and enable trace-on-first-retry. Place specs in `tests/e2e/`."

### Step 7: Run Playwright locally (confirm green, headed)
```bash
npx playwright test --headed
```

### Step 8: Create the NEW manually-triggered Playwright workflow
Prompt the agent:
> "Create a new workflow `.github/workflows/e2e-playwright.yml` that is **manually
> triggered** via `workflow_dispatch`. Install browsers with
> `npx playwright install --with-deps`, run the suite headless, and upload traces via
> `actions/upload-artifact`. Keep it separate from the main deploy workflow."

### Step 9: Commit, then trigger the Playwright workflow manually
```bash
git checkout -b add-playwright-tests
git add tests/ .github/workflows/e2e-playwright.yml
git commit -m "Add agent-authored Playwright tests and manual CI workflow"
git push -u origin add-playwright-tests
# Manually trigger the new workflow and watch it run
gh workflow run e2e-playwright.yml --ref add-playwright-tests
gh run watch
```

## Part 3 — Prove the Gate

### Step 10: Introduce a deliberate regression
Make a small, visible UI change that breaks one asserted behavior.

### Step 11: Show the gate fail
```bash
# Locally:
npx playwright test
# Or re-run the manual workflow and watch it go red:
gh workflow run e2e-playwright.yml --ref add-playwright-tests
gh run watch
```

### Step 12: Fix and confirm green
Revert the regression (or have the agent fix it), then re-run:
```bash
npx playwright test
gh workflow run e2e-playwright.yml --ref add-playwright-tests
gh run watch
```

## Cleanup
```bash
git checkout main
git branch -D add-playwright-tests   # if discarding the demo branch
```
