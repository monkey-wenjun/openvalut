import 'package:openvalut/env/_base.dart';
import 'package:openvalut/env/env.dart';

Future<void> main() async => await WebProduction().start();

class WebProduction extends EnvAppBase {
  WebProduction() : super(EnvType.production);

  @override
  bool get featureCloudStorageProprietary => false;

  @override
  EnvSecrets? get secrets => EnvSecrets.nullSecrets;
}
