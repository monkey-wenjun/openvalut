import 'package:openvalut/env/_base.dart';
import 'package:openvalut/env/env.dart';

Future<void> main() async => await CustomDesktop().start();

/// Desktop (Linux) build of the OpenValut custom distribution.
///
/// Mirrors the sideload environment flags so the desktop app behaves like the
/// Android build: same custom WebDAV provider, no onboarding, no proprietary
/// cloud extras.
class CustomDesktop extends EnvAppBase {
  CustomDesktop() : super(EnvType.production);

  @override
  EnvSecrets? get secrets => EnvSecrets.nullSecrets;

  @override
  bool get featureOnboarding => false;

  @override
  bool get featureCloudStorageProprietary => false;

  @override
  bool get featureFetchWebsiteIconEnabledByDefault => false;

  @override
  bool get diacHidden => true;

  @override
  bool get diacDefaultDisabled => true;

  @override
  FeatureFlags get featureFlags {
    const fromEnv = String.fromEnvironment(
      'openvalut_CLOUD_URI',
      defaultValue: '',
    );
    if (fromEnv.isNotEmpty) {
      return FeatureFlags(
        (b) => b
          ..openvalutCloud = true
          ..openvalutCloudUri = fromEnv,
      );
    }
    return super.featureFlags;
  }
}
