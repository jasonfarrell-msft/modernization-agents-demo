// Pattern: DI / Options — typed configuration for messaging (MODERNIZATION_PATTERNS §2)
// Pattern: Managed Identity — fully-qualified namespace only; no SAS key

namespace OgeFieldOps.Core.Messaging;

/// <summary>
/// Azure Service Bus options. Bind to the "Messaging" config section.
/// Pattern: Managed Identity — fully-qualified namespace only; no SAS key.
/// </summary>
public sealed class ServiceBusOptions
{
    public string NotificationQueueName { get; set; } = "outage-notifications";
}
