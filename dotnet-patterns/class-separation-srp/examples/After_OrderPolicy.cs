public interface IOrderPolicy
{
    void Validate(PlaceOrderCommand command);
}

public sealed class OrderPolicy : IOrderPolicy
{
    public void Validate(PlaceOrderCommand command)
    {
        if (command.Items.Count == 0)
        {
            throw new InvalidOperationException("Order must contain at least one item.");
        }
    }
}
