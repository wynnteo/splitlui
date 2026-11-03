# Phase 11 — Share group invitations

From **Groups → choose group → Invitation code**, tap **Share invite**.
This opens Android/iOS's system share sheet (including WhatsApp when installed),
with a friendly invite message, the group name, **existing 64-character
high-entropy invite code**, and instructions for joining.

Recipients install/open SplitLui, select **Join Group**, enter a nickname
and paste **either the code alone or the entire invitation text**. The join
action extracts the code and calls the existing secure Supabase
`join_trip_group` RPC. No new database migration is needed.

## Install URL (when available)

For an unpublished app, **no public app-install URL is inserted**, since
an APK stored only on the developer's phone isn't a publicly accessible
installation link. Once published, pass the real Play Store URL when
building the APK:

```bash
flutter build apk --release \
  --dart-define='SPLITLUI_INSTALL_URL=https://play.google.com/store/apps/details?id=YOUR_REAL_PACKAGE_ID'
```

Use the app's actual Play listing package ID, not the placeholder above.
Then the generated share message includes the install URL.

Avoid embedding private APK links or fake store URLs. An app store listing
may not yet be accessible to friends until the release/testing track is
configured and friends are authorized testers.

## Security

- Anyone who learns the code can join the group. Share it only with
  trusted people, and use **Reset invitation code** if it leaks.
- The code is not a login or personal account recovery mechanism.
- Existing anonymous Supabase accounts are still device-bound.
- No new server permissions are required; membership is enforced in the
  existing join-group SQL RPC.

## Validation after merging

```bash
git checkout master
git pull origin master
flutter pub get
flutter gen-l10n
flutter analyze
flutter test test/group_invite_message_test.dart
flutter build apk --release
```

Test on two devices: invite generation, share to WhatsApp, paste **full
message** into Join Group, verify membership sync, reset code and verify
old code stops working. Check English and Chinese strings.

**Not included:** automatic group joining from tapping the install link,
Android App Links / Universal Links, referral tracking, and an app download
host. Friends still paste the code after installation. Flutter tests and
live Supabase integration were not run in the repository editing environment.
