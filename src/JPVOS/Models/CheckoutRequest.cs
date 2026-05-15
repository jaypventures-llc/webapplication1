namespace JPVOS.Models;

public record CheckoutRequest
{
    public string? PackageKey { get; init; }
    public string? SuccessUrl { get; init; }
    public string? CancelUrl { get; init; }
}
