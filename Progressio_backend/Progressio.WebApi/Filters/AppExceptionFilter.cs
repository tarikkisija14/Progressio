using Microsoft.AspNetCore.Mvc;
using Microsoft.AspNetCore.Mvc.Filters;
using Progressio.Model.Exceptions;

namespace Progressio.WebApi.Filters
{
    public class AppExceptionFilter : IExceptionFilter
    {

       
      
        private readonly ILogger<AppExceptionFilter> _logger;

        public AppExceptionFilter(ILogger<AppExceptionFilter> logger)
        {
            _logger = logger;
        }

        public void OnException(ExceptionContext context)
        {
            Console.WriteLine("=== AppExceptionFilter UDAREN ===");
            Console.WriteLine(context.Exception.Message);

            var exception = context.Exception;

            var (statusCode, title) = exception switch
            {
                NotFoundException => (StatusCodes.Status404NotFound, "Resurs nije pronađen"),
                BusinessException => (StatusCodes.Status400BadRequest, "Greška poslovne logike"),
                ConflictException => (StatusCodes.Status409Conflict, "Konflikt podataka"),
                UnauthorizedException => (StatusCodes.Status401Unauthorized, "Autentifikacija obavezna"),
                ForbiddenException => (StatusCodes.Status403Forbidden, "Pristup zabranjen"),
                AppException => (StatusCodes.Status400BadRequest, "Greška zahtjeva"),
                _ => (StatusCodes.Status500InternalServerError, "Interna greška servera")
            };

            if (statusCode >= 500)
                _logger.LogError(exception, "Neočekivana greška: {Message}", exception.Message);
            else
                _logger.LogWarning("Aplikacijska greška [{Code}]: {Message}", statusCode, exception.Message);

            context.Result = new ObjectResult(new ProblemDetails
            {
                Status = statusCode,
                Title = title,
                Detail = statusCode < 500
                    ? exception.Message
                    : "Molimo pokušajte ponovo. Ako se problem nastavi, kontaktirajte podršku."
            })
            {
                StatusCode = statusCode
            };

            context.ExceptionHandled = true;
        }
    }
}