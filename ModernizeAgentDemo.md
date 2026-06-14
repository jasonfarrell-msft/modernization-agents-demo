# Demo Script for GitHub Modernization Agent

Use this script as the prompt brief for the modernization agent.

## Upfront plan
1. Start with a short assessment of the current legacy app and list the highest-impact modernization risks.
2. Propose the smallest number of changes needed to move the app toward .NET 10, secure configuration, and Azure-ready deployment.
3. Prefer low-cost, high-value actions first, and avoid broad rewrites unless necessary.
4. End with a concrete next-step plan and a brief rationale for each recommended change.

## Goal
Modernize the legacy upload sample from .NET Framework to .NET 10, containerize it for Azure Red Hat OpenShift, and replace local-only dependencies with cloud-ready patterns.

Use dummy placeholder values for any connection strings, storage keys, and secrets in the legacy configuration so the demo remains safe and non-production. The modernization work should also strengthen the application’s security posture by removing hard-coded credentials, using managed identity or Key Vault where possible, and enabling secure defaults for configuration and deployment.

## New flow for this demo
1. First, use GHCP to reverse-engineer the main user flows and save the findings to a local markdown artifact in this repo (ignored by Git).
2. Use those documented use cases to create Playwright tests that protect the UI from regressions.
3. Only after that, run the GitHub Modernization Agent for the architecture and code modernization phase.
4. In the alternative flow, show the modernization outcome because the Playwright suite covers the UI surface that should remain stable.

## Demo Steps

1. Baseline assessment
   - Analyze the existing sample in `legacy-upload-demo/LegacyUploadDemo`.
   - Identify the legacy pain points: .NET Framework (`net48`), local file path configuration, direct `SqlConnection` / `SqlCommand` / `SqlDataAdapter` usage, and LocalDB-style assumptions.
   - Capture the modernization target: build on .NET 10, support containerized deployment, and remove hard-coded local machine dependencies.

2. Modernize the application architecture
   - Upgrade the app to modern .NET 10 with current dependency injection, configuration, and logging patterns.
   - Replace the old `App.config` / local path behavior with environment-based configuration.
   - Replace any real or sample credentials with clearly marked dummy values in the legacy configuration so the demo is safe to share.
   - Replace the legacy ADO.NET data access pattern with modern `Microsoft.Data.SqlClient` or EF Core where appropriate.
   - Keep the upload flow, but make it cloud-ready, secure, and testable.

3. Replace local storage and database assumptions
   - Convert the current local upload folder to either:
     - Azure Blob Storage for durable, scalable file uploads, or
     - a mounted persistent volume for OpenShift if the demo needs a simple file-system path.
   - Replace the LocalDB connection string with Azure SQL, using managed identity or secure connection settings where possible.
   - Add guidance for secrets, connection strings, and storage account configuration through environment variables or Azure Key Vault.
   - Explicitly preserve dummy placeholder secrets in the demo configuration so no sensitive values are exposed during the walkthrough.

4. Containerize and prepare for Azure Red Hat OpenShift
   - Generate a production-ready container build for the modernized app.
   - Add a Dockerfile and any required OpenShift-friendly deployment manifests.
   - Ensure the app is ready for Azure Red Hat OpenShift with health checks, non-root execution, and cloud-native configuration.
   - Call out the key modernization wins for the demo: .NET 10, Azure storage, Azure SQL, and OpenShift deployment readiness.

## Suggested prompt to paste into the Modernization Agent

"Start with a short plan, then modernize the legacy upload sample in `legacy-upload-demo/LegacyUploadDemo` from .NET Framework to .NET 10. Focus on the highest-value, lowest-cost changes first: replace local machine assumptions with cloud-ready patterns, use Azure Blob Storage or an OpenShift-mounted volume for uploads, switch the database from LocalDB/legacy ADO.NET to Azure SQL, and containerize the application for Azure Red Hat OpenShift. Preserve the file-upload scenario, but modernize the codebase for current .NET, secure configuration, and deployment readiness. Use dummy placeholder connection strings and other sample secrets in the legacy config, remove hard-coded sensitive values, and prefer managed identity, Key Vault, and secure environment-based settings. Guide the user through the workflow and keep the plan concise, secure, and cost-aware."
