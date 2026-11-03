# Phase 10 — PayNow details and sharing repayment requests

This phase adds **optional PayNow-linked Singapore mobile details** and a
**Share payment request** action to the existing **Who owes whom** page.

SplitLui does **not** create a bank QR, initiate payments, validate a
recipient's bank identity, verify bank transaction status, or mark a debt
as settled when a request is shared. Payment receipt confirmation remains
the recipient-controlled feature from Phase 9.

## First-time setup

1. Merge PR and pull `master`.
2. Run `supabase/migrations/20261103_000008_paynow_details.sql` in
   **Supabase Dashboard → SQL Editor**. Phase 2 group schema must exist.
   A GitHub merge does not apply the migration automatically.
3. In Android Studio Terminal:

       git checkout master
       git pull origin master
       flutter pub get
       flutter gen-l10n
       flutter analyze

4. Press Android Studio's normal **Run** button.

The new `share_plus` plugin uses the phone's **system share sheet**.
Select WhatsApp if installed, or share using Messages/other supported apps.
The app does not have permission to read WhatsApp contacts or send messages
without you choosing a destination.

## User journey

1. Open **Groups → [Group] → Who owes whom**.
2. Tap **My PayNow details**, enter your own Singapore mobile linked to
   PayNow (e.g. 91234567) and save. Leaving the field blank removes it.
3. If somebody owes **you**, your suggested transfer card shows
   **Share payment request** and **Confirm money received**.
4. Tap **Share payment request**, choose WhatsApp from the system sheet,
   select the contact and send. The generated message contains the group
   name, sender, recipient, outstanding amount in group spending currency,
   and your optional PayNow phone.
5. Once the money is actually received, tap **Confirm money received**.
   Sharing a request does not reduce the balance.

For a JPY trip with **SGD settlement currency**, the message shows
the outstanding **JPY amount** and a separately labeled **approximate
SGD equivalent** using the group's current exchange rate. PayNow is a
Singapore-dollar transfer method: agree on the actual SGD amount before
paying. The estimate is not a live bank rate.

## Privacy and safety

- The PayNow number is **opt-in** and scoped to **one group**, not global.
- All current group members can view group members' entered PayNow
  numbers; enter a number only if you're comfortable sharing it.
- Only an authenticated group member can edit/remove **their own** number.
  The SQL RPC enforces ownership and validates a Singapore mobile with
  eight digits beginning with 8 or 9. Prefix +65 is accepted.
- Never enter OTPs, bank login details, passwords, PayNow PINs or
  account credentials in SplitLui.
- A saved phone number is **self-declared**. SplitLui cannot verify
  whether it is registered for PayNow or who owns the receiving bank
  account. Users should always verify the actual recipient name in
  their banking app before transferring funds.
- No PayNow QR is generated in this phase; QR payments require proper
  payment-standard compliance and verified payment details.
- Both read and write access require Supabase RLS/RPC permissions. No
  direct table INSERT/UPDATE/DELETE is granted to the Flutter client.

## Regression tests

1. Member A saves their PayNow number; refresh and verify it persists.
2. Member B can read the number only if B belongs to the same group.
3. Member B cannot change member A's number using the RPC.
4. Remove the number by saving an empty value.
5. Reject invalid mobile numbers (length/prefix).
6. Ensure only the creditor sees the Share/Confirm buttons for a
   suggested transfer; sharing does not mark a repayment as received.
7. From the share sheet, choose WhatsApp and verify message formatting.
8. Check JPY→SGD group settlement message labels the SGD amount as
   an estimate and warns users to agree the actual amount.
9. Test dark mode, English/Chinese and Android Studio normal Run.

**Validation:** Dart, Flutter plugin build and live Supabase SQL have
not been run by the assistant. Execute `flutter analyze` and test
on two devices before production use.
