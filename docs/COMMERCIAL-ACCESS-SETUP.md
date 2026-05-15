# JPV-OS Commercial Access Setup

## 1. Package Pricing

| Package Key                      | Description                       | Billing Interval | Example Price |
|----------------------------------|-----------------------------------|-----------------|--------------|
| member_access_monthly            | Member Access (Monthly)           | monthly         | $10/mo       |
| member_access_annual             | Member Access (Annual)            | annual          | $100/yr      |
| creator_launch_monthly           | Creator Launch (Monthly)          | monthly         | $25/mo       |
| creator_launch_annual            | Creator Launch (Annual)           | annual          | $250/yr      |
| partner_package_monthly          | Partner Package (Monthly)         | monthly         | $100/mo      |
| partner_package_annual           | Partner Package (Annual)          | annual          | $1000/yr     |
| enterprise_infrastructure_monthly| Enterprise Infrastructure (Monthly)| monthly        | $500/mo      |
| enterprise_infrastructure_annual | Enterprise Infrastructure (Annual)| annual          | $5000/yr     |
| custom_implementation_one_time   | Custom Implementation (One-Time)  | one_time        | Custom       |

## 2. Stripe Products & Prices to Create

For each package above, create a Stripe Product and a Price (recurring or one-time as appropriate). Copy the Price ID for each and set as an environment variable.

- STRIPE_PRICE_MEMBER_MONTHLY
- STRIPE_PRICE_MEMBER_ANNUAL
- STRIPE_PRICE_CREATOR_MONTHLY
- STRIPE_PRICE_CREATOR_ANNUAL
- STRIPE_PRICE_PARTNER_MONTHLY
- STRIPE_PRICE_PARTNER_ANNUAL
- STRIPE_PRICE_ENTERPRISE_MONTHLY
- STRIPE_PRICE_ENTERPRISE_ANNUAL
- STRIPE_PRICE_CUSTOM_IMPLEMENTATION

## 3. Required Environment Variables

Set these as environment variables in your deployment environment (do NOT store secrets in appsettings.json):

- STRIPE_SECRET_KEY
- STRIPE_WEBHOOK_SECRET
- STRIPE_PRICE_MEMBER_MONTHLY
- STRIPE_PRICE_MEMBER_ANNUAL
- STRIPE_PRICE_CREATOR_MONTHLY
- STRIPE_PRICE_CREATOR_ANNUAL
- STRIPE_PRICE_PARTNER_MONTHLY
- STRIPE_PRICE_PARTNER_ANNUAL
- STRIPE_PRICE_ENTERPRISE_MONTHLY
- STRIPE_PRICE_ENTERPRISE_ANNUAL
- STRIPE_PRICE_CUSTOM_IMPLEMENTATION
- DISCORD_CLIENT_ID
- DISCORD_CLIENT_SECRET
- DISCORD_BOT_TOKEN
- DISCORD_GUILD_ID
- DISCORD_ROLE_MEMBER
- DISCORD_ROLE_CREATOR
- DISCORD_ROLE_PARTNER
- DISCORD_ROLE_ENTERPRISE
- DISCORD_ROLE_CUSTOM
- DISCORD_REDIRECT_URI

## 4. Discord Roles to Create

Create the following roles in your Discord server and copy their IDs:

- Member
- Creator
- Partner
- Enterprise
- Custom

Assign the role IDs to the corresponding environment variables above.

## 5. Local Test Checklist

- [ ] Set all required environment variables in your .env or launch profile.
- [ ] Run `dotnet build` and `dotnet run`.
- [ ] Test Stripe checkout flow (use test keys).
- [ ] Test Stripe webhook (use Stripe CLI to forward events).
- [ ] Test Discord OAuth connection and role assignment.
- [ ] Confirm entitlement state updates on payment, cancellation, and failure.
- [ ] Confirm no secrets are present in appsettings files or source code.

## 6. Production Deployment Checklist

- [ ] Set all environment variables in your production environment (Azure, AWS, etc).
- [ ] Use live Stripe keys and price IDs.
- [ ] Use live Discord bot token and client secret.
- [ ] Confirm HTTPS is enabled.
- [ ] Confirm Stripe webhook endpoint is reachable and secret is set.
- [ ] Confirm Discord bot is in your server and has Manage Roles permission.
- [ ] Confirm no secrets are present in appsettings files or source code.

## 7. Revocation Rules

- On payment failure or subscription cancellation, paid Discord roles are removed and entitlement is revoked.
- On downgrade, roles are updated to match new package.
- EntitlementService is in-memory for development only; use persistent storage for production.

---

**Never commit real secrets or live price IDs to source control. Always use environment variables for secrets and IDs.**
