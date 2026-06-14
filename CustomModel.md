# Custom Model: GPT-5-Codex via Azure AI Foundry (BYOM in VS Code)

This document covers the demo path for using a **customer-controlled** model with GitHub Copilot in VS Code instead of the GHCP defaults. The target model is `gpt-5-codex` deployed in **Azure AI Foundry** inside the customer's own Azure tenant.

## Why this path

Out-of-the-box GHCP runs against GitHub-managed inference. Customers with residency, sovereignty, or audit requirements need:

- Inference in a region they pick
- The model running in *their* Azure subscription
- Private networking, CMK, and their own logging/retention
- A model on their approved list (here: `gpt-5-codex`, per `~/.copilot/copilot-instructions.md`)

`gpt-5-codex` on Azure AI Foundry gives the same residency/control story as open-weight models (Kimi, Qwen) but keeps frontier coding capability and Microsoft EDP + indemnity.

## Prerequisites

- Azure subscription with rights to create an AI Foundry project
- `az` CLI logged in to the target tenant
- VS Code with GitHub Copilot Chat installed
- Quota for `gpt-5-codex` in the chosen region (check before the demo)

## Steps

### 1. Create the Foundry project and model deployment

In the Azure portal or via CLI:

1. Create (or reuse) an **Azure AI Foundry** resource in the target region.
2. Create a project inside it.
3. In **Models + endpoints**, deploy `gpt-5-codex` (latest GA version).
4. Pick a deployment name you can remember — e.g. `codex-prod`.
5. Copy the **endpoint URL** and **deployment name**. Do **not** copy or use API keys.

### 2. Lock down the deployment

Before pointing VS Code at it:

- **Identity:** disable key-based auth; enable **Microsoft Entra (AAD) auth** on the Foundry resource.
- **Network:** set Public network access to **Disabled**, add a **Private Endpoint** if the demo machine is on the customer VNet (or allowlist the demo egress IP for the session).
- **Encryption:** confirm CMK is configured if the customer requires it.
- **Logging:** in Foundry, set content logging to **off** (or to the customer's required retention); enable diagnostic settings to the customer's Log Analytics workspace.
- **RBAC:** grant the developer the **Azure AI User** role (or **Cognitive Services OpenAI User**) on the deployment — least privilege, no broader Contributor.

### 3. Wire BYOM into VS Code Copilot

1. In VS Code, open the Command Palette → **GitHub Copilot: Manage Models**.
2. Choose **Add Model** → **Azure** (or **Azure AI Foundry**, depending on VS Code version).
3. Provide:
   - **Endpoint:** the Foundry endpoint URL from step 1
   - **Deployment name:** e.g. `codex-prod`
   - **Auth:** Microsoft Entra (sign in with the same account that has the RBAC role)
4. Set the model as **default for Chat** (and optionally inline completions, where supported).

### 4. Verify

- Open Copilot Chat, run `@workspace explain this project`.
- Confirm in the model picker that `gpt-5-codex` (Azure) is the active model.
- In the Azure portal, open the Foundry deployment → **Metrics**, confirm token usage shows up against your deployment.
- In Log Analytics, confirm a request log entry appears for the call.

### 5. Run the modernization demo against it

Use this Copilot configuration to run the existing demo flow (see [DemoStart.md](DemoStart.md) and [ModernizeAgentDemo.md](ModernizeAgentDemo.md)) — reverse-engineer flows, generate Playwright tests, then run the modernization agent. All Copilot inference now stays in the customer tenant.

## Hardening checklist (for the customer takeaway)

- [ ] Foundry deployment in approved region
- [ ] Entra auth only, key auth disabled
- [ ] Private endpoint or IP allowlist
- [ ] CMK enabled (if required)
- [ ] Content logging disabled or routed to customer-owned storage
- [ ] Diagnostic settings → customer Log Analytics
- [ ] Least-privilege RBAC (`Cognitive Services OpenAI User` on the deployment, not the whole resource)
- [ ] Model deployment version pinned (no auto-upgrade)
- [ ] Quota and TPM/RPM sized for expected developer concurrency

## Notes

- Use the **latest GA** API version for the deployment. Prefer GA `2024-12-01-preview` or newer when GA is unavailable.
- Open-weight models (Kimi-K2.6, Qwen) in Foundry are a fallback **only** when the customer specifically requires open weights. They lose coding capability vs `gpt-5-codex` with no residency gain.
- This setup gives the developer control of the model used by GHCP without leaving the GHCP UX in VS Code — the demo story is "same Copilot, your model, your tenant".
