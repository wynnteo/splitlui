# Phase 6 — One Groups experience

## Why
Before this update, the app mixed phone-only (legacy) groups and Supabase
Shared Groups. A device-only group could not use Expenses or Common Fund.
This update makes **Groups** the main screen whenever Supabase is configured.

## How to use
1. Open SplitLui in Android Studio using the normal **Run** button.
2. Tap **Create group**, enter your nickname (first time), group details
   and save. The group is stored in Supabase.
3. Open the group. Invite friends using the code; use Expenses, Members
   and Common Fund directly from the same group detail page.
4. If you created an older local group before cloud sync, look under
   **Older groups on this device**. Tap **Move to Groups** to copy its
   metadata to a new cloud group. It does not copy any expenses because
   legacy groups never had a functional expense ledger. The old copy is
   removed only after the new cloud group is successfully created.
5. Owners can **Edit group** to change name, travel/hangout type,
   exchange rate and optional budget. Currency codes are intentionally
   locked after creation: historical financial records must not be
   silently re-denominated.
6. Owners can **Delete group**. They must type the group's current name.
   **Deletion is permanent**: members, invitations, expenses and Common
   Fund records are removed from Supabase via cascades. There is no
   undo/recycle bin yet. Other members cannot delete or edit the group.

## Required Supabase change
Run `supabase/migrations/20261103_000005_group_management.sql` in
Supabase Dashboard → SQL Editor, once, after the original group schema.
Without this migration, Edit/Delete buttons will fail because the RPCs
do not yet exist.

## Local setup
After merging and applying SQL:
    git checkout master
    git pull origin master
    flutter pub get
    flutter gen-l10n
    flutter analyze

Press Run in Android Studio. No additional --dart-define argument.

## Tests
- Brand-new user sees only one Groups page, can create group, and
  immediately open Expenses, Members and Common Fund.
- Existing device-only groups are visible under the legacy section
  and can be moved into cloud groups without data loss.
- Edit group name/budget/type/rate, navigate back, verify list updated.
- Editing currency is disabled on existing cloud groups.
- Delete confirmation must match exact group name. Wrong name fails.
- Owner delete removes related records; non-owner RPC calls fail.
- Confirm group member and fund data survive ordinary edits.
- English/Chinese, light/dark modes, narrow Android screen.

This PR and migration have not been executed in the remote Supabase
project or Flutter SDK by the assistant. Test before production use.
