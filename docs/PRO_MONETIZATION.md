# SplitLui Pro – hybrid monetization rollout

This is a staging design, **not yet an operational billing integration**.

## Product catalogue (create in both stores)

| Product ID | Type | Tentative Singapore target |
| --- | --- | --- |
| `splitlui_pro_monthly` | Auto-renewable subscription | SGD 2.98/month |
| `splitlui_pro_yearly` | Auto-renewable subscription | SGD 19.98/year |
| `splitlui_pro_lifetime` | Non-consumable one-time purchase | SGD 39.98 once |

Display localized **store-provided** prices, subscription terms and durations before checkout; these are proposed amounts only. Apple monthly/yearly plans belong in the same subscription group. Lifetime is a separate non-consumable. Consider not selling lifetime and renewable Pro simultaneously to the same account.

## Confirmed Free tier policy — unlimited groups

**Decision: unlimited group creation and joining are free.** The previously proposed limit of 3 new groups per calendar year is cancelled. There is no group-creation quota to enforce. No legacy quota counters or backend restrictions should be introduced.

| Capability | Free | Pro (planned) |
| --- | --- | --- |
| Create, join, delete and manage groups | Unlimited | Unlimited |
| Members and shared expenses | Unlimited | Unlimited |
| Equal, exact, percentage and weighted splits | Included | Included |
| Multi-currency expenses and agreed exchange rates | Included | Included |
| Common Fund: contributions, purchases, targets, top-ups and refunds | Included | Included |
| Repayment suggestions, confirmation, reversals | Included | Included |
| Offline entry and syncing | Included | Included |
| Manual receipt photo attachment | Included | Included |
| On-device receipt OCR | Included, initially unrestricted | Included; future convenience enhancements |
| Basic trip closing PDF and financial history | Included | Included |
| Advanced analytics and comparison dashboards | Not included | Planned |
| Advanced/custom-branded PDF layouts and deeper breakdowns | Not included | Planned |
| CSV/spreadsheet bulk export and organiser productivity tools | Not included | Planned |
| Advertising (only if introduced later) | May show ads | Ad-free |

**Launch policy:** do not enforce OCR scan quotas or other new restrictions until there is a verifiable and reliable quota service. Existing OCR and current trip-closing PDF work remain free. Pro should enhance convenience, insights and presentation, not block the financial basics.

**Pro scope is a roadmap, not shipped functionality.** Do not display subscription checkout or grant Pro until Google Play / App Store products, server verification, restore purchases and entitlements are working. Never downgrade or hide existing group data or settled financial history on expiry.

## Product and safety principles

- Unlimited group creation, joining, member access and expenses stay free, even if Pro is cancelled.
- Users can always view/export essential financial records, reconcile fund balances and confirm repayments without paying.
- Existing Common Fund targets, top-ups and refunds stay free.
- If advertising is introduced, it must not disrupt expense entry, settlement, receipt review, or critical confirmations.
- Advanced reporting must add genuinely new insights rather than merely relabel an existing free report.
- Any paid entitlement check must be verified on the server and must not depend on a locally stored paid flag.
- Group creators and members must not be forced to subscribe to resolve financial obligations.
- On-device OCR currently has no enforced quota; revisit usage caps only after measuring meaningful operating costs and user needs.

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
