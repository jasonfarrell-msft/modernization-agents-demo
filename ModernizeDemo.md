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

**Model Recommendation:** Use a frontier model (Claude Opus 4.6+ or GPT-5.3+) for this step. The test generation prompt is reasoning-heavy and requires understanding of multiple acceptance criteria, legacy quirks, resilient selectors, and error handling paths. Frontier models produce significantly better test coverage with less churn and iteration. Older/smaller models (e.g., Haiku) tend to generate brittle tests and require multiple refinement passes.

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

### 4. List generated tests from the terminal

From repo root, prepare Playwright dependencies and list all tests:

```bash
cd pw-orchestrator/playwright
( [ -f package-lock.json ] && npm ci || npm install )
npx playwright install
```

List all available tests:

```bash
npx playwright test --list
```

This will show:
- test files
- suites within each file
- individual test cases

### 5. Run tests from the terminal

Run all tests:

```bash
npx playwright test
```

Run a specific test file:

```bash
npx playwright test tests/upload.baseline.spec.ts
```

Run tests in headed mode (see the browser):

```bash
npx playwright test --headed
```

Run tests with verbose output:

```bash
npx playwright test --verbose
```

Review test results in the HTML report generated after the run:

```bash
npx playwright show-report
```

### 6. Review generated test artifacts

After tests complete, inspect the generated test and coverage artifacts under `pw-orchestrator/playwright/`.

## Section 2a: Modernize with GitHub Modernization Agent

Use the GitHub Modernization Agent to produce modernization changes and deployment artifacts with a container as the end state.

**IMPORTANT:** This section uses customer pattern standards extracted from `dotnet-patterns/` to guide modernization. These generated pattern files are NOT tracked by git.

### 0. Extract customer patterns and create modernization standards

Before running modernize-dotnet, establish pattern reference files that align modernization with customer standards.

#### Step 1: Extract patterns from dotnet-patterns into reference documents

Use GitHub Copilot to read the `dotnet-patterns/` folder and generate two files:
- `MODERNIZATION_PATTERNS.md` — consolidated reference of all patterns
- `AGENTS.md` — agent instructions that reference the patterns

Use this prompt in Copilot Chat:

```text
Read the entire dotnet-patterns folder and consolidate all patterns into two files:

1. MODERNIZATION_PATTERNS.md
   - One comprehensive reference document
   - Include all pattern READMEs (managed-identity, dependency-injection, error-handling-resilience, observability-diagnostics, class-separation-srp, naming-conventions)
   - For each pattern: include the README content + key code examples from the examples/ folder
   - Add a brief intro explaining these are customer standards
   - Format for easy agent reference (headings, bullets, code blocks)

2. AGENTS.md
   - Create with this structure:
     ---
     name: Modernization Standards
     description: Customer-aligned patterns for .NET modernization
     ---
     ## When Modernizing .NET Projects
     Reference MODERNIZATION_PATTERNS.md for:
     - Managed Identity patterns (authentication/authorization)
     - Dependency Injection configuration and lifecycle management
     - Error Handling & Resilience (circuits, retries, idempotent commands, ProblemDetails)
     - Observability & Diagnostics (structured logging, correlation IDs, request context)
     - Class Separation & SRP (single responsibility, cohesion)
     - Naming Conventions (casing, clarity, legacy vs modern)
     
     ## Required Pattern Application
     Modernization agents MUST:
     - Read MODERNIZATION_PATTERNS.md before planning
     - Apply managed-identity patterns to remove hardcoded credentials
     - Apply DI patterns to configuration, middleware, and service setup
     - Apply error-handling patterns to middleware, command handlers, and APIs
     - Apply observability patterns to logging, diagnostics, and tracing
     - Apply SRP improvements to refactored classes
     - Apply naming conventions during modernization
     - Cite which patterns were applied during implementation
   - Stop. Do not execute. Return only the files created.

Execution constraints:
- Create files in the repository root only
- Do not modify existing files
- Do not commit to git; these files will be added to .gitignore
```

After Copilot finishes, confirm both files exist:
- [ ] `MODERNIZATION_PATTERNS.md` created
- [ ] `AGENTS.md` created

### 1. Set modernization target and constraints

Target state:

- [ ] Application targets **.NET 10**.
- [ ] Application is packaged as a **container** suitable for Azure deployment.
- [ ] Legacy persistence services are replaced with modern equivalents.
- [ ] Deployment artifacts exist for **Azure Container Apps (ACA)** in a chosen resource group.

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

### 2. Send modernization prompt to the GitHub Modernization Agent (modernize-dotnet)

**Prerequisites:**
- [ ] `MODERNIZATION_PATTERNS.md` exists in repo root
- [ ] `AGENTS.md` exists in repo root
- [ ] Both files are listed in `.gitignore`

Use this prompt in VS Code with the modernize-dotnet agent:

```text
Modernize legacy-upload-demo into a containerized .NET 10 application for Azure deployment using customer pattern standards.

Reference MODERNIZATION_PATTERNS.md and AGENTS.md from the repository root for all design decisions.

Execution mode (non-negotiable):
- Demo speed mode: prioritize execution speed over process overhead.
- Automatic flow: do not pause for stage approvals unless blocked by missing required input.
- Use safe defaults for non-critical decisions; do not ask preference questions when a reasonable default exists.
- If a workflow tool times out twice or is unavailable, immediately use the closest direct implementation path and continue.
- No exploratory loops or optional review-agent passes unless explicitly requested.

Scope and safety:
- Create all modernization implementation in a new sibling directory: legacy-upload-demo-modernized
- Do not modify files under the existing legacy-upload-demo application tree.
- Keep user-visible behavior aligned with the Playwright baseline contract.
- Pattern compliance is MANDATORY, not optional (see AGENTS.md and MODERNIZATION_PATTERNS.md)

Technical requirements:
- Target .NET 10.
- Apply patterns from MODERNIZATION_PATTERNS.md for:
  - Managed Identity (remove all hardcoded secrets/credentials)
  - Dependency Injection (externalize configuration, apply DI principles)
  - Error Handling & Resilience (middleware, circuit breakers, retry policies)
  - Observability & Diagnostics (structured logging, correlation IDs, request tracing)
  - Class Separation & SRP (refactor for single responsibility)
  - Naming Conventions (apply customer standards)
- Replace legacy persistence patterns with cloud-native equivalents:
  - local file upload storage -> object storage abstraction
  - on-prem SQL access -> managed cloud database access
  - SMTP pickup/file-drop notifications -> managed messaging/notification integration
  - local audit file logging -> centralized structured telemetry/logging
- Remove machine-bound assumptions and make the app stateless for container scale-out.
- Externalize configuration/secrets and use Managed Identity where possible.
- Produce Dockerfile/containerization updates and Azure-ready runtime configuration.
- Produce Bicep deployment artifacts for Azure Container Apps targeting a specified resource group.

Output only:
1) Change plan (implementation-focused, no exploratory alternatives, with pattern citations)
2) File-by-file modifications (with pattern category applied)
3) Infrastructure/runtime config changes needed for container and ACA deployment
4) Pattern application summary (which patterns were applied where)
5) Risks and manual follow-up items
```

### 3. Review generated modernization output before applying

Confirm:

- [ ] .NET 10 target is explicit.
- [ ] Persistence replacements are explicitly mapped (old -> new).
- [ ] Containerization artifacts are present.
- [ ] ACA deployment artifacts are called out.
- [ ] Local run instructions exist for `legacy-upload-demo-modernized`.
- [ ] Carried-forward Playwright tests can target a local base URL for the modernized app.
- [ ] No plaintext secrets are introduced.
- [ ] Baseline behavior compatibility is called out.
- [ ] Pattern application is cited (managed-identity, DI, error-handling, observability, SRP, naming-conventions).
- [ ] All patterns from MODERNIZATION_PATTERNS.md were reviewed before design decisions.

### 4. Apply generated changes and validate against baseline

1. Apply the generated modernization changes.
2. Start `legacy-upload-demo-modernized` locally.
3. Run the carried-forward Playwright baseline tests against the local modernized app URL.
4. Record pass/fail and gaps.
5. Keep remediation items separate from this section's generated output.
6. Verify pattern application in code changes (DI, Managed Identity, error handling, observability, SRP, naming conventions).

## Section 2b: Custom Agent Modernization

### 0. Start standards context locally (required before Section 2b prompts)

Ensure the client standards sources are available to the agent before running any Section 2b modernization prompts.

1. Start the local `dotnet-patterns` MCP server:

```bash
dotnet build mcp-servers/dotnet-patterns-mcp/PatternsMcp.Server.csproj
PATTERNS_PATH=/Users/jasonfarrell/Projects/modernization-demo/dotnet-patterns \
dotnet run --project mcp-servers/dotnet-patterns-mcp --no-build -c Release
```

2. Ensure the **improve** skill exists at user scope so it is available across projects (no git clone path):

Use this prompt in Copilot Chat:

```text
Create or update a local user-scoped skill named "improve" at ~/.github/skills/improve using the contents/spec from https://github.com/shadcn/improve.

Constraints:
- Do not run git clone, git pull, or any git-based sync command.
- If ~/.github/skills/improve already exists, update files in place to match the latest skill structure.
- If it does not exist, create the folder and required skill files directly.
- Preserve local file permissions and avoid touching unrelated folders.

Return only:
1) Files created/updated
2) Any manual follow-up needed
```

3. Confirm both are ready:
   - MCP server process is running and reachable by your MCP-capable client.
   - `~/.github/skills/improve` exists locally.

### 1. Create the modernization plan with the improve skill

Use the **improve** skill to produce the plan only. Do not generate implementation in this step.

Use this prompt:

```text
Use the improve skill to create a modernization plan only for legacy-upload-demo.

Execution boundary:
- Source folder is read-only: legacy-upload-demo
- Destination folder must be a new sibling directory named exactly: legacy-upload-improve
- Do not modify legacy-upload-demo, pw-orchestrator/playwright, dotnet-patterns, or shared repo-level configuration in this planning step
- Do not create, edit, move, delete, or format files in this step

Planning goals:
- Modernize the application into legacy-upload-improve
- Preserve current user-visible behavior defined by the Playwright baseline contract
- Bring the existing Playwright baseline tests forward as validation assets for the modernized app
- End state must produce a containerized application deployable to Azure Container Apps

Required planning coverage:
- target framework and project structure
- container build/runtime approach
- local run instructions for the modernized app
- configuration and secret externalization
- storage/persistence modernization
- authentication/authorization approach
- observability and diagnostics
- error handling and resilience
- class separation / SRP improvements
- naming conventions and code organization
- test migration/carry-forward approach for Playwright
- local Playwright execution against a configurable base URL
- ACA deployment artifacts and deployment prerequisites
- Service Principal scope and least-privilege deployment requirements

Output only:
1) modernization phases
2) file/folder creation plan for legacy-upload-improve
3) dependency/package plan
4) containerization plan
5) ACA deployment plan (Bicep + deployment identity flow)
6) risk list
7) validation plan tied to the existing Playwright baseline
```

### 2. Review the plan before execution

Confirm the plan explicitly states:

- [ ] `legacy-upload-demo` remains unchanged
- [ ] all new implementation goes into `legacy-upload-improve`
- [ ] Playwright tests are carried forward and not regenerated as a weaker contract
- [ ] `legacy-upload-improve` must run locally before deployment work begins
- [ ] carried-forward Playwright tests must run against a local base URL for `legacy-upload-improve`
- [ ] container target is Azure Container Apps deployable
- [ ] client standards are applied through MCP-backed pattern guidance

### 3. Execute the modernization plan with the dotnet-patterns MCP server

Run the implementation step only after the MCP server from Step 0 is available.

Use this prompt:

```text
Implement the approved modernization plan using the local dotnet-patterns MCP server as a required standards source.

Execution boundary:
- Read from: legacy-upload-demo
- Write only to: legacy-upload-improve
- Do not modify legacy-upload-demo
- Do not modify pw-orchestrator/playwright baseline tests
- Do not weaken assertions or alter tests to make the modernization pass
- If the dotnet-patterns MCP server is unavailable, stop and report that blocker instead of continuing

Required MCP usage:
- Query the local dotnet-patterns MCP server before implementation
- Use the pattern guidance as a hard constraint, not optional reference
- Cite which pattern areas were applied during implementation decisions
- At minimum, review and apply guidance from:
  - managed-identity
  - dependency-injection
  - observability-diagnostics
  - error-handling-resilience
  - class-separation-srp
  - naming-conventions

Implementation goals:
- Create a modernized application in legacy-upload-improve
- Keep user-visible behavior aligned with the existing Playwright baseline
- Bring over the Playwright test assets needed to validate the modernized app
- Ensure the modernized app can be started locally for validation
- Ensure the carried-forward Playwright tests can target the app through a configurable local base URL
- Produce a containerized application suitable for Azure Container Apps deployment
- Externalize configuration and avoid hardcoded secrets, keys, or user-specific paths
- Produce Bicep deployment artifacts targeting a specified resource group
- Prepare deployment steps for a newly created deployment-only Service Principal

Output only:
1) files created/updated under legacy-upload-improve
2) pattern categories applied and where they influenced the design
3) container/runtime notes
4) ACA/Bicep deployment artifacts and where they live
5) validation steps to run the carried-forward Playwright baseline against the modernized app
6) blockers or follow-up items
```

### 4. Validate execution boundaries after generation

Before applying or reviewing generated changes, confirm:

- [ ] no files were changed under `legacy-upload-demo`
- [ ] all modernization output is under `legacy-upload-improve`
- [ ] baseline Playwright tests were preserved as the validation contract
- [ ] MCP pattern guidance is reflected in the generated output
- [ ] container and ACA deployment artifacts are present
- [ ] `legacy-upload-improve` can run locally
- [ ] carried-forward Playwright tests can run locally against `legacy-upload-improve`

## Section 3: Manual Container Deployment to Azure Container Apps

Trigger deployment manually only after choosing which app to deploy.

### 1. Select the deployment target

Choose exactly one:

- `legacy-upload-demo-container`
- `legacy-upload-improve`

Do not infer a default target.

### 2. Prepare deployment setup

Use this prompt:

```text
Prepare the final manual deployment path to Azure Container Apps for a selected app target (`legacy-upload-demo-container` or `legacy-upload-improve`) using a newly created deployment-only Service Principal and Bicep.

Constraints:
- Deployment is manual-only. Do not auto-deploy as part of modernization or planning.
- Require the operator to explicitly provide the chosen app target before producing deploy commands.
- Do not hardcode, print, commit, or persist Service Principal secrets, tokens, or credentials in repository files
- Scope the Service Principal to the desired resource group only
- Do not use Owner; use least-privilege RBAC suitable for ACA/Bicep deployment
- If any required deployment identity inputs are missing, stop and report them instead of inventing defaults
- Use the local dotnet-patterns MCP server guidance where relevant for managed identity, diagnostics, resilience, and naming

Required deployment coverage:
- Service Principal creation command(s)
- Required environment variables for secure local use
- Bicep for ACA environment, Container App, ingress, configuration, and diagnostics
- Parameterization for resource group, location, container image, and app settings
- Validation and deployment commands
- Post-deployment smoke-test steps
- Explicit prerequisite that the selected app has already passed local Playwright validation

Output only:
1) Service Principal creation steps
2) Bicep files and parameters required
3) Validation and deployment commands for the chosen resource group
4) Post-deployment verification steps
5) Any manual secrets/configuration that must be supplied securely outside the repo
```
