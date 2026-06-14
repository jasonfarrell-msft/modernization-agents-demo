# Improve Modernize Demo Script

Use this brief when you want the GitHub Modernization Agent to apply the improve custom skill to the legacy sample and produce a modernization plan grounded in patterns from a local MCP-backed repo.

## Upfront plan
1. Begin with a brief assessment of the legacy app and identify the few highest-impact modernization risks.
2. Use the improve skill to generate a concise, cost-aware plan rather than a full rewrite.
3. Use the local MCP repo only for targeted pattern capture that adds real value to the modernization plan.
4. End with a simple next-step checklist the user can follow.

## Goal
Use the improve custom skill to audit the legacy upload sample, identify modernization gaps, and generate a concrete improvement plan that also incorporates patterns and practices from a local demo repo.

## New flow for this demo
1. Start by using GHCP to document the key user flows and save them to a local ignored markdown file in this repo.
2. Convert those flows into Playwright tests that validate the UI remains stable through the modernization work.
3. Then use the improve skill and the local MCP repo to plan the modernization work with lower cost and better context.
4. Keep the alternative demo path focused on the modernization result, since the UI baseline is already protected by Playwright.

## Repo to use for the improve skill
- Official improve repo: https://github.com/shadcn/improve
- The agent should use the improve workflow to analyze the codebase and produce a plan for a cheaper/safer modernization path.

## Demo setup
1. Point the agent at this repository root.
2. Instruct it to use the improve custom skill to audit the legacy app in `legacy-upload-demo/LegacyUploadDemo`.
3. Ask it to bring in patterns and practices from a locally deployed MCP server that reads from a custom local folder/demo repo.
4. Ask it to produce a modernization plan, not to fully rewrite the app in this step.

## What to emphasize
- Use the improve skill for codebase auditing and plan generation.
- Provide the improve repo URL as a reference for the skill and its intended workflow.
- Use a locally deployed MCP server to surface reusable patterns from a custom local folder for the demo.
- Keep the output focused on:
  - architecture modernization
  - secure configuration
  - Azure-ready storage and database choices
  - containerization and deployment readiness

## Suggested prompt to paste into the Modernization Agent

"Start with a short plan, then use the improve custom skill to audit the legacy upload sample in `legacy-upload-demo/LegacyUploadDemo` and generate a cost-aware modernization plan. Provide the repo URL for the improve project: https://github.com/shadcn/improve. Also use a locally deployed MCP server to bring in only the most relevant patterns and practices from a custom local demo folder/repo in this workspace. Keep the plan concise, guide the user through the workflow, and focus on high-value, low-cost steps for .NET 10, secure configuration, Azure-ready storage/database choices, and container deployment readiness."

## Local MCP/demo note
- The local MCP should be configured to read from a custom local folder in this demo repo so the agent can reference repository patterns and practices during planning.
- The plan should explicitly call out which recommendations come from the improve workflow versus which come from the local MCP pattern repository.
