# Presenter Notes

## Key message

The demo is prompt-first: one operator prompt initiates baseline creation.

## Talk track

- We start with a baseline contract before any modernization.
- The baseline run is orchestrated, not manual.
- Playwright executes tests; GitHub Copilot custom agents accelerate scenario and test generation.
- Human approval remains the release gate.

## Simple explanation: Playwright Orchestrator

A Playwright Orchestrator is a workflow coordinator around Playwright.

It does four things:

1. Accepts a high-level prompt.
2. Routes work to GitHub Copilot custom agents (scenario generation, test generation, analysis).
3. Runs Playwright and captures evidence.
4. Returns a decision-ready summary for human approval.

## Customer-aligned response

Use this when addressing the customer statement:

- "We use a prompt-first orchestration model."
- "The orchestrator uses GitHub Copilot custom agents to generate and refine Playwright baseline tests."
- "Playwright remains the execution engine and source of behavioral truth."
- "We gate modernization behind a reviewed baseline contract."

## Suggested operator prompt for demo

```text
Establish a baseline test contract for legacy-upload-demo using Playwright.
Scope current user-visible behavior only.
Use GitHub Copilot custom agents to propose scenarios and generate baseline tests.
Run the baseline suite, collect artifacts, and return a gap summary with risks.
Do not modernize application code in this phase.
```

## Likely Q&A

### Q: Is this mostly manual?

A: No. The default flow is prompt-first orchestration. Manual steps are fallback only.

### Q: What is automated vs human?

A: Agents generate and analyze; Playwright executes; humans approve the baseline contract.

### Q: Why baseline first?

A: It creates a regression contract so modernization changes are intentional and measurable.

### Q: What evidence do we show?

A: Playwright report, traces, screenshots/videos for failures, and a gap summary.

### Q: Any security considerations?

A: Yes. We review artifacts for sensitive data and enforce retention limits to control exposure and cost.
