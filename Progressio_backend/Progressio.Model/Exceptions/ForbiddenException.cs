namespace Progressio.Model.Exceptions
{
    public class ForbiddenException : AppException
    {
        public ForbiddenException(string message = "Nemate pravo pristupa ovom resursu.") : base(message) { }
    }

}
