namespace DriveOps.Application.Exceptions
{
    public class KeycloakUserNotFoundException : Exception
    {
        public KeycloakUserNotFoundException(string message) : base(message) { }
    }

    public class DuplicateDriverException : Exception
    {
        public DuplicateDriverException(string message) : base(message) { }
    }

    public class KeycloakUserConflictException : Exception
    {
        public KeycloakUserConflictException(string message) : base(message) { }
    }
}
