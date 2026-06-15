using Microsoft.AspNetCore.Authentication;
using Microsoft.Extensions.Options;
using System.Security.Claims;
using System.Security.Cryptography;
using System.Text;
using System.Text.Encodings.Web;
using Progressio.Services.Configuration;

namespace Progressio.WebApi.Security
{
    public static class InternalApiKeyDefaults
    {
        public const string Scheme = "InternalApiKey";
        public const string HeaderName = "X-Internal-Key";
    }

    public sealed class InternalApiKeyAuthenticationHandler : AuthenticationHandler<AuthenticationSchemeOptions>
    {
        private readonly byte[] _configuredKeyBytes;

        public InternalApiKeyAuthenticationHandler(
            IOptionsMonitor<AuthenticationSchemeOptions> options,
            ILoggerFactory logger,
            UrlEncoder encoder,
            IConfiguration configuration)
            : base(options, logger, encoder)
        {
            _configuredKeyBytes = Encoding.UTF8.GetBytes(
                configuration.GetRequiredValue("Api:InternalKey"));
        }

        protected override Task<AuthenticateResult> HandleAuthenticateAsync()
        {
            var suppliedKey = Request.Headers[InternalApiKeyDefaults.HeaderName].FirstOrDefault();
            if (string.IsNullOrWhiteSpace(suppliedKey))
                return Task.FromResult(AuthenticateResult.Fail("Internal API key is missing."));

            var suppliedBytes = Encoding.UTF8.GetBytes(suppliedKey);
            if (_configuredKeyBytes.Length != suppliedBytes.Length ||
                !CryptographicOperations.FixedTimeEquals(_configuredKeyBytes, suppliedBytes))
            {
                return Task.FromResult(AuthenticateResult.Fail("Internal API key is invalid."));
            }

            var identity = new ClaimsIdentity(
                [new Claim(ClaimTypes.Name, "Progressio.Worker")],
                InternalApiKeyDefaults.Scheme);

            return Task.FromResult(AuthenticateResult.Success(
                new AuthenticationTicket(
                    new ClaimsPrincipal(identity),
                    InternalApiKeyDefaults.Scheme)));
        }
    }
}
