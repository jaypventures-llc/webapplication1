using System.Text.Json;

namespace JPVOS.Infrastructure.Stripe;

public sealed class StripePricingLoader
{
    private readonly IWebHostEnvironment _env;
    private readonly ILogger<StripePricingLoader> _logger;
    private StripePricingMap? _cache;

    public StripePricingLoader(
        IWebHostEnvironment env,
        ILogger<StripePricingLoader> logger)
    {
        _env = env;
        _logger = logger;
    }

    public StripePricingMap Load()
    {
        if (_cache != null)
        {
            return _cache;
        }

        var root = Directory.GetParent(_env.ContentRootPath)?.Parent?.Parent?.FullName;

        if (root is null)
        {
            throw new InvalidOperationException("Unable to resolve repo root.");
        }

        var mode = Environment.GetEnvironmentVariable("STRIPE_MODE") ?? "test";

        var path = Path.Combine(
            root,
            "infrastructure",
            "stripe",
            "generated",
            $"stripe-pricing.{mode}.json");

        if (!File.Exists(path))
        {
            throw new FileNotFoundException(
                $"Stripe pricing map missing: {path}");
        }

        var json = File.ReadAllText(path);

        var result = JsonSerializer.Deserialize<StripePricingMap>(
            json,
            new JsonSerializerOptions
            {
                PropertyNameCaseInsensitive = true
            });

        if (result is null)
        {
            throw new InvalidOperationException(
                "Failed to deserialize Stripe pricing map.");
        }

        _cache = result;

        _logger.LogInformation(
            "Stripe pricing map loaded for mode {Mode}",
            mode);

        return result;
    }

    public StripePriceDefinition Resolve(string lookupKey)
    {
        var map = Load();

        if (!map.Prices.TryGetValue(lookupKey, out var result))
        {
            throw new KeyNotFoundException(
                $"Stripe lookup key not found: {lookupKey}");
        }

        return result;
    }
}
