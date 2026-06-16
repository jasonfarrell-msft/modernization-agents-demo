public sealed class IdempotentCommandHandler(IIdempotencyStore idempotencyStore, IOrderService orderService)
{
    public async Task HandleAsync(CreateOrderCommand command, CancellationToken ct)
    {
        if (await idempotencyStore.ExistsAsync(command.IdempotencyKey, ct))
        {
            return;
        }

        await orderService.CreateAsync(command, ct);
        await idempotencyStore.MarkProcessedAsync(command.IdempotencyKey, ct);
    }
}
