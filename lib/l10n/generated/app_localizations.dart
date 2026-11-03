import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart' as intl;

import 'app_localizations_en.dart';
import 'app_localizations_zh.dart';

// ignore_for_file: type=lint

/// Callers can lookup localized strings with an instance of AppLocalizations
/// returned by `AppLocalizations.of(context)`.
///
/// Applications need to include `AppLocalizations.delegate()` in their app's
/// `localizationDelegates` list, and the locales they support in the app's
/// `supportedLocales` list. For example:
///
/// ```dart
/// import 'generated/app_localizations.dart';
///
/// return MaterialApp(
///   localizationsDelegates: AppLocalizations.localizationsDelegates,
///   supportedLocales: AppLocalizations.supportedLocales,
///   home: MyApplicationHome(),
/// );
/// ```
///
/// ## Update pubspec.yaml
///
/// Please make sure to update your pubspec.yaml to include the following
/// packages:
///
/// ```yaml
/// dependencies:
///   # Internationalization support.
///   flutter_localizations:
///     sdk: flutter
///   intl: any # Use the pinned version from flutter_localizations
///
///   # Rest of dependencies
/// ```
///
/// ## iOS Applications
///
/// iOS applications define key application metadata, including supported
/// locales, in an Info.plist file that is built into the application bundle.
/// To configure the locales supported by your app, you’ll need to edit this
/// file.
///
/// First, open your project’s ios/Runner.xcworkspace Xcode workspace file.
/// Then, in the Project Navigator, open the Info.plist file under the Runner
/// project’s Runner folder.
///
/// Next, select the Information Property List item, select Add Item from the
/// Editor menu, then select Localizations from the pop-up menu.
///
/// Select and expand the newly-created Localizations item then, for each
/// locale your application supports, add a new item and select the locale
/// you wish to add from the pop-up menu in the Value field. This list should
/// be consistent with the languages listed in the AppLocalizations.supportedLocales
/// property.
abstract class AppLocalizations {
  AppLocalizations(String locale)
      : localeName = intl.Intl.canonicalizedLocale(locale.toString());

  final String localeName;

  static AppLocalizations? of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations);
  }

  static const LocalizationsDelegate<AppLocalizations> delegate =
      _AppLocalizationsDelegate();

  /// A list of this localizations delegate along with the default localizations
  /// delegates.
  ///
  /// Returns a list of localizations delegates containing this delegate along with
  /// GlobalMaterialLocalizations.delegate, GlobalCupertinoLocalizations.delegate,
  /// and GlobalWidgetsLocalizations.delegate.
  ///
  /// Additional delegates can be added by appending to this list in
  /// MaterialApp. This list does not have to be used at all if a custom list
  /// of delegates is preferred or required.
  static const List<LocalizationsDelegate<dynamic>> localizationsDelegates =
      <LocalizationsDelegate<dynamic>>[
    delegate,
    GlobalMaterialLocalizations.delegate,
    GlobalCupertinoLocalizations.delegate,
    GlobalWidgetsLocalizations.delegate,
  ];

  /// A list of this localizations delegate's supported locales.
  static const List<Locale> supportedLocales = <Locale>[
    Locale('en'),
    Locale('zh')
  ];

  /// No description provided for @hello.
  ///
  /// In en, this message translates to:
  /// **'Your moments, together.'**
  String get hello;

  /// No description provided for @subtitle.
  ///
  /// In en, this message translates to:
  /// **'Plan, share and settle with ease.'**
  String get subtitle;

  /// No description provided for @groups.
  ///
  /// In en, this message translates to:
  /// **'Your groups'**
  String get groups;

  /// No description provided for @newGroup.
  ///
  /// In en, this message translates to:
  /// **'Create group'**
  String get newGroup;

  /// No description provided for @empty.
  ///
  /// In en, this message translates to:
  /// **'Your next adventure starts here!'**
  String get empty;

  /// No description provided for @settings.
  ///
  /// In en, this message translates to:
  /// **'Settings'**
  String get settings;

  /// No description provided for @theme.
  ///
  /// In en, this message translates to:
  /// **'Appearance'**
  String get theme;

  /// No description provided for @language.
  ///
  /// In en, this message translates to:
  /// **'Language'**
  String get language;

  /// No description provided for @system.
  ///
  /// In en, this message translates to:
  /// **'System'**
  String get system;

  /// No description provided for @light.
  ///
  /// In en, this message translates to:
  /// **'Light'**
  String get light;

  /// No description provided for @dark.
  ///
  /// In en, this message translates to:
  /// **'Dark'**
  String get dark;

  /// No description provided for @name.
  ///
  /// In en, this message translates to:
  /// **'Group name'**
  String get name;

  /// No description provided for @travel.
  ///
  /// In en, this message translates to:
  /// **'Travel'**
  String get travel;

  /// No description provided for @hangout.
  ///
  /// In en, this message translates to:
  /// **'Hangout'**
  String get hangout;

  /// No description provided for @spending.
  ///
  /// In en, this message translates to:
  /// **'Spending currency'**
  String get spending;

  /// No description provided for @settlement.
  ///
  /// In en, this message translates to:
  /// **'Settlement currency'**
  String get settlement;

  /// No description provided for @rate.
  ///
  /// In en, this message translates to:
  /// **'Spending currency per 1 settlement currency'**
  String get rate;

  /// No description provided for @budget.
  ///
  /// In en, this message translates to:
  /// **'Budget (optional, spending currency)'**
  String get budget;

  /// No description provided for @create.
  ///
  /// In en, this message translates to:
  /// **'Create group'**
  String get create;

  /// No description provided for @required.
  ///
  /// In en, this message translates to:
  /// **'Please enter a group name'**
  String get required;

  /// No description provided for @invalid.
  ///
  /// In en, this message translates to:
  /// **'Please enter a valid number'**
  String get invalid;

  /// No description provided for @expenses.
  ///
  /// In en, this message translates to:
  /// **'Expenses'**
  String get expenses;

  /// No description provided for @fund.
  ///
  /// In en, this message translates to:
  /// **'Common fund'**
  String get fund;

  /// No description provided for @members.
  ///
  /// In en, this message translates to:
  /// **'Members'**
  String get members;

  /// No description provided for @soon.
  ///
  /// In en, this message translates to:
  /// **'Coming in the next feature!'**
  String get soon;

  /// No description provided for @local.
  ///
  /// In en, this message translates to:
  /// **'Saved on this device. Group invitations and sync are not available yet.'**
  String get local;

  /// No description provided for @rateHint.
  ///
  /// In en, this message translates to:
  /// **'Example: 1 SGD = 115 JPY → enter 115'**
  String get rateHint;

  /// No description provided for @version.
  ///
  /// In en, this message translates to:
  /// **'SplitLui 0.1.0'**
  String get version;

  /// No description provided for @cloudGroups.
  ///
  /// In en, this message translates to:
  /// **'Shared groups'**
  String get cloudGroups;

  /// No description provided for @cloudTitle.
  ///
  /// In en, this message translates to:
  /// **'Shared groups'**
  String get cloudTitle;

  /// No description provided for @cloudSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Invite friends and plan your adventures together.'**
  String get cloudSubtitle;

  /// No description provided for @cloudJoin.
  ///
  /// In en, this message translates to:
  /// **'Join group'**
  String get cloudJoin;

  /// No description provided for @cloudRefresh.
  ///
  /// In en, this message translates to:
  /// **'Refresh'**
  String get cloudRefresh;

  /// No description provided for @cloudNickname.
  ///
  /// In en, this message translates to:
  /// **'What should friends call you?'**
  String get cloudNickname;

  /// No description provided for @cloudNicknameHint.
  ///
  /// In en, this message translates to:
  /// **'Your nickname'**
  String get cloudNicknameHint;

  /// No description provided for @cloudCancel.
  ///
  /// In en, this message translates to:
  /// **'Cancel'**
  String get cloudCancel;

  /// No description provided for @cloudContinue.
  ///
  /// In en, this message translates to:
  /// **'Continue'**
  String get cloudContinue;

  /// No description provided for @cloudInviteHint.
  ///
  /// In en, this message translates to:
  /// **'Paste an invitation code'**
  String get cloudInviteHint;

  /// No description provided for @cloudInviteCode.
  ///
  /// In en, this message translates to:
  /// **'Invitation code'**
  String get cloudInviteCode;

  /// No description provided for @cloudCopyInvite.
  ///
  /// In en, this message translates to:
  /// **'Copy invite code'**
  String get cloudCopyInvite;

  /// No description provided for @cloudCopied.
  ///
  /// In en, this message translates to:
  /// **'Invitation code copied'**
  String get cloudCopied;

  /// No description provided for @cloudResetInvite.
  ///
  /// In en, this message translates to:
  /// **'Reset invitation code'**
  String get cloudResetInvite;

  /// No description provided for @cloudOwner.
  ///
  /// In en, this message translates to:
  /// **'Organiser'**
  String get cloudOwner;

  /// No description provided for @cloudEmpty.
  ///
  /// In en, this message translates to:
  /// **'No shared groups yet. Start one or join a friend\'s group!'**
  String get cloudEmpty;

  /// No description provided for @cloudIdentityWarning.
  ///
  /// In en, this message translates to:
  /// **'Guest accounts are device-bound. Clearing app data may lose access. Account recovery will be added later.'**
  String get cloudIdentityWarning;

  /// No description provided for @cloudExpenseNext.
  ///
  /// In en, this message translates to:
  /// **'Expenses, common funds and automatic settlements are coming next.'**
  String get cloudExpenseNext;

  /// No description provided for @cloudNotConfigured.
  ///
  /// In en, this message translates to:
  /// **'Shared groups need Supabase configuration before they can be used.'**
  String get cloudNotConfigured;

  /// No description provided for @nameHint.
  ///
  /// In en, this message translates to:
  /// **'e.g. Weekend in Tokyo'**
  String get nameHint;

  /// No description provided for @settingsIntro.
  ///
  /// In en, this message translates to:
  /// **'Personalise your SplitLui experience.'**
  String get settingsIntro;

  /// No description provided for @appearanceHint.
  ///
  /// In en, this message translates to:
  /// **'Choose how SplitLui looks on your device.'**
  String get appearanceHint;

  /// No description provided for @languageHint.
  ///
  /// In en, this message translates to:
  /// **'Select your preferred app language.'**
  String get languageHint;

  /// No description provided for @addExpense.
  ///
  /// In en, this message translates to:
  /// **'Add expense'**
  String get addExpense;

  /// No description provided for @expenseTitle.
  ///
  /// In en, this message translates to:
  /// **'Expense name'**
  String get expenseTitle;

  /// No description provided for @expenseTitleHint.
  ///
  /// In en, this message translates to:
  /// **'e.g. Dinner'**
  String get expenseTitleHint;

  /// No description provided for @expenseAmount.
  ///
  /// In en, this message translates to:
  /// **'Amount'**
  String get expenseAmount;

  /// No description provided for @paidBy.
  ///
  /// In en, this message translates to:
  /// **'Paid by'**
  String get paidBy;

  /// No description provided for @splitBetween.
  ///
  /// In en, this message translates to:
  /// **'Split between'**
  String get splitBetween;

  /// No description provided for @equalSplitOnly.
  ///
  /// In en, this message translates to:
  /// **'Equal split between selected members. Amounts are rounded to the nearest cent.'**
  String get equalSplitOnly;

  /// No description provided for @selectParticipants.
  ///
  /// In en, this message translates to:
  /// **'Select at least one person to split with.'**
  String get selectParticipants;

  /// No description provided for @saveExpense.
  ///
  /// In en, this message translates to:
  /// **'Save expense'**
  String get saveExpense;

  /// No description provided for @noExpenses.
  ///
  /// In en, this message translates to:
  /// **'No expenses yet. Add the first expense to get started.'**
  String get noExpenses;

  /// No description provided for @expenseEntryHint.
  ///
  /// In en, this message translates to:
  /// **'Add and review shared expenses'**
  String get expenseEntryHint;

  /// No description provided for @fundEntryHint.
  ///
  /// In en, this message translates to:
  /// **'Manage pooled contributions and spending'**
  String get fundEntryHint;

  /// No description provided for @fundBalance.
  ///
  /// In en, this message translates to:
  /// **'Available fund balance'**
  String get fundBalance;

  /// No description provided for @fundLowBalance.
  ///
  /// In en, this message translates to:
  /// **'Fund is running low. Consider topping up.'**
  String get fundLowBalance;

  /// No description provided for @fundThreshold.
  ///
  /// In en, this message translates to:
  /// **'Low-balance alert'**
  String get fundThreshold;

  /// No description provided for @fundThresholdHint.
  ///
  /// In en, this message translates to:
  /// **'Set an alert threshold in the spending currency. Enter 0 to turn off the warning.'**
  String get fundThresholdHint;

  /// No description provided for @fundManualNotice.
  ///
  /// In en, this message translates to:
  /// **'Manual ledger only — record contributions after receiving the money. No bank transfers happen in this app.'**
  String get fundManualNotice;

  /// No description provided for @fundAddContribution.
  ///
  /// In en, this message translates to:
  /// **'Record contribution'**
  String get fundAddContribution;

  /// No description provided for @fundPayExpense.
  ///
  /// In en, this message translates to:
  /// **'Pay from common fund'**
  String get fundPayExpense;

  /// No description provided for @fundHistory.
  ///
  /// In en, this message translates to:
  /// **'Fund activity'**
  String get fundHistory;

  /// No description provided for @fundNoEntries.
  ///
  /// In en, this message translates to:
  /// **'No fund transactions yet.'**
  String get fundNoEntries;

  /// No description provided for @fundContributedBy.
  ///
  /// In en, this message translates to:
  /// **'Contributed by'**
  String get fundContributedBy;

  /// No description provided for @fundPaidFromPool.
  ///
  /// In en, this message translates to:
  /// **'Paid using group funds'**
  String get fundPaidFromPool;

  /// No description provided for @fundContributionNote.
  ///
  /// In en, this message translates to:
  /// **'Contribution note'**
  String get fundContributionNote;

  /// No description provided for @fundContributionHint.
  ///
  /// In en, this message translates to:
  /// **'e.g. Cash collected'**
  String get fundContributionHint;

  /// No description provided for @fundContributor.
  ///
  /// In en, this message translates to:
  /// **'Contributed by'**
  String get fundContributor;

  /// No description provided for @fundRecordActual.
  ///
  /// In en, this message translates to:
  /// **'Only record money actually received, not an amount someone promised to pay.'**
  String get fundRecordActual;

  /// No description provided for @fundNoDoubleSplit.
  ///
  /// In en, this message translates to:
  /// **'This payment uses common funds and will not create an individual split expense.'**
  String get fundNoDoubleSplit;

  /// No description provided for @localOnlyFeatures.
  ///
  /// In en, this message translates to:
  /// **'This group is saved only on this device. Expenses, Common Fund and member management work in Shared Groups, where everyone can join.'**
  String get localOnlyFeatures;

  /// No description provided for @openSharedGroups.
  ///
  /// In en, this message translates to:
  /// **'Open shared groups'**
  String get openSharedGroups;

  /// No description provided for @createLocalGroup.
  ///
  /// In en, this message translates to:
  /// **'Create local group'**
  String get createLocalGroup;

  /// No description provided for @editGroup.
  ///
  /// In en, this message translates to:
  /// **'Edit group'**
  String get editGroup;

  /// No description provided for @saveChanges.
  ///
  /// In en, this message translates to:
  /// **'Save changes'**
  String get saveChanges;

  /// No description provided for @groupUpdated.
  ///
  /// In en, this message translates to:
  /// **'Group updated'**
  String get groupUpdated;

  /// No description provided for @deleteGroup.
  ///
  /// In en, this message translates to:
  /// **'Delete group'**
  String get deleteGroup;

  /// No description provided for @typeGroupName.
  ///
  /// In en, this message translates to:
  /// **'Type the group name to permanently delete this group and all its expenses, funds and members'**
  String get typeGroupName;

  /// No description provided for @olderDeviceGroups.
  ///
  /// In en, this message translates to:
  /// **'Older groups on this device'**
  String get olderDeviceGroups;

  /// No description provided for @olderDeviceGroupsHint.
  ///
  /// In en, this message translates to:
  /// **'These were created before group syncing. Move them online to use Expenses and Common Fund.'**
  String get olderDeviceGroupsHint;

  /// No description provided for @moveToGroups.
  ///
  /// In en, this message translates to:
  /// **'Move to Groups'**
  String get moveToGroups;

  /// No description provided for @deleteLocalGroup.
  ///
  /// In en, this message translates to:
  /// **'Delete device-only group?'**
  String get deleteLocalGroup;

  /// No description provided for @deleteLocalWarning.
  ///
  /// In en, this message translates to:
  /// **'This removes the group from this phone. It cannot be recovered.'**
  String get deleteLocalWarning;

  /// No description provided for @expenseCurrency.
  ///
  /// In en, this message translates to:
  /// **'Expense currency'**
  String get expenseCurrency;

  /// No description provided for @expenseRateToGroup.
  ///
  /// In en, this message translates to:
  /// **'Exchange rate to group currency'**
  String get expenseRateToGroup;

  /// No description provided for @groupEquivalent.
  ///
  /// In en, this message translates to:
  /// **'Equivalent in group currency'**
  String get groupEquivalent;

  /// No description provided for @expenseConversionHint.
  ///
  /// In en, this message translates to:
  /// **'The exchange rate is saved with this expense. Original and converted shares are both recorded; conversions are rounded to two decimals.'**
  String get expenseConversionHint;

  /// No description provided for @settlementPreview.
  ///
  /// In en, this message translates to:
  /// **'Who owes whom'**
  String get settlementPreview;

  /// No description provided for @settlementEntryHint.
  ///
  /// In en, this message translates to:
  /// **'Review balances and suggested repayments'**
  String get settlementEntryHint;

  /// No description provided for @settlementExplanation.
  ///
  /// In en, this message translates to:
  /// **'See each member\'s net balance from shared expenses, converted into the group\'s spending currency.'**
  String get settlementExplanation;

  /// No description provided for @settlementRateNote.
  ///
  /// In en, this message translates to:
  /// **'Estimated conversion rate'**
  String get settlementRateNote;

  /// No description provided for @settlementTotalExpenses.
  ///
  /// In en, this message translates to:
  /// **'Total shared expenses'**
  String get settlementTotalExpenses;

  /// No description provided for @settlementSuggestedTransfers.
  ///
  /// In en, this message translates to:
  /// **'Suggested repayments'**
  String get settlementSuggestedTransfers;

  /// No description provided for @settlementAllEven.
  ///
  /// In en, this message translates to:
  /// **'Everyone is settled up so far.'**
  String get settlementAllEven;

  /// No description provided for @settlementMemberBalances.
  ///
  /// In en, this message translates to:
  /// **'Member balances'**
  String get settlementMemberBalances;

  /// No description provided for @settlementIsOwed.
  ///
  /// In en, this message translates to:
  /// **'Should receive'**
  String get settlementIsOwed;

  /// No description provided for @settlementOwes.
  ///
  /// In en, this message translates to:
  /// **'Needs to pay'**
  String get settlementOwes;

  /// No description provided for @settlementBalanced.
  ///
  /// In en, this message translates to:
  /// **'Balanced'**
  String get settlementBalanced;

  /// No description provided for @settlementLimitations.
  ///
  /// In en, this message translates to:
  /// **'Preview only. No payment is made or recorded. Settlement-currency figures are approximate and based on the group\'s current rate. Common Fund contributions, spending and refunds are excluded; review those separately before closing a trip.'**
  String get settlementLimitations;

  /// No description provided for @repaymentConfirmReceived.
  ///
  /// In en, this message translates to:
  /// **'Confirm money received'**
  String get repaymentConfirmReceived;

  /// No description provided for @repaymentConfirmWarning.
  ///
  /// In en, this message translates to:
  /// **'Only confirm after the money is actually received. This does not initiate PayNow or a bank transfer. You can record a partial payment.'**
  String get repaymentConfirmWarning;

  /// No description provided for @repaymentNote.
  ///
  /// In en, this message translates to:
  /// **'Payment note (optional)'**
  String get repaymentNote;

  /// No description provided for @repaymentNoteHint.
  ///
  /// In en, this message translates to:
  /// **'e.g. PayNow received'**
  String get repaymentNoteHint;

  /// No description provided for @repaymentHistory.
  ///
  /// In en, this message translates to:
  /// **'Confirmed repayments'**
  String get repaymentHistory;

  /// No description provided for @repaymentNoRecords.
  ///
  /// In en, this message translates to:
  /// **'No repayments have been confirmed yet.'**
  String get repaymentNoRecords;

  /// No description provided for @repaymentReceivedRecorded.
  ///
  /// In en, this message translates to:
  /// **'Received and recorded'**
  String get repaymentReceivedRecorded;

  /// No description provided for @repaymentLimitations.
  ///
  /// In en, this message translates to:
  /// **'Only the recipient can confirm money received. Recorded repayments reduce outstanding personal debts, not Common Fund balances. No payment is transferred or verified by a bank. Mistaken confirmations cannot yet be reversed; check carefully.'**
  String get repaymentLimitations;

  /// No description provided for @payNowDetails.
  ///
  /// In en, this message translates to:
  /// **'My PayNow details'**
  String get payNowDetails;

  /// No description provided for @payNowPrivacyWarning.
  ///
  /// In en, this message translates to:
  /// **'Optional: save your PayNow-linked Singapore mobile number for this group. Every member of this group can view the number. Never enter OTPs, bank logins or account credentials.'**
  String get payNowPrivacyWarning;

  /// No description provided for @payNowMobile.
  ///
  /// In en, this message translates to:
  /// **'PayNow mobile number'**
  String get payNowMobile;

  /// No description provided for @payNowMobileHint.
  ///
  /// In en, this message translates to:
  /// **'e.g. 91234567'**
  String get payNowMobileHint;

  /// No description provided for @payNowInvalid.
  ///
  /// In en, this message translates to:
  /// **'Enter a valid Singapore mobile (8 digits, starting with 8 or 9).'**
  String get payNowInvalid;

  /// No description provided for @payNowRemoveHint.
  ///
  /// In en, this message translates to:
  /// **'Leave the field empty and save to remove your PayNow number from this group.'**
  String get payNowRemoveHint;

  /// No description provided for @payNowRequestTo.
  ///
  /// In en, this message translates to:
  /// **'Request for'**
  String get payNowRequestTo;

  /// No description provided for @payNowRecipient.
  ///
  /// In en, this message translates to:
  /// **'Pay recipient'**
  String get payNowRecipient;

  /// No description provided for @payNowAmountDue.
  ///
  /// In en, this message translates to:
  /// **'Outstanding amount'**
  String get payNowAmountDue;

  /// No description provided for @payNowVerifyRecipient.
  ///
  /// In en, this message translates to:
  /// **'Verify the PayNow recipient name in your banking app before paying.'**
  String get payNowVerifyRecipient;

  /// No description provided for @payNowNoDetailsShared.
  ///
  /// In en, this message translates to:
  /// **'Ask the recipient for their preferred payment details.'**
  String get payNowNoDetailsShared;

  /// No description provided for @payNowNotPayment.
  ///
  /// In en, this message translates to:
  /// **'This is a payment request only. SplitLui does not send money or confirm a transfer.'**
  String get payNowNotPayment;

  /// No description provided for @payNowCopied.
  ///
  /// In en, this message translates to:
  /// **'PayNow number copied'**
  String get payNowCopied;

  /// No description provided for @payNowCopyNumber.
  ///
  /// In en, this message translates to:
  /// **'Copy PayNow number'**
  String get payNowCopyNumber;

  /// No description provided for @payNowShareRequest.
  ///
  /// In en, this message translates to:
  /// **'Share payment request'**
  String get payNowShareRequest;

  /// No description provided for @payNowEstimatedSgd.
  ///
  /// In en, this message translates to:
  /// **'Approximate SGD equivalent (confirm rate before payment)'**
  String get payNowEstimatedSgd;

  /// No description provided for @payNowAgreeSgd.
  ///
  /// In en, this message translates to:
  /// **'PayNow transfers in SGD. Agree the SGD amount with the recipient before paying.'**
  String get payNowAgreeSgd;
}

class _AppLocalizationsDelegate
    extends LocalizationsDelegate<AppLocalizations> {
  const _AppLocalizationsDelegate();

  @override
  Future<AppLocalizations> load(Locale locale) {
    return SynchronousFuture<AppLocalizations>(lookupAppLocalizations(locale));
  }

  @override
  bool isSupported(Locale locale) =>
      <String>['en', 'zh'].contains(locale.languageCode);

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}

AppLocalizations lookupAppLocalizations(Locale locale) {
  // Lookup logic when only language code is specified.
  switch (locale.languageCode) {
    case 'en':
      return AppLocalizationsEn();
    case 'zh':
      return AppLocalizationsZh();
  }

  throw FlutterError(
      'AppLocalizations.delegate failed to load unsupported locale "$locale". This is likely '
      'an issue with the localizations generation tool. Please file an issue '
      'on GitHub with a reproducible sample app and the gen-l10n configuration '
      'that was used.');
}
