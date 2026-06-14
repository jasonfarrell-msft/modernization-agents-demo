# Squad Demo: Small Outage Triage App

This folder is intentionally designed for a first-time Squad walkthrough with OGE-style content, but kept small enough to finish quickly.

## Goal
Show how Squad can assemble a small delivery team with at least one specialist role beyond the usual app roles.

Use this scenario for a short, high-signal demo:
- a simple outage triage dashboard for an OGE-style operations environment
- one clearly visible specialist agent for outage/transmission reasoning
- minimal implementation scope so the team can finish in one session

This is not a modernization demo. It is a Squad introduction demo.

## Recommended scenario
Build a lightweight web page that displays:
- current outage incidents
- severity and affected area
- recommended first-response actions
- a short note from an operations specialist

Keep the app to one page and one mock data file. Do not add a full backend, database, or containerized deployment for the first demo.

## Why this works
- It is easy to explain in one sentence: "Squad helps a team build a small operational tool with specialist judgment."
- It proves that Squad is more than a generic coder.
- It gives you a natural place to show custom agents and role-specific prompts.

## Suggested Squad composition
Use a small team like this:

1. Product/Scenario Agent
   - Defines the user story and acceptance criteria.
   - Keeps the scope narrow.

2. Frontend Engineer Agent
   - Builds the dashboard UI.
   - Uses simple HTML/CSS/JavaScript or a very small React view.

3. Operations Specialist Agent (the non-typical role)
   - Reviews outage severity, suggested crew response, and safety notes.
   - Adds the domain-specific logic that a standard app developer would miss.

4. QA Agent
   - Verifies the page renders correctly.
   - Confirms the mock data and response guidance are sensible.

This gives you at least one specialist outside the usual development roles.

## Simple implementation plan
Use the lightest possible stack:
- static HTML/CSS/JavaScript
- one mock JSON file for outage data
- optional simple local server if needed

Avoid:
- full Azure deployment
- database setup
- heavy framework scaffolding
- long-running background tasks

## Suggested folder layout
```text
multi-agent-dev/
  README.md
  data/
    outages.json
  app/
    index.html
    styles.css
    app.js
```

## How to set up Squad
1. Start with the standard GHCP / Copilot agent setup you already use.
2. Create a small custom agent for the Operations Specialist role.
3. Add a simple Frontend Engineer agent for the UI.
4. Add a QA agent to validate the demo flow.
5. Keep the prompts short and role-specific.

## Sample agent roles

### 1. Operations Specialist Agent
Use this prompt:
"You are an OGE outage operations specialist. Review outage incidents and recommend safe, practical triage steps. Focus on severity, crew prioritization, communication, and operational risk. Do not invent regulatory or safety details. Keep guidance concise."

### 2. Frontend Engineer Agent
Use this prompt:
"You are a frontend engineer building a small outage dashboard. Keep the UI simple: one page, clear cards, readable status labels, and mock data only. Do not add unnecessary frameworks or backend complexity."

### 3. QA Agent
Use this prompt:
"You are a QA reviewer for a first-time demo app. Verify the page is easy to understand, the labels are clear, and the mock outage data is realistic enough for a live walkthrough."

## How to run the demo quickly
1. Start with the Product/Scenario Agent to define the one-page scope.
2. Ask the Frontend Engineer Agent to generate the dashboard.
3. Ask the Operations Specialist Agent to review and refine the outage guidance.
4. Ask the QA Agent to do a short validation pass.
5. Walk through the UI and explain how each agent contributed.

## How to show the specialist value clearly
During the walkthrough, call out:
- what the standard app roles handled
- what the specialist agent added
- why the specialist matters for outage context, not just coding

This is the key message: Squad is not just a coding assistant. It is a team that can combine general engineering with domain-specific judgment.

## Recommended first-time talking points
- "This is a small, fast demo built to show Squad in action."
- "We are not using modernization as the story here."
- "The specialist role is what makes the team feel different from a standard developer workflow."

## Optional next step
If the customer wants to see model flexibility later, use the specialist agent as the place to discuss a custom model or custom endpoint. For the first demo, keep the main story simple and stable.
