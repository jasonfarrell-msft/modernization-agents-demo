# Observability & Diagnostics

## Overview

Observability patterns make production behavior explainable: what failed, where it failed, and why it failed. For containerized .NET workloads, logs alone are not enough; combine structured logs, traces, and metrics.

## Problem

Modernized services often ship with inconsistent logging, no correlation IDs, and no distributed trace context. Incidents then require guesswork across pods and downstream services.

## Solution

Standardize on OpenTelemetry for traces/metrics, structured JSON logging with consistent fields, and health/readiness endpoints. Every request should carry correlation context through logs and outbound calls.

## Benefits

- Faster root-cause analysis
- Better SLO/SLA monitoring
- Cleaner handoff to platform/SRE teams
- Safer modernization rollouts with measurable outcomes

## Tradeoffs

- Initial instrumentation effort
- Storage and ingestion cost for telemetry
- Need to tune signal quality to reduce noise

## When to Use

- Any service deployed to Azure/OpenShift
- Any API or worker with external dependencies

## When NOT to Use

- Throwaway prototypes with no production lifecycle

## Implementation Steps

1. Add OpenTelemetry SDK and exporters in `Program.cs`.
2. Enable structured logging with request, user, and correlation fields.
3. Instrument inbound HTTP, outbound HTTP, and database calls.
4. Add health (`/health`) and readiness (`/ready`) endpoints.
5. Define core RED metrics (rate, errors, duration) for each endpoint/operation.

## Code Example

See [`examples/`](./examples/):
- `Program.cs` - OpenTelemetry + health checks baseline.
- `RequestLoggingMiddleware.cs` - correlation-aware structured request logs.

## Validation Checklist

See [`CHECKLIST.md`](./CHECKLIST.md).

## References

- https://learn.microsoft.com/dotnet/core/diagnostics/observability-with-otel
- https://opentelemetry.io/docs/languages/net/
- https://learn.microsoft.com/aspnet/core/host-and-deploy/health-checks
