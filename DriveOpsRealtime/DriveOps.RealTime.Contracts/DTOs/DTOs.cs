using DriveOps.RealTime.Contracts.Enums;

namespace DriveOps.RealTime.Contracts.DTOs;

public record DriverLocationDto(
    Guid DriverId,
    decimal Latitude,
    decimal Longitude,
    bool IsOnline,
    DateTime LastUpdated
);

public record ChatMessageDto(
    Guid Id,
    Guid ConversationId,
    Guid SenderUserId,
    string Content,
    DateTime SentAt
);

public record ConversationDto(
    Guid Id,
    Guid? TripId,
    bool IsActive,
    DateTime CreatedAt,
    DateTime UpdatedAt,
    IEnumerable<Guid> ParticipantUserIds,
    int UnreadCount
);

public record TripStatusChangedDto(
    Guid TripId,
    TripStatus NewStatus,
    Guid CustomerId,
    Guid? DriverId,
    DateTime Timestamp
);

public record TripAssignedDto(
    Guid TripId,
    Guid DriverId,
    Guid VehicleId,
    string DriverName,
    decimal DriverLatitude,
    decimal DriverLongitude,
    DateTime AssignedAt
);

public record TripRequestDto(
    Guid TripId,
    Guid CustomerId,
    TripType TripType,
    decimal PickupLatitude,
    decimal PickupLongitude,
    string PickupAddress,
    decimal DropoffLatitude,
    decimal DropoffLongitude,
    string DropoffAddress,
    decimal? EstimatedFare,
    DateTime RequestedAt
);

public record NotificationDto(
    Guid Id,
    string Type,
    string Title,
    string Message,
    DateTime Timestamp
);

public record FleetUpdateDto(
    string UpdateType,
    string PayloadJson,
    DateTime Timestamp
);

public record ConversationSummaryDto(
    Guid Id,
    Guid? TripId,
    string ConversationType,
    DateTime LastMessageAt,
    int UnreadCount,
    IEnumerable<Guid> ParticipantUserIds
);

public record PagedMessagesDto(
    int TotalCount,
    int Page,
    int PageSize,
    IEnumerable<ChatMessageDto> Messages
);

public record CreateDirectConversationRequest(Guid OtherUserId);
