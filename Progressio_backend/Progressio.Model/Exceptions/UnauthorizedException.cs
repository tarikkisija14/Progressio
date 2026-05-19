namespace Progressio.Model.Exceptions
{
    public class UnauthorizedException : AppException
    {
        public UnauthorizedException(string message = "Niste autentificirani.") : base(message) { }
    }

}
