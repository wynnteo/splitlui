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
