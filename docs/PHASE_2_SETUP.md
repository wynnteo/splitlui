# Phase 2: Shared groups

Group membership is cloud-backed. Phase 1 local groups remain separate.

## Supabase setup
1. Create a Supabase project.
2. Enable Authentication > Providers > Anonymous Sign-Ins for development.
3. Execute supabase/migrations/20261103_000001_trip_groups.sql in the Supabase SQL Editor.
4. The project URL and **publishable (public client) key** are already committed in `config/supabase.json` for this app. Never use a secret/service_role key in Flutter.

## Run
The configuration is **already included** in `config/supabase.json`. No file copying or editing required.

    flutter pub get
    flutter gen-l10n
    flutter analyze
    flutter run --dart-define-from-file=config/supabase.json

The publishable key is intended for use in client applications and is not a secret. Authorization is enforced with Supabase RLS. Do not add a service_role or secret key to this checked-in file.

Without Supabase settings, cloud groups stay disabled and local Phase 1 groups still work.

## Try on two separate devices
1. Device A: Shared groups > enter nickname > Create group.
2. Open the group, copy its 64-character invitation code and send it to your friend.
3. Device B: Shared groups > Join group > enter nickname and paste invite code.
4. Refresh on either device to view members. Rejoining an existing group is idempotent.
5. Group owner can reset invite code; older codes then stop working for future joins.

## Security and limitations
- RLS restricts groups and members to current group members.
- Database RPCs create and join groups, rather than exposing unrestricted table writes.
- Invitation tokens are generated with strong random UUID values and can be rotated by the owner.
- Invite codes are copied manually, not deep linked yet.
- There is no realtime streaming of membership updates yet; press Refresh.
- Anonymous Auth is device/session-bound. Clearing app data can lose access; implement recoverable login before public release.
- No multiuser expense edits, shared-fund ledger, or PayNow transfers in this phase.
- Configure Supabase Auth abuse/rate limiting and verify cross-user RLS before public release.
- Only English and Simplified Chinese are supported; all new text uses ARB.

## Validation
Test with separate devices, invalid code, rotated code, unauthorized RLS reads, both themes and both languages.
Flutter SDK is not available in the GitHub editing environment; run Flutter analysis locally before merging.
