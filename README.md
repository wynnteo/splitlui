# SplitLui 🌈

**Good times. Fair shares.**

A colorful Flutter app for travel groups, shared funds and group expense splitting.

## First milestone

- Playful home screen and responsive rounded-card styling.
- Light, dark and system appearance.
- English and Simplified Chinese via Flutter's generated `gen-l10n` ARB files (`lib/l10n/app_en.arb` and `app_zh.arb`).
- Saved theme and language settings.
- Create Travel and Hangout groups, with settlement/spending currency, custom agreed exchange rate and optional spending budget.
- Groups persist locally on the device via shared_preferences.

**Not built yet:** invitations, multi-user sync, actual expenses, common-fund transactions, PayNow QR and real settlement. Placeholder cards explicitly indicate upcoming features.

## Bootstrap native Flutter project

This repository starts with Flutter source and manifest, without generated Android/iOS/native folders. On your development Mac:

```bash
git clone https://github.com/wynnteo/splitlui.git
cd splitlui
flutter create --project-name splitlui --org dev.cloudfullstack .
python3 scripts/ensure_android_internet_permission.py
flutter pub get
flutter gen-l10n
flutter analyze
flutter run
```

Before committing generated platform files, review `git diff` and configure your desired application IDs.

## Currency rule

Store the rate as **spending currency units per 1 settlement currency unit**.

Example: 1 SGD = 115 JPY. Rate is `115`. An expense of 11,500 JPY is 100 SGD. This is an agreed/manual rate, not a live market rate.

## Planned next steps

1. Supabase Auth, RLS-protected group membership and shareable invite links.
2. Collaborative member expense entry: payer, participants, equal/exact/percentage splits.
3. Common Fund ledger: contributions, pooled payments, top-ups and refunds.
4. Custom per-expense rates, balance algorithm and SGD settlement.
5. PayNow QR image sharing and manual confirmed-settlement workflow.

## Build an Android release APK with internet access

Android platform files are generated locally by `flutter create` and are not
currently committed in this repository. Therefore **don't overwrite your
existing AndroidManifest.xml with a generic template**: it may contain
important application IDs, plugins, activity settings, and signing setup.

From the SplitLui project folder on your Mac, run:

```bash
git pull origin master
python3 scripts/ensure_android_internet_permission.py
flutter clean
flutter pub get
flutter gen-l10n
flutter build apk --release
```

The idempotent script adds
`<uses-permission android:name="android.permission.INTERNET" />`
inside your existing
`android/app/src/main/AndroidManifest.xml` (outside `<application>`).
It preserves the rest of the manifest and can be run more than once.
If the Android platform folder is missing, first run:

```bash
flutter create --project-name splitlui --org dev.cloudfullstack .
```

The APK is at `build/app/outputs/flutter-apk/app-release.apk`.
For a USB-connected Android phone you can also use
`flutter install --release` after building.

If a release APK still reports `Failed host lookup`, open your
configured Supabase project's URL in the phone browser, and check
Wi-Fi/mobile data, DNS/VPN/Private DNS, and the Supabase project status.
An internet permission fixes a missing app permission, but not a real
DNS outage or a wrong Supabase URL.
