# Dependency Injection — Validation Checklist

## Registration

- [ ] All services registered in `Program.cs` (or `AddXxx` extension methods grouped by feature)
- [ ] Each registration uses the correct lifetime (`Singleton` / `Scoped` / `Transient`)
- [ ] No service locator usage (`IServiceProvider.GetService<T>()`) outside composition root or factory boundaries
- [ ] No `new` of services that should be injected
- [ ] Extension methods follow `AddFeatureName(this IServiceCollection)` convention

## Lifetimes

- [ ] `DbContext` and per-request services registered as `Scoped`
- [ ] No scoped service injected into a singleton (no captive dependencies)
- [ ] Background services use `IServiceScopeFactory` to create scopes for scoped work
- [ ] Singletons are thread-safe (or documented as not requiring it)

## Configuration

- [ ] Configuration bound to typed options (`IOptions<T>` / `IOptionsSnapshot<T>` / `IOptionsMonitor<T>`)
- [ ] No raw `IConfiguration` passed into business logic
- [ ] Options validated with `ValidateDataAnnotations()` and `ValidateOnStart()`
- [ ] No secrets in `appsettings.json` (use Key Vault + Managed Identity, see [managed-identity](../managed-identity/))

## HTTP clients

- [ ] All `HttpClient` usage goes through `IHttpClientFactory` (named or typed clients)
- [ ] Resilience configured (Polly via `Microsoft.Extensions.Http.Resilience` or `AddStandardResilienceHandler`)
- [ ] No `new HttpClient()` in long-lived services (socket exhaustion)

## Testability

- [ ] Public constructors take abstractions, not concretions
- [ ] No more than 4-5 constructor parameters per class (SRP signal)
- [ ] Integration test builds the host and resolves all controllers/handlers without errors
- [ ] Unit tests substitute dependencies via constructor (no DI container needed)

## Disposal

- [ ] Services owning unmanaged resources implement `IDisposable` or `IAsyncDisposable`
- [ ] Container ownership respected — don't dispose injected services manually
- [ ] Scoped resources released at end of request/scope

## Azure / Aspire alignment

- [ ] Telemetry registered via `AddOpenTelemetry()` in `ServiceDefaults`
- [ ] Health checks registered via `AddHealthChecks()`
- [ ] Azure SDK clients registered via `Azure.Identity` + `AddAzureClients()` (see [managed-identity](../managed-identity/))
- [ ] Aspire `ServiceDefaults` extension applied in every service host
