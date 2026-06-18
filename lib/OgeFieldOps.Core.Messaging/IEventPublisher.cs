// Pattern: SRP — IEventPublisher handles only outbound event publishing (MODERNIZATION_PATTERNS §5)

namespace OgeFieldOps.Core.Messaging;

public sealed record DocumentUploadedEvent(
    string TicketNumber,
    int OutageId,
    string FileName,
    string UploadedBy,
    DateTime UploadedAt,
    string Region);

public sealed record WorkOrderCreatedEvent(
    string TicketNumber,
    int OutageId,
    string Region,
    string Cause,
    int CustomersAffected,
    DateTime ReportedAt,
    string ReportedBy);

/// <summary>Publishes domain events to an external message broker.</summary>
public interface IEventPublisher
{
    Task PublishDocumentUploadedAsync(DocumentUploadedEvent evt, CancellationToken ct = default);
    Task PublishWorkOrderCreatedAsync(WorkOrderCreatedEvent evt, CancellationToken ct = default);
}
