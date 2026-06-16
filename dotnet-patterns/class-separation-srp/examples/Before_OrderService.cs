public sealed class OrderService(AppDbContext db, IPaymentClient payments, ILogger<OrderService> logger)
{
    public async Task PlaceOrderAsync(PlaceOrderRequest request, CancellationToken ct)
    {
        // Validation, pricing rule evaluation, payment call, persistence, and logging
        // are all mixed in one class. This is the anti-pattern.
    }
}
