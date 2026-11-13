#import "WinsparkleFlutterPlugin.h"
#if __has_include(<winsparkle_flutter/winsparkle_flutter-Swift.h>)
#import <winsparkle_flutter/winsparkle_flutter-Swift.h>
#else
// Support project import fallback if the generated compatibility header
// is not copied when this plugin is created as a library.
// https://forums.swift.org/t/swift-static-libraries-dont-copy-generated-objective-c-header/19816
#import "winsparkle_flutter-Swift.h"
#endif

@implementation WinsparkleFlutterPlugin
+ (void)registerWithRegistrar:(NSObject<FlutterPluginRegistrar>*)registrar {
  [SwiftWinsparkleFlutterPlugin registerWithRegistrar:registrar];
}
@end
