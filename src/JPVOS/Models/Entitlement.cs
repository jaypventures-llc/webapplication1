namespace JPVOS.Models;

public class Entitlement
{
    public string Id { get; set; } = Guid.NewGuid().ToString();
    public string StripeCustomerId { get; set; } = string.Empty;
    public string StripeSubscriptionId { get; set; } = string.Empty;
    public string PackageKey { get; set; } = string.Empty;
    public string BillingInterval { get; set; } = string.Empty;
    public string Status { get; set; } = "pending";
    public DateTime? AccessExpiration { get; set; }
    public string DiscordUserId { get; set; } = string.Empty;
    public string DiscordRole { get; set; } = string.Empty;
}
