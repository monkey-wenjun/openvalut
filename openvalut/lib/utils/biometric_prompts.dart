import 'package:biometric_storage/biometric_storage.dart';
import 'package:openvalut/utils/app_locale.dart';

/// Locale-aware prompt strings for the biometric authentication dialogs.
///
/// The biometric_storage plugin defaults are English ("Authenticate to unlock
/// data" / "Cancel"); every authenticated read passes these instead.
PromptInfo biometricPromptInfo() {
  final zh = AppLocale.isChinese;
  return PromptInfo(
    androidPromptInfo: AndroidPromptInfo(
      title: zh ? '验证指纹以解锁数据' : 'Authenticate to unlock data',
      subtitle: zh ? '使用已录入的指纹验证身份' : 'Verify with a saved fingerprint',
      negativeButton: zh ? '取消' : 'Cancel',
    ),
    iosPromptInfo: IosPromptInfo(
      saveTitle: zh ? '解锁以保存数据' : 'Unlock to save data',
      accessTitle: zh ? '解锁以访问数据' : 'Unlock to access data',
    ),
    macOsPromptInfo: IosPromptInfo(
      saveTitle: zh ? '解锁以保存数据' : 'Unlock to save data',
      accessTitle: zh ? '解锁以访问数据' : 'Unlock to access data',
    ),
  );
}
