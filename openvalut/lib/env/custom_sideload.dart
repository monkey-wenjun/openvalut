import 'package:openvalut/env/_base.dart';
import 'package:openvalut/env/env.dart';

Future<void> main() async => await CustomSideload().start();

class CustomSideload extends EnvAppBase {
  CustomSideload() : super(EnvType.production);

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
