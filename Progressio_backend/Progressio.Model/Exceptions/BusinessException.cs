namespace Progressio.Model.Exceptions
{
    public class BusinessException : AppException
    {
        public BusinessException(string message) : base(message)
        {
        }

        public BusinessException(string message, Exception innerException)
            : base(message, innerException)
        {
        }
    }


}
