# Member management and Common Fund detail safe-area fix

## Fixed on Android

The Common Fund purchase detail bottom sheet now:
- Shows the creator-only Edit/Delete notice **above** the receipt preview, not as
  the last line that can end up under gesture/navigation controls.
- Adds Android bottom safe-area padding plus a comfortable extra 36px, while
  retaining the scrollable sheet and its existing Edit/Delete actions.

## Group creator can now manage member display names

On **Group → Members**, the group owner gets a **three-dot menu** beside each
member. Choose **Edit member name** to change the nickname shown in that
group. This is a display name only. It does not edit anyone's Supabase
authentication identity or another group's nickname.

For nonowner members, the group owner also sees **Remove member**. The
action requires explicit confirmation. **Important limitation:** the server
allows removal only if that member has *no group financial history or other
recorded financial activity*. The SQL checks personal expense ownership,
expense shares, repayments, fund contributions/purchases, confirmed refunds,
targets, request history, receipt records, and correction/operation audit
records. The owner cannot remove themself. Members with financial activity
can be renamed instead, avoiding broken balances and history.

When an unused member is removed:
- Their membership and stored PayNow contact in *that group only* are removed.
- Their access to group data is revoked by the existing member-based RLS.
- The invite code is regenerated, because the removed member may still know
  the old code. **Existing invite links stop working**: share the new code
  with intended members after removal.
- No group expenses, fund balances, or repayments are deleted.

## Supabase deployment

Apply this migration **after 000019**:

`supabase/migrations/20261103_000020_group_member_management.sql`

It adds two owner-only `SECURITY DEFINER` RPCs, leaving existing membership
table RLS and client-side direct-write prohibitions unchanged:
`rename_trip_group_member(uuid,uuid,text)` and
`remove_trip_group_member(uuid,uuid)`.

No new Flutter dependencies.

## Checks before merge

```sh
flutter pub get
flutter gen-l10n
flutter analyze
flutter test
flutter build apk --release
```

Test on a small Android device with both gesture and 3-button navigation:
1. Open an old Common Fund expense recorded by another user; its notice
   must remain readable and never overlap the navigation bar.
2. Scroll through a long receipt preview; the bottom is reachable.
3. Confirm the expense creator still sees Edit/Delete and other members
   only see the explanatory notice.
4. Group owner opens Members → three-dot menu. Rename a nonowner; reload
   to verify the new name appears throughout the group.
5. A nonowner must not see member management and must not be able to call
   the owner RPCs directly.
6. Remove a newly joined member with no financial activity. Confirm
   their group access stops; an old invite token no longer joins the group.
7. Invite a member using the newly generated invite token.
8. Attempt to remove a member who owes, paid, contributed, was assigned
   an expense, or has a target/recorded audit history. The server must
   reject it and leave all financial data unchanged.
9. Attempt to remove the owner: unavailable in UI and rejected by RPC.
10. Test English and Chinese, light and dark themes.

**Validation:** Source delimiter checks and localization parity passed.
Supabase migration and Flutter/device builds have not run in this
repository editing environment. Keep draft until tested.
