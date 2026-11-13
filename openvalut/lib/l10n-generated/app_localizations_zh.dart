// ignore_for_file: omit_local_variable_types,unused_local_variable

// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Chinese (`zh`).
class AppLocalizationsZh extends AppLocalizations {
  AppLocalizationsZh([String locale = 'zh']) : super(locale);

  @override
  String get okAction => '确定';

  @override
  String get cloudAuthEmailOrSecretInvalid => '邮箱或 Secret Key 不正确，请检查后重试。';

  @override
  String get cloudEmailAlreadyRegistered => '该邮箱已注册，请直接登录。';

  @override
  String cloudConnectFailed(Object error) {
    return '无法连接 OpenValut Cloud 服务：$error';
  }

  @override
  String get cloudNoVaultTitle => '该账号还没有密码库';

  @override
  String get cloudNoVaultBody => '注册时会自动创建密码库；请退出后用注册流程创建账号和密码库。';

  @override
  String get cloudWrongMasterPassword => '主密码错误，无法解锁密码库。';

  @override
  String get cloudDecryptFailedMasterPassword => '云端数据解密失败：主密码可能不正确。';

  @override
  String cloudScanCreateFailed(Object error) {
    return '无法创建登录二维码：$error';
  }

  @override
  String get cloudScanExpired => '二维码已过期，请刷新后重试。';

  @override
  String cloudScanSessionInvalid(Object message) {
    return '登录会话已失效（$message），请刷新二维码。';
  }

  @override
  String cloudScanWaitingPhone(Object error) {
    return '等待手机确认中（$error）';
  }

  @override
  String get cloudRegisterNoSecretKey => '注册失败：未返回 Secret Key';

  @override
  String get cloudSaveSecretKeyTitle => '保存你的 Secret Key';

  @override
  String get cloudSecretKeyDescription =>
      '这是你 OpenValut Cloud 账号的唯一身份密钥（账号 UUID）。登录时需要 邮箱 + Secret Key + 主密码。此密钥无法找回，请立即复制并妥善保存；也可以稍后跳过。';

  @override
  String get cloudSaveToFileAction => '保存到本地文件';

  @override
  String get cloudCopyAction => '复制';

  @override
  String get cloudSkipAction => '跳过';

  @override
  String get cloudSavedContinueAction => '我已保存并继续';

  @override
  String get cloudSavedTitle => '已保存';

  @override
  String get cloudSavedToFileBody => 'Secret Key 已保存到本地文件，请妥善保管。';

  @override
  String get cloudSaveFailedTitle => '保存失败';

  @override
  String cloudSaveFailedBody(Object error) {
    return '无法保存 Secret Key：$error';
  }

  @override
  String cloudAccountLabel(Object email) {
    return '账号：$email';
  }

  @override
  String get cloudLoginRequiresNote => '登录时需要：邮箱 + Secret Key + 主密码';

  @override
  String get cloudSecretKeepSafeNote => '此密钥无法找回，请妥善保管。';

  @override
  String get cloudRegisterTitle => '注册 OpenValut Cloud 账号';

  @override
  String get cloudLoginTitle => '登录 OpenValut Cloud';

  @override
  String get cloudRegisterIntro => '注册只需邮箱；密码库主密码仅在本机用于加密，不会上传服务器。';

  @override
  String get cloudLoginIntroDesktop => '输入邮箱、Secret Key 和主密码登录，或使用移动端扫码。';

  @override
  String get cloudLoginIntro => '输入邮箱、Secret Key 和主密码登录。';

  @override
  String get cloudServerUrlLabel => '服务器地址';

  @override
  String get cloudServerUrlHelp => '已内置默认服务器地址，可改为自建域名。';

  @override
  String get cloudServerUrlRequired => '请输入服务器地址';

  @override
  String get cloudServerUrlInvalid => '服务器地址需以 http:// 或 https:// 开头';

  @override
  String get cloudEmailLabel => '邮箱';

  @override
  String get cloudEmailRequired => '请输入邮箱';

  @override
  String get cloudEmailNoSpaces => '邮箱不能包含空格';

  @override
  String get cloudEmailInvalid => '请输入有效的邮箱地址';

  @override
  String get cloudSecretKeyLabel => 'Secret Key（注册时保存的 UUID）';

  @override
  String get cloudSecretKeyRequired => '请输入 Secret Key';

  @override
  String get cloudSecretKeyChars => 'Secret Key 只能包含十六进制字符和 - 分隔符';

  @override
  String get cloudSecretKeyLength => 'Secret Key 应为 32 位十六进制字符';

  @override
  String get cloudMasterPasswordLabel => '密码库主密码';

  @override
  String get cloudMasterPasswordRequired => '请输入密码库主密码';

  @override
  String get cloudPasswordNoSpaces => '密码不能包含空格';

  @override
  String get cloudVaultNameLabel => '密码库名称';

  @override
  String get cloudVaultNameRequired => '请输入密码库名称';

  @override
  String get cloudVaultNameNoLeadingDigit => '名称不能以数字开头';

  @override
  String get cloudVaultNameChars => '名称只能包含中文、英文和数字';

  @override
  String get cloudMasterPasswordMin6 => '主密码至少 6 位';

  @override
  String get cloudConfirmMasterPasswordLabel => '确认主密码';

  @override
  String get cloudPasswordMismatch => '两次输入的密码不一致';

  @override
  String get cloudRegisterSubmit => '注册并创建密码库';

  @override
  String get cloudLoginSubmit => '登录';

  @override
  String get cloudSwitchToLogin => '已有账号？去登录';

  @override
  String get cloudSwitchToRegister => '没有账号？注册一个';

  @override
  String get cloudUseQrLogin => '使用移动端扫码登录';

  @override
  String cloudServerInfo(Object server) {
    return '服务器：$server';
  }

  @override
  String get cloudQrLoginTitle => '扫码登录 OpenValut Cloud';

  @override
  String get cloudQrLoginDescription =>
      '请使用已登录 OpenValut Cloud 的移动端 App 扫描下方二维码确认登录。';

  @override
  String get cloudScanWaiting => '等待手机确认…';

  @override
  String get cloudRefreshQr => '刷新二维码';

  @override
  String get cloudBackToManual => '返回手动输入';

  @override
  String get myShareReceiveTitle => '接收分享';

  @override
  String get myShareReceiveNeedVault => '请先打开或创建一个 OpenValut Cloud 密码库以接收分享。';

  @override
  String myShareAutoSavedCount(Object count) {
    return '已自动存入 $count 条分享到密码库';
  }

  @override
  String get myShareRevokeTitle => '撤销分享';

  @override
  String myShareRevokeConfirm(Object entry) {
    return '确定撤销「$entry」的分享吗？对方将无法再查看。';
  }

  @override
  String get myShareRevokeAction => '撤销';

  @override
  String get myShareRevokeFailed => '撤销失败';

  @override
  String get myShareUrlField => '网址';

  @override
  String get myShareNotesField => '备注';

  @override
  String get myShareUntitledEntry => '未命名条目';

  @override
  String myShareFromOwner(Object owner) {
    return '来自 $owner';
  }

  @override
  String myShareOutgoingSubtitle(Object date, Object recipient) {
    return '分享给 $recipient · $date';
  }

  @override
  String myShareIncomingSubtitle(Object date, Object owner) {
    return '来自 $owner · $date';
  }

  @override
  String myShareCopyFieldTooltip(Object field) {
    return '复制 $field';
  }

  @override
  String myShareCopiedField(Object field) {
    return '已复制 $field';
  }

  @override
  String get myShareDeleteTitle => '删除分享';

  @override
  String get myShareDeleteConfirm => '确定删除这条分享吗？';

  @override
  String get myShareDeleteFailed => '删除失败';

  @override
  String get mySharesTitle => '我的分享';

  @override
  String get mySharesNeedLogin => '请先登录 OpenValut Cloud';

  @override
  String get mySharesRefresh => '刷新';

  @override
  String mySharesLoadFailed(Object error) {
    return '加载分享失败：$error';
  }

  @override
  String get mySharesEmpty => '还没有任何分享';

  @override
  String get mySharesByMe => '我分享的';

  @override
  String get mySharesToMe => '分享给我的';

  @override
  String get myShareDeletedEntry => '已删除的条目';

  @override
  String get myShareGroupBadge => '整组';

  @override
  String myShareGroupSubtitle(Object count, Object date, Object owner) {
    return '整组 · $count 条 · 来自 $owner · $date';
  }

  @override
  String get myShareGroupSyncAction => '同步到我的密码库';

  @override
  String myShareGroupSyncedCount(Object count) {
    return '已同步 $count 个分组分享到密码库';
  }

  @override
  String get myShareGroupEmpty => '这个分组分享还没有条目。';

  @override
  String get importUntitledEntry => '未命名条目';

  @override
  String importReadFailed(Object error) {
    return '读取失败：$error';
  }

  @override
  String get importCsvEmptyOrInvalid => 'CSV 文件为空或格式不正确';

  @override
  String get importPasswordWrongTitle => '密码错误';

  @override
  String get importPasswordWrongBody => 'KDBX 文件密码错误，请重新输入。';

  @override
  String get importNeedCloudVault => '请先打开一个 OpenValut Cloud 密码库';

  @override
  String get importReadonlyVaultWarning =>
      '当前密码库是用记住的密钥打开的（只读）。请先锁定 App，再用主密码重新打开密码库，然后再导入。';

  @override
  String get importKdbxPasswordTitle => '输入 KDBX 文件密码';

  @override
  String importPasswordLabelForFile(Object fileName) {
    return '密码（$fileName）';
  }

  @override
  String importDoneCount(Object count) {
    return '成功导入 $count 个条目';
  }

  @override
  String importFailed(Object error) {
    return '导入失败：$error';
  }

  @override
  String get importReselectAction => '重新选择';

  @override
  String get importSourcePickerIntro =>
      '选择数据来源，读取后可以选择要导入的条目，导入到当前打开的 OpenValut Cloud 密码库。';

  @override
  String get importSource1PasswordCsvSubtitle => '1Password 导出的 CSV 文件';

  @override
  String get importSourceKdbxTitle => 'KDBX 文件';

  @override
  String get importSourceKdbxSubtitle => 'KeePass / 其他密码库导出的 .kdbx';

  @override
  String get importReadingEllipsis => '读取中…';

  @override
  String get importSelectFileAndRead => '选择文件并读取';

  @override
  String importSelectAllCount(Object count) {
    return '全选（共 $count 个条目）';
  }

  @override
  String importSelectedCount(Object count) {
    return '已选 $count';
  }

  @override
  String get importImportingEllipsis => '导入中…';

  @override
  String importImportSelectedCount(Object count) {
    return '导入选中的 $count 个条目';
  }

  @override
  String get fieldNotesLabel => '备注';

  @override
  String get masterChangeLockedFirst => '请先锁定密码库，用主密码重新打开后再修改主密码。';

  @override
  String get scanLoginNeedAccount => '请先登录 OpenValut Cloud 账号，再使用扫码授权登录。';

  @override
  String get scanLoginNotOpenvalutQr => '不是 OpenValut 登录二维码，请扫描 PC 端登录页显示的二维码。';

  @override
  String get scanLoginConfirmedNoKey => '已确认，PC 端将自动登录（未携带主密码，请在 PC 上输入）。';

  @override
  String get scanLoginConfirmedUnlock => '已确认，PC 端将自动登录并直接解锁密码库。';

  @override
  String scanLoginConfirmFailed(Object error) {
    return '确认失败：$error';
  }

  @override
  String get scanLoginEnterMasterTitle => '输入密码库主密码';

  @override
  String get scanLoginMasterLabel => '主密码';

  @override
  String get scanLoginMasterHint => '用于授权 PC 端直接解锁';

  @override
  String get pickerSearchHint => '搜索应用名称或包名';

  @override
  String get pickerNoMatchingApps => '没有找到匹配的应用';

  @override
  String get twoFactorNoOpenVault => '没有打开的密码库';

  @override
  String get twoFactorNoUsername => '无法确定当前系统用户名';

  @override
  String get twoFactorNoMachineId => '无法确定本机标识';

  @override
  String get twoFactorEmptySudoPassword => 'sudo 密码不能为空';

  @override
  String get twoFactorTotpFileWriteFailed =>
      '无法写入加密 TOTP 文件（缺少 machine-id 或主目录）';

  @override
  String twoFactorSystemSetupIncomplete(Object detail) {
    return '系统配置未完成：$detail';
  }

  @override
  String get twoFactorConfiguredDone => '计算机两步验证已配置完成，sudo 现在会额外要求输入一次性验证码。';

  @override
  String twoFactorConfigFailed(Object error) {
    return '配置失败：$error';
  }

  @override
  String get twoFactorIdentityMissing => '无法确定用户名/主目录/本机标识';

  @override
  String get twoFactorUserCancelled => '用户取消或认证失败';

  @override
  String twoFactorTotpFileDeleteFailed(Object localError, Object systemError) {
    return '无法删除 TOTP 文件（$localError），且系统清理失败（$systemError）';
  }

  @override
  String get twoFactorDisabledPamFailed =>
      '已关闭两步验证（sudo 不再要求验证码）。未能移除 /etc/pam.d/sudo 中的 PAM 行。';

  @override
  String get twoFactorDisabledDone => '已关闭系统两步验证，sudo 不再要求一次性验证码。';

  @override
  String twoFactorAssetReadFailed(Object error) {
    return '无法读取内置的 PAM 模块/askpass 文件：$error';
  }

  @override
  String twoFactorPkexecFailed(Object code, Object message) {
    return 'pkexec 未能完成（退出码 $code）：$message';
  }

  @override
  String get sshKeysAlreadyImported => '这些 SSH 密钥已经在密码库中，无需重复导入。';

  @override
  String get sshSkippedAlreadyImported => '已存在，跳过';

  @override
  String get openFileFailedLabel => '打开文件失败';

  @override
  String get untitledLabel => '未命名';

  @override
  String get trayShowOpenvalut => '显示 OpenValut';

  @override
  String get trayQuit => '退出';

  @override
  String get appAlreadyRunningMessage =>
      'OpenValut 正在运行（可能已最小化到系统托盘），请先右键托盘图标选择「退出」后再启动。';

  @override
  String get lockedChooseAnotherVault => '选择其他密码库';

  @override
  String get offlineBannerTitle => '当前断开了网络连接';

  @override
  String get selectFileOpenLocalFile => '打开本地文件';

  @override
  String get enableFingerprintQuestion => '是否启用指纹认证？';

  @override
  String get enableFingerprintDescription => '启用后，打开密码库时可直接使用指纹验证，无需再次输入主密码。';

  @override
  String get enableFingerprintAction => '启用';

  @override
  String get cloudUnlockFailedTitle => '无法解锁云端密码库';

  @override
  String get cloudUnlockFailedDescription =>
      '云端数据解密失败：主密码可能不正确，或该库是在其他设备上用不同主密码创建的。';

  @override
  String get menuImportPasswords => '导入密码';

  @override
  String get menuExportCsv => '导出 CSV';

  @override
  String get menuScanLogin => '扫码授权登录';

  @override
  String get menuAboutOpenvalut => '关于 OpenValut';

  @override
  String get menuAbout => '关于';

  @override
  String get menuAuthorName => 'OpenValut 贡献者';

  @override
  String get menuEmailPrefix => '邮箱：';

  @override
  String get menuBlogPrefix => '博客：';

  @override
  String get menuExportedCsvTitle => '已导出';

  @override
  String get menuExportedAllCsv => '已导出全部条目为 CSV。';

  @override
  String get menuExportFailedTitle => '导出失败';

  @override
  String get copyUsernameAction => '复制用户名';

  @override
  String get renameEntryDialogTitle => '重命名条目';

  @override
  String get newNameFieldLabel => '新名称';

  @override
  String get restoredSnack => '已恢复';

  @override
  String get deletedSnack => '已删除';

  @override
  String get undoAction => '撤销';

  @override
  String get shareWithFamilyTitle => '分享给家人';

  @override
  String get shareRecipientEmailLabel => '接收者的 OpenValut Cloud 邮箱';

  @override
  String get shareRecipientEmailHint => '例如 family@example.com';

  @override
  String get shareTargetLoginRequired =>
      '请先登录 OpenValut Cloud（选库页 → OpenValut Cloud）。';

  @override
  String get shareRequiresCloudVault => '仅 OpenValut Cloud 密码库中的条目支持分享。';

  @override
  String sharedToRecipient(Object recipient) {
    return '已分享给 $recipient';
  }

  @override
  String shareUserNotFound(Object recipient) {
    return '找不到用户 $recipient，请确认对方已注册并登录过 OpenValut Cloud。';
  }

  @override
  String get shareFailed => '分享失败';

  @override
  String shareFailedDetail(Object detail) {
    return '分享失败：$detail';
  }

  @override
  String get shareGroupTitle => '分享整个分组';

  @override
  String get shareGroupActionLabel => '分享整个分组…';

  @override
  String get shareGroupRequiresCloudVault =>
      '只有 OpenValut Cloud 密码库里的分组才能整组分享。';

  @override
  String get shareGroupSelfNotAllowed => '不能把分组分享给自己。';

  @override
  String get shareGroupRecipientRequired => '请输入接收者的 OpenValut Cloud 邮箱。';

  @override
  String shareGroupAlreadyShared(Object recipient) {
    return '该分组已经分享给 $recipient 了。';
  }

  @override
  String sharedGroupToRecipient(Object group, Object recipient) {
    return '已把分组「$group」分享给 $recipient，之后的新增和修改会自动同步。';
  }

  @override
  String get drawerAllEntries => '全部';

  @override
  String get drawerRecycleBin => '回收站';

  @override
  String get drawerMyShares => '我的分享';

  @override
  String get drawerGroupNameLabel => '分组名称';

  @override
  String get renameGroupDialogTitle => '重命名分组';

  @override
  String get cliReadAllowTitle => '允许 CLI/脚本读取';

  @override
  String get cliReadAllowSubtitle => '该分组（含子分组）下的条目默认禁止读取，点击后全部允许';

  @override
  String get cliReadDenyTitle => '禁止 CLI/脚本读取';

  @override
  String get cliReadDenySubtitle => '恢复默认：该分组下的条目对 CLI/脚本隐藏';

  @override
  String get cliReadGroupAllAllowed => '该分组下的条目已全部允许 CLI/脚本读取';

  @override
  String cliReadGroupAllowedCount(Object count) {
    return '已允许 $count 条条目被 CLI/脚本读取（保存后生效）';
  }

  @override
  String get cliReadGroupAllDenied => '该分组下的条目已全部禁止 CLI/脚本读取';

  @override
  String cliReadGroupDeniedCount(Object count) {
    return '已禁止 $count 条条目被 CLI/脚本读取（保存后生效）';
  }

  @override
  String get organizeByCategoryTitle => '按分类整理';

  @override
  String get organizeByCategoryDescription =>
      '将把密码库根目录下的条目按「网站 / APP / 其他 / 金融」自动归入对应分组（分组不存在则自动创建），并保存到服务器。要继续吗？';

  @override
  String get organizeAction => '整理';

  @override
  String organizeDoneCount(Object count) {
    return '已整理 $count 个条目';
  }

  @override
  String get groupListNewGroup => '新建分组';

  @override
  String get weakPasswordsLabel => '弱口令';

  @override
  String get allowCliRead => '允许 CLI/脚本读取';

  @override
  String get denyCliRead => '禁止 CLI/脚本读取';

  @override
  String get entryAllowCliRead => '允许 CLI/脚本读取';

  @override
  String get entryAllowCliReadDescription =>
      '默认禁止读取。开启后 openvalut-cli list/get 与本地凭据服务才能读取此条目';

  @override
  String get entryAddWebsite => '添加目标网站';

  @override
  String get entryAddAttachment => '添加附件';

  @override
  String get entryAddSpecialField => '添加自定义字段';

  @override
  String entryPasswordExpired(Object days) {
    return '该密码已过期 $days 天，请及时修改密码';
  }

  @override
  String entryPasswordExpires(Object remaining) {
    return '该密码还剩 $remaining 天到期，请及时修改密码';
  }

  @override
  String get entryLinkApp => '关联 App';

  @override
  String entryTargetWebsite(Object number) {
    return '目标网站 $number';
  }

  @override
  String get entryPickAppTooltip => '选择要关联的 App';

  @override
  String entryPasteReference(Object reference) {
    return '已复制引用：$reference';
  }

  @override
  String get entryCopyReferenceTitle => '复制引用';

  @override
  String masterPasswordExpiredBanner(Object days) {
    return '主密码已过期 $days 天，建议立即修改';
  }

  @override
  String masterPasswordExpiresBanner(Object remaining) {
    return '主密码将在 $remaining 天后过期，建议尽快修改';
  }

  @override
  String get changeMasterPasswordAction => '修改密码';

  @override
  String get remindLaterAction => '稍后提醒';

  @override
  String get prefDisablingSystem2fa => '正在关闭系统两步验证…';

  @override
  String get prefTwoFactorDisabled => '已关闭';

  @override
  String get prefTwoFactorDisableFailed => '关闭失败';

  @override
  String get prefNeedUnlockedVaultForAutoConfig => '请先打开并解锁一个密码库，再开启自动配置。';

  @override
  String get prefConfiguringSystem2fa => '正在配置计算机两步验证…';

  @override
  String get prefTwoFactorConfigured => '配置完成';

  @override
  String get prefTwoFactorConfigFailed => '配置失败';

  @override
  String get prefSystemPasswordDialogTitle => '输入系统登录密码';

  @override
  String get prefSudoPasswordLabel => 'sudo 密码';

  @override
  String get prefSudoPasswordHelper => '用于录入计算机条目，并作为两步验证的保护密码';

  @override
  String get prefRememberMasterPasswordTitle => '记住主密码';

  @override
  String get prefRememberOffEveryLogin => '关闭（每次输入主密码）';

  @override
  String prefDaysPlaceholder(Object days) {
    return '$days 天';
  }

  @override
  String get prefCloudServiceNotConfigured => '未配置 OpenValut Cloud 服务';

  @override
  String get prefUpToDate => '已是最新版本';

  @override
  String prefNewVersionAvailableTitle(Object versionName) {
    return '发现新版本 $versionName';
  }

  @override
  String get prefUpdateNowQuestion => '有新版本可用，是否立即更新？';

  @override
  String get prefUpdateLaterAction => '以后再说';

  @override
  String get prefUpdateNowAction => '立即更新';

  @override
  String get prefNewVersionDownloadedTitle => '新版本已下载';

  @override
  String prefInstallManuallyBody(Object installHint, Object path) {
    return '安装包已保存到：\n$path\n\n请到该目录手动安装。\nLinux 示例：\n$installHint';
  }

  @override
  String get prefGotItAction => '知道了';

  @override
  String prefUpdateCheckFailedTitle(Object error) {
    return '检查更新失败: $error';
  }

  @override
  String get prefClipboardAutoClearTitle => '剪贴板自动清空';

  @override
  String get prefClipboardAutoClearSubtitle => '复制密码/用户名后，自动清空系统剪贴板';

  @override
  String get prefOff => '关闭';

  @override
  String prefSecondsPlaceholder(Object seconds) {
    return '$seconds 秒';
  }

  @override
  String get prefZeroDisablesAutoClear => '0 表示关闭自动清空';

  @override
  String get prefCloseWindowTitle => '关闭窗口时';

  @override
  String get prefCloseWindowSubtitle => '选择关闭按钮的行为';

  @override
  String get prefHideToTrayRunning => '隐藏到托盘（程序继续运行）';

  @override
  String get prefMinimizeToTaskbarRunning => '最小化到任务栏（程序继续运行）';

  @override
  String get prefQuitApplication => '退出程序';

  @override
  String get prefHideToTray => '隐藏到托盘';

  @override
  String get prefMinimizeToTaskbar => '最小化到任务栏';

  @override
  String get prefSshConfigAppendPreview => '将在 ~/.ssh/config 末尾追加：\n\n';

  @override
  String get prefNotEnabledStatus => '未开启';

  @override
  String prefReminderNoChangeDate(Object days) {
    return '每 $days 天提醒（尚未记录修改日期）';
  }

  @override
  String prefReminderExpired(Object days) {
    return '已于 $days 天前到期，建议立即修改';
  }

  @override
  String prefReminderEvery(Object days, Object remaining) {
    return '每 $days 天提醒，还剩 $remaining 天';
  }

  @override
  String get prefLoadingEllipsis => '加载中…';

  @override
  String get prefAlwaysShowSidePanel => '始终显示左侧面板';

  @override
  String get prefAlwaysShowSidePanelSubtitle =>
      '开启后左侧分类面板常驻显示；关闭后为折叠面板，点击其他区域自动收起';

  @override
  String get prefCheckForUpdatesSubtitle => '检查 OpenValut Cloud 发布的新版本并下载';

  @override
  String get prefRememberMasterPasswordSubtitle => '期间打开密码库无需再次输入主密码';

  @override
  String get prefStartAtLogin => '开机自动启动';

  @override
  String get prefStartAtLoginSubtitle => '登录系统后自动启动 OpenValut 并隐藏到托盘';

  @override
  String get prefFingerprintUnlock => '指纹解锁';

  @override
  String get prefFingerprintUnlockSubtitle => '开启后可用指纹快速解锁，无需输入主密码';

  @override
  String get prefAutoTwoFactorTitle => '自动配置两步验证';

  @override
  String get prefAutoTwoFactorSubtitle =>
      '开启后自动录入本机用户名/密码/一次性验证码，并配置系统 sudo 的两步验证（PAM 模块、askpass 与 /etc/pam.d/sudo）';

  @override
  String get prefImportSshSubtitle => '~/.ssh 下的私钥导入到密码库，自动标注本机';

  @override
  String prefImportedSshKeys(Object count) {
    return '已导入 $count 个 SSH 密钥';
  }

  @override
  String get prefPasswordChangeReminderTitle => '密码修改提醒';

  @override
  String get fieldUserName => '用户';

  @override
  String get fieldPassword => '密码';

  @override
  String get fieldWebsite => '目标网站';

  @override
  String get fieldTitle => '标题';

  @override
  String get fieldTotp => '基于时间的身份验证 (TOTP)';

  @override
  String get english => 'English';

  @override
  String get german => '德语';

  @override
  String get russian => '俄语';

  @override
  String get ukrainian => '乌克兰语';

  @override
  String get lithuanian => '立陶宛语';

  @override
  String get french => '法语';

  @override
  String get spanish => '西班牙语';

  @override
  String get indonesian => '印度尼西亚语';

  @override
  String get turkish => '土耳其语';

  @override
  String get hebrew => '希伯来语';

  @override
  String get italian => '意大利语';

  @override
  String get chineseSimplified => '简体中文';

  @override
  String get chineseTraditional => '繁体中文';

  @override
  String get portugueseBrazilian => '葡萄牙语（巴西）';

  @override
  String get slovak => '斯洛伐克语';

  @override
  String get dutch => '荷兰语';

  @override
  String get selectItem => '选择…';

  @override
  String get selectKeepassFile => 'OpenValut - 打开密码库';

  @override
  String get selectKeepassFileLabel => '请打开一个数据库，后缀名为.kdbx';

  @override
  String get createNewFile => '新建一个';

  @override
  String get openLocalFile => '本地\n文件';

  @override
  String get openFile => '打开文件';

  @override
  String get loadFromDropdownMenu => '更多…';

  @override
  String get quickUnlockingFiles => '正在解锁文件…';

  @override
  String openFileProgress(Object fileName, Object current, Object totalCount) {
    return '正在准备 $fileName …\n已完成($current / $totalCount)';
  }

  @override
  String loadFrom(String cloudStorageName) {
    return '从 $cloudStorageName 导入';
  }

  @override
  String get loadFromRemoteUrl => '从链接打开KDBX文件';

  @override
  String get createNewKeepass => '首次使用？\n创建新的密码库';

  @override
  String get labelLastOpenFiles => '上次打开的密码库:';

  @override
  String get noFilesHaveBeenOpenYet => '尚未打开任何文件';

  @override
  String get preferenceSelectLanguage => '选择界面语言';

  @override
  String get preferenceLanguage => '界面语言';

  @override
  String get preferenceTextScaleFactor => '字体大小';

  @override
  String get preferenceVisualDensity => '图标密度';

  @override
  String get preferenceTheme => '应用程序主题';

  @override
  String get preferenceThemeLight => '明亮模式';

  @override
  String get preferenceThemeDark => '深色模式';

  @override
  String get preferenceSystemDefault => '跟随系统';

  @override
  String get preferenceDefault => '默认';

  @override
  String get lockAllFiles => '锁定所有数据库';

  @override
  String get preferenceAllowScreenshots => '允许对本应用截屏';

  @override
  String get preferenceEnableAutoFill => '启用密码自动填充';

  @override
  String get enableAutofillSuggestionBanner => '需要开启密码自动填充功能吗？';

  @override
  String get dismissAutofillSuggestionBannerButton => '不需要';

  @override
  String get enableAutofillSuggestionBannerButton => '启用！';

  @override
  String get preferenceAutoFillDescription => '仅支持安卓 8.0 (Oreo) 或更高版本。';

  @override
  String get preferenceTitle => '设置';

  @override
  String get preferenceEnableSystemWideShortcuts => '启用全局快捷键';

  @override
  String get preferenceEnableSystemWideShortcutsHelp =>
      '将 Ctrl+Alt+F 注册为打开搜索的全局快捷键';

  @override
  String get preferencesSearchFields => '自定义搜索范围';

  @override
  String get preferencesSearchFieldPromptTitle => '搜索范围';

  @override
  String get preferencesSearchFieldPromptLabel => '允许搜索的字段列表，用半角逗号分隔';

  @override
  String preferencesSearchFieldPromptHelp(
    Object wildCardCharacter,
    Object defaultSearchFields,
  ) {
    return '使用 $wildCardCharacter 代表所有字段，留空则使用默认字段 ($defaultSearchFields)';
  }

  @override
  String get aboutAppName => 'openvalut';

  @override
  String get aboutLinkFeedback => '欢迎反馈意见！';

  @override
  String get aboutLinkVisitWebsite => '别忘了参观一下我们的网站';

  @override
  String get aboutLinkGitHub => '本项目是自由开源软件！';

  @override
  String aboutLogFile(String logFilePath) {
    return '日志文件: $logFilePath';
  }

  @override
  String get aboutLinkContributors => '显示贡献者';

  @override
  String get unableToLaunchUrlTitle => '无法打开链接';

  @override
  String unableToLaunchUrlDescription(Object url, Object openError) {
    return '打开链接 $url 失败: $openError';
  }

  @override
  String get unableToLaunchUrlNoHandler => '找不到可以打开此链接的应用程序';

  @override
  String launchedUrl(Object url) {
    return '您打开的链接是: $url';
  }

  @override
  String get menuItemGeneratePassword => '生成安全密码';

  @override
  String get menuItemPreferences => '偏好设置';

  @override
  String get menuItemOpenAnotherFile => '打开另一个数据库';

  @override
  String get menuItemCheckForUpdates => '检查更新';

  @override
  String get menuItemSupport => '发送日志';

  @override
  String get menuItemSupportSubtitle => '通过电子邮件发送日志';

  @override
  String get menuItemForum => '帮助论坛';

  @override
  String get menuItemForumSubtitle => '报告问题并获得帮助';

  @override
  String get menuItemHelp => '寻求帮助';

  @override
  String get menuItemHelpSubtitle => '在浏览器查阅用户文档';

  @override
  String get menuItemAbout => '关于本应用';

  @override
  String get actionOpenUrl => '打开链接';

  @override
  String get passwordPlainText => '显示密码';

  @override
  String get generatorPassword => '生成的密码';

  @override
  String get generatePassword => '生成随机密码';

  @override
  String get doneButtonLabel => '完成';

  @override
  String get useAsDefault => '用作默认密码';

  @override
  String get characterSetLowerCase => '小写字母 (a-z)';

  @override
  String get characterSetUpperCase => '大写字母 (A-Z)';

  @override
  String get characterSetNumeric => '数字 (0-9)';

  @override
  String get characterSetUmlauts => 'ASCII扩展字符 (ä)';

  @override
  String get characterSetSpecial => '特殊字符 (@%+)';

  @override
  String get length => '长度';

  @override
  String get customLength => '自定义密码长度';

  @override
  String customLengthHelperText(Object customMinLength) {
    return '请输入大于 $customMinLength 的整数';
  }

  @override
  String savedFiles(int numFiles, Object files) {
    final intl.NumberFormat numFilesNumberFormat =
        intl.NumberFormat.compactLong(
          locale: localeName,
        );
    final String numFilesString = numFilesNumberFormat.format(numFiles);

    String _temp0 = intl.Intl.pluralLogic(
      numFiles,
      locale: localeName,
      other: '$numFilesString 个已保存的文件: $files',
      one: '一个文件已保存: $files',
    );
    return '$_temp0';
  }

  @override
  String get manageGroups => '分组管理';

  @override
  String get lockFiles => '锁定文件';

  @override
  String get searchHint => '搜索…';

  @override
  String get searchButtonLabel => '搜索';

  @override
  String get filterButtonLabel => '按组筛选';

  @override
  String get clear => '清空';

  @override
  String get autofillFilterPrefix => '筛选：';

  @override
  String get autofillMatchPrefix => '匹配条目：';

  @override
  String get autofillPrompt => '选择用于自动填充的密码条目。';

  @override
  String get autofillNoMatches => '当前页面没有匹配的条目。';

  @override
  String get autofillNoOpenVault =>
      '没有已解锁的密码库。请先在 OpenValut 中打开密码库，再返回浏览器重新触发自动填充。';

  @override
  String get androidAutofillSection => 'Android 自动填充';

  @override
  String get prefAutofillIgnoredAppsTitle => '这些 App 里永不自动填充';

  @override
  String get prefAutofillIgnoredAppsSubtitle =>
      '选中的 App 里 OpenValut 一声不吭，哪怕它出现了密码框或验证码输入框。这类 App 内嵌 WebView 打开的登录页同样静音。键盘上那个自动填充键去不掉，点了只是没东西。';

  @override
  String get prefAutofillIgnoredAppsNone => '无';

  @override
  String prefAutofillIgnoredAppsCount(int count) {
    return '$count 个';
  }

  @override
  String get prefAutofillIgnoredAppsPickerTitle => '选择要忽略的 App';

  @override
  String get prefAutofillIgnoredAppsDone => '完成';

  @override
  String get prefAutofillIgnoredAppsRemoveAll => '全部移除';

  @override
  String get prefAutofillIgnoreBrowserTitle => '要忽略这个浏览器吗？';

  @override
  String prefAutofillIgnoreBrowserBody(String app) {
    return '$app 是浏览器：只要它在忽略列表里，OpenValut 在这个浏览器里就不会填任何网页的账号密码。这通常不是你想要的。';
  }

  @override
  String get prefAutofillIgnoreBrowserConfirm => '确定忽略';

  @override
  String get showVaultStartPage => '每次打开 OpenValut 时显示此页面';

  @override
  String get securityCategoryLabel => '安全';

  @override
  String get weakPasswordsEmpty => '没有检测到弱口令，很棒。';

  @override
  String get generateSshKeyPair => '生成 SSH 密钥对';

  @override
  String get sshKeyNameLabel => '密钥名称';

  @override
  String get sshKeyGenerated => '已生成 SSH 密钥对';

  @override
  String get sshKeyGenerationFailedTitle => '生成 SSH 密钥失败';

  @override
  String get sshKeysGroupName => 'SSH 密钥';

  @override
  String get fieldSshPrivateKey => 'SSH 私钥';

  @override
  String get fieldSshPublicKey => 'SSH 公钥';

  @override
  String get fieldSshPort => 'SSH 端口';

  @override
  String get fieldAccessKey => 'Access Key ID';

  @override
  String get fieldSecretKey => 'Secret Access Key';

  @override
  String get entryAddAkskCredential => 'AK/SK 凭证';

  @override
  String get addSpecialField => '添加字段';

  @override
  String get addTotpField => '一次性密码';

  @override
  String get totpSecretPromptTitle => '添加一次性密码';

  @override
  String get totpSecretPromptLabel => 'otpauth:// 链接或 base32 密钥';

  @override
  String get localServicesSection => '本地服务';

  @override
  String get sshAgentSetting => 'SSH Agent';

  @override
  String get sshAgentSettingHelp =>
      '密码库解锁期间，ssh 可通过 IdentityAgent 使用密码库内的密钥，私钥不下盘。';

  @override
  String get credentialServerSetting => '凭据服务（openvalut-cli）';

  @override
  String get credentialServerSettingHelp =>
      '密码库解锁期间，openvalut-cli 可读取用户名、密码和两步验证码。';

  @override
  String get importSshKeys => '导入本机 SSH 密钥';

  @override
  String get importSshKeysNoneFound => '~/.ssh 下没有找到可导入的 SSH 密钥。';

  @override
  String get importButton => '导入';

  @override
  String get importSshKeysDeleteTitle => '删除本机原始密钥？';

  @override
  String get importSshKeysDeleteBody =>
      '密钥已导入密码库。是否删除 ~/.ssh 下的原始文件？删除后只能在密码库解锁时通过 SSH Agent 使用。';

  @override
  String get keep => '保留';

  @override
  String get delete => '删除';

  @override
  String get sshConfigSnippet => 'SSH 配置';

  @override
  String get writeSshConfig => '写入 ~/.ssh/config';

  @override
  String get writeSshConfigDone => '已写入 ~/.ssh/config';

  @override
  String get sshConfigExternalIdentityAgent =>
      '检测到 ~/.ssh/config 已有 IdentityAgent 配置，ssh 会优先使用最先匹配到的值，OpenValut 引用可能不生效。';

  @override
  String get sshConfigRemoved => '已从 ~/.ssh/config 移除 OpenValut SSH Agent 引用';

  @override
  String get sshConfigAlreadyPresent => 'OpenValut SSH Agent 引用已存在';

  @override
  String get copiedToClipboard => '成功复制到剪贴板';

  @override
  String get noTitle => '(无标题)';

  @override
  String get noUsername => '(空空如也)';

  @override
  String get filterCustomize => '自定义…';

  @override
  String get swipeCopyPassword => '复制密码';

  @override
  String get swipeCopyUsername => '复制登录帐号';

  @override
  String get copyUsernameNotExists => '此条目缺少用户名';

  @override
  String get copyPasswordNotExists => '此条目缺少密码';

  @override
  String get doneCopiedPassword => '密码已复制到剪贴板。';

  @override
  String get doneCopiedUsername => '帐号已复制到剪贴板。';

  @override
  String get doneCopiedField => '复制成功！';

  @override
  String copiedFieldToClipboard(Object fieldName) {
    return '$fieldName 已在剪贴板待命。';
  }

  @override
  String copiedFieldEmpty(Object fieldName) {
    return '$fieldName 是空的。';
  }

  @override
  String get emptyPasswordVaultPlaceholder => '这里还没有密码呢';

  @override
  String get emptyPasswordVaultButtonLabel => '创建第一个密码';

  @override
  String get loading => '正在通过网络加载文件';

  @override
  String get loadingFile => '正在解锁文件';

  @override
  String get internalFile => '内部文件';

  @override
  String get internalFileSubtitle => '过去使用本应用创建的密码库';

  @override
  String get filePicker => '文件选择器';

  @override
  String get filePickerSubtitle => '从设备存储打开文件。';

  @override
  String get credentialsAppBarTitle => '解锁密码';

  @override
  String get credentialLabel => '输入这个数据库的解锁密码';

  @override
  String get masterPasswordInputLabel => '用主密码保护您的密码库';

  @override
  String get masterPasswordEmptyValidator => '欢迎回来！请在这里输入主密码';

  @override
  String get masterPasswordIncorrectValidator => '该密码无效';

  @override
  String get useKeyFile => '使用密钥文件';

  @override
  String get saveMasterPasswordBiometric => '使用生物识别保存密码？';

  @override
  String get close => '关闭';

  @override
  String get addNewPassword => '添加新密码';

  @override
  String get errorOpenFileInvalidFileStructureTitle => '打开失败，检查一下文件？';

  @override
  String errorOpenFileInvalidFileStructureBody(Object fileName) {
    return '无法打开 ($fileName)。请选择一个有效的KDBX文件，或创建一个新的。';
  }

  @override
  String get errorOpenFileAlreadyOpenTitle => '文件已被打开';

  @override
  String errorOpenFileAlreadyOpenBody(
    Object databaseName,
    Object openFileSource,
    Object newFileSource,
  ) {
    return '所选数据库 $databaseName 已经从 $openFileSource 打开(试图从 $newFileSource 打开)';
  }

  @override
  String get loadFromUrl => '从链接下载';

  @override
  String get loadFromUrlEnterUrl => '输入网址';

  @override
  String get loadFromUrlErrorEnterFullUrl => '请输入以 http:// 或 https:// 开头的完整链接';

  @override
  String get loadFromUrlErrorInvalidUrl => '请输入一个有效的链接。';

  @override
  String get linuxAppArmorWarning =>
      'OpenValut 需要访问 Secret Service 的权限才能保存云端验证信息\n请在终端运行以下命令：';

  @override
  String get cancel => '取消';

  @override
  String get errorLoadFileFromSourceTitle => '打开文件时出错。';

  @override
  String errorLoadFileFromSourceBody(Object source, Object error) {
    return '无法打开 $source \n$error';
  }

  @override
  String get errorUnlockFileTitle => '无法打开文件';

  @override
  String errorUnlockFileBody(Object error) {
    return '尝试打开文件时发生未知错误。 $error';
  }

  @override
  String get dialogContinue => '下一步';

  @override
  String get dialogSendErrorReport => '发送错误报告';

  @override
  String get dialogReportErrorForum => '在论坛中报告错误';

  @override
  String get groupFilterDescription => '选择要显示的分组';

  @override
  String get groupFilterSelectAll => '全选';

  @override
  String get groupFilterDeselectAll => '取消全选';

  @override
  String get createSubgroup => '创建下级分组';

  @override
  String get editAction => '编辑';

  @override
  String get mailboxEnableLabel => '(重新)启用';

  @override
  String get mailboxEnableHint => '继续接收邮件';

  @override
  String get mailboxDisableLabel => '停用';

  @override
  String get mailboxDisableHint => '停止接收邮件';

  @override
  String get mailListNoMail => '您还没有部署任何代理邮箱';

  @override
  String mailboxLabelPrefixForEntry(Object entryLabel) {
    return '条目: $entryLabel';
  }

  @override
  String mailboxLabelPrefixUnknownEntry(Object entryUuid) {
    return '未知条目: $entryUuid';
  }

  @override
  String mailboxLabelPrefixCreatedAt(Object dateTime) {
    return '创建于： $dateTime';
  }

  @override
  String get masterPasswordDescription => '主密码用于加密您的密码数据库。请务必记住它，因为此密码无法恢复。';

  @override
  String get unsavedChangesWarningTitle => '稍等！';

  @override
  String get unsavedChangesWarningBody => '存在未保存的修改，要取消修改吗？';

  @override
  String get unsavedChangesDiscardActionLabel => '放弃修改';

  @override
  String get deletePermanentlyAction => '彻底删除';

  @override
  String get restoreFromRecycleBinAction => '恢复';

  @override
  String get deleteAction => '删除';

  @override
  String get deletedEntry => '条目已删除';

  @override
  String get successfullyDeletedGroup => '已删除分组。';

  @override
  String get undoButtonLabel => '撤消';

  @override
  String get saveButtonLabel => '保存';

  @override
  String get webDavSettings => '配置WebDAV';

  @override
  String get webDavUrlLabel => '链接地址';

  @override
  String get webDavUrlHelperText => 'WebDAV服务的Url';

  @override
  String get webDavUrlValidatorError => '请输入网址';

  @override
  String get webDavUrlValidatorInvalidUrlError =>
      '请输入以 http:// 或 https:// 开头的完整链接';

  @override
  String get webDavAuthUser => '用户名';

  @override
  String get webDavopenvalutword => '密码';

  @override
  String get mergeSuccessDialogTitle => '合并密码数据库成功';

  @override
  String mergeSuccessDialogMessage(Object fileName, Object mergeSummary) {
    return '保存 $fileName 时检测到冲突, 它已成功与远程文件合并: \n\n$mergeSummary';
  }

  @override
  String forDetailsVisitUrl(Object url) {
    return '详情请访问 $url';
  }

  @override
  String get openvalutCloudAuthEmailInputLabel => '请输入邮箱地址以开始注册或登录';

  @override
  String get openvalutCloudAuthEmailInvalid => '请输入有效的电子邮件地址。';

  @override
  String get openvalutCloudAuthConfirmEmailButtonLabel => '请确认地址';

  @override
  String get openvalutCloudAuthConfirmEmail => '请检查您的邮箱以确认您的代理邮件地址。';

  @override
  String get openvalutCloudAuthConfirmEmailExplain =>
      '保持此界面打开，直到您成功打开从电子邮件收到的链接。';

  @override
  String get openvalutCloudAuthResendExplain =>
      '如果您没有收到电子邮件，请检查您的垃圾邮件。您也可以重新发送请求。';

  @override
  String get openvalutCloudAuthResendButtonLabel => '重新发送请求';

  @override
  String permanentlyDeleteEntryConfirm(Object title) {
    return '这将永久删除 $title 条目，且不能撤消。确定要这么做吗？';
  }

  @override
  String get permanentlyDeletedEntrySnackBar => '条目已被彻底删除！';

  @override
  String get initialNewGroupName => '新建分组';

  @override
  String get deleteGroupErrorTitle => '删除失败！';

  @override
  String get deleteGroupErrorBodyContainsGroup => '此分组中还包含分组！您目前只能删除空群组。';

  @override
  String get deleteGroupErrorBodyContainsEntries => '此分组中还包含密码！您目前只能删除空群组。';

  @override
  String get groupListAppBarTitle => '分组';

  @override
  String get groupListFilterAppbarTitle => '按分组筛选';

  @override
  String get clearQuickUnlock => '清除生物识别记录（如指纹）';

  @override
  String get clearQuickUnlockSubtitle => '删除已保存的主密码';

  @override
  String get unlock => '解锁';

  @override
  String get closePasswordFiles => '关闭密码文件';

  @override
  String get clearQuickUnlockSuccess => '已取消生物识别解锁';

  @override
  String get diacOptIn => '应用内消息';

  @override
  String get diacOptInSubtitle => '会偶尔连接网络获取新闻和问卷并在应用内显示';

  @override
  String browserAutofillThirdPartyModeTitle(String browserName) {
    return 'Enable AutoFill in $browserName';
  }

  @override
  String browserAutofillThirdPartyModeSubtitle(String browserName) {
    return '$browserName currently uses its own password manager. Tap to open its settings and select “Autofill using another service”, then restart $browserName.';
  }

  @override
  String get enableAutofillDebug => '启用自动填充的调试模式';

  @override
  String get enableAutofillDebugSubtitle => '为每个输入字段显示调试信息叠加层';

  @override
  String get createPasswordDatabase => '新建密码库';

  @override
  String get nameNewPasswordDatabase => '为您的新密码库命名';

  @override
  String get validatorNameMissing => '请为您的新密码库起一个名字！';

  @override
  String get masterPasswordHelpText => '设置一个安全的主密码，请务必牢记！';

  @override
  String get inputMasterPasswordText => '主密码';

  @override
  String get masterPasswordMissingCreate => '请输入一个您能记住的足够安全的密码';

  @override
  String get createDatabaseAction => '创建密码库';

  @override
  String get databaseExistsError => '已有同名文件存在';

  @override
  String databaseExistsErrorDescription(Object filePath) {
    return '创建数据库失败，已有同名文件，请尝试换一个名字。\n出错位置: $filePath';
  }

  @override
  String get databaseCreateDefaultName => '我的密码';

  @override
  String get preferenceDynamicLoadIcons => '联网加载图标';

  @override
  String preferenceDynamicLoadIconsSubtitle(Object urlFieldName) {
    return '将会向$urlFieldName发送未加密的http请求来获取网页图标';
  }

  @override
  String passwordScore(Object score) {
    return '密码强度: $score / 4';
  }

  @override
  String get passwordStrengthVeryWeak => '极弱';

  @override
  String get passwordStrengthWeak => '弱';

  @override
  String get passwordStrengthFair => '一般';

  @override
  String get passwordStrengthStrong => '强';

  @override
  String get passwordStrengthVeryStrong => '极强';

  @override
  String get passwordStrengthHintVeryWeak => '密码太短或太常见，建议加长并混合字母、数字和符号。';

  @override
  String get passwordStrengthHintWeak => '强度仍偏低，建议再多几位字符或避免常见词语。';

  @override
  String get passwordStrengthHintFair => '还可以，换成不常见的短语会更安全。';

  @override
  String get passwordStrengthHintStrong => '强度不错。';

  @override
  String get passwordStrengthHintVeryStrong => '非常强。';

  @override
  String get entryInfoFile => '文件：';

  @override
  String get entryInfoGroup => '分组:';

  @override
  String get entryInfoLastModified => '最后修改时间：';

  @override
  String movedEntryToGroup(Object groupName) {
    return '移动条目到 $groupName';
  }

  @override
  String sizeBytesStoredopenvalutCloud(Object count) {
    return '$count 字节，已保存到OpenValut Cloud';
  }

  @override
  String sizeBytes(Object count) {
    return '$count 字节';
  }

  @override
  String get entryAttachmentSizeWarning =>
      '附件可以是任何文件，它将与密码文件结合，这会大大增加打开/保存密码所需的时间。';

  @override
  String get iconPngSizeWarning => '自定义图标将合并入密码数据库。这会增加打开/保存密码所需的时间。';

  @override
  String get notPngError => '只支持PNG格式';

  @override
  String get entryAddField => '添加项目';

  @override
  String get entryCustomField => '自定义字段';

  @override
  String get entryCustomFieldTitle => '添加新自定义字段';

  @override
  String get entryCustomFieldInputLabel => '输入字段名称';

  @override
  String get swipeCopyField => '复制项目';

  @override
  String get fieldRename => '重命名';

  @override
  String get fieldGeneratePassword => '生成随机密码…';

  @override
  String get fieldProtect => '锁定';

  @override
  String get fieldUnprotect => '取消锁定';

  @override
  String get fieldPresent => '显示二维码';

  @override
  String get fieldGenerateEmail => '生成电子邮箱地址';

  @override
  String get onboardingBackToOnboarding => '时间回溯';

  @override
  String get onboardingBackToOnboardingSubtitle => '回到初始引导界面';

  @override
  String get onboardingHeadline => '守护您的密码安全！';

  @override
  String get onboardingQuestion =>
      '您之前用过本软件\n或其他兼容KeePass的密码管理器吗？\n（如KeepassDX、KeepassXC等）';

  @override
  String get onboardingYesOpenPasswords => '使用已有的KDBX文件';

  @override
  String get onboardingNoCreate => '新建KDBX密码库';

  @override
  String get backupButton => '保存到云端';

  @override
  String get dismissBackupButton => '不需要';

  @override
  String backupWarningMessage(Object databasename) {
    return '$databasename 密码库中的密码没有上传到云端！';
  }

  @override
  String get saveAs => '保存到…';

  @override
  String get saving => '正在保存…';

  @override
  String get increaseValue => '增加';

  @override
  String get decreaseValue => '减少';

  @override
  String get resetValue => '重置';

  @override
  String cloudStorageAppBarTitle(Object cloudStorageName) {
    return '云存储 - $cloudStorageName';
  }

  @override
  String get cloudStorageLogInCaption => '即将为您打开OpenValut验证界面，验证后即可获取您的数据';

  @override
  String get cloudStorageLogInCode => '输入验证码';

  @override
  String launchUrlError(Object url) {
    return '无法访问链接: $url';
  }

  @override
  String cloudStorageLogInActionLabel(Object cloudStorageName) {
    return '登录 $cloudStorageName 账号';
  }

  @override
  String cloudStorageAuthCodeDialogTitle(Object cloudStorageName) {
    return '$cloudStorageName - 身份验证';
  }

  @override
  String get cloudStorageAuthCodeLabel => '身份验证码';

  @override
  String get cloudStorageAuthErrorTitle => '抱歉，验证出错了，再试一次？';

  @override
  String cloudStorageAuthErrorMessage(
    Object cloudStorageName,
    Object errorMessage,
  ) {
    return '尝试认证到 $cloudStorageName 时出错： \n$errorMessage';
  }

  @override
  String get cloudStorageSearchBoxLabel => '路漫漫其修远兮…';

  @override
  String cloudStorageItemsInFolder(Object itemCount) {
    return '共有 $itemCount 个条目。';
  }

  @override
  String get mailSubject => '主题';

  @override
  String get mailFrom => '发件人：';

  @override
  String get mailDate => '日期:';

  @override
  String get mailMailbox => '全部代理邮箱';

  @override
  String get mailNoData => '没有内容，或被加密/已损坏';

  @override
  String get mailMailboxesTitle => '全部代理邮箱';

  @override
  String get mailboxCreateButtonLabel => '新建';

  @override
  String get mailboxNameInputDialogTitle => '为新邮箱命名（可选）';

  @override
  String get mailboxNameInputLabel => '（内部）名称';

  @override
  String get mailScreenTitle => 'OpenValut - 代理邮箱';

  @override
  String get mailTabBarTitleMailbox => '邮箱列表';

  @override
  String get mailTabBarTitleMail => '邮件列表';

  @override
  String get mailMailboxListEmpty => '还没有部署任何代理邮箱';

  @override
  String mailMailboxAddressCopied(Object mailboxAddress) {
    return '已复制邮箱地址到剪贴板: $mailboxAddress';
  }

  @override
  String get errorWhileSavingTitle => '保存时出错！';

  @override
  String errorWhileSavingBody(Object errorMessage) {
    return '无法保存文件: $errorMessage';
  }

  @override
  String get databaseDoesNotSupportSaving =>
      '抱歉，无法保存到此数据库。请打开本地数据库文件，或者选择“另存为”。';

  @override
  String get otpInvalidKeyTitle => '无效密钥！';

  @override
  String get otpInvalidKeyBody => '此代码无效，请检查您的输入';

  @override
  String get otpUnsupportedMigrationTitle => 'Unsupported OTP Migration';

  @override
  String otpUnsupportedMigrationBody(Object uriCount) {
    return 'We currently only support single item migrations. Got $uriCount';
  }

  @override
  String get otpPromptTitle => '基于时间的身份认证';

  @override
  String get otpPromptHelperText => '请输入TOTP密钥';

  @override
  String otpErrorMessageGeneration(Object errorMessage) {
    return '生成邀请码时出错: $errorMessage';
  }

  @override
  String get otpCopySecretActionLabel => '复制此密钥';

  @override
  String get otpEntryLabel => '一次性口令（TOTP）';

  @override
  String get entryFieldProtected => '受保护区域。点击以显示。';

  @override
  String get entryFieldActionRevealField => '展开受保护区域';

  @override
  String get entryAttachmentOpenActionLabel => '打开';

  @override
  String get entryAttachmentShareActionLabel => '分享';

  @override
  String get entryAttachmentShareSubject => '附件';

  @override
  String get entryAttachmentSaveActionLabel => '保存到设备';

  @override
  String get entryAttachmentRemoveActionLabel => '移除';

  @override
  String entryAttachmentRemoveConfirm(Object attachmentLabel) {
    return '确定要删除 $attachmentLabel 吗？';
  }

  @override
  String get entryRenameFieldPromptTitle => '重命名字段';

  @override
  String get removerecentfile => '移除';

  @override
  String get entryRenameFieldPromptLabel => '输入新字段名称';

  @override
  String get promptDialogPasteActionTooltip => '从剪贴板中粘贴';

  @override
  String get promptDialogPasteHint => '小贴士：您可以使用左侧按钮进行粘贴';

  @override
  String get genericErrorDialogTitle => '处理操作时出错';

  @override
  String genericErrorDialogBody(Object errorMessage) {
    return '发生意外错误。 $errorMessage';
  }

  @override
  String get saveAsEntryLocalFile => '本地文件';

  @override
  String get fileTypePngs => '图像(png)';

  @override
  String get selectIconDialogAction => '选择图标';

  @override
  String get retryDialogActionLabel => '重试';

  @override
  String errorDuringNetworkCall(Object errorMessage) {
    return '调用api时出错。 $errorMessage';
  }

  @override
  String get passwordFilterHideDeleted => '隐藏已删除条目';

  @override
  String get passwordFilterOnlyDeleted => '已删除条目';

  @override
  String passwordFilterPrefixForOneGroup(Object groupName) {
    return '群组: $groupName';
  }

  @override
  String passwordFilterPrefixForMultipleGroups(Object groupCount) {
    return '自定义筛选器 ($groupCount 组)';
  }

  @override
  String get menuItemopenvalutCloudAuthenticate => '使用 OpenValut Cloud 验证';

  @override
  String get menuItemopenvalutCloudMailboxes => 'OpenValut - 代理邮箱';

  @override
  String changesWithoutSaving(Object fileName) {
    return '您对 \"$fileName\"进行了修改，但其不支持写入更改。';
  }

  @override
  String get changesSaveLocally => '保存到本地';

  @override
  String get clearColor => '清除颜色';

  @override
  String get databaseRenameInputLabel => '输入数据库名称';

  @override
  String get databasePath => '路径';

  @override
  String get databaseColor => '颜色';

  @override
  String get databaseColorChoose => '选择一种颜色用以区分多个文件';

  @override
  String get databaseAutofill => 'AutoFill';

  @override
  String get databaseAutofillSubtitle =>
      'Offer this database\'s entries when apps and websites ask for a password.';

  @override
  String get databaseAutofillCopyWarning =>
      'An encrypted copy of this database is kept for AutoFill until you switch it off, or close the database.';

  @override
  String get databaseAutofillNeedsKdbx4 =>
      'AutoFill needs KDBX 4. Upgrade this database below to use it.';

  @override
  String get databaseAutofillSystemHint =>
      'Also turn OpenValut on in Settings › General › AutoFill & Passwords.';

  @override
  String get databaseKdbxVersion => 'KDBX文件版本';

  @override
  String databaseKdbxUpgradeVersion(Object versionName) {
    return '升级到 $versionName';
  }

  @override
  String get databaseKdbxUpgradeSuccessful => '升级成功，文件已保存';

  @override
  String get databaseReload => '重新载入并合并';

  @override
  String progressStatus(Object statusProgress) {
    return '状态: $statusProgress';
  }

  @override
  String finishedMerge(Object status) {
    return '已完成合并 $status';
  }

  @override
  String get closeAndLockFile => '关闭/锁定';

  @override
  String get openvalutHomeScreenTagline => '密码管理器，开放源代码，可在所有平台上使用。';

  @override
  String get addNewPasswordButtonLabel => '添加新的密码';

  @override
  String get unnamedEntryPlaceholder => '(未命名)';

  @override
  String get unnamedGroupPlaceholder => '(未命名)';

  @override
  String get unnamedFilePlaceholder => '(未命名)';

  @override
  String get editGroupScreenTitle => '编辑群组';

  @override
  String get editGroupGroupNameLabel => '群组名称';

  @override
  String get files => '文件';

  @override
  String get newGroupDialogTitle => '新建分组';

  @override
  String get newGroupDialogInputLabel => '新群组名称';

  @override
  String get groupActionShowPasswords => '显示密码';

  @override
  String get groupActionDelete => '删除';

  @override
  String get logoutTooltip => '登出';

  @override
  String get successfullyDeletedFileCloudStorage => '删除文件成功';

  @override
  String shareDialogTitle(Object fileName) {
    return '发送 $fileName';
  }

  @override
  String get shareFileActionLabel => '分享';

  @override
  String get shareTokenListEmptyScreenPlaceholder => '文件尚未共享。';

  @override
  String get shareTokenNoLabel => '无 标签/说明';

  @override
  String get shareTokenReadWrite => '读/写';

  @override
  String get shareTokenReadOnly => '只读';

  @override
  String get shareCreateTokenDialogTitle => '共享文件';

  @override
  String get shareCreateTokenReadOnly => '只读';

  @override
  String get shareCreateTokenReadOnlyHelpText => '不允许保存更改';

  @override
  String get shareCreateTokenLabelText => '说明';

  @override
  String get shareCreateTokenLabelHint => '分享给我的朋友';

  @override
  String get shareCreateTokenLabelHelp => '可选标签用以区分共享口令';

  @override
  String get shareCreateTokenSuccess => '成功创建私密共享口令';

  @override
  String get sharePresentDialogTitle => '通过私密分享共令分享文件';

  @override
  String get sharePresentDialogHelp =>
      '使用以下共享口令用户可以访问数据库文件。他们需要密码 和/或 密钥文件来打开它。';

  @override
  String get sharePresentToken => '共享口令';

  @override
  String get sharePresentCopied => '共享口令已复制到剪贴板';

  @override
  String get openvalutCloudOpenWithShareCodeTooltip => '使用私密共享口令打开';

  @override
  String get openvalutCloudShareFileActionLabel => '分享';

  @override
  String get preferenceopenvalutCloudAttachmentTitle => '使用OpenValut Cloud附件';

  @override
  String get preferenceopenvalutCloudAttachmentSubtitle =>
      '将附件加密保存到OpenValut Cloud。';

  @override
  String get shareCodeInputDialogTitle => '输入私密共享口令';

  @override
  String get shareCodeInputDialogScan => '扫描二维码';

  @override
  String get shareCodeInputLabel => '私密共享口令';

  @override
  String get shareCodeInputHelperText => '如果您收到了一个共享口令，请将其粘贴在上面。';

  @override
  String get shareCodeOpen => '收到了OpenValut Cloud的共享口令？';

  @override
  String get shareCodeOpenScreenTitle => '通过共享口令加载文件';

  @override
  String get shareCodeLoadingProgress => '正在加载文件…';

  @override
  String get shareCodeOpenFileButtonLabel => '打开';

  @override
  String get shareCodeOpenInstallAppCaption => '想用我们的本地应用程序打开此文件吗？';

  @override
  String get shareCodeOpenAnotherAppCaption => '想在其他设备上打开此文件吗？';

  @override
  String get shareCodeOpenInstallAppButtonLabel => '安装应用';

  @override
  String get shareCodeOpenShowCodeButtonLabel => '显示共享口令';

  @override
  String get changeMasterPasswordActionLabel => '更改主密码';

  @override
  String get changeMasterPasswordFormSubmit => '使用新密码保存';

  @override
  String get changeMasterPasswordSuccess => '成功保存主密码。';

  @override
  String get changeMasterPasswordScreenTitle => '更改主密码';

  @override
  String get changeMasterPasswordConfirmLabel => 'Repeat new password';

  @override
  String get changeMasterPasswordCleanupTitle =>
      'Password changed — one more step';

  @override
  String get changeMasterPasswordCleanupDevices =>
      '• Other devices: lock the vault and unlock it again with the new master password. Sessions remembered with the old password can no longer decrypt the vault.';

  @override
  String get changeMasterPasswordCleanupBackups =>
      '• Backups and exported copies made before the change are still encrypted with the old password — open and re-save them, or delete them.';

  @override
  String get changeMasterPasswordCleanupQuickUnlock =>
      '• On this device, quick unlock and remembered passwords were cleared; the new password will be required at the next unlock.';

  @override
  String get changeMasterPasswordRotationFailedTitle =>
      'Could not re-encrypt the cloud vault';

  @override
  String changeMasterPasswordRotationFailedBody(Object error) {
    return 'The master password was changed on this device, but re-encrypting the vault on the server failed: $error. Open \"Change Master Password\" again and enter the same new password once more to retry.';
  }

  @override
  String finishedReload(Object status) {
    return 'Finished Reload $status';
  }

  @override
  String get openvalutCloudAuthClickedLink => '我已收到电子邮件并访问了链接';

  @override
  String get openvalutCloudAuthNotConfirmed =>
      '邮箱地址尚未确认。请确保点击您收到的电子邮件中的链接并通过验证以便确认您的电子邮箱地址。';

  @override
  String get getHelpButton => '在论坛中寻求帮助';

  @override
  String get shortcutCopyUsername => '复制登录帐号';

  @override
  String get shortcutCopyPassword => '复制密码';

  @override
  String get shortcutCopyTotp => '复制TOTP码';

  @override
  String get shortcutMoveUp => '选择上一个密码';

  @override
  String get shortcutMoveDown => '选择下一个密码';

  @override
  String get shortcutGeneratePassword => '生成随机密码';

  @override
  String get shortcutCopyUrl => '复制链接';

  @override
  String get shortcutOpenUrl => '打开链接';

  @override
  String get shortcutCancelSearch => '取消搜索';

  @override
  String get shortcutShortcutHelp => '键盘快捷键帮助';

  @override
  String get shortcutHelpTitle => '快捷键';

  @override
  String unexpectedError(String error) {
    return '意外错误: $error';
  }

  @override
  String get googleDriveMorePermissionsRequired =>
      'Additional permissions needed to access Google Drive.';

  @override
  String get googleDriveRequestPermissionButtonLabel => 'Request Permissions';

  @override
  String get scanQrCodeTitle => 'Scan QR Code.';
}

/// The translations for Chinese, as used in Taiwan (`zh_TW`).
class AppLocalizationsZhTw extends AppLocalizationsZh {
  AppLocalizationsZhTw() : super('zh_TW');

  @override
  String get entryAddAttachment => '新增附件';

  @override
  String get fieldUserName => '帳號名稱';

  @override
  String get fieldPassword => '密碼';

  @override
  String get fieldWebsite => '網站';

  @override
  String get fieldTitle => '顯示標題';

  @override
  String get fieldTotp => '單次密碼（OTP，依時間變化）';

  @override
  String get english => '英文';

  @override
  String get german => '德文';

  @override
  String get russian => '俄文';

  @override
  String get ukrainian => '烏克蘭文';

  @override
  String get lithuanian => '立陶宛文';

  @override
  String get french => '法文';

  @override
  String get spanish => '西班牙文';

  @override
  String get indonesian => '印尼文';

  @override
  String get turkish => '土耳其文';

  @override
  String get hebrew => '希伯來文';

  @override
  String get italian => '義大利文';

  @override
  String get chineseSimplified => '簡體中文';

  @override
  String get chineseTraditional => '正體中文';

  @override
  String get portugueseBrazilian => '葡萄牙文（巴西）';

  @override
  String get slovak => '斯洛伐克語';

  @override
  String get dutch => '荷蘭語';

  @override
  String get selectItem => '選取';

  @override
  String get selectKeepassFile => 'OpenValut - 選取 KeePass 格式檔';

  @override
  String get selectKeepassFileLabel => '請選擇 KeePass（.kdbx）格式檔。';

  @override
  String get createNewFile => '建立新密碼檔';

  @override
  String get openLocalFile => '開啟\n本機檔案';

  @override
  String get openFile => '開啟檔案';

  @override
  String get loadFromDropdownMenu => '從其他來源加載...';

  @override
  String get quickUnlockingFiles => '快速解鎖…';

  @override
  String openFileProgress(Object fileName, Object current, Object totalCount) {
    return '$fileName';
  }

  @override
  String loadFrom(String cloudStorageName) {
    return '開啟雲端檔案 $cloudStorageName';
  }

  @override
  String get loadFromRemoteUrl => '自 URL 開啟 kdbx 檔';

  @override
  String get createNewKeepass => 'KeePass 新手嗎？\n建立新的檔案資料庫';

  @override
  String get labelLastOpenFiles => '上次開啟檔案：';

  @override
  String get noFilesHaveBeenOpenYet => '尚未開啟任何檔案。';

  @override
  String get preferenceSelectLanguage => '選擇語言';

  @override
  String get preferenceLanguage => '語言設定';

  @override
  String get preferenceTextScaleFactor => '文字尺寸';

  @override
  String get preferenceVisualDensity => '行距';

  @override
  String get preferenceTheme => '佈景主題';

  @override
  String get preferenceThemeLight => '淺色';

  @override
  String get preferenceThemeDark => '深色';

  @override
  String get preferenceSystemDefault => '系統預設';

  @override
  String get preferenceDefault => '預設值';

  @override
  String get lockAllFiles => '鎖定所有開啟中的檔案';

  @override
  String get preferenceAllowScreenshots => '允許在 App 畫面截圖';

  @override
  String get preferenceEnableAutoFill => '啟用自動填入';

  @override
  String get enableAutofillSuggestionBanner => '您可以啟用自動填充來填寫其他應用程序中的字段！';

  @override
  String get dismissAutofillSuggestionBannerButton => '關閉';

  @override
  String get enableAutofillSuggestionBannerButton => '啟用！';

  @override
  String get preferenceAutoFillDescription => '僅 Android Oreo（8.0）以上支援此功能。';

  @override
  String get preferenceTitle => '偏好設定';

  @override
  String get preferencesSearchFields => '自定義搜索字段';

  @override
  String get preferencesSearchFieldPromptTitle => '搜索字段';

  @override
  String get aboutAppName => 'OpenValut';

  @override
  String get aboutLinkFeedback => '歡迎指教！';

  @override
  String get aboutLinkVisitWebsite => '記得上我們的網站';

  @override
  String get aboutLinkGitHub => '還有開源專案';

  @override
  String aboutLogFile(String logFilePath) {
    return '記錄檔： $logFilePath';
  }

  @override
  String get aboutLinkContributors => '顯示貢獻者';

  @override
  String get unableToLaunchUrlTitle => '無法開啟 URL';

  @override
  String unableToLaunchUrlDescription(Object url, Object openError) {
    return '無法開啟 $url： $openError';
  }

  @override
  String get unableToLaunchUrlNoHandler => '沒有適合開啟該 URL 的軟體';

  @override
  String launchedUrl(Object url) {
    return '開啟的 URL：$url';
  }

  @override
  String get menuItemGeneratePassword => '產生密碼';

  @override
  String get menuItemPreferences => '偏好設定';

  @override
  String get menuItemOpenAnotherFile => '開啟其他檔案';

  @override
  String get menuItemCheckForUpdates => '檢查更新';

  @override
  String get menuItemSupport => '發送日誌';

  @override
  String get menuItemSupportSubtitle => '通過電子郵件發送日誌';

  @override
  String get menuItemForum => '支援論壇';

  @override
  String get menuItemForumSubtitle => '報告問題並獲得幫助';

  @override
  String get menuItemHelp => '說明';

  @override
  String get menuItemHelpSubtitle => '開啟說明文件';

  @override
  String get menuItemAbout => '關於';

  @override
  String get actionOpenUrl => '開啟 URL';

  @override
  String get passwordPlainText => '顯示密碼';

  @override
  String get generatorPassword => '密碼';

  @override
  String get generatePassword => '產生密碼';

  @override
  String get doneButtonLabel => '完成';

  @override
  String get useAsDefault => '存為預設值';

  @override
  String get characterSetLowerCase => '小寫英文（a-z）';

  @override
  String get characterSetUpperCase => '大寫英文（A-Z）';

  @override
  String get characterSetNumeric => '數字（0-9）';

  @override
  String get characterSetUmlauts => '變音字母（ä）';

  @override
  String get characterSetSpecial => '特殊字元（@%+）';

  @override
  String get length => '字數';

  @override
  String get customLength => '自訂字數';

  @override
  String customLengthHelperText(Object customMinLength) {
    return '僅供超過 $customMinLength 字時使用';
  }

  @override
  String savedFiles(int numFiles, Object files) {
    final intl.NumberFormat numFilesNumberFormat =
        intl.NumberFormat.compactLong(
          locale: localeName,
        );
    final String numFilesString = numFilesNumberFormat.format(numFiles);

    String _temp0 = intl.Intl.pluralLogic(
      numFiles,
      locale: localeName,
      other: '已儲存 $numFilesString 個檔案： $files',
    );
    return '$_temp0';
  }

  @override
  String get manageGroups => '管理群組';

  @override
  String get lockFiles => '鎖住檔案';

  @override
  String get searchHint => '搜尋';

  @override
  String get searchButtonLabel => '搜尋';

  @override
  String get filterButtonLabel => '篩選群組';

  @override
  String get clear => '清除篩選條件';

  @override
  String get autofillFilterPrefix => '篩選：';

  @override
  String get autofillPrompt => '選擇密碼以填入';

  @override
  String get copiedToClipboard => '複製到剪貼簿。';

  @override
  String get noTitle => '（無顯示標題）';

  @override
  String get noUsername => '（無帳號名稱）';

  @override
  String get filterCustomize => '自訂篩選 …';

  @override
  String get swipeCopyPassword => '複製密碼';

  @override
  String get swipeCopyUsername => '複製帳號';

  @override
  String get copyUsernameNotExists => '此條目沒有定義用戶名。';

  @override
  String get copyPasswordNotExists => '此條目沒有定義密碼。';

  @override
  String get doneCopiedPassword => '已將密碼複製到剪貼簿。';

  @override
  String get doneCopiedUsername => '已將帳號複製到剪貼簿。';

  @override
  String get doneCopiedField => '已複製。';

  @override
  String copiedFieldToClipboard(Object fieldName) {
    return '$fieldName 已被複製';
  }

  @override
  String copiedFieldEmpty(Object fieldName) {
    return '$fieldName 為空。';
  }

  @override
  String get emptyPasswordVaultPlaceholder => '目前資料庫中沒有任何密碼。';

  @override
  String get emptyPasswordVaultButtonLabel => '記下第一組密碼';

  @override
  String get loading => '正在加載';

  @override
  String get loadingFile => '檔案讀取中 …';

  @override
  String get internalFile => '內部檔案';

  @override
  String get internalFileSubtitle => '先前以 OpenValut 建立的資料庫';

  @override
  String get filePicker => '選擇檔案';

  @override
  String get filePickerSubtitle => '自本機開啟檔案。';

  @override
  String get credentialsAppBarTitle => '驗證資訊';

  @override
  String get credentialLabel => '輸入密碼，開啟資料庫';

  @override
  String get masterPasswordInputLabel => '密碼';

  @override
  String get masterPasswordEmptyValidator => '請輸入密碼。';

  @override
  String get masterPasswordIncorrectValidator => '密碼錯誤';

  @override
  String get useKeyFile => '使用金鑰檔';

  @override
  String get saveMasterPasswordBiometric => '以生物驗證儲存檔案密碼？';

  @override
  String get close => '關閉';

  @override
  String get addNewPassword => '新增密碼';

  @override
  String get errorOpenFileAlreadyOpenTitle => '這個檔案早已開啟了';

  @override
  String errorOpenFileAlreadyOpenBody(
    Object databaseName,
    Object openFileSource,
    Object newFileSource,
  ) {
    return '您選的資料庫 $databaseName 早已自$openFileSource 開啟（您正試圖從$newFileSource 再度開啟）';
  }

  @override
  String get loadFromUrl => '從網址下載';

  @override
  String get loadFromUrlEnterUrl => '輸入網址';

  @override
  String get loadFromUrlErrorEnterFullUrl => '請輸入以 http:// 或 https:// 開頭的完整網址';

  @override
  String get loadFromUrlErrorInvalidUrl => '請輸入有效網址。';

  @override
  String get linuxAppArmorWarning =>
      'OpenValut 需要與 Secret Service 通信以存儲雲存儲憑據的權限。\n請運行以下命令：';

  @override
  String get cancel => '取消';

  @override
  String get errorLoadFileFromSourceTitle => '打開文件時出錯。';

  @override
  String errorLoadFileFromSourceBody(Object source, Object error) {
    return '無法打開 $source\n$error';
  }

  @override
  String get errorUnlockFileTitle => '無法開啟檔案';

  @override
  String errorUnlockFileBody(Object error) {
    return '開啟檔案時發生不明錯誤：$error';
  }

  @override
  String get dialogContinue => '繼續';

  @override
  String get dialogSendErrorReport => '發送錯誤報告';

  @override
  String get dialogReportErrorForum => '在論壇/幫助中報告錯誤';

  @override
  String get groupFilterDescription => '選擇要顯示的群組（包含子群組）';

  @override
  String get groupFilterSelectAll => '全選';

  @override
  String get groupFilterDeselectAll => '全部不選';

  @override
  String get createSubgroup => '建立子群組';

  @override
  String get editAction => '編輯';

  @override
  String get mailboxEnableLabel => '（重新）啟用';

  @override
  String get mailboxEnableHint => '繼續接收電子郵件';

  @override
  String get mailboxDisableLabel => '禁用';

  @override
  String get mailboxDisableHint => '不再接收電子郵件';

  @override
  String get mailListNoMail => '您還沒有任何電子郵件。';

  @override
  String mailboxLabelPrefixUnknownEntry(Object entryUuid) {
    return '未知條目: $entryUuid';
  }

  @override
  String mailboxLabelPrefixCreatedAt(Object dateTime) {
    return '創建於: $dateTime';
  }

  @override
  String get masterPasswordDescription => '主密碼用於安全地加密您的密碼數據庫。 請務必記住它，它無法被恢復。';

  @override
  String get unsavedChangesWarningTitle => '未保存的更改';

  @override
  String get unsavedChangesWarningBody => '仍有未保存的更改。 是否要放棄更改？';

  @override
  String get unsavedChangesDiscardActionLabel => '放棄更改';

  @override
  String get deletePermanentlyAction => '永久刪除';

  @override
  String get restoreFromRecycleBinAction => '恢復';

  @override
  String get deleteAction => '刪除';

  @override
  String get deletedEntry => '已刪除條目。';

  @override
  String get successfullyDeletedGroup => '群組已刪除。';

  @override
  String get undoButtonLabel => '復原';

  @override
  String get saveButtonLabel => '儲存';

  @override
  String get webDavSettings => 'WebDAV設定';

  @override
  String get webDavUrlLabel => '網址';

  @override
  String get webDavUrlHelperText => 'WebDAV 服務的基礎 URL。';

  @override
  String get webDavUrlValidatorError => '請輸入網址';

  @override
  String get webDavUrlValidatorInvalidUrlError =>
      '請輸入以 http:// 或 https:// 開頭的有效網址';

  @override
  String get webDavAuthUser => '用戶名';

  @override
  String get webDavopenvalutword => '密碼';

  @override
  String get mergeSuccessDialogTitle => '成功合併密碼數據庫';

  @override
  String mergeSuccessDialogMessage(Object fileName, Object mergeSummary) {
    return '保存 $fileName 時檢測到衝突，它與遠程文件成功合併：\n\n$mergeSummary';
  }

  @override
  String forDetailsVisitUrl(Object url) {
    return '有關詳細信息，請訪問 $url';
  }

  @override
  String get openvalutCloudAuthEmailInputLabel => '輸入電子郵件地址以註冊或登錄。';

  @override
  String get openvalutCloudAuthEmailInvalid => '請輸入有效的電子郵件地址。';

  @override
  String get openvalutCloudAuthConfirmEmailButtonLabel => '確認地址';

  @override
  String get openvalutCloudAuthConfirmEmail => '請檢查您的電子郵件以確認您的電子郵件地址。';

  @override
  String get openvalutCloudAuthConfirmEmailExplain =>
      '將此界面保持開啟，直到您已訪問通過電子郵件收到的鏈接。';

  @override
  String get openvalutCloudAuthResendExplain =>
      '如果您沒有收到電子郵件，請檢查您的垃圾郵件文件夾。 否則，您可以嘗試請求新的確認鏈接。';

  @override
  String get openvalutCloudAuthResendButtonLabel => '請求新的確認鏈接';

  @override
  String permanentlyDeleteEntryConfirm(Object title) {
    return '這將永久刪除密碼條目 $title 。這不能被撤消。確認要繼續嗎？';
  }

  @override
  String get permanentlyDeletedEntrySnackBar => '條目已被永久刪除';

  @override
  String get initialNewGroupName => '新群組';

  @override
  String get deleteGroupErrorTitle => '無法刪除群組';

  @override
  String get deleteGroupErrorBodyContainsGroup =>
      '此群組下還有其他子群組，無法刪除。目前只能刪除不含任何內容的群組。';

  @override
  String get deleteGroupErrorBodyContainsEntries =>
      '此群組下還存有密碼資料，無法刪除。目前只能刪除不含任何內容的群組。';

  @override
  String get groupListAppBarTitle => '群組清單';

  @override
  String get groupListFilterAppbarTitle => '選擇要顯示的群組';

  @override
  String get clearQuickUnlock => '清除生物辨識資訊';

  @override
  String get clearQuickUnlockSubtitle => '不再記憶主密碼';

  @override
  String get unlock => '檔案解鎖';

  @override
  String get closePasswordFiles => '關閉密碼檔';

  @override
  String get clearQuickUnlockSuccess => '自生物驗證資料裡刪除存下的主密碼。';

  @override
  String get diacOptIn => '顯示本軟體的新知及問卷調查';

  @override
  String get diacOptInSubtitle => '啟用後，軟體偶爾會連線擷取最新消息資料';

  @override
  String get enableAutofillDebug => '自動填入：除錯模式';

  @override
  String get enableAutofillDebugSubtitle => '顯示每個輸入欄的資訊';

  @override
  String get createPasswordDatabase => '建立密碼資料庫';

  @override
  String get nameNewPasswordDatabase => '新資料庫名稱';

  @override
  String get validatorNameMissing => '請輸入新資料庫的名稱。';

  @override
  String get masterPasswordHelpText => '選擇安全的資料庫主密碼，並且確實記牢。';

  @override
  String get inputMasterPasswordText => '主密碼';

  @override
  String get masterPasswordMissingCreate => '請輸入安全、記得著的密碼。';

  @override
  String get createDatabaseAction => '建立資料庫';

  @override
  String get databaseExistsError => '已有同名檔案';

  @override
  String databaseExistsErrorDescription(Object filePath) {
    return '建立資料庫 $filePath 時發生錯誤：已有同名檔案存在，請換個名字。';
  }

  @override
  String get databaseCreateDefaultName => 'PersonalPasswords';

  @override
  String get preferenceDynamicLoadIcons => '載入網站圖示';

  @override
  String preferenceDynamicLoadIconsSubtitle(Object urlFieldName) {
    return '將產生 HTTP 連線到 $urlFieldName 欄位指定的網站，以讀取網站圖示。';
  }

  @override
  String passwordScore(Object score) {
    return '密碼強度：$score （滿分為 4）';
  }

  @override
  String get entryInfoFile => '檔案：';

  @override
  String get entryInfoGroup => '群組：';

  @override
  String get entryInfoLastModified => '修改時間：';

  @override
  String movedEntryToGroup(Object groupName) {
    return '已將此項目移入$groupName';
  }

  @override
  String sizeBytes(Object count) {
    return '$count 位元組';
  }

  @override
  String get entryAttachmentSizeWarning => '附件會存入密碼資料庫檔案中，也可能大幅拉長存取密碼所需的時間。';

  @override
  String get iconPngSizeWarning => '自訂圖示會存入密碼資料庫檔案中，也可能大幅拉長存取密碼所需的時間。';

  @override
  String get notPngError => '您選擇的檔案並非 PNG 格式';

  @override
  String get entryAddField => '新增欄位';

  @override
  String get entryCustomField => '自訂欄位';

  @override
  String get entryCustomFieldTitle => '新增自訂的欄位';

  @override
  String get entryCustomFieldInputLabel => '輸入欄位名稱';

  @override
  String get swipeCopyField => '複製內容';

  @override
  String get fieldRename => '重新命名';

  @override
  String get fieldGeneratePassword => '產生密碼…';

  @override
  String get fieldProtect => '隱藏內容';

  @override
  String get fieldUnprotect => '不必隱藏內容';

  @override
  String get fieldPresent => '展示 QRCode';

  @override
  String get fieldGenerateEmail => '產生 Email';

  @override
  String get onboardingBackToOnboarding => '概覽';

  @override
  String get onboardingBackToOnboardingSubtitle => '重現新手引領畫面 😅️';

  @override
  String get onboardingHeadline => '妥善保護您的密碼！';

  @override
  String get onboardingQuestion => '您是否用過密碼管理工具？';

  @override
  String get onboardingYesOpenPasswords => '是，我要使用先前的資料';

  @override
  String get onboardingNoCreate => '沒有，該怎麼開始呢？';

  @override
  String get backupButton => '存到雲端';

  @override
  String get dismissBackupButton => '關閉';

  @override
  String backupWarningMessage(Object databasename) {
    return '$databasename 中的密碼僅僅存在本機中！';
  }

  @override
  String get saveAs => '儲存到...';

  @override
  String get saving => '儲存中';

  @override
  String get increaseValue => '增加';

  @override
  String get decreaseValue => '減少';

  @override
  String get resetValue => '重新設定';

  @override
  String get cloudStorageLogInCaption => '您將被重定向到驗證 OpenValut 以訪問您的數據。';

  @override
  String get cloudStorageLogInCode => '輸入代碼';

  @override
  String launchUrlError(Object url) {
    return '無法啟動網址。請訪問$url';
  }

  @override
  String cloudStorageLogInActionLabel(Object cloudStorageName) {
    return '登錄到 $cloudStorageName';
  }

  @override
  String get cloudStorageAuthCodeLabel => '驗證碼';

  @override
  String get cloudStorageAuthErrorTitle => '驗證時出錯';

  @override
  String get cloudStorageSearchBoxLabel => '搜索查詢';

  @override
  String get mailSubject => '主題';

  @override
  String get mailFrom => '發件人';

  @override
  String get mailDate => '日期';

  @override
  String get mailMailbox => '郵箱';

  @override
  String get mailNoData => '沒有數據';

  @override
  String get mailMailboxesTitle => '郵箱';

  @override
  String get mailboxCreateButtonLabel => '創建';

  @override
  String get mailScreenTitle => 'OpenValut 郵箱';

  @override
  String get mailTabBarTitleMailbox => '郵箱';

  @override
  String get mailTabBarTitleMail => '郵件';

  @override
  String get mailMailboxListEmpty => '您還沒有任何郵箱。';

  @override
  String mailMailboxAddressCopied(Object mailboxAddress) {
    return '成功將郵箱地址複製到剪貼板： $mailboxAddress';
  }

  @override
  String get errorWhileSavingTitle => '保存時出錯';

  @override
  String errorWhileSavingBody(Object errorMessage) {
    return '無法保存文件： $errorMessage';
  }

  @override
  String get databaseDoesNotSupportSaving =>
      '抱歉，此數據庫不支持保存。請打開一個本地數據庫文件。或使用“另存為”。';

  @override
  String get otpInvalidKeyTitle => '無效密鑰';

  @override
  String get otpInvalidKeyBody => '給定的輸入不是有效的 base32 TOTP 代碼。請驗證您的輸入。';

  @override
  String get otpPromptTitle => '基於時間的身份驗證';

  @override
  String get otpPromptHelperText => '請輸入基於時間的密鑰。';

  @override
  String get entryFieldProtected => '受保護的領域。點擊揭示。';

  @override
  String get entryFieldActionRevealField => '顯示受保護的字段';

  @override
  String get entryAttachmentOpenActionLabel => '打開';

  @override
  String get entryAttachmentShareActionLabel => '分享';

  @override
  String get entryAttachmentShareSubject => '附件';

  @override
  String get entryAttachmentSaveActionLabel => '保存到設備';

  @override
  String get entryAttachmentRemoveActionLabel => '移除';

  @override
  String entryAttachmentRemoveConfirm(Object attachmentLabel) {
    return '確定要刪除 $attachmentLabel 嗎？';
  }

  @override
  String get entryRenameFieldPromptTitle => '重命名字段';

  @override
  String get removerecentfile => '隱藏';

  @override
  String get entryRenameFieldPromptLabel => '輸入字段的新名稱';

  @override
  String get promptDialogPasteActionTooltip => '從剪貼板粘貼';

  @override
  String get promptDialogPasteHint => '提示：如果您需要粘貼，不妨嘗試左邊的按鈕 ;-)';

  @override
  String get genericErrorDialogTitle => '處理動作時出錯';

  @override
  String genericErrorDialogBody(Object errorMessage) {
    return '發生意外錯誤：$errorMessage';
  }

  @override
  String get saveAsEntryLocalFile => '本機檔案';

  @override
  String get newGroupDialogTitle => '新群組';

  @override
  String get groupActionDelete => '刪除';

  @override
  String get shareCodeLoadingProgress => '檔案讀取中 …';

  @override
  String get shortcutCopyUsername => '複製帳號';

  @override
  String get shortcutCopyPassword => '複製密碼';

  @override
  String get shortcutGeneratePassword => '產生密碼';

  @override
  String get shortcutOpenUrl => '開啟 URL';

  @override
  String unexpectedError(String error) {
    return '不明錯誤：$error';
  }
}
