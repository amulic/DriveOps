namespace DriveOps.RealTime.Contracts.Enums;

// Mirrors DriveOps.Model.Enums.DriverStatus so the API's numeric enum values
// deserialize unchanged in the Realtime service.
public enum DriverStatus
{
    Pending = 0,
    Active = 1,
    Inactive = 2,
    Suspended = 3,
    OnTrip = 4
}
