// ignore_for_file: implementation_imports

import 'package:openvalut/env/_base.dart';
import 'package:openvalut/utils/path_utils.dart';
import 'package:openvalut/utils/platform.dart';
import 'package:clock/clock.dart';
import 'package:flutter_cache_manager/flutter_cache_manager.dart';
import 'package:http/http.dart' as http;
import 'package:string_literal_finder_annotations/string_literal_finder_annotations.dart';

class OpenValutCacheManager extends CacheManager {
  factory OpenValutCacheManager({
    required PathUtils pathUtils,
    required Env env,
  }) {
    final key = getKey(pathUtils);
    final config = Config(
      getKey(pathUtils),
      maxNrOfCacheObjects: 200,
      stalePeriod: const Duration(days: 30),
      repo: OpenValutPlatform.isWeb
          ? NonStoringObjectProvider()
          : JsonCacheInfoRepository(databaseName: key),
      fileService: HttpFileService(
        httpClient: LazyUserAgentClient(
          (() async => _buildUserAgent(await env.getAppInfo()))(),
          http.Client(),
        ),
      ),
    );
    final cacheManager = OpenValutCacheManager._(
      pathUtils: pathUtils,
      config: config,
    );
    return cacheManager;
  }

  @NonNls
  static String _buildUserAgent(AppInfo appInfo) {
    return '${appInfo.appName}/${appInfo.versionLabel} '
        '(${OpenValutPlatform.operatingSystem})';
  }

  OpenValutCacheManager._({required this.pathUtils, required Config config})
    : key = getKey(pathUtils),
      super(config);

  @NonNls
  static const _keyBase = 'openvalutCachedImageData';
  static String getKey(PathUtils pathUtils) => pathUtils.namespace == null
      ? _keyBase
      : nonNls('${_keyBase}__${pathUtils.namespace}');
  final String key;

  PathUtils pathUtils;
}

class MemoryCacheObject {
  MemoryCacheObject(this.cacheObject) : touched = clock.now();

  final CacheObject cacheObject;
  final DateTime touched;
}

/// Add a user-agent adder to the given value.
class LazyUserAgentClient extends http.BaseClient {
  LazyUserAgentClient(this.userAgent, this._inner);

  final Future<String> userAgent;
  String? _userAgent;
  final http.Client _inner;

  @override
  Future<http.StreamedResponse> send(http.BaseRequest request) async {
    final ua = _userAgent ??= await userAgent;
    request.headers[nonNls('user-agent')] = ua;
    return _inner.send(request);
  }
}
