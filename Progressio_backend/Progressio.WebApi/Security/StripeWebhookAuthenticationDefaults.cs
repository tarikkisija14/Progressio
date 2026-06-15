using Microsoft.AspNetCore.Authentication;
using Microsoft.Extensions.Options;
using System.Security.Claims;
using System.Text.Encodings.Web;

namespace Progressio.WebApi.Security
{
    public static class StripeWebhookAuthenticationDefaults
    {
        public const string Scheme = "StripeWebhook";
        public const string SignatureHeader = "Stripe-Signature";
    }
    public sealed class StripeWebhookAuthenticationHandler : AuthenticationHandler<AuthenticationSchemeOptions>
    {
        public StripeWebhookAuthenticationHandler(
            IOptionsMonitor<AuthenticationSchemeOptions> options,
            ILoggerFactory logger,
            UrlEncoder encoder)
            : base(options, logger, encoder)
        {
        }

        protected override Task<AuthenticateResult> HandleAuthenticateAsync()
        {
            if (!Request.Headers.TryGetValue(StripeWebhookAuthenticationDefaults.SignatureHeader, out var signature) ||
                string.IsNullOrWhiteSpace(signature))
            {
                return Task.FromResult(AuthenticateResult.Fail("Stripe signature header is missing."));
            }

            var identity = new ClaimsIdentity(
                [new Claim(ClaimTypes.Name, "Stripe")],
                StripeWebhookAuthenticationDefaults.Scheme);

            return Task.FromResult(AuthenticateResult.Success(
                new AuthenticationTicket(new ClaimsPrincipal(identity), StripeWebhookAuthenticationDefaults.Scheme)));
        }
    }

}
