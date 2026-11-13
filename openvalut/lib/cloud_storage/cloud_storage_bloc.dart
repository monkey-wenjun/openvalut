import 'package:openvalut/bloc/analytics.dart';
import 'package:openvalut/cloud_storage/cloud_storage_provider.dart';
import 'package:openvalut/env/_base.dart';
import 'package:openvalut/utils/path_util.dart';
import 'package:collection/collection.dart' show IterableExtension;

/// manages available cloud storages.
/// BloC is definitely the wrong name here...
class CloudStorageBloc {
  CloudStorageBloc(this.env, PathUtil pathUtil, Analytics analytics) {
    // Third-party cloud storage providers (WebDAV removed; Dropbox, Google
    // Drive and OneDrive register themselves via the environment flags).
  }

  final Env env;
  final Set<CloudStorageProvider> availableCloudStorage = {};

  CloudStorageProvider? providerById(String? id) =>
      availableCloudStorage.firstWhereOrNull((p) => p.id == id);
}
