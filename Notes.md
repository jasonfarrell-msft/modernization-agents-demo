# Presenter Notes

## Key message

Baseline first. Modernization without a behavioral baseline is guessing.

## Why baseline first

- Establishes what the legacy app does today.
- Separates intentional changes from accidental regressions.
- Gives the team confidence before refactoring or replacing code.
- Creates objective evidence for customer and engineering review.
- Turns modernization into a controlled process instead of a rewrite gamble.

## What Playwright gives us

- End-to-end coverage of real user workflows.
- Browser-based validation of current behavior.
- Screenshots, traces, and videos for evidence.
- Repeatable tests for local and CI runs.
- A regression safety net before modernization begins.

## Simple explanation: Playwright Orchestrator

A Playwright Orchestrator is a coordination layer around Playwright.

It does not replace Playwright.

It helps coordinate steps like:

1. Understand the workflow.
2. Ask an agent to propose test scenarios.
3. Ask an agent to draft or update Playwright tests.
4. Run the tests.
5. Collect reports, traces, and screenshots.
6. Use the results to guide the next iteration.

In practice:

- Playwright runs the tests.
- GitHub Copilot custom agents assist with generation and analysis.
- The orchestrator manages the sequence.
- Humans approve changes.

## How to address the customer comment

Customer said:

> "I recently architected yet have not developed a Playwright Orchestrator utilizing GitHub Copilot custom agents to generate Playwright scripts, so I am interested in learning more about your approach and solutions."

Suggested response:

- "Our approach starts with the baseline. Before orchestrating generation, we establish trusted Playwright coverage for the legacy behavior."
- "The orchestrator concept fits after that: agents can suggest scenarios, generate tests, analyze failures, and iterate."
- "We keep Playwright as the execution layer and use custom agents as helpers in the workflow."
- "We also treat Playwright artifacts carefully because screenshots, traces, and videos can expose sensitive data and increase CI storage cost."
- "For this demo, we are not implementing the orchestrator yet. We are showing the foundation it would depend on."

## Likely Q&A

### Q: Why not start with agent-generated tests immediately?

A: We can, but we still need a trusted baseline. Generated tests are only useful if we know what behavior they are protecting.

### Q: What does the orchestrator actually do?

A: It coordinates the loop: propose tests, generate tests, run Playwright, collect artifacts, analyze failures, and prepare the next action.

### Q: Do custom agents replace test engineers?

A: No. They accelerate test creation and analysis. Humans still review intent, approve coverage, and decide what behavior matters.

### Q: Why Playwright instead of unit tests?

A: For modernization, the first risk is breaking user-visible behavior. Playwright validates workflows in the browser, which makes it a strong baseline tool.

### Q: What artifacts matter most?

A: HTML reports, screenshots, traces, videos for failures, and a known-behavior notes list.

### Q: When should modernization code changes begin?

A: After the baseline runs locally, runs in CI, and the team agrees it covers the critical legacy workflows.

### Q: How does this help with CI?

A: CI turns the baseline into an automated gate. Every modernization change must preserve approved behavior unless the team intentionally changes it.

### Q: What is the demo takeaway?

A: Establish the Playwright baseline first. Then use orchestration and custom agents to scale test creation, analysis, and modernization confidence.
