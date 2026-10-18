namespace DriveOps.Application.Exceptions
{
    public class ActiveTripExistsException : Exception
    {
        public ActiveTripExistsException(string message) : base(message) { }
    }
}
