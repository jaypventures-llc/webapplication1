# Commercial Access Testing Guide

## 1. Stripe Test Card Flow
- Use Stripe test cards (e.g., 4242 4242 4242 4242) for checkout.
- Confirm successful payment creates an active entitlement and assigns Discord role.
- Test with different packages and intervals (monthly, annual, one-time).

## 2. Webhook Local Test Flow
- Use Stripe CLI to forward webhook events to your local server:
  - `stripe listen --forward-to localhost:5111/api/stripe/webhook`
- Confirm events update entitlement state as expected.

## 3. Discord OAuth Test Flow
- Connect Discord via the OAuth flow.
- Confirm Discord user is linked to entitlement and receives correct role.

## 4. Cancellation Test
- Cancel a Stripe subscription in the dashboard.
- Confirm entitlement is revoked and Discord role is removed.

## 5. Failed Payment Test
- Use Stripe test card that triggers payment failure (e.g., 4000 0000 0000 9995).
- Confirm entitlement is marked past_due and Discord role is removed.

## 6. Annual vs Monthly Test
- Purchase both monthly and annual packages.
- Confirm entitlements reflect correct interval and expiration.

## 7. Access Revocation Test
- Simulate subscription deletion or payment failure.
- Confirm access is revoked and Discord role is removed.

## 8. Idempotency Test
- Repeat the same Stripe checkout/session.
- Confirm no duplicate entitlements or Discord role assignments.

---

**Always test with Stripe test keys and Discord test server before deploying to production.**
