// Pattern: SRP — notification service handles only outbound messaging (MODERNIZATION_PATTERNS §5)
// Pattern: Managed Identity — ServiceBusClient via DefaultAzureCredential (MODERNIZATION_PATTERNS §1)
// Pattern: Error Handling — propagate exceptions; caller decides retry/fallback (MODERNIZATION_PATTERNS §3)
// Pattern: Observability — structured log events for every notification (MODERNIZATION_PATTERNS §4)

using System.Text.Json;
using Azure.Messaging.ServiceBus;
using Microsoft.Extensions.Logging;
using Microsoft.Extensions.Options;

namespace OgeFieldOps.Core.Messaging;

/// <summary>
/// Publishes outage events to Azure Service Bus.
/// Pattern: Managed Identity — no SAS keys; RBAC role: Azure Service Bus Data Sender.
/// Downstream consumers (email, SMS, etc.) react to these events independently —
/// this preserves the legacy "fire notification" semantics without tight coupling.
/// </summary>
public sealed class ServiceBusEventPublisher : IEventPublisher
{
    private readonly ServiceBusSender _sender;
    private readonly ILogger<ServiceBusEventPublisher> _logger;

    public ServiceBusEventPublisher(
        ServiceBusClient client,
        IOptions<ServiceBusOptions> options,
        ILogger<ServiceBusEventPublisher> logger)
    {
        _sender = client.CreateSender(options.Value.NotificationQueueName);
        _logger = logger;
    }

    public async Task PublishDocumentUploadedAsync(DocumentUploadedEvent evt, CancellationToken ct = default)
    {
        var message = CreateMessage(evt, "DocumentUploaded");
        _logger.LogInformation(
            "Event publishing. {EventType} {TicketNumber}", "DocumentUploaded", evt.TicketNumber);
        await _sender.SendMessageAsync(message, ct);
        _logger.LogInformation(
            "Event published. {EventType} {TicketNumber}", "DocumentUploaded", evt.TicketNumber);
    }

    public async Task PublishWorkOrderCreatedAsync(WorkOrderCreatedEvent evt, CancellationToken ct = default)
    {
        var message = CreateMessage(evt, "WorkOrderCreated");
        _logger.LogInformation(
            "Event publishing. {EventType} {TicketNumber}", "WorkOrderCreated", evt.TicketNumber);
        await _sender.SendMessageAsync(message, ct);
        _logger.LogInformation(
            "Event published. {EventType} {TicketNumber}", "WorkOrderCreated", evt.TicketNumber);
    }

    private static ServiceBusMessage CreateMessage<T>(T payload, string subject)
        where T : notnull
    {
        var json = JsonSerializer.Serialize(payload);
        return new ServiceBusMessage(json)
        {
            Subject = subject,
            ContentType = "application/json",
            MessageId = Guid.NewGuid().ToString()
        };
    }
}
