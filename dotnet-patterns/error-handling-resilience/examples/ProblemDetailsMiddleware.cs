app.UseExceptionHandler(errorApp =>
{
    errorApp.Run(async context =>
    {
        var feature = context.Features.Get<Microsoft.AspNetCore.Diagnostics.IExceptionHandlerFeature>();
        var (status, type, title) = feature?.Error switch
        {
            ArgumentException => (StatusCodes.Status400BadRequest, "https://example.com/errors/validation", "Validation error"),
            KeyNotFoundException => (StatusCodes.Status404NotFound, "https://example.com/errors/not-found", "Resource not found"),
            TimeoutException => (StatusCodes.Status503ServiceUnavailable, "https://example.com/errors/dependency-timeout", "Dependency timeout"),
            _ => (StatusCodes.Status500InternalServerError, "https://example.com/errors/unexpected", "Unexpected error")
        };

        context.Response.StatusCode = status;
        context.Response.ContentType = "application/problem+json";
        await context.Response.WriteAsJsonAsync(new
        {
            type,
            title,
            status
        });
    });
});
