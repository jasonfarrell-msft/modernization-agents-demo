# Error Handling & Resilience

## Overview

Resilience patterns keep services useful when dependencies degrade. They bound failure, avoid cascading outages, and return predictable errors to callers.

## Problem

Without explicit resilience policies, transient faults (timeouts, throttling, network drops) become user-facing incidents. Naive retries can amplify load and worsen outages.

## Solution

Apply explicit timeout/retry/circuit-breaker policies per dependency. Use idempotency keys for retry-safe commands. Map exceptions into stable API error contracts (for example, RFC 7807 Problem Details).

## Benefits

- Fewer customer-visible incidents during partial outages
- Improved recovery behavior under load
- Consistent error handling across teams

## Tradeoffs

- More policy configuration to maintain
- Incorrect retry scopes can cause duplicate effects
- Needs observability to tune thresholds

## When to Use

- Any service calling external APIs, queues, storage, or databases
- Background workers processing at-least-once deliveries

## When NOT to Use

- Pure in-memory utilities with no network or I/O dependencies

## Implementation Steps

1. Classify dependencies (critical, optional, best-effort).
2. Apply timeout and retry policies with jitter for transient faults.
3. Add circuit breakers to stop overload during sustained failures.
4. Use idempotency keys for command handlers with side effects.
5. Return normalized error payloads and status codes.

## Code Example

See [`examples/`](./examples/):
- `HttpClientResilience.cs` - resilient outbound HTTP setup.
- `ProblemDetailsMiddleware.cs` - consistent API exception mapping.
- `IdempotentCommandHandler.cs` - retry-safe command handling with idempotency key.

## Validation Checklist

See [`CHECKLIST.md`](./CHECKLIST.md).

## References

- https://learn.microsoft.com/dotnet/core/resilience/http-resilience
- https://www.rfc-editor.org/rfc/rfc7807
- https://learn.microsoft.com/aspnet/core/fundamentals/error-handling
