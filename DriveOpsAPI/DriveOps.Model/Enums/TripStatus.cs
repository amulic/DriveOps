namespace DriveOps.Model.Enums;

public enum TripStatus
{
    Requested = 1,
    Assigned = 2,
    DriverEnRoute = 3,
    InProgress = 4,
    Completed = 5,
    Cancelled = 6,
    NoDriverAvailable = 7,
    Declined = 8
}
