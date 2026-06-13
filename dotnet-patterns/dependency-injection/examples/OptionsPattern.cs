// Typed configuration via the Options pattern.
// Bind once in Program.cs, validate on startup, inject IOptions<T> everywhere.

using System.ComponentModel.DataAnnotations;
using Microsoft.AspNetCore.Builder;
using Microsoft.Extensions.DependencyInjection;
using Microsoft.Extensions.Options;

namespace Patterns.DependencyInjection.Examples;

public sealed class CatalogOptions
{
    public const string SectionName = "Catalog";

    [Required, Url]
    public string ServiceUrl { get; init; } = default!;

    [Range(1, 60)]
    public int TimeoutSeconds { get; init; } = 10;

    [Range(0, 5)]
    public int RetryCount { get; init; } = 3;
}

public static class OptionsRegistration
{
    public static void AddCatalogOptions(this WebApplicationBuilder builder)
    {
        builder.Services
            .AddOptions<CatalogOptions>()
            .Bind(builder.Configuration.GetSection(CatalogOptions.SectionName))
            .ValidateDataAnnotations()
            .ValidateOnStart(); // Fails fast at app startup, not first request.
    }
}

// Consume via IOptions<T> (singleton snapshot), IOptionsSnapshot<T> (per-scope refresh),
// or IOptionsMonitor<T> (push notifications on change).
public sealed class CatalogClient(IOptions<CatalogOptions> options)
{
    private readonly CatalogOptions _options = options.Value;

    public TimeSpan Timeout => TimeSpan.FromSeconds(_options.TimeoutSeconds);
}
