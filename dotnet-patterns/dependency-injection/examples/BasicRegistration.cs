// Basic DI registration — lifetimes and constructor injection.
// Reference only; not compiled as part of this repo.

using Microsoft.AspNetCore.Builder;
using Microsoft.AspNetCore.Mvc;
using Microsoft.Extensions.DependencyInjection;
using Microsoft.Extensions.Logging;

namespace Patterns.DependencyInjection.Examples;

// 1. Define abstractions in the application layer.
public interface IOrderRepository
{
    Task<Order?> GetAsync(Guid id, CancellationToken ct);
}

public interface IClock
{
    DateTimeOffset UtcNow { get; }
}

// 2. Implement in the infrastructure layer.
internal sealed class SqlOrderRepository(OrdersDbContext db) : IOrderRepository
{
    public Task<Order?> GetAsync(Guid id, CancellationToken ct) =>
        db.Orders.FindAsync([id], ct).AsTask();
}

internal sealed class SystemClock : IClock
{
    public DateTimeOffset UtcNow => DateTimeOffset.UtcNow;
}

// 3. Consume via constructor injection (primary constructor).
public sealed class OrdersController(
    IOrderRepository repository,
    IClock clock,
    ILogger<OrdersController> logger) : ControllerBase
{
    [HttpGet("orders/{id:guid}")]
    public async Task<IActionResult> Get(Guid id, CancellationToken ct)
    {
        logger.LogInformation("Fetching order {OrderId} at {Timestamp}", id, clock.UtcNow);
        var order = await repository.GetAsync(id, ct);
        return order is null ? NotFound() : Ok(order);
    }
}

// 4. Compose in Program.cs.
public static class Composition
{
    public static void Configure(WebApplicationBuilder builder)
    {
        // Singleton — stateless, thread-safe, lives for app lifetime.
        builder.Services.AddSingleton<IClock, SystemClock>();

        // Scoped — one instance per HTTP request. DbContext requires scoped.
        builder.Services.AddDbContext<OrdersDbContext>();
        builder.Services.AddScoped<IOrderRepository, SqlOrderRepository>();

        // Transient — new instance per resolution. Use sparingly.
        builder.Services.AddTransient<IOrderValidator, OrderValidator>();
    }
}

// Stubs for compile context.
public sealed record Order(Guid Id);
public sealed class OrdersDbContext { public DbSet<Order> Orders { get; } = null!; }
public interface IOrderValidator;
internal sealed class OrderValidator : IOrderValidator;
public sealed class DbSet<T> { public ValueTask<T?> FindAsync(object[] _, CancellationToken __) => default; }
