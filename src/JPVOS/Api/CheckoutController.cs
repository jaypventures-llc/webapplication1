using Microsoft.AspNetCore.Mvc;
using JPVOS.Infrastructure.Stripe;

namespace JPVOS.Api;

[ApiController]
[Route("api/checkout")]
public sealed class CheckoutController : ControllerBase
{
    private readonly StripeCheckoutService _checkout;

    public CheckoutController(
        StripeCheckoutService checkout)
    {
        _checkout = checkout;
    }

    public sealed class CheckoutRequest
    {
        public string LookupKey { get; set; } = "";
    }

    [HttpPost("session")]
    public async Task<IActionResult> CreateSession(
        [FromBody] CheckoutRequest request)
    {
        if (string.IsNullOrWhiteSpace(request.LookupKey))
        {
            return BadRequest(new
            {
                error = "lookup_key_required"
            });
        }

        var session =
            await _checkout.CreateCheckoutSessionAsync(
                request.LookupKey,
                Request);

        return Ok(new
        {
            url = session.Url,
            sessionId = session.Id
        });
    }
}
