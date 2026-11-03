# Phase 3 — Advanced Common Fund targets, top-ups, refunds and closing preview

## What the Common Fund page now shows

- **Contribution targets per member**, set only by the group owner.
  Enter zero to clear a target. Targets are in the group's spending currency.
- **Actual contributions already received**, read from the existing protected
  fund ledger. These remain confirmed money, never a promise.
- **Still to collect** = max(target − confirmed contributions, 0)
  per member. Extra contributions do not make outstanding negative.
- **Top-up requests**, created and cancelled by the owner. Requests appear
  for group members to see but do NOT move any money. A separate manual
  contribution must be recorded after funds are actually received.
  Requests are a communication history rather than an automatically
  fulfilled payment processor; cancel an obsolete request manually.
- **Confirmed refunds**, recorded only by the owner AFTER actually
  returning money. Each refund has an amount and required reason/payment
  description. A protected server RPC locks the fund account and refuses
  refunds that overdraw the pooled balance or exceed that member's net
  recorded contributions (contributions minus their prior refunds).
  Refunds are separate from personal expense repayments and do not
  create a new split.
- **Fund closing preview**, with total contributions, fund purchases,
  confirmed refunds, fund balance, outstanding contribution targets,
  and an accounting mismatch warning if the totals do not reconcile.

The preview is informational. It neither closes the fund nor initiates a
bank transfer. A final fund lock and agreed per-member allocation of
the remaining balance are future functionality; do not automatically
divide the remaining pooled money equally.

## Database migration — REQUIRED

Apply after migration 000016 from PR #35:

    supabase/migrations/20261103_000017_advanced_common_fund.sql

It creates:
- `trip_fund_targets`
- `trip_fund_topup_requests`
- `trip_fund_refunds`

All tables use RLS for group-member read access. Mobile clients have NO
direct write grants. Only authenticated group owners can run:
`set_trip_fund_target`, `request_trip_fund_topup`,
`cancel_trip_fund_topup`, `confirm_trip_fund_refund`.

The refund RPC locks the fund account, checks recipient group membership,
current available balance, member contributions minus previous refunds,
and writes the balance debit + immutable refund record in one transaction.
This is important if two people attempt to confirm money at the same time.

All calculations use the **group spending currency**, not automatically
SGD or MYR. Multi-currency actual contribution/refund capture would
require explicitly storing the amount received/sent and the applied rate;
this phase does not silently convert currencies.

## Deployment checks

```bash
flutter pub get
flutter gen-l10n
flutter analyze
flutter test test/fund_reconciliation_test.dart
flutter build apk --release
```

### Manual multi-device checklist

1. With an existing four-person trip, set a SGD 200 target per member.
2. Record 200, 100, 0 and 250 in actual contributions. Outstanding should
   be 0, 100, 200 and 0. The excess 50 is not negative outstanding.
3. Request a 100 top-up; both owner and other member should see it.
   Confirm no fund balance change. Cancel it and check the audit status.
4. Confirm a member's actual contribution; verify fund balance increased
   only when the contribution RPC succeeds.
5. Spend from Common Fund; verify balance decreases without creating a
   personal debt or duplicate expense.
6. Confirm a 50 refund to a member with >=50 net contributions and available
   fund balance. Verify balance decreases by exactly 50 and refund history
   retains the note.
7. Try refund > current balance, refund > member net contributions, and
   refund to another group's member. All must fail server-side.
8. A non-owner cannot create targets, requests or refunds, even by RPC.
9. On two devices, attempt concurrent refunds that together exceed balance;
   exactly one must succeed.
10. Check fund closing preview: received - purchases - refunds = balance,
    and mismatch warning appears if historical data disagrees.
11. Retest PR #35 Common Fund edit/delete corrections after a refund:
    they must not overdraw the current balance.
12. Check small Android screens, English/Chinese, dark/light themes.

Source static checks and ARB parsing can run without Flutter, but a
Flutter release build and live Supabase integration tests are still
required before production deployment.
