import 'package:openvalut/env/_base.dart';
import 'package:openvalut/env/env.dart';
import 'package:string_literal_finder_annotations/string_literal_finder_annotations.dart';

Future<void> main() async => await Development().start();

class Development extends EnvAppBase {
  Development() : super(EnvType.development);

  @NonNls
  @override
  String get storageNamespace => '${super.storageNamespace ?? ''}development';

  @override
  EnvSecrets? get secrets => EnvSecrets.nullSecrets;

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
