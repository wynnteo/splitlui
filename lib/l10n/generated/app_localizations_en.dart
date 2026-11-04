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
      'Only the recipient can confirm or reverse a repayment. Recorded repayments reduce outstanding personal debts, not Common Fund balances. No payment is transferred or verified by a bank. Reversals restore debt and remain visible in the audit history.';

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

  @override
  String get inviteShareHeading => 'You\'re invited to join my SplitLui group!';

  @override
  String get inviteShareInstructions =>
      'Install/open SplitLui, tap Join Group, then paste this code (or the full message).';

  @override
  String get inviteInstallApp => 'Install SplitLui';

  @override
  String get inviteShareButton => 'Share invite';

  @override
  String get inviteShareHint =>
      'Share this code privately with people you trust. Anyone with it can join until the organiser resets it.';

  @override
  String get inviteInvalidCode =>
      'Paste a valid invitation code or the full invitation message.';

  @override
  String get expenseFundAvailable => 'Common Fund available';

  @override
  String get expenseFundInsufficient =>
      'Not enough Common Fund balance. Please top up the fund or change the payer.';

  @override
  String get expenseFundNoSplit =>
      'Paid from Common Fund. No individual shares or personal repayment will be created.';

  @override
  String get settlementDisplayCurrency => 'Show repayments in';

  @override
  String get settlementOriginalBalance => 'Original balance';

  @override
  String get settlementEstimateDisclaimer =>
      'Converted amounts are estimates using the group\'s agreed exchange rate; confirm the amount and currency before paying.';

  @override
  String get settlementLedgerNote =>
      'Repayment records are still tracked in the group\'s spending currency';

  @override
  String get settlementConvertedEstimate => 'Converted estimate';

  @override
  String get payNowReceivesFrom => 'To receive';

  @override
  String get payNowFromMember => 'From';

  @override
  String get expenseOriginalTotal => 'Paid in this currency';

  @override
  String get expenseCombinedTotal => 'Combined total';

  @override
  String get expenseCombinedRateNote =>
      'Original payments stay in their own currency. The combined estimate converts the trip spending currency using the registered group exchange rate. Shared member-paid expenses only; Common Fund purchases are excluded.';

  @override
  String get expenseCombinedRateMixed =>
      'Original payments stay in their own currency. The trip spending currency uses the registered group rate; any other currencies use the saved expense conversions. Shared member-paid expenses only; Common Fund purchases are excluded.';

  @override
  String get repaymentDefaultCurrency => 'Default repayment currency';

  @override
  String get repaymentDefaultCurrencyHint =>
      'Choose your preferred repayment currency. You can change it for each repayment; exchange rates outside the group\'s currency pair are entered manually.';

  @override
  String get repaymentPaidCurrency => 'Currency received';

  @override
  String get repaymentPaidAmount => 'Amount actually received';

  @override
  String get repaymentConversionRate =>
      'Exchange rate to group spending currency';

  @override
  String get repaymentRateHint =>
      'Record the currency and amount actually received. For a different currency, enter the agreed rate; no live exchange rate is assumed.';

  @override
  String get repaymentLedgerEquivalent => 'Amount credited against debt';

  @override
  String get repaymentOutstanding => 'Outstanding balance';

  @override
  String get repaymentExceedsOutstanding =>
      'The converted repayment exceeds the outstanding balance. Record a smaller amount.';

  @override
  String get repaymentUndo => 'Undo confirmation';

  @override
  String get repaymentUndoWarning =>
      'Only undo if the payment was recorded incorrectly. This restores the debt and keeps a permanent reversal record; it does not reverse any bank transfer.';

  @override
  String get repaymentReversalReason => 'Reason for reversal';

  @override
  String get repaymentReversalReasonHint => 'e.g. Wrong amount recorded';

  @override
  String get repaymentReversalReasonInvalid =>
      'Enter a reason (at least 3 characters).';

  @override
  String get repaymentUndoConfirm => 'Confirm reversal';

  @override
  String get repaymentReversed => 'Reversed — debt restored';

  @override
  String get receiptAttachment => 'Receipt (optional)';

  @override
  String get receiptCamera => 'Take photo';

  @override
  String get receiptGallery => 'Choose photo';

  @override
  String get receiptRemove => 'Remove photo';

  @override
  String get receiptReviewHint =>
      'Text recognition is only a suggestion. Check the amount and currency before saving.';

  @override
  String get receiptUploadFailed =>
      'Expense was saved, but the receipt photo could not be uploaded. Please do not save this expense again.';

  @override
  String get editExpense => 'Edit expense';

  @override
  String get deleteExpense => 'Delete expense';

  @override
  String get deleteExpenseWarning =>
      'Delete this expense and its member shares? Outstanding balances will be recalculated. Expenses cannot be changed after confirmed repayments.';

  @override
  String get expenseReceiptCleanupWarning =>
      'Expense deleted, but its stored receipt photo could not be removed. Please contact support for cleanup.';

  @override
  String get expenseReceiptDate => 'Receipt date';

  @override
  String get expenseChooseDate => 'Choose receipt date';

  @override
  String get offlinePendingHeading => 'Saved offline · Waiting to sync';

  @override
  String get offlineRetry => 'Sync now';

  @override
  String get offlinePending => 'Saved on this device · Not yet synced';

  @override
  String get offlineNeedsReview =>
      'Sync needs attention · Retry when connected';

  @override
  String get offlineReceiptPending => 'Expense synced · Receipt upload pending';

  @override
  String get offlineReadOnlySnapshot =>
      'Showing saved expenses from this device. Balances may be outdated until connected.';

  @override
  String get offlineReadOnlyDetails =>
      'Offline snapshot. Member splits, receipt downloads and editing require an internet connection. Amounts may have changed on another device.';

  @override
  String get offlinePendingDetails =>
      'This expense has been stored on this device. It is not included in shared balances until the server confirms it. Do not enter it again while waiting for sync.';

  @override
  String get fundPurchaseDeleteWarning =>
      'Delete this Common Fund purchase? Its full amount will be restored to the fund balance. This correction will be kept in the audit history.';

  @override
  String get fundPurchaseAuthorOnly =>
      'Only the member who recorded this Common Fund purchase can edit or delete it while online.';

  @override
  String get fundContributionTargets => 'Contribution targets';

  @override
  String get fundTargetTotal => 'Target';

  @override
  String get fundTotalReceived => 'Received';

  @override
  String get fundOutstandingToCollect => 'Still to collect';

  @override
  String get fundTargetsNotBalance =>
      'Targets and top-up requests are plans only. They do not increase the available Common Fund balance.';

  @override
  String get fundTargetSet => 'Set target';

  @override
  String get fundTopUpRequest => 'Request top-up';

  @override
  String get fundRefundConfirm => 'Confirm refund received';

  @override
  String get fundRefundNote => 'Refund reason and payment method';

  @override
  String get fundRefundWarning =>
      'Only confirm after the recipient has actually received the refund. This permanently reduces the Common Fund balance and records an audit entry.';

  @override
  String get fundRefunded => 'Refunded to members';

  @override
  String get fundTopUpRequests => 'Top-up requests';

  @override
  String get fundNoRequests => 'No requests yet.';

  @override
  String get fundTopUpPending => 'Requested · not a confirmed contribution';

  @override
  String get fundTopUpCancelled => 'Cancelled';

  @override
  String get fundCancelRequest => 'Cancel request';

  @override
  String get fundClosingPreview => 'Fund closing preview';

  @override
  String get fundTotalSpent => 'Fund purchases';

  @override
  String get fundClosingNotFinal =>
      'Reconciliation preview only. This does not close the fund or pay anyone. Resolve outstanding contributions and confirm agreed refunds before closing the trip.';

  @override
  String get fundReconciliationMismatch =>
      'Warning: fund balance does not reconcile with received contributions, purchases and confirmed refunds.';

  @override
  String get fundAdvancedLoadError =>
      'Could not load fund targets and refunds. Check your connection and Supabase migration.';

  @override
  String get fundRefundHistory => 'Confirmed refunds';

  @override
  String get fundNoRefunds => 'No refunds confirmed yet.';

  @override
  String get repaymentActualReceivedHint =>
      'Enter the amount you actually received. A rounded or partial payment is fine.';

  @override
  String get settlementMoreDetails => 'More details';

  @override
  String get repaymentSettleFull => 'This payment settles the full amount';

  @override
  String get tripReportTitle => 'Trip closing report';

  @override
  String get tripReportEntryHint =>
      'Share a summary of expenses, Common Fund and repayments';

  @override
  String get tripReportIntro =>
      'Create a PDF snapshot of your trip records. Nothing is closed or paid automatically.';

  @override
  String get tripReportIncludes => 'What\'s included';

  @override
  String get tripReportContents =>
      'Original-currency spending, combined estimates, remaining repayments, Common Fund contributions, refunds, outstanding targets and reconciliation checks.';

  @override
  String get tripReportIncludeReceipts => 'Include receipt photos';

  @override
  String get tripReportReceiptNotice =>
      'Optional · Up to 8 receipts. Anyone you send the PDF to can keep the images.';

  @override
  String get tripReportWarning =>
      'Requires internet and the latest synced records. The PDF is a snapshot, not confirmation of payment or formal fund closure. Reports support English and Simplified Chinese.';

  @override
  String get tripReportGenerating => 'Preparing PDF…';

  @override
  String get tripReportSharePdf => 'Create and share PDF';

  @override
  String get offlineSkipReceipt => 'Skip photo';

  @override
  String get offlineSkipReceiptWarning =>
      'This expense is already saved for the group. Stop trying to upload its photo? This will delete the local photo copy, but will NOT remove or change the expense.';

  @override
  String get offlineExpenseAlreadySaved =>
      'The expense is confirmed. Only its receipt photo is waiting to upload.';

  @override
  String get offlineSyncProblem => 'Sync details';

  @override
  String get offlineReceiptsHeading => 'Receipt photos waiting to upload';

  @override
  String get splitModeEqual => 'Equal';

  @override
  String get splitModeAmount => 'Amount';

  @override
  String get splitModePercent => 'Percent';

  @override
  String get splitModeShares => 'Shares';

  @override
  String get splitEditHint =>
      'Enter each person\'s amount, percentage or number of shares. The total must match the bill.';

  @override
  String get splitAllocationValid => 'Split total matches the bill';

  @override
  String get splitAllocationInvalid =>
      'Check the amount and split values. Exact amounts must match the bill; percentages must add to 100%.';

  @override
  String get receiptSuggestionsTitle => 'Detected on receipt';

  @override
  String get receiptSuggestionsSubtitle =>
      'Tap a suggestion to use it. Please check everything before saving.';

  @override
  String get receiptMultipleTotalsWarning =>
      'More than one possible total was found. Choose the amount on your receipt.';

  @override
  String get receiptNoTotalFound =>
      'No clear total found. Enter the amount manually.';

  @override
  String get receiptAmbiguousDateWarning =>
      'Date format might be day/month or month/day. Check before applying.';

  @override
  String get fundAddContributionShort => 'Add money';

  @override
  String get fundPayExpenseShort => 'Pay expense';

  @override
  String get fundManualNoticeShort =>
      'Record only money actually received or spent.';

  @override
  String get fundOpenRequests => 'open requests';

  @override
  String get fundRefundRecords => 'confirmed refunds';

  @override
  String get fundClosingNotFinalShort =>
      'Preview only — no money moves and this does not close the group.';

  @override
  String get groupManageMember => 'Manage member';

  @override
  String get groupRenameMember => 'Edit member name';

  @override
  String get groupMemberNicknameHint => 'Name shown in this group';

  @override
  String get groupRemoveMember => 'Remove member';

  @override
  String get groupRemoveMemberWarning =>
      'Remove this member from the group? They will lose access and the old invite code will be replaced. Members with financial activity cannot be removed; you can rename them instead.';
}
