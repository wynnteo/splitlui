# SplitLui Pro – hybrid monetization rollout

This is a staging design, **not yet an operational billing integration**.

## Product catalogue (create in both stores)

| Product ID | Type | Tentative Singapore target |
| --- | --- | --- |
| `splitlui_pro_monthly` | Auto-renewable subscription | SGD 2.98/month |
| `splitlui_pro_yearly` | Auto-renewable subscription | SGD 19.98/year |
| `splitlui_pro_lifetime` | Non-consumable one-time purchase | SGD 39.98 once |

Display localized **store-provided** prices, subscription terms and durations before checkout; these are proposed amounts only. Apple monthly/yearly plans belong in the same subscription group. Lifetime is a separate non-consumable. Consider not selling lifetime and renewable Pro simultaneously to the same account.

## Confirmed Free tier policy — annual group creation quota

**Decision: three newly created cloud groups per account per UTC calendar year.** This is a future enforcement specification, not an active limit.

- A Free user can successfully create up to **3 groups during January 1–December 31 UTC**. The quota automatically refreshes on January 1 UTC. Display the renewal date in the user's local timezone, while using the server's UTC year for consistency.
- Count every successful `create_trip_group` once. Never count a failed RPC or a mere attempt; handle concurrent attempts atomically. Existing groups from before the feature is enabled must be grandfathered and not silently counted retroactively.
- Deleting or archiving a group **does not refund the annual creation count**. Do not erase accounting records when a group is deleted. Keep only minimal quota metadata, subject to the privacy/data-retention policy.
- Joining somebody else's group, editing existing groups, viewing historical expenses, settling debts and Common Fund activity **never consumes a group creation slot**.
- If Free usage reaches 3/3, show a bilingual message and an optional Pro preview. Do not submit the group creation RPC; never block existing group participation or financial obligations.
- A verified Pro entitlement allows unlimited groups. If Pro later expires, previously created groups remain usable; only further creation above the Free annual quota is restricted.
- Require a durable authenticated account before enforcing purchases or annual limits. **Current anonymous Supabase accounts can be reset with an app reinstall**, so an anonymous identity alone cannot reliably enforce account-level fair use.
- Server-side enforcement belongs inside the same transaction as the group creation RPC. Use an account/year quota ledger plus an account-specific transactional lock or atomic UPSERT, and count only after successful creation. Enforce across Android/iOS and multiple devices. Never trust a client-supplied year, remaining quota, or paid flag.
- Before enabling this policy, finish Google/Apple purchase validation, Supabase entitlements, restore purchases, account linking, and the bilingual quota UI. Keep restrictions disabled until all paths pass end-to-end tests.

### Acceptance cases

1. Fresh Free account creates 3 groups; 4th is blocked with 3/3 usage and a clear reset date.
2. Delete the first group: quota remains 3/3; a new group is still blocked.
3. Join an unlimited number of other groups: quota unchanged.
4. Two concurrent third/fourth group requests cannot both succeed.
5. Failed group creations never consume a slot; network retries cannot double-count a successful request.
6. Reset UTC year: Free user receives 3 new slots.
7. Verified Pro and lifetime owners create unlimited groups; expiration never hides or locks financial history.
8. Existing users are not retrospectively charged for already-created groups.
9. Reinstall or sign out does not bypass quota for a permanent account.
10. English and Simplified Chinese explain the cap and recovery, without Thai localization.

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
