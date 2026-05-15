using Microsoft.AspNetCore.Mvc;
using Microsoft.Extensions.Configuration;
using System.Collections.Generic;
using System.Linq;

[ApiController]
[Route("api/checkout/config-status")]
public class CheckoutConfigStatusController : ControllerBase
{
    private static readonly string[] RequiredVars = new[]
    {
        "STRIPE_SECRET_KEY",
        "STRIPE_PRICE_MEMBER_MONTHLY",
        "STRIPE_PRICE_MEMBER_ANNUAL",
        "STRIPE_PRICE_CREATOR_MONTHLY",
        "STRIPE_PRICE_CREATOR_ANNUAL",
        "STRIPE_PRICE_PARTNER_MONTHLY",
        "STRIPE_PRICE_PARTNER_ANNUAL",
        "STRIPE_PRICE_ENTERPRISE_MONTHLY",
        "STRIPE_PRICE_ENTERPRISE_ANNUAL"
    };

    private static readonly string CustomVar = "STRIPE_PRICE_CUSTOM_IMPLEMENTATION";

    private readonly IConfiguration _config;
    public CheckoutConfigStatusController(IConfiguration config)
    {
        _config = config;
    }

    [HttpGet]
    public IActionResult Get()
    {
        var missing = RequiredVars.Where(v => string.IsNullOrWhiteSpace(_config[v])).ToList();
        var stripeConfigured = missing.Count == 0 && !string.IsNullOrWhiteSpace(_config["STRIPE_SECRET_KEY"]);
        var priceIdsConfigured = RequiredVars.Count(v => !string.IsNullOrWhiteSpace(_config[v]));
        var customSet = !string.IsNullOrWhiteSpace(_config[CustomVar]);
        var secret = _config["STRIPE_SECRET_KEY"] ?? "";
        string checkoutMode = "unknown";
        if (!string.IsNullOrWhiteSpace(secret))
        {
            checkoutMode = secret.StartsWith("sk_test_") ? "test" : (secret.StartsWith("sk_live_") ? "live" : "unknown");
        }
        return Ok(new
        {
            stripeConfigured,
            missingVariables = missing,
            checkoutMode,
            priceIdsConfigured,
            customImplementationConfigured = customSet
        });
    }
}
