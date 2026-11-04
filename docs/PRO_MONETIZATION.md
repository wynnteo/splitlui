# SplitLui Pro – hybrid monetization rollout

This is a staging design, **not yet an operational billing integration**.

## Product catalogue (create in both stores)

| Product ID | Type | Tentative Singapore target |
| --- | --- | --- |
| `splitlui_pro_monthly` | Auto-renewable subscription | SGD 2.98/month |
| `splitlui_pro_yearly` | Auto-renewable subscription | SGD 19.98/year |
| `splitlui_pro_lifetime` | Non-consumable one-time purchase | SGD 39.98 once |

Display localized **store-provided** prices, subscription terms and durations before checkout; these are proposed amounts only. Apple monthly/yearly plans belong in the same subscription group. Lifetime is a separate non-consumable. Consider not selling lifetime and renewable Pro simultaneously to the same account.

## Fair-use feature policy

Free must always retain viewing existing groups, expenses, repayment history, Common Fund balances and confirmed financial records, and access to export/backup where required to avoid data lock-in. **Never block reconciliation, repayment confirmations or member access to existing financial records behind a subscription.**

Suggested launch differentiation:
- Free: all current core features; modest new-group creation cap for *future* groups only (do not retroactively lock existing groups).
- Pro: unlimited *new* groups, higher receipt OCR usage allowance, enhanced insights and presentation-only advanced reports.
- If limits are introduced, enforce them on the backend (Supabase RPC/RLS), not by hiding buttons on the device; do not remove offline unsynced data.
- A premium group feature should not force non-paying group members to subscribe simply to see or settle obligations.

## Required before accepting any payment

1. Add `in_app_purchase` Flutter dependency and startup purchase stream listener.
2. Create all products in Play Console and App Store Connect, including subscription metadata and terms. Ensure package `com.cloudfullstack.splitlui` is the Play application ID.
3. Implement a trusted Supabase Edge Function that authenticates the user, verifies Android purchase tokens through Google Play Developer API or Apple transactions using App Store Server API, and stores canonical status (active, expired, refunded/revoked, lifetime) in a protected entitlement table.
4. Uniquely bind purchase transaction / token to one account; handle replays and duplicate events. Reconcile Play RTDN and App Store Server Notifications V2, plus periodic expiry/renewal checks.
5. Add server-side entitlement read and enforce **only optional Pro features** with server checks. No boolean in SharedPreferences can grant access.
6. Handle interrupted purchases, refunds, cancellations, grace periods, billing retries, restore purchases, sign-out/sign-in, account switching and cross-platform entitlement sync.
7. Verify the transaction BEFORE granting Pro; finalize/acknowledge purchases according to store timing requirements. Handle failed verification safely and allow retry.
8. Show subscription auto-renewal terms, localized real prices, Restore Purchases, Manage Subscription, privacy policy and terms links.
9. Test Play license testers (internal/closed testing) and Apple sandbox on physical devices. Run `flutter analyze`, `flutter test` and signed AAB / iOS archive checks.

## Current rollout status

- [x] Bilingual Pro preview in Settings; no charged checkout actions
- [x] Single catalogue of monthly / yearly / lifetime IDs
- [x] Entitlement model fails closed unless explicitly server verified
- [x] Unit tests for product identity and fail-closed rules (run locally)
- [ ] Store products, subscription disclosures and real price retrieval
- [ ] Backend verification and entitlement storage
- [ ] Purchase stream, checkout and restore flow
- [ ] Cancellation/renewal/revocation event handling
- [ ] Gated optional Pro features and end-to-end QA

Source: https://pub.dev/packages/in_app_purchase
Google verification: https://developer.android.com/google/play/billing/security
