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
      '只有收款人可确认或撤销还款记录。已确认还款会减少个人欠款，不影响共同基金。系统不会自动转账或向银行核实。撤销会恢复欠款，并保留审计记录。';

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

  @override
  String get inviteShareHeading => '邀请你加入我的 SplitLui 群组！';

  @override
  String get inviteShareInstructions =>
      '安装或打开 SplitLui，选择「加入群组」，然后贴上邀请码（或整段邀请消息）。';

  @override
  String get inviteInstallApp => '安装 SplitLui';

  @override
  String get inviteShareButton => '分享邀请';

  @override
  String get inviteShareHint => '请私下分享给你信任的人。任何拿到邀请码的人都可以加入，直到组织者重置邀请码。';

  @override
  String get inviteInvalidCode => '请贴上有效的邀请码或完整邀请消息。';

  @override
  String get expenseFundAvailable => '共同基金可用余额';

  @override
  String get expenseFundInsufficient => '共同基金余额不足，请先补款或更换付款人。';

  @override
  String get expenseFundNoSplit => '由共同基金付款，不会另外分摊给成员，也不会产生个人欠款。';

  @override
  String get settlementDisplayCurrency => '还款显示货币';

  @override
  String get settlementOriginalBalance => '原本欠款';

  @override
  String get settlementEstimateDisclaimer => '换算金额仅根据群组约定汇率估算。付款前请确认金额及货币。';

  @override
  String get settlementLedgerNote => '已确认的还款仍以群组消费货币记录';

  @override
  String get settlementConvertedEstimate => '换算参考金额';

  @override
  String get payNowReceivesFrom => '待收款';

  @override
  String get payNowFromMember => '付款人';

  @override
  String get expenseOriginalTotal => '以此货币支付';

  @override
  String get expenseCombinedTotal => '合计';

  @override
  String get expenseCombinedRateNote =>
      '保留实际付款货币；合计仅使用群组设定汇率换算旅程消费货币。这里只统计成员垫付的分摊开销，不包含共同基金支出。';

  @override
  String get expenseCombinedRateMixed =>
      '保留实际付款货币；旅程消费货币依群组汇率换算，其他货币依每笔开销已保存的汇率换算。这里只统计成员垫付的分摊开销，不包含共同基金支出。';

  @override
  String get repaymentDefaultCurrency => '默认还款货币';

  @override
  String get repaymentDefaultCurrencyHint =>
      '选择默认还款货币。每笔还款仍可更改；若货币不属于群组设定的货币组合，请手动输入约定汇率。';

  @override
  String get repaymentPaidCurrency => '实际收到的货币';

  @override
  String get repaymentPaidAmount => '实际收到的金额';

  @override
  String get repaymentConversionRate => '兑换成群组消费货币的汇率';

  @override
  String get repaymentRateHint =>
      '请记录实际收到的货币与金额。如使用其他货币，请输入双方约定的汇率；不会自动使用实时汇率。';

  @override
  String get repaymentLedgerEquivalent => '抵扣欠款的金额';

  @override
  String get repaymentOutstanding => '尚欠金额';

  @override
  String get repaymentExceedsOutstanding => '换算后的还款超过尚欠金额，请减少还款金额。';

  @override
  String get repaymentUndo => '撤销收款确认';

  @override
  String get repaymentUndoWarning => '仅在误记录收款时撤销。系统会恢复欠款并保留撤销记录；此操作不会撤回任何银行转账。';

  @override
  String get repaymentReversalReason => '撤销原因';

  @override
  String get repaymentReversalReasonHint => '例如：记录的金额有误';

  @override
  String get repaymentReversalReasonInvalid => '请填写至少 3 个字的原因。';

  @override
  String get repaymentUndoConfirm => '确认撤销';

  @override
  String get repaymentReversed => '已撤销 — 欠款已恢复';

  @override
  String get receiptAttachment => '收据照片（选填）';

  @override
  String get receiptCamera => '拍照';

  @override
  String get receiptGallery => '从相册选择';

  @override
  String get receiptRemove => '移除照片';

  @override
  String get receiptReviewHint => '识别金额仅供参考，保存前请确认金额和货币。';

  @override
  String get receiptUploadFailed => '开销已保存，但收据照片上传失败。请勿重复新增同一笔开销。';

  @override
  String get editExpense => '编辑开销';

  @override
  String get deleteExpense => '删除开销';

  @override
  String get deleteExpenseWarning => '确定删除此开销和成员分摊吗？欠款将重新计算。已有确认还款的群组不可修改开销。';

  @override
  String get expenseReceiptCleanupWarning => '开销已删除，但收据照片清理失败，请联系管理员处理。';

  @override
  String get expenseReceiptDate => '收据日期';

  @override
  String get expenseChooseDate => '选择收据日期';

  @override
  String get offlinePendingHeading => '离线保存 · 等待同步';

  @override
  String get offlineRetry => '立即同步';

  @override
  String get offlinePending => '已保存到本机 · 尚未同步';

  @override
  String get offlineNeedsReview => '同步需处理 · 联网后重试';

  @override
  String get offlineReceiptPending => '开销已同步 · 收据待上传';

  @override
  String get offlineReadOnlySnapshot => '正在显示本机缓存的开销。联网前余额可能不是最新的。';

  @override
  String get offlineReadOnlyDetails => '离线缓存资料。成员分摊、收据下载和编辑需要联网；其他设备可能已修改金额。';

  @override
  String get offlinePendingDetails => '这笔开销已保存在本机。服务器确认前不会计入群组余额。等待同步期间请勿重复新增。';

  @override
  String get fundPurchaseDeleteWarning =>
      '确定删除这笔共同基金开销吗？已扣除的金额会退回共同基金余额，调整记录将保留供查阅。';

  @override
  String get fundPurchaseAuthorOnly => '只有最初记录这笔共同基金开销的成员才能在联网时编辑或删除。';

  @override
  String get fundContributionTargets => '共同基金分摊目标';

  @override
  String get fundTargetTotal => '目标金额';

  @override
  String get fundTotalReceived => '实际收到';

  @override
  String get fundOutstandingToCollect => '尚待收取';

  @override
  String get fundTargetsNotBalance => '目标和补款请求只是计划，不会增加共同基金实际余额。';

  @override
  String get fundTargetSet => '设置目标';

  @override
  String get fundTopUpRequest => '请求补款';

  @override
  String get fundRefundConfirm => '确认已退款';

  @override
  String get fundRefundNote => '退款原因及支付方式';

  @override
  String get fundRefundWarning => '请仅在成员确实收到退款后确认。操作会扣减共同基金余额，并留下审计记录。';

  @override
  String get fundRefunded => '已退还成员';

  @override
  String get fundTopUpRequests => '补款请求';

  @override
  String get fundNoRequests => '暂无补款请求。';

  @override
  String get fundTopUpPending => '已请求 · 尚非实际入账';

  @override
  String get fundTopUpCancelled => '已取消';

  @override
  String get fundCancelRequest => '取消请求';

  @override
  String get fundClosingPreview => '共同基金结算预览';

  @override
  String get fundTotalSpent => '共同基金支出';

  @override
  String get fundClosingNotFinal => '这里只是结算预览，不会真正关闭共同基金或转账。请先处理未收款项和已同意的退款。';

  @override
  String get fundReconciliationMismatch => '提醒：当前基金余额与已收贡献、支出和已确认退款不一致。';

  @override
  String get fundAdvancedLoadError => '无法载入基金目标和退款资料，请检查网络及 Supabase 数据库迁移。';

  @override
  String get fundRefundHistory => '已确认退款记录';

  @override
  String get fundNoRefunds => '暂无已确认的退款。';

  @override
  String get repaymentActualReceivedHint => '请输入实际收到的金额。可以是凑整金额或部分还款。';

  @override
  String get settlementMoreDetails => '查看更多详情';

  @override
  String get repaymentSettleFull => '这笔还款已全部结清';

  @override
  String get tripReportTitle => '旅程结算报告';

  @override
  String get tripReportEntryHint => '分享开销、共同基金及还款汇总';

  @override
  String get tripReportIntro => '生成旅程记录的 PDF 快照，不会自动关闭群组或进行转账。';

  @override
  String get tripReportIncludes => '报告内容';

  @override
  String get tripReportContents => '原币开销、换算估计、未结清还款、共同基金贡献与退款、待收款目标及对账检查。';

  @override
  String get tripReportIncludeReceipts => '附上收据照片';

  @override
  String get tripReportReceiptNotice => '选填 · 最多 8 张。任何收到 PDF 的人都可以保存这些照片。';

  @override
  String get tripReportWarning =>
      '需要网络连接及最新同步记录。PDF 只是快照，并非付款确认或正式基金结算。目前导出的 PDF 使用英文标题及支持拉丁文字的字体。';

  @override
  String get tripReportGenerating => '正在生成 PDF…';

  @override
  String get tripReportSharePdf => '生成并分享 PDF';

  @override
  String get offlineSkipReceipt => '跳过收据照片';

  @override
  String get offlineSkipReceiptWarning =>
      '这笔开销已记录到群组。确定停止上传照片吗？本机照片将被删除，但不会删除或修改开销。';

  @override
  String get offlineExpenseAlreadySaved => '开销已确认，只有收据照片尚未上传。';

  @override
  String get offlineSyncProblem => '同步详情';

  @override
  String get offlineReceiptsHeading => '收据照片等待上传';

  @override
  String get splitModeEqual => '平均分摊';

  @override
  String get splitModeAmount => '指定金额';

  @override
  String get splitModePercent => '百分比';

  @override
  String get splitModeShares => '份数';

  @override
  String get splitEditHint => '填写每个人的金额、百分比或份数。分摊总额必须与账单一致。';

  @override
  String get splitAllocationValid => '分摊金额与账单一致';

  @override
  String get splitAllocationInvalid => '请检查金额及分摊数值。指定金额须等于账单总额，百分比须合计 100%。';
}
