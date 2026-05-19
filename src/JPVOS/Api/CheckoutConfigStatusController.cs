using Microsoft.AspNetCore.Mvc;
using JPVOS.Infrastructure.Stripe;

namespace JPVOS.Api;

[ApiController]
[Route("api/checkout/status")]
public sealed class CheckoutConfigStatusController : ControllerBase
{
    private readonly StripePricingLoader _loader;

    public CheckoutConfigStatusController(
        StripePricingLoader loader)
    {
        _loader = loader;
    }

    [HttpGet]
    public IActionResult Get()
    {
        try
        {
            var map = _loader.Load();

            var secret =
                Environment.GetEnvironmentVariable("STRIPE_SECRET_KEY");

            var webhook =
                Environment.GetEnvironmentVariable("STRIPE_WEBHOOK_SECRET");

            return Ok(new
            {
                stripeConfigured =
                    !string.IsNullOrWhiteSpace(secret),

                webhookConfigured =
                    !string.IsNullOrWhiteSpace(webhook),

                pricingMapLoaded = true,

                mode = map.Mode,

                lookupKeys = map.Prices.Keys,

                environmentHealthy = true
            });
        }
        catch (Exception ex)
        {
            return StatusCode(500, new
            {
                environmentHealthy = false,
                error = ex.Message
            });
        }
    }
}
