// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Chinese (`zh`).
class AppLocalizationsZh extends AppLocalizations {
  AppLocalizationsZh([String locale = 'zh']) : super(locale);

  @override
  String get hello => '一起记录美好时光';

  @override
  String get subtitle => '一起规划、分账和结算，简单一点。';

  @override
  String get groups => '我的群组';

  @override
  String get newGroup => '创建群组';

  @override
  String get empty => '下一趟旅程从这里开始！';

  @override
  String get settings => '设置';

  @override
  String get theme => '外观';

  @override
  String get language => '语言';

  @override
  String get system => '跟随系统';

  @override
  String get light => '浅色';

  @override
  String get dark => '深色';

  @override
  String get name => '群组名称';

  @override
  String get travel => '旅行';

  @override
  String get hangout => '聚会';

  @override
  String get spending => '消费货币';

  @override
  String get settlement => '结算货币';

  @override
  String get rate => '每 1 单位结算货币可兑换多少消费货币';

  @override
  String get budget => '预算（选填，以消费货币计）';

  @override
  String get create => '创建群组';

  @override
  String get required => '请输入群组名称';

  @override
  String get invalid => '请输入有效数字';

  @override
  String get expenses => '开销';

  @override
  String get fund => '共同基金';

  @override
  String get members => '成员';

  @override
  String get soon => '下一个阶段推出！';

  @override
  String get local => '目前只保存在这台设备，邀请和实时同步尚未开放。';

  @override
  String get rateHint => '例如：1 SGD = 115 JPY → 输入 115';

  @override
  String get version => 'SplitLui 0.1.0';

  @override
  String get cloudGroups => '多人共享群组';

  @override
  String get cloudTitle => '多人共享群组';

  @override
  String get cloudSubtitle => '邀请朋友加入，一起规划旅程和开销。';

  @override
  String get cloudJoin => '加入群组';

  @override
  String get cloudRefresh => '刷新';

  @override
  String get cloudNickname => '朋友应该怎么称呼你？';

  @override
  String get cloudNicknameHint => '你的昵称';

  @override
  String get cloudCancel => '取消';

  @override
  String get cloudContinue => '继续';

  @override
  String get cloudInviteHint => '粘贴邀请码';

  @override
  String get cloudInviteCode => '邀请码';

  @override
  String get cloudCopyInvite => '复制邀请码';

  @override
  String get cloudCopied => '邀请码已复制';

  @override
  String get cloudResetInvite => '重置邀请码';

  @override
  String get cloudOwner => '组织者';

  @override
  String get cloudEmpty => '还没有共享群组，创建一个或加入朋友的群组吧！';

  @override
  String get cloudIdentityWarning =>
      '访客账号绑定当前设备。清除 App 数据可能失去群组访问权限，账号恢复将在之后加入。';

  @override
  String get cloudExpenseNext => '共同记账、公款管理和自动结算将在下一阶段加入。';

  @override
  String get cloudNotConfigured => '请先配置 Supabase 才能使用共享群组。';

  @override
  String get nameHint => '例如：东京周末游';

  @override
  String get settingsIntro => '调整 SplitLui 的使用偏好。';

  @override
  String get appearanceHint => '选择适合你的显示模式。';

  @override
  String get languageHint => '选择 App 的显示语言。';

  @override
  String get addExpense => '添加开销';

  @override
  String get expenseTitle => '开销名称';

  @override
  String get expenseTitleHint => '例如：晚餐';

  @override
  String get expenseAmount => '金额';

  @override
  String get paidBy => '付款人';

  @override
  String get splitBetween => '分摊成员';

  @override
  String get equalSplitOnly => '目前支持所选成员平均分摊，金额会精确分配到分。';

  @override
  String get selectParticipants => '请至少选择一位分摊成员。';

  @override
  String get saveExpense => '保存开销';

  @override
  String get noExpenses => '目前还没有开销。添加第一笔开销吧。';

  @override
  String get expenseEntryHint => '添加和查看共同开销';

  @override
  String get fundEntryHint => '记录共同基金的出资及支出';

  @override
  String get fundBalance => '共同基金余额';

  @override
  String get fundLowBalance => '共同基金余额偏低，可以考虑补款。';

  @override
  String get fundThreshold => '低余额提醒';

  @override
  String get fundThresholdHint => '以消费货币设置提醒金额；输入 0 即关闭提醒。';

  @override
  String get fundManualNotice => '目前仅提供手动记录。收到款项后才记录出资，App 不会自动转账。';

  @override
  String get fundAddContribution => '记录成员出资';

  @override
  String get fundPayExpense => '使用共同基金付款';

  @override
  String get fundHistory => '共同基金记录';

  @override
  String get fundNoEntries => '暂时没有共同基金交易记录。';

  @override
  String get fundContributedBy => '出资成员';

  @override
  String get fundPaidFromPool => '由共同基金支付';

  @override
  String get fundContributionNote => '出资备注';

  @override
  String get fundContributionHint => '例如：已收现金';

  @override
  String get fundContributor => '出资人';

  @override
  String get fundRecordActual => '请在实际收到款项后才记录，不要将口头承诺当作已出资。';

  @override
  String get fundNoDoubleSplit => '此费用从共同基金扣除，不会再分摊到个人账目。';

  @override
  String get localOnlyFeatures => '此群组只储存在当前设备。要使用多人记账、共同基金和成员管理，请进入「多人共享群组」。';

  @override
  String get openSharedGroups => '打开多人共享群组';

  @override
  String get createLocalGroup => '创建本地群组';

  @override
  String get editGroup => '编辑群组';

  @override
  String get saveChanges => '保存修改';

  @override
  String get groupUpdated => '群组已更新';

  @override
  String get deleteGroup => '删除群组';

  @override
  String get typeGroupName => '请输入群组名称以永久删除群组及所有开销、共同基金和成员资料';

  @override
  String get olderDeviceGroups => '旧版本地群组';

  @override
  String get olderDeviceGroupsHint => '这些群组是在启用云端同步前创建的。转移到线上后，才可以使用开销及共同基金功能。';

  @override
  String get moveToGroups => '转移到群组';

  @override
  String get deleteLocalGroup => '删除本地群组？';

  @override
  String get deleteLocalWarning => '此操作会从手机永久移除此群组，无法恢复。';

  @override
  String get expenseCurrency => '开销货币';

  @override
  String get expenseRateToGroup => '兑换成群组货币的汇率';

  @override
  String get groupEquivalent => '换算成群组货币';

  @override
  String get expenseConversionHint =>
      '系统会保存这笔开销所用的汇率，同时记录原币与换算金额；换算结果四舍五入至两位小数。';

  @override
  String get settlementPreview => '谁该还谁钱';

  @override
  String get settlementEntryHint => '查看各成员应收应付和建议转账';

  @override
  String get settlementExplanation => '根据个人垫付与分摊开销，计算各成员的净余额，并统一换算为群组消费货币。';

  @override
  String get settlementRateNote => '参考换算汇率';

  @override
  String get settlementTotalExpenses => '共同分摊开销总额';

  @override
  String get settlementSuggestedTransfers => '建议还款';

  @override
  String get settlementAllEven => '目前大家的个人开销已经结清。';

  @override
  String get settlementMemberBalances => '成员余额';

  @override
  String get settlementIsOwed => '应收款';

  @override
  String get settlementOwes => '应付款';

  @override
  String get settlementBalanced => '已平衡';

  @override
  String get settlementLimitations =>
      '仅供参考，不会实际转账或记录已付款。结算货币金额按照群组当前汇率估算。共同基金的出资、支出及退款暂不计入个人应收应付，结束旅程前请另行核对。';

  @override
  String get repaymentConfirmReceived => '确认已收到还款';

  @override
  String get repaymentConfirmWarning =>
      '请确定已经实际收到款项才确认。此功能不会自动通过 PayNow 或银行转账，可记录部分还款。';

  @override
  String get repaymentNote => '还款备注（选填）';

  @override
  String get repaymentNoteHint => '例如：已收到 PayNow 转账';

  @override
  String get repaymentHistory => '已确认还款记录';

  @override
  String get repaymentNoRecords => '目前还没有已确认的还款。';

  @override
  String get repaymentReceivedRecorded => '已收到并记录';

  @override
  String get repaymentLimitations =>
      '只有收款人才可以确认已收到款项。还款会减少个人应收应付，不会更改共同基金余额。本功能不会自动转账或向银行核实。错误确认目前不能撤销，请核对后再记录。';

  @override
  String get payNowDetails => '我的 PayNow 收款资料';

  @override
  String get payNowPrivacyWarning =>
      '可选择为此群组填写绑定 PayNow 的新加坡手机号码。群组内所有成员都可以看到，请勿填写 OTP、银行密码或账户凭证。';

  @override
  String get payNowMobile => 'PayNow 手机号码';

  @override
  String get payNowMobileHint => '例如：91234567';

  @override
  String get payNowInvalid => '请输入有效的新加坡手机号码（8 位数字，以 8 或 9 开头）。';

  @override
  String get payNowRemoveHint => '清空号码并保存，即可从这个群组移除 PayNow 收款资料。';

  @override
  String get payNowRequestTo => '付款请求对象';

  @override
  String get payNowRecipient => '收款人';

  @override
  String get payNowAmountDue => '未结金额';

  @override
  String get payNowVerifyRecipient => '付款前请在银行 App 核对 PayNow 收款人姓名。';

  @override
  String get payNowNoDetailsShared => '请向收款人索取合适的付款资料。';

  @override
  String get payNowNotPayment => '这只是付款请求。SplitLui 不会自动转账，也不会确认已付款。';

  @override
  String get payNowCopied => '已复制 PayNow 号码';

  @override
  String get payNowCopyNumber => '复制 PayNow 号码';

  @override
  String get payNowShareRequest => '分享付款请求';

  @override
  String get payNowEstimatedSgd => '参考新币金额（付款前请确认汇率）';

  @override
  String get payNowAgreeSgd => 'PayNow 以新币转账，付款前请与收款人确认实际 SGD 金额。';
}
