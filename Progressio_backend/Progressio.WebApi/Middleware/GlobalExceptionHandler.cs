using Microsoft.AspNetCore.Diagnostics;
using Microsoft.AspNetCore.Mvc;
using Progressio.Model.Exceptions;

namespace Progressio.WebApi.Middleware
{
    public class GlobalExceptionHandler : IExceptionHandler
    {
        private readonly ILogger<GlobalExceptionHandler> _logger;

        public GlobalExceptionHandler(ILogger<GlobalExceptionHandler> logger)
        {
            _logger = logger;
        }

        public async ValueTask<bool> TryHandleAsync(HttpContext httpContext,Exception exception,CancellationToken cancellationToken)
        {
            var (statusCode, title) = exception switch
            {
                NotFoundException => (StatusCodes.Status404NotFound, "Resurs nije pronađen"),
                BusinessException => (StatusCodes.Status400BadRequest, "Greška poslovne logike"),
                UnauthorizedException => (StatusCodes.Status401Unauthorized, "Autentifikacija obavezna"),
                ForbiddenException => (StatusCodes.Status403Forbidden, "Pristup zabranjen"),
                AppException => (StatusCodes.Status400BadRequest, "Greška zahtjeva"),
                _ => (StatusCodes.Status500InternalServerError, "Interna greška servera")
            };

            if (statusCode == StatusCodes.Status500InternalServerError)
            {
                _logger.LogError(exception, "Neočekivana greška: {Message}", exception.Message);
            }
            else
            {
                _logger.LogWarning("Aplikacijska greška [{Code}]: {Message}", statusCode, exception.Message);
            }

            var problemDetails = new ProblemDetails
            {
                Status = statusCode,
                Title = title,
                
                Detail = statusCode < 500 ? exception.Message : "Molimo pokušajte ponovo. Ako problem persists, kontaktirajte podršku."
            };

            httpContext.Response.StatusCode = statusCode;
            await httpContext.Response.WriteAsJsonAsync(problemDetails, cancellationToken);

            return true;
        }

    }
}
