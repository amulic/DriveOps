namespace DriveOps.Application.Exceptions
{
    /// <summary>
    /// Raised when a driver/vehicle cannot be assigned to a trip because it does
    /// not satisfy the same availability rules used to select it.
    /// </summary>
    public class TripAssignmentException : Exception
    {
        public TripAssignmentException(string message) : base(message) { }
    }

    /// <summary>
    /// Raised when a vehicle cannot be physically deleted because trips, defect
    /// reports or service records depend on it. The vehicle should be retired
    /// instead so its history is preserved.
    /// </summary>
    public class VehicleHasDependenciesException : Exception
    {
        public VehicleHasDependenciesException(string message) : base(message) { }
    }
}
