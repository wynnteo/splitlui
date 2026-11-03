// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for English (`en`).
class AppLocalizationsEn extends AppLocalizations {
  AppLocalizationsEn([String locale = 'en']) : super(locale);

  @override
  String get hello => 'Your moments, together.';

  @override
  String get subtitle => 'Plan, share and settle with ease.';

  @override
  String get groups => 'Your groups';

  @override
  String get newGroup => 'Create group';

  @override
  String get empty => 'Your next adventure starts here!';

  @override
  String get settings => 'Settings';

  @override
  String get theme => 'Appearance';

  @override
  String get language => 'Language';

  @override
  String get system => 'System';

  @override
  String get light => 'Light';

  @override
  String get dark => 'Dark';

  @override
  String get name => 'Group name';

  @override
  String get travel => 'Travel';

  @override
  String get hangout => 'Hangout';

  @override
  String get spending => 'Spending currency';

  @override
  String get settlement => 'Settlement currency';

  @override
  String get rate => 'Spending currency per 1 settlement currency';

  @override
  String get budget => 'Budget (optional, spending currency)';

  @override
  String get create => 'Create group';

  @override
  String get required => 'Please enter a group name';

  @override
  String get invalid => 'Please enter a valid number';

  @override
  String get expenses => 'Expenses';

  @override
  String get fund => 'Common fund';

  @override
  String get members => 'Members';

  @override
  String get soon => 'Coming in the next feature!';

  @override
  String get local =>
      'Saved on this device. Group invitations and sync are not available yet.';

  @override
  String get rateHint => 'Example: 1 SGD = 115 JPY → enter 115';

  @override
  String get version => 'SplitLui 0.1.0';

  @override
  String get cloudGroups => 'Shared groups';

  @override
  String get cloudTitle => 'Shared groups';

  @override
  String get cloudSubtitle =>
      'Invite friends and plan your adventures together.';

  @override
  String get cloudJoin => 'Join group';

  @override
  String get cloudRefresh => 'Refresh';

  @override
  String get cloudNickname => 'What should friends call you?';

  @override
  String get cloudNicknameHint => 'Your nickname';

  @override
  String get cloudCancel => 'Cancel';

  @override
  String get cloudContinue => 'Continue';

  @override
  String get cloudInviteHint => 'Paste an invitation code';

  @override
  String get cloudInviteCode => 'Invitation code';

  @override
  String get cloudCopyInvite => 'Copy invite code';

  @override
  String get cloudCopied => 'Invitation code copied';

  @override
  String get cloudResetInvite => 'Reset invitation code';

  @override
  String get cloudOwner => 'Organiser';

  @override
  String get cloudEmpty =>
      'No shared groups yet. Start one or join a friend\'s group!';

  @override
  String get cloudIdentityWarning =>
      'Guest accounts are device-bound. Clearing app data may lose access. Account recovery will be added later.';

  @override
  String get cloudExpenseNext =>
      'Expenses, common funds and automatic settlements are coming next.';

  @override
  String get cloudNotConfigured =>
      'Shared groups need Supabase configuration before they can be used.';

  @override
  String get nameHint => 'e.g. Weekend in Tokyo';

  @override
  String get settingsIntro => 'Personalise your SplitLui experience.';

  @override
  String get appearanceHint => 'Choose how SplitLui looks on your device.';

  @override
  String get languageHint => 'Select your preferred app language.';

  @override
  String get addExpense => 'Add expense';

  @override
  String get expenseTitle => 'Expense name';

  @override
  String get expenseTitleHint => 'e.g. Dinner';

  @override
  String get expenseAmount => 'Amount';

  @override
  String get paidBy => 'Paid by';

  @override
  String get splitBetween => 'Split between';

  @override
  String get equalSplitOnly =>
      'Equal split between selected members. Amounts are rounded to the nearest cent.';

  @override
  String get selectParticipants => 'Select at least one person to split with.';

  @override
  String get saveExpense => 'Save expense';

  @override
  String get noExpenses =>
      'No expenses yet. Add the first expense to get started.';

  @override
  String get expenseEntryHint => 'Add and review shared expenses';

  @override
  String get fundEntryHint => 'Manage pooled contributions and spending';

  @override
  String get fundBalance => 'Available fund balance';

  @override
  String get fundLowBalance => 'Fund is running low. Consider topping up.';

  @override
  String get fundThreshold => 'Low-balance alert';

  @override
  String get fundThresholdHint =>
      'Set an alert threshold in the spending currency. Enter 0 to turn off the warning.';

  @override
  String get fundManualNotice =>
      'Manual ledger only — record contributions after receiving the money. No bank transfers happen in this app.';

  @override
  String get fundAddContribution => 'Record contribution';

  @override
  String get fundPayExpense => 'Pay from common fund';

  @override
  String get fundHistory => 'Fund activity';

  @override
  String get fundNoEntries => 'No fund transactions yet.';

  @override
  String get fundContributedBy => 'Contributed by';

  @override
  String get fundPaidFromPool => 'Paid using group funds';

  @override
  String get fundContributionNote => 'Contribution note';

  @override
  String get fundContributionHint => 'e.g. Cash collected';

  @override
  String get fundContributor => 'Contributed by';

  @override
  String get fundRecordActual =>
      'Only record money actually received, not an amount someone promised to pay.';

  @override
  String get fundNoDoubleSplit =>
      'This payment uses common funds and will not create an individual split expense.';

  @override
  String get localOnlyFeatures =>
      'This group is saved only on this device. Expenses, Common Fund and member management work in Shared Groups, where everyone can join.';

  @override
  String get openSharedGroups => 'Open shared groups';

  @override
  String get createLocalGroup => 'Create local group';

  @override
  String get editGroup => 'Edit group';

  @override
  String get saveChanges => 'Save changes';

  @override
  String get groupUpdated => 'Group updated';

  @override
  String get deleteGroup => 'Delete group';

  @override
  String get typeGroupName =>
      'Type the group name to permanently delete this group and all its expenses, funds and members';

  @override
  String get olderDeviceGroups => 'Older groups on this device';

  @override
  String get olderDeviceGroupsHint =>
      'These were created before group syncing. Move them online to use Expenses and Common Fund.';

  @override
  String get moveToGroups => 'Move to Groups';

  @override
  String get deleteLocalGroup => 'Delete device-only group?';

  @override
  String get deleteLocalWarning =>
      'This removes the group from this phone. It cannot be recovered.';

  @override
  String get expenseCurrency => 'Expense currency';

  @override
  String get expenseRateToGroup => 'Exchange rate to group currency';

  @override
  String get groupEquivalent => 'Equivalent in group currency';

  @override
  String get expenseConversionHint =>
      'The exchange rate is saved with this expense. Original and converted shares are both recorded; conversions are rounded to two decimals.';

  @override
  String get settlementPreview => 'Who owes whom';

  @override
  String get settlementEntryHint => 'Review balances and suggested repayments';

  @override
  String get settlementExplanation =>
      'See each member\'s net balance from shared expenses, converted into the group\'s spending currency.';

  @override
  String get settlementRateNote => 'Estimated conversion rate';

  @override
  String get settlementTotalExpenses => 'Total shared expenses';

  @override
  String get settlementSuggestedTransfers => 'Suggested repayments';

  @override
  String get settlementAllEven => 'Everyone is settled up so far.';

  @override
  String get settlementMemberBalances => 'Member balances';

  @override
  String get settlementIsOwed => 'Should receive';

  @override
  String get settlementOwes => 'Needs to pay';

  @override
  String get settlementBalanced => 'Balanced';

  @override
  String get settlementLimitations =>
      'Preview only. No payment is made or recorded. Settlement-currency figures are approximate and based on the group\'s current rate. Common Fund contributions, spending and refunds are excluded; review those separately before closing a trip.';

  @override
  String get repaymentConfirmReceived => 'Confirm money received';

  @override
  String get repaymentConfirmWarning =>
      'Only confirm after the money is actually received. This does not initiate PayNow or a bank transfer. You can record a partial payment.';

  @override
  String get repaymentNote => 'Payment note (optional)';

  @override
  String get repaymentNoteHint => 'e.g. PayNow received';

  @override
  String get repaymentHistory => 'Confirmed repayments';

  @override
  String get repaymentNoRecords => 'No repayments have been confirmed yet.';

  @override
  String get repaymentReceivedRecorded => 'Received and recorded';

  @override
  String get repaymentLimitations =>
      'Only the recipient can confirm money received. Recorded repayments reduce outstanding personal debts, not Common Fund balances. No payment is transferred or verified by a bank. Mistaken confirmations cannot yet be reversed; check carefully.';

  @override
  String get payNowDetails => 'My PayNow details';

  @override
  String get payNowPrivacyWarning =>
      'Optional: save your PayNow-linked Singapore mobile number for this group. Every member of this group can view the number. Never enter OTPs, bank logins or account credentials.';

  @override
  String get payNowMobile => 'PayNow mobile number';

  @override
  String get payNowMobileHint => 'e.g. 91234567';

  @override
  String get payNowInvalid =>
      'Enter a valid Singapore mobile (8 digits, starting with 8 or 9).';

  @override
  String get payNowRemoveHint =>
      'Leave the field empty and save to remove your PayNow number from this group.';

  @override
  String get payNowRequestTo => 'Request for';

  @override
  String get payNowRecipient => 'Pay recipient';

  @override
  String get payNowAmountDue => 'Outstanding amount';

  @override
  String get payNowVerifyRecipient =>
      'Verify the PayNow recipient name in your banking app before paying.';

  @override
  String get payNowNoDetailsShared =>
      'Ask the recipient for their preferred payment details.';

  @override
  String get payNowNotPayment =>
      'This is a payment request only. SplitLui does not send money or confirm a transfer.';

  @override
  String get payNowCopied => 'PayNow number copied';

  @override
  String get payNowCopyNumber => 'Copy PayNow number';

  @override
  String get payNowShareRequest => 'Share payment request';

  @override
  String get payNowEstimatedSgd =>
      'Approximate SGD equivalent (confirm rate before payment)';

  @override
  String get payNowAgreeSgd =>
      'PayNow transfers in SGD. Agree the SGD amount with the recipient before paying.';
}
