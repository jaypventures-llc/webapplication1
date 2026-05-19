using Stripe;
using Stripe.Checkout;

namespace JPVOS.Infrastructure.Stripe;

public sealed class StripeCheckoutService
{
    private readonly StripePricingLoader _pricingLoader;
    private readonly IConfiguration _configuration;

    public StripeCheckoutService(
        StripePricingLoader pricingLoader,
        IConfiguration configuration)
    {
        _pricingLoader = pricingLoader;
        _configuration = configuration;
    }

    public async Task<Session> CreateCheckoutSessionAsync(
        string lookupKey,
        HttpRequest request)
    {
        var price = _pricingLoader.Resolve(lookupKey);

        if (string.IsNullOrWhiteSpace(price.Price_Id))
        {
            throw new InvalidOperationException(
                $"Price ID missing for lookup key: {lookupKey}");
        }

        var baseUrl =
            $"{request.Scheme}://{request.Host}";

        var options = new SessionCreateOptions
        {
            Mode = "subscription",

            SuccessUrl =
                $"{baseUrl}/billing/success?session_id={{CHECKOUT_SESSION_ID}}",

            CancelUrl =
                $"{baseUrl}/billing/cancelled",

            LineItems = new List<SessionLineItemOptions>
            {
                new()
                {
                    Price = price.Price_Id,
                    Quantity = 1
                }
            },

            AutomaticTax = new SessionAutomaticTaxOptions
            {
                Enabled = true
            },

            Metadata = new Dictionary<string, string>
            {
                ["ecosystem"] = "JPV-OS",
                ["lookup_key"] = lookupKey,
                ["source"] = "access_gateway"
            }
        };

        var service = new SessionService();

        return await service.CreateAsync(options);
    }
}
