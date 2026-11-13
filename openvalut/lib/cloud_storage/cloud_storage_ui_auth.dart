import 'package:openvalut/cloud_storage/cloud_storage_provider.dart';
import 'package:openvalut/cloud_storage/cloud_storage_ui_adapt.dart';
import 'package:openvalut/l10n-generated/app_localizations.dart';
import 'package:openvalut/ui/widgets/link_button.dart';
import 'package:openvalut/ui/widgets/primary_button.dart';
import 'package:openvalut/utils/dialog_utils.dart';
import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:logging/logging.dart';

final _logger = Logger('cloud_storage_ui_auth');

class CloudStorageAuthentication extends StatelessWidget {
  const CloudStorageAuthentication({
    super.key,
    required this.provider,
    required this.onSuccess,
  });

  final CloudStorageProvider provider;
  final void Function() onSuccess;

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final provider = this.provider;
    final defaultLoginWidget = PrimaryButton(
      icon: const FaIcon(FontAwesomeIcons.rightToBracket),
      onPressed: () async {
        await _startLoginFlow(context);
      },
      child: Text(loc.cloudStorageLogInActionLabel(provider.displayName)),
    );
    final loginWidget = provider is CloudStorageCustomLoginButtonAdapter
        ? provider.getCustomLoginWidget(
            onSuccess: onSuccess,
            defaultWidget: defaultLoginWidget,
          )
        : defaultLoginWidget;
    return Padding(
      padding: const EdgeInsets.all(32.0),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          loginWidget,
          const SizedBox(height: 16),
          Text(
            loc.cloudStorageLogInCaption,
            style: theme.textTheme.bodySmall,
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 16),
          LinkButton(
            onPressed: () async {
              await _startLoginFlow(context, forceNoOpenUrl: true);
            },
            child: Text(
              loc.cloudStorageLogInCode,
              textScaler: const TextScaler.linear(0.75),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _startLoginFlow(
    BuildContext context, {
    bool forceNoOpenUrl = false,
  }) async {
    final loc = AppLocalizations.of(context);
    try {
      final auth = await provider.startAuth((final prompt) async {
        if (prompt
            is UserAuthenticationPrompt<
              OAuthTokenResult,
              OAuthTokenFlowPromptData
            >) {
          final promptData = prompt.data;
          final uri = promptData.openUri;
          _logger.fine('Launching authentication url $uri');

          if (!forceNoOpenUrl) {
            if (!await DialogUtils.openUrl(uri)) {
              if (!context.mounted) {
                _logger.severe('Widget no longer mounted, not showing dialog.');
                return;
              }
              await DialogUtils.showSimpleAlertDialog(
                context,
                null,
                loc.launchUrlError(uri),
                routeAppend: 'cloudStorageAuthError',
              );
              prompt.result(null);
              return;
            }
          }
          if (!context.mounted) {
            return;
          }
          final code = await SimpleAuthCodePromptDialog(
            title: loc.cloudStorageAuthCodeDialogTitle(provider.displayName),
            labelText: loc.cloudStorageAuthCodeLabel,
          ).show(context);
          prompt.result(OAuthTokenResult(code));
        } else {
          throw StateError('Unsupported prompt: $prompt');
        }
      });
      _logger.fine('finished launching. $auth');
      onSuccess();
    } catch (e, stackTrace) {
      _logger.severe('Error while authenticating.', e, stackTrace);
      if (!context.mounted) {
        return;
      }
      await DialogUtils.showErrorDialog(
        context,
        loc.cloudStorageAuthErrorTitle,
        loc.cloudStorageAuthErrorMessage(provider.displayName, e),
      );
    }
  }
}
