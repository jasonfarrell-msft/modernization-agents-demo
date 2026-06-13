# Dependency Injection

## Overview

Dependency Injection (DI) is a design pattern where an object's dependencies are
provided ("injected") by an external container instead of being constructed
internally. In .NET, the built-in `Microsoft.Extensions.DependencyInjection`
container is the canonical mechanism — it's used by ASP.NET Core, Worker
Services, Azure Functions (isolated worker), and .NET Aspire.

## Problem

Tightly coupled classes that `new` up their own dependencies are:

- **Hard to test** — you can't substitute a fake `HttpClient`, `DbContext`, or `IBlobClient`.
- **Hard to evolve** — swapping `SqlServer` for `Postgres`, or `RabbitMQ` for `Azure Service Bus`, means hunting through the codebase.
- **Hard to configure** — secrets, connection strings, and policies leak into business logic.
- **Hard to reason about lifecycles** — singletons accidentally hold scoped state, scoped services get captured by singletons, etc.

## Solution

Register dependencies in a composition root (typically `Program.cs`) using
`IServiceCollection`, then declare them as constructor parameters. The container
resolves the graph at runtime and disposes scoped/transient services
deterministically.

## Benefits

- **Testability** — inject test doubles via constructor.
- **Loose coupling** — depend on abstractions (`IOrderRepository`), not implementations.
- **Lifecycle management** — container disposes `IDisposable` / `IAsyncDisposable` services.
- **Configuration discipline** — wire `IOptions<T>` from `IConfiguration` once, consume everywhere.
- **Composability** — Aspire, OpenTelemetry, HealthChecks, Polly all plug in via DI.

## Tradeoffs

- **Indirection** — stack traces include container frames; new contributors need to learn DI conventions.
- **Runtime errors** — missing registrations throw at first resolution, not compile time. Mitigate with integration tests that build the host.
- **Lifetime bugs** — capturing a `DbContext` (scoped) inside a singleton silently breaks. Use `IServiceScopeFactory`.
- **Over-abstraction risk** — don't introduce an interface for every class. Only abstract what varies or what you mock.

## When to Use

- Any non-trivial application with persistence, HTTP clients, messaging, or external services.
- Code that needs unit tests with isolated dependencies.
- Applications targeting Azure where credentials, telemetry, and feature flags must be configurable per environment.

## When NOT to Use

- One-off scripts, console utilities, or single-file tools.
- Pure functions / static helpers that have no state and no side effects.
- Domain entities — keep them POCOs; inject services into application/handler classes instead.

## Implementation Steps

1. **Define the abstraction** (`IOrderRepository`) in the application or domain layer.
2. **Implement it** (`SqlOrderRepository`) in the infrastructure layer.
3. **Register it** in `Program.cs` with the correct lifetime.
4. **Consume it** via constructor injection — no `new`, no service locator.
5. **Configure options** with `IOptions<T>` bound to a config section.
6. **Add an integration test** that calls `host.Services.GetRequiredService<T>()` to catch missing registrations.

### Service lifetimes

| Lifetime    | New instance per...        | Use for                                              |
|-------------|----------------------------|------------------------------------------------------|
| `Singleton` | Application                | Stateless services, expensive setups, caches         |
| `Scoped`    | HTTP request / scope       | `DbContext`, per-request state, unit-of-work         |
| `Transient` | Resolution                 | Lightweight stateless helpers                        |

### Anti-patterns to avoid

- **Service Locator** — calling `serviceProvider.GetService<T>()` from business code. Inject what you need.
- **Captive dependency** — singleton holds a scoped service. Use `IServiceScopeFactory` and create a scope.
- **Constructor over-injection** — >5 dependencies signals a class doing too much (SRP violation).
- **Static `Configuration`** — bind config to typed options, don't pass `IConfiguration` around.

## Code Example

See [`examples/`](./examples/) for runnable code:

- `BasicRegistration.cs` — lifetimes and consumption
- `OptionsPattern.cs` — typed configuration binding
- `KeyedServices.cs` — .NET 8+ keyed registration
- `HttpClientFactory.cs` — typed clients with Polly
- `ScopedFromSingleton.cs` — correct use of `IServiceScopeFactory`

## Validation Checklist

See [`CHECKLIST.md`](./CHECKLIST.md).

## References

- [.NET Dependency Injection](https://learn.microsoft.com/dotnet/core/extensions/dependency-injection)
- [Service lifetimes](https://learn.microsoft.com/dotnet/core/extensions/dependency-injection#service-lifetimes)
- [Options pattern](https://learn.microsoft.com/dotnet/core/extensions/options)
- [Keyed services (.NET 8+)](https://learn.microsoft.com/dotnet/core/extensions/dependency-injection#keyed-services)
- [DI guidelines](https://learn.microsoft.com/dotnet/core/extensions/dependency-injection-guidelines)
