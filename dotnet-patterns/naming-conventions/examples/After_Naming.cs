namespace Contoso.Orders.Application.Submission;

public sealed class OrderSubmissionProcessor
{
    public bool CanSubmit(string orderId) => !string.IsNullOrWhiteSpace(orderId);
}
