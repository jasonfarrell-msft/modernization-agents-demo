public sealed class OrderWorkflow(IOrderPolicy policy, IOrderRepository repository, IOutboxPublisher outbox)
{
    public async Task PlaceOrderAsync(PlaceOrderCommand command, CancellationToken ct)
    {
        policy.Validate(command);
        await repository.SaveAsync(command, ct);
        await outbox.PublishAsync(new OrderPlaced(command.OrderId), ct);
    }
}
