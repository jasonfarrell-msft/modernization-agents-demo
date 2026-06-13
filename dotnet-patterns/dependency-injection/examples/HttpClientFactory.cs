// Typed HttpClient with resilience.
// Never `new HttpClient()` in long-lived services — socket exhaustion + DNS staleness.

using Microsoft.AspNetCore.Builder;
using Microsoft.Extensions.DependencyInjection;
using Microsoft.Extensions.Http.Resilience;
using Microsoft.Extensions.Options;

namespace Patterns.DependencyInjection.Examples;

public sealed class CatalogApiClient(HttpClient http)
{
    public Task<HttpResponseMessage> GetItemAsync(int id, CancellationToken ct) =>
        http.GetAsync($"items/{id}", ct);
}

public static class HttpClientRegistration
{
    public static void AddCatalogClient(this WebApplicationBuilder builder)
    {
        builder.Services
            .AddHttpClient<CatalogApiClient>((sp, client) =>
            {
                var options = sp.GetRequiredService<IOptions<CatalogOptions>>().Value;
                client.BaseAddress = new Uri(options.ServiceUrl);
                client.Timeout = TimeSpan.FromSeconds(options.TimeoutSeconds);
            })
            // Standard resilience: retry, circuit breaker, timeout, bulkhead.
            .AddStandardResilienceHandler();
    }
}
