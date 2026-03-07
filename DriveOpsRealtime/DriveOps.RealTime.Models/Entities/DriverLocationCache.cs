namespace DriveOps.RealTime.Models.Entities;

public class DriverLocationCache
{
    public Guid DriverId { get; set; }
    public decimal Latitude { get; set; }
    public decimal Longitude { get; set; }
    public Guid? ActiveTripId { get; set; }
    public bool IsOnline { get; set; }
    public DateTime LastUpdated { get; set; }
}
