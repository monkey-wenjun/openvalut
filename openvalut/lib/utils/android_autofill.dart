import 'dart:async';
import 'dart:convert';

import 'package:autofill_service/autofill_service.dart';
import 'package:autofill_shared/credential_matcher.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:kdbx/kdbx.dart';
import 'package:logging/logging.dart';
import 'package:openvalut/bloc/deps.dart';
import 'package:openvalut/bloc/kdbx/file_source.dart';
import 'package:openvalut/credential_server/credential_server.dart';
import 'package:openvalut/utils/app_locale.dart';
import 'package:openvalut/l10n-generated/app_localizations.dart';

final _logger = Logger('android_autofill');

/// Bridges Android autofill requests into the running Flutter app.
///
/// When the user picks "使用 OpenValut 自动填充" in a browser, Android launches
/// MainActivity (or delivers `onNewIntent` to the already-running instance).
/// The native side parses the assist structure (web domains + app package)
/// and forwards it over the `app.openvalut/misc` channel as `onAutofillIntent`.
/// This class turns that into the credential picker and commits the chosen
/// entry through the autofill_service plugin's `resultWithDataset`, which is
/// what finally fills the browser's fields.
///
/// The app-side flow was missing entirely, which is why the browser looped:
/// the autofill suggestion opened the app and nothing ever filled back.
class AndroidAutofillCoordinator {
  AndroidAutofillCoordinator._();

  static final AndroidAutofillCoordinator instance =
      AndroidAutofillCoordinator._();

  static const _miscChannel = MethodChannel('app.openvalut/misc');

  /// Ignore the same metadata pushed twice (once from the channel, once from
  /// the cold-start poll) within this window, while still allowing a new
  /// autofill request on the same page to re-open the picker.
  static const _dedupeWindow = Duration(seconds: 10);

  Deps? _deps;
  GlobalKey<NavigatorState>? _navigatorKey;
  String? _lastMetadataJson;
  DateTime? _lastHandledAt;
  bool _initialized = false;
  BuildContext? _pickerContext;

  void init({
    required Deps deps,
    required GlobalKey<NavigatorState> navigatorKey,
  }) {
    if (_initialized) {
      return;
    }
    _initialized = true;
    _deps = deps;
    _navigatorKey = navigatorKey;
    _miscChannel.setMethodCallHandler(_onMethodCall);
  }

  Future<void> _onMethodCall(MethodCall call) async {
    switch (call.method) {
      case 'onAutofillIntent':
        final json = call.arguments as String?;
        if (json != null && json.isNotEmpty) {
          final parsed = _parseMetadataJson(json);
          if (parsed != null) {
            // 每次用户触发自动填充都是新会话；channel 推送不去重，
            // 否则同一 App 短时间内的第二次请求会被 10 秒窗口吞掉。
            await _handleAutofillMetadata(
              parsed.$1,
              parsed.$2,
              dedupe: false,
            );
          }
        }
        return;
      case 'dismissAutofillPicker':
        // The user opened the app on their own; close any picker left open
        // from an earlier autofill session.
        dismissOpenPicker();
        return;
      default:
        throw MissingPluginException('No implementation for ${call.method}');
    }
  }

  /// Whether the credential picker is currently on screen.
  bool get isPickerOpen => _pickerContext != null;

  /// Registers the picker sheet while it is visible.
  void pickerOpened(BuildContext context) {
    _pickerContext = context;
  }

  /// Forgets the picker sheet once it is gone.
  void pickerClosed() {
    _pickerContext = null;
  }

  /// Closes the open picker, if any. Used when a non-autofill intent brings
  /// the app to the front, so a normal launch never shows an autofill prompt.
  void dismissOpenPicker() {
    final context = _pickerContext;
    _pickerContext = null;
    if (context != null && context.mounted) {
      _logger.info('Dismissing open autofill picker.');
      Navigator.of(context, rootNavigator: true).pop();
    }
  }

  /// Cold-start path: the autofill intent started a fresh process, so no
  /// `onAutofillIntent` channel call arrives. Ask for the metadata once the
  /// first frame is up.
  ///
  /// The metadata must describe the intent that actually launched the
  /// activity. The plugin reads `lastIntent` / the activity's intent, which is
  /// null for a normal launcher start, so a plain "open the app" never pops
  /// the picker. MainActivity's static is only a fallback when the plugin
  /// channel is not yet attached.
  Future<void> checkForPendingAutofillIntent() async {
    if (!_initialized) {
      return;
    }

    AutofillMetadata? metadata;
    try {
      metadata = await AutofillService().getAutofillMetadata();
    } catch (e) {
      _logger.fine('Autofill metadata unavailable from plugin: $e');
    }

    if (metadata != null) {
      await _handleAutofillMetadata(
        metadata,
        _metadataKey(metadata),
        dedupe: true,
      );
      return;
    }

    // Fallback: the plugin channel may not be attached yet on a cold start.
    // MainActivity clears this static whenever a non-autofill intent arrives,
    // so it only ever describes the intent that launched the activity.
    String? json;
    try {
      json = await _miscChannel.invokeMethod<String>('getAutofillMetadataJson');
    } catch (e) {
      _logger.fine('No pending autofill metadata: $e');
    }
    if (json != null && json.isNotEmpty) {
      final parsed = _parseMetadataJson(json);
      if (parsed != null) {
        await _handleAutofillMetadata(
          parsed.$1,
          parsed.$2,
          dedupe: true,
        );
      }
    }
  }

  static (AutofillMetadata, String)? _parseMetadataJson(String json) {
    try {
      final metadata = AutofillMetadata.fromJson(
        jsonDecode(json) as Map<dynamic, dynamic>,
      );
      return (metadata, json);
    } catch (e) {
      _logger.warning('Unable to parse autofill metadata: $e');
      return null;
    }
  }

  /// Stable identity for deduplication, independent of whether the metadata
  /// arrived as a channel string or through the plugin.
  static String _metadataKey(AutofillMetadata metadata) => jsonEncode({
    'packageNames': metadata.packageNames.toList()..sort(),
    'webDomains': [
      for (final domain in metadata.webDomains)
        {'scheme': domain.scheme, 'domain': domain.domain},
    ],
  });

  Future<void> _handleAutofillMetadata(
    AutofillMetadata metadata,
    String key, {
    bool dedupe = true,
  }) async {
    final now = DateTime.now();
    final last = _lastHandledAt;
    if (dedupe &&
        _lastMetadataJson == key &&
        last != null &&
        now.difference(last) < _dedupeWindow) {
      _logger.fine('Duplicate autofill metadata, ignoring.');
      return;
    }
    _lastMetadataJson = key;
    _lastHandledAt = now;

    final navigator = _navigatorKey?.currentState;
    final deps = _deps;
    if (navigator == null || deps == null || !navigator.mounted) {
      return;
    }
    // Wait for the first frame so the sheet has a real overlay/theme.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!navigator.mounted || isPickerOpen) {
        return;
      }
      if (deps.kdbxBloc.openedFilesWithSources.isNotEmpty) {
        _showPicker(navigator, deps, metadata);
        return;
      }
      // 冷启动自动填充：此时密码库还在解锁，列表是空的。等解锁完成
      // （openedFiles 非空）再弹出，否则用户只会看到“没有解锁的密码库”。
      _logger.info('Waiting for vault unlock before showing autofill picker.');
      var cancelled = false;
      late final StreamSubscription<dynamic> sub;
      sub = deps.kdbxBloc.openedFilesChanged.listen((_) {
        if (cancelled || deps.kdbxBloc.openedFilesWithSources.isEmpty) {
          return;
        }
        cancelled = true;
        sub.cancel();
        if (navigator.mounted && !isPickerOpen) {
          _showPicker(navigator, deps, metadata);
        }
      });
      // 兜底：解锁超时也展示（提示用户先解锁）。
      Timer(const Duration(seconds: 10), () {
        if (cancelled) {
          return;
        }
        cancelled = true;
        sub.cancel();
        if (navigator.mounted && !isPickerOpen) {
          _showPicker(navigator, deps, metadata);
        }
      });
    });
  }

  void _showPicker(
    NavigatorState navigator,
    Deps deps,
    AutofillMetadata metadata,
  ) {
    if (!navigator.mounted || isPickerOpen) {
      return;
    }
    if (deps.kdbxBloc.openedFilesWithSources.isEmpty) {
      _logger.info(
        'Showing autofill picker (no vault open) for '
        'web=${metadata.webDomains.map((d) => d.domain).join(',')} '
        'packages=${metadata.packageNames.join(',')}',
      );
    } else {
      _logger.info(
        'Showing autofill picker for '
        'web=${metadata.webDomains.map((d) => d.domain).join(',')} '
        'packages=${metadata.packageNames.join(',')}',
      );
    }
    unawaited(
      showAndroidAutofillPicker(
        navigator.context,
        deps,
        metadata,
        onOpened: pickerOpened,
        onClosed: pickerClosed,
      ),
    );
  }
}

/// Opens the credential picker for an autofill request.
Future<void> showAndroidAutofillPicker(
  BuildContext context,
  Deps deps,
  AutofillMetadata metadata, {
  required void Function(BuildContext) onOpened,
  required void Function() onClosed,
}) async {
  onOpened(context);
  try {
    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (sheetContext) =>
          AndroidAutofillPickerSheet(deps: deps, metadata: metadata),
    );
  } finally {
    onClosed();
  }
}

/// Bottom sheet listing the vault entries that match the requesting page or
/// app. Tapping one commits the fill and returns to the browser.
class AndroidAutofillPickerSheet extends StatelessWidget {
  const AndroidAutofillPickerSheet({
    super.key,
    required this.deps,
    required this.metadata,
  });

  final Deps deps;
  final AutofillMetadata metadata;

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context);
    final openedFiles = deps.kdbxBloc.openedFilesWithSources.toList();
    final matches = openedFiles.isEmpty
        ? const <_AutofillMatch>[]
        : _matchEntries(openedFiles);

    final requested = _requestedLabel();

    return ConstrainedBox(
      constraints: BoxConstraints(
        maxHeight: MediaQuery.of(context).size.height * 0.75,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 18, 20, 4),
            child: Text(
              loc.autofillPrompt,
              style: Theme.of(context).textTheme.titleMedium,
            ),
          ),
          if (requested != null)
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 4, 20, 8),
              child: Text(
                '${loc.autofillMatchPrefix} $requested',
                style: Theme.of(context).textTheme.bodySmall,
              ),
            ),
          const Divider(height: 1),
          Flexible(
            child: matches.isEmpty
                ? _EmptyAutofillState(
                    icon: openedFiles.isEmpty
                        ? Icons.lock_outline
                        : Icons.search_off,
                    message: openedFiles.isEmpty
                        ? loc.autofillNoOpenVault
                        : loc.autofillNoMatches,
                    hint:
                        openedFiles.isNotEmpty &&
                            metadata.webDomains.isEmpty &&
                            metadata.packageNames.isNotEmpty
                        // 原生 App 请求需要条目 URL 里存 androidapp://包名
                        // 才能匹配上，这里直接告诉用户怎么关联。
                        ? (AppLocale.isChinese
                              ? '未找到关联该 App 的条目，可在条目 URL 中添加 '
                                    'androidapp://包名 进行关联'
                              : 'No entry is linked to this app. Add '
                                    'androidapp://package in the entry URL to link it.')
                        : null,
                  )
                : ListView.separated(
                    shrinkWrap: true,
                    padding: const EdgeInsets.symmetric(vertical: 4),
                    itemCount: matches.length,
                    separatorBuilder: (_, _) =>
                        const Divider(height: 1, indent: 56),
                    itemBuilder: (context, index) {
                      final match = matches[index];
                      return ListTile(
                        leading: const CircleAvatar(
                          child: Icon(Icons.key, size: 20),
                        ),
                        title: Text(
                          match.entry.label ?? loc.noTitle,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        subtitle: Text(
                          [
                            if ((match.username ?? '').isNotEmpty)
                              match.username!,
                            match.fileName,
                          ].join(' · '),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        onTap: () => _fill(context, match),
                      );
                    },
                  ),
          ),
          const Divider(height: 1),
          Padding(
            padding: const EdgeInsets.all(8),
            child: TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: Text(loc.cancel),
            ),
          ),
        ],
      ),
    );
  }

  List<_AutofillMatch> _matchEntries(
    List<MapEntry<FileSource, KdbxFile>> openedFiles,
  ) {
    final requests = <CredentialRequest>[
      for (final domain in metadata.webDomains)
        CredentialRequest.web(_domainUrl(domain)),
      for (final package in metadata.packageNames)
        CredentialRequest.application(package),
    ];
    if (requests.isEmpty) {
      return const [];
    }

    final matcher = CredentialMatcher.instance;
    final candidates = <_AutofillMatch>[
      for (final opened in openedFiles)
        for (final entry in opened.value.body.rootGroup.getAllEntries())
          if (!entry.isInRecycleBin())
            _AutofillMatch(
              entry: entry,
              fileName: opened.key.displayName,
            ),
    ];
    return matcher.rank(requests, candidates, (c) => c.entry.autofillUrls);
  }

  String? _requestedLabel() {
    final web = metadata.webDomains.map((d) => d.domain).join(', ');
    if (web.isNotEmpty) {
      return web;
    }
    return metadata.packageNames.isEmpty ? null : metadata.packageNames.first;
  }

  Future<void> _fill(BuildContext context, _AutofillMatch match) async {
    Navigator.of(context).pop();
    try {
      // Fill the current TOTP alongside username/password so the second step
      // of a 2FA login (an OTP-only page) also gets autofilled.
      final totp = generateTotpForEntry(
        match.entry,
        nowMillis: () => DateTime.now().millisecondsSinceEpoch,
      );
      final ok = await AutofillService().resultWithDataset(
        label: match.entry.label ?? '',
        username: match.username ?? '',
        password: match.password ?? '',
        otp: totp?.code,
      );
      if (!ok) {
        _logger.warning('Autofill commit reported failure.');
      }
    } catch (e) {
      _logger.warning('Autofill commit failed: $e');
    }
  }
}

String _domainUrl(AutofillWebDomain domain) {
  final scheme = domain.scheme?.trim();
  return (scheme == null || scheme.isEmpty)
      ? domain.domain
      : '$scheme://${domain.domain}';
}

class _EmptyAutofillState extends StatelessWidget {
  const _EmptyAutofillState({
    required this.icon,
    required this.message,
    this.hint,
  });

  final IconData icon;
  final String message;
  final String? hint;

  @override
  Widget build(BuildContext context) {
    final hint = this.hint;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 28),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 40, color: Theme.of(context).disabledColor),
          const SizedBox(height: 10),
          Text(
            message,
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.bodyMedium,
          ),
          if (hint != null) ...[
            const SizedBox(height: 8),
            Text(
              hint,
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: Theme.of(context).disabledColor,
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _AutofillMatch {
  _AutofillMatch({required this.entry, required this.fileName});

  final KdbxEntry entry;
  final String fileName;

  String? get username => entry.getString(KdbxKeyCommon.USER_NAME)?.getText();

  String? get password => entry.getString(KdbxKeyCommon.PASSWORD)?.getText();
}
