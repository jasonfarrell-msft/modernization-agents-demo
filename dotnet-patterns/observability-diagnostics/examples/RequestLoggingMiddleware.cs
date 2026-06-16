public sealed class RequestLoggingMiddleware(RequestDelegate next, ILogger<RequestLoggingMiddleware> logger)
{
    public async Task Invoke(HttpContext context)
    {
        var traceId = System.Diagnostics.Activity.Current?.TraceId.ToString() ?? context.TraceIdentifier;
        using (logger.BeginScope(new Dictionary<string, object?> { ["trace_id"] = traceId }))
        {
            logger.LogInformation("Request start {method} {path}", context.Request.Method, context.Request.Path);
            await next(context);
            logger.LogInformation("Request end {status_code}", context.Response.StatusCode);
        }
    }
}
