using Microsoft.AspNetCore.Mvc;
using Microsoft.Extensions.Configuration;
using Stripe.Checkout;

[ApiController]
[Route("api/[controller]")]
public class CheckoutController : ControllerBase
{
    private readonly IConfiguration _config;
    public CheckoutController(IConfiguration config)
    {
        _config = config;
    }

    public class CheckoutRequest
    {
        public string PackageKey { get; set; } = string.Empty;
        public string Interval { get; set; } = "monthly";
        public string SuccessUrl { get; set; } = string.Empty;
        public string CancelUrl { get; set; } = string.Empty;
    }

    [HttpPost("create")]
    public IActionResult Create([FromBody] CheckoutRequest req)
    {
        var priceId = GetStripePriceId(req.PackageKey);
        if (string.IsNullOrEmpty(priceId))
            return BadRequest("Invalid package key.");

        var domain = Request.Scheme + "://" + Request.Host.Value;
        var options = new SessionCreateOptions
        {
            PaymentMethodTypes = new List<string> { "card" },
            LineItems = new List<SessionLineItemOptions>
            {
                new SessionLineItemOptions
                {
                    Price = priceId,
                    Quantity = 1
                }
            },
            Mode = req.PackageKey == "custom_implementation_one_time" ? "payment" : "subscription",
            SuccessUrl = string.IsNullOrEmpty(req.SuccessUrl) ? domain + "/success" : req.SuccessUrl,
            CancelUrl = string.IsNullOrEmpty(req.CancelUrl) ? domain + "/pricing" : req.CancelUrl,
        };
        var service = new SessionService();
        var session = service.Create(options);
        return Ok(new { url = session.Url });
    }

    private string GetStripePriceId(string packageKey)
    {
        // Map package keys to env vars
        return packageKey switch
        {
            "member_access_monthly" => _config["STRIPE_PRICE_MEMBER_MONTHLY"],
            "member_access_annual" => _config["STRIPE_PRICE_MEMBER_ANNUAL"],
            "creator_launch_monthly" => _config["STRIPE_PRICE_CREATOR_MONTHLY"],
            "creator_launch_annual" => _config["STRIPE_PRICE_CREATOR_ANNUAL"],
            "partner_package_monthly" => _config["STRIPE_PRICE_PARTNER_MONTHLY"],
            "partner_package_annual" => _config["STRIPE_PRICE_PARTNER_ANNUAL"],
            "enterprise_infrastructure_monthly" => _config["STRIPE_PRICE_ENTERPRISE_MONTHLY"],
            "enterprise_infrastructure_annual" => _config["STRIPE_PRICE_ENTERPRISE_ANNUAL"],
            "custom_implementation_one_time" => _config["STRIPE_PRICE_CUSTOM_IMPLEMENTATION"],
            _ => null
        };
    }
}
