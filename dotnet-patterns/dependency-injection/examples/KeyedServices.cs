// Keyed services (.NET 8+) — pick an implementation by key at resolution time.
// Useful for strategy patterns: multiple payment providers, multiple cache tiers, etc.

using Microsoft.AspNetCore.Builder;
using Microsoft.Extensions.DependencyInjection;

namespace Patterns.DependencyInjection.Examples;

public interface IPaymentProvider
{
    Task<string> ChargeAsync(decimal amount, CancellationToken ct);
}

internal sealed class StripeProvider : IPaymentProvider
{
    public Task<string> ChargeAsync(decimal amount, CancellationToken ct) =>
        Task.FromResult($"stripe-{Guid.NewGuid():N}");
}

internal sealed class AdyenProvider : IPaymentProvider
{
    public Task<string> ChargeAsync(decimal amount, CancellationToken ct) =>
        Task.FromResult($"adyen-{Guid.NewGuid():N}");
}

public static class KeyedRegistration
{
    public static void AddPaymentProviders(this WebApplicationBuilder builder)
    {
        builder.Services.AddKeyedSingleton<IPaymentProvider, StripeProvider>("stripe");
        builder.Services.AddKeyedSingleton<IPaymentProvider, AdyenProvider>("adyen");
    }
}

// Resolve by key with [FromKeyedServices].
public sealed class CheckoutHandler(
    [FromKeyedServices("stripe")] IPaymentProvider primary,
    [FromKeyedServices("adyen")] IPaymentProvider fallback)
{
    public async Task<string> ChargeAsync(decimal amount, CancellationToken ct)
    {
        try
        {
            return await primary.ChargeAsync(amount, ct);
        }
        catch
        {
            return await fallback.ChargeAsync(amount, ct);
        }
    }
}
