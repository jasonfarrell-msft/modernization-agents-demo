// Captive dependency fix — resolving scoped services inside a singleton/background service.
// NEVER inject a scoped service directly into a singleton; create a scope explicitly.

using Microsoft.Extensions.DependencyInjection;
using Microsoft.Extensions.Hosting;
using Microsoft.Extensions.Logging;

namespace Patterns.DependencyInjection.Examples;

// BackgroundService is a singleton — must not capture scoped services.
public sealed class OrderReconciliationWorker(
    IServiceScopeFactory scopeFactory,
    ILogger<OrderReconciliationWorker> logger) : BackgroundService
{
    protected override async Task ExecuteAsync(CancellationToken stoppingToken)
    {
        while (!stoppingToken.IsCancellationRequested)
        {
            // New scope per iteration — gives fresh DbContext, etc.
            await using var scope = scopeFactory.CreateAsyncScope();

            var repository = scope.ServiceProvider.GetRequiredService<IOrderRepository>();
            // ... do scoped work ...

            logger.LogInformation("Reconciliation tick complete");
            await Task.Delay(TimeSpan.FromMinutes(1), stoppingToken);
        }
    }
}
