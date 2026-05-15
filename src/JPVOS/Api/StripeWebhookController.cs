using Microsoft.AspNetCore.Mvc;
using Microsoft.Extensions.Configuration;
using Stripe;
using System.Text;
using System.Text.Json;

[ApiController]
[Route("api/stripe/webhook")]
public class StripeWebhookController : ControllerBase
{
    private readonly IConfiguration _config;
    public StripeWebhookController(IConfiguration config)
    {
        _config = config;
    }

    [HttpPost]
    public async Task<IActionResult> Post()
    {
        var json = await new StreamReader(HttpContext.Request.Body).ReadToEndAsync();
        var signatureHeader = Request.Headers["Stripe-Signature"];
        var webhookSecret = _config["STRIPE_WEBHOOK_SECRET"];
        Event stripeEvent;
        try
        {
            stripeEvent = EventUtility.ConstructEvent(json, signatureHeader, webhookSecret);
        }
        catch (Exception)
        {
            return BadRequest();
        }

        // Handle events
        switch (stripeEvent.Type)
        {
            case "checkout.session.completed":
                // TODO: Create pending/active entitlement
                break;
            case "invoice.paid":
                // TODO: Confirm or extend active entitlement
                break;
            case "invoice.payment_failed":
                // TODO: Mark account past_due and warn user
                break;
            case "customer.subscription.updated":
                // TODO: Sync plan changes, upgrades, downgrades, cancellations
                break;
            case "customer.subscription.deleted":
                // TODO: Revoke paid entitlement and remove Discord paid role
                break;
        }
        return Ok();
    }
}
