// Pattern: Observability — correlation ID propagation per request (MODERNIZATION_PATTERNS §4)
// Pattern: Naming Conventions — PascalCase class/method names

using Microsoft.AspNetCore.Http;
using Microsoft.Extensions.DependencyInjection;
using Microsoft.Extensions.Logging;

namespace OgeFieldOps.Core.Observability;

/// <summary>
/// Propagates or generates a Correlation-ID header on every HTTP request.
/// Adds the ID to the response and to the logging scope so all log entries
/// for the request carry the same correlation context.
/// </summary>
public sealed class CorrelationIdMiddleware
{
    private const string CorrelationIdHeader = "X-Correlation-ID";
    private readonly RequestDelegate _next;

    public CorrelationIdMiddleware(RequestDelegate next) => _next = next;

    public async Task InvokeAsync(HttpContext context)
    {
        // Reuse an incoming ID (from an upstream gateway) or mint a new one.
        var correlationId = context.Request.Headers[CorrelationIdHeader].FirstOrDefault()
                            ?? Guid.NewGuid().ToString("N");

        context.Response.Headers[CorrelationIdHeader] = correlationId;
        context.Items[CorrelationIdHeader] = correlationId;

        // Pattern: Observability — push correlation ID into the ambient log scope
        using var scope = context.RequestServices
            .GetRequiredService<ILogger<CorrelationIdMiddleware>>()
            .BeginScope(new Dictionary<string, object>
            {
                ["CorrelationId"] = correlationId,
                ["RequestPath"] = context.Request.Path.ToString()
            });

        await _next(context);
    }
}
