import 'package:flutter/material.dart';
import 'package:flutter_async_utils/flutter_async_utils.dart';
import 'package:logging/logging.dart';
import 'package:openvalut/bloc/kdbx/file_source_ui.dart';
import 'package:openvalut/bloc/kdbx_bloc.dart';
import 'package:openvalut/cloud_storage/cloud_storage_provider.dart';
import 'package:openvalut/l10n-generated/app_localizations.dart';
import 'package:openvalut/ui/screens/main_app_scaffold.dart';
import 'package:openvalut/ui/widgets/password_input_field.dart';
import 'package:openvalut/ui/widgets/primary_button.dart';
import 'package:openvalut/utils/constants.dart';
import 'package:openvalut/utils/dialog_utils.dart';
import 'package:openvalut/utils/extension_methods.dart';
import 'package:provider/provider.dart';
import 'package:recase/recase.dart';
// ignore: implementation_imports
import 'package:zxcvbn/zxcvbn.dart';

final _logger = Logger('create_file');

class CreateFile extends StatefulWidget {
  const CreateFile({this.target});
  static PageRoute<void> route({CloudStorageSaveTarget? target}) =>
      MaterialPageRoute(
        settings: const RouteSettings(
          name: '/createFile',
        ),
        builder: (context) => CreateFile(
          target: target,
        ),
      );

  final CloudStorageSaveTarget? target;

  @override
  _CreateFileState createState() => _CreateFileState();
}

class _CreateFileState extends State<CreateFile> with FutureTaskStateMixin {
  static final _zxcvbn = Zxcvbn();

  final GlobalKey<FormState> _formKey = GlobalKey();
  final TextEditingController _databaseName = TextEditingController();
  final TextEditingController _password = TextEditingController();
  final FocusNode _passwordFocus = FocusNode();

  Result? _strength;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final loc = AppLocalizations.of(context);
    if (_databaseName.text.isEmpty) {
      _databaseName.text = loc.databaseCreateDefaultName;
    }
  }

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final target = widget.target;
    return Scaffold(
      appBar: AppBar(
        title: Text(loc.createPasswordDatabase),
      ),
      body: Form(
        key: _formKey,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 4),
          child: Theme(
            data: theme.copyWith(
              inputDecorationTheme: theme.inputDecorationTheme.copyWith(
                filled: true,
              ),
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: <Widget>[
                if (target != null) ...[
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      target.provider.displayIcon.iconData.widget(),
                      const SizedBox(width: 16),
                      Text(target.provider.displayName),
                      ...?target.parent?.let(
                        (it) => [
                          const Text(CharConstants.chevronRight),
                          Text(it.pathOrBaseName),
                        ],
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                ],
                TextFormField(
                  controller: _databaseName,
                  decoration: InputDecoration(
                    labelText: loc.nameNewPasswordDatabase,
                    suffixText: '.kdbx', // NON-NLS
                    filled: true,
                  ),
                  textInputAction: TextInputAction.next,
                  onFieldSubmitted: (val) => _passwordFocus.requestFocus(),
                  validator: (val) {
                    final value = val?.trim() ?? '';
                    if (value.isEmpty) {
                      return loc.validatorNameMissing;
                    }
                    return _validateDatabaseName(value);
                  },
                ),
                const SizedBox(height: 16),
                PasswordInputField(
                  labelText: loc.inputMasterPasswordText,
                  controller: _password,
                  focusNode: _passwordFocus,
                  autofocus: true,
                  onFieldSubmitted: (val) => _submitCallback()?.call(),
                  autovalidateMode: AutovalidateMode.onUserInteraction,
                  onChanged: (value) {
                    final userInput = _databaseName.text.pathCase.split(
                      CharConstants.slash,
                    );
                    setState(() {
                      if (value.isEmpty) {
                        _strength = null;
                      } else {
                        _strength = _zxcvbn.evaluate(
                          value,
                          userInputs: userInput,
                        );
                      }
                    });
                  },
                  validator: (val) {
                    if (val == null || val.isEmpty) {
                      return loc.masterPasswordMissingCreate;
                    }
                    if (val.contains(' ')) {
                      return loc.cloudPasswordNoSpaces;
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 8),
                PasswordStrengthDisplay(strength: _strength),
                const SizedBox(height: 8),
                Text(
                  loc.masterPasswordDescription,
                  style: Theme.of(context).textTheme.bodySmall,
                ),
                Container(
                  padding: const EdgeInsets.only(top: 8),
                  alignment: Alignment.centerRight,
                  child: task != null
                      ? const CircularProgressIndicator(
                          backgroundColor: Colors.red,
                        )
                      : PrimaryButton(
                          large: false,
                          onPressed: _submitCallback(),
                          child: Text(loc.createDatabaseAction),
                        ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  String? _validateDatabaseName(String value) {
    final loc = AppLocalizations.of(context);
    if (value.startsWith(RegExp(r'[0-9]'))) {
      return loc.cloudVaultNameNoLeadingDigit;
    }
    if (!RegExp(r'^[\u4e00-\u9fa5a-zA-Z0-9]+$').hasMatch(value)) {
      return loc.cloudVaultNameChars;
    }
    return null;
  }

  VoidCallback? _submitCallback() => asyncTaskCallback((progress) async {
    if (_formKey.currentState!.validate()) {
      final kdbxBloc = Provider.of<KdbxBloc>(context, listen: false);
      try {
        final created = await kdbxBloc.createFile(
          password: _password.text,
          databaseName: _databaseName.text.trim(),
          openAfterCreate: true,
          target: widget.target,
        );
        _logger.finest('Created file $created');
        if (!mounted) {
          return;
        }
        await Navigator.of(
          context,
        ).pushAndRemoveUntil(MainAppScaffold.route(), (route) => false);
      } on FileExistsException catch (e, stackTrace) {
        _logger.warning('Showing file exists error dialog.', e, stackTrace);
        if (!mounted) {
          _logger.severe('context no longer mounted. not showing dialog.');
          return;
        }
        final loc = AppLocalizations.of(context);
        await DialogUtils.showSimpleAlertDialog(
          context,
          loc.databaseExistsError,
          loc.databaseExistsErrorDescription(e.path),
          routeAppend: 'createFileExists',
        );
      } catch (e, stackTrace) {
        _logger.severe('Error while creating file.', e, stackTrace);
        rethrow;
      }
    }
  });
}

class PasswordStrengthDisplay extends ImplicitlyAnimatedWidget {
  const PasswordStrengthDisplay({super.key, this.strength})
    : super(duration: const Duration(milliseconds: 300));

  final Result? strength;

  @override
  _PasswordStrengthDisplayState createState() =>
      _PasswordStrengthDisplayState();
}

class _PasswordStrengthDisplayState
    extends AnimatedWidgetBaseState<PasswordStrengthDisplay> {
  static final _strengthColors = [
    Colors.red,
    Colors.orange,
    Colors.amber,
    Colors.lightGreen,
    Colors.green,
  ];

  Tween<double?>? _scoreTween;
  ColorTween? _colorTween;
  ColorTween? _backgroundColorTween;

  int get _score => widget.strength?.score?.toInt() ?? 0;

  String _label(AppLocalizations loc, int score) {
    return switch (score) {
      0 => loc.passwordStrengthVeryWeak,
      1 => loc.passwordStrengthWeak,
      2 => loc.passwordStrengthFair,
      3 => loc.passwordStrengthStrong,
      _ => loc.passwordStrengthVeryStrong,
    };
  }

  String _hint(AppLocalizations loc, int score) {
    return switch (score) {
      0 => loc.passwordStrengthHintVeryWeak,
      1 => loc.passwordStrengthHintWeak,
      2 => loc.passwordStrengthHintFair,
      3 => loc.passwordStrengthHintStrong,
      _ => loc.passwordStrengthHintVeryStrong,
    };
  }

  @override
  void forEachTween(visitor) {
    _scoreTween =
        visitor(
              _scoreTween,
              widget.strength == null ? 0.0 : (_score + 1).toDouble(),
              (dynamic value) => Tween<double>(begin: value as double?),
            )
            as Tween<double?>?;
    _colorTween =
        visitor(
              _colorTween,
              _strengthColors[_score],
              (dynamic value) => ColorTween(begin: value as Color?),
            )
            as ColorTween?;
    _backgroundColorTween =
        visitor(
              _backgroundColorTween,
              widget.strength == null
                  ? Colors.grey.shade300
                  : Colors.grey.shade400,
              (dynamic value) => ColorTween(begin: value as Color?),
            )
            as ColorTween?;
  }

  @override
  Widget build(BuildContext context) {
    final strength = widget.strength;
    if (strength == null) {
      return const SizedBox.shrink();
    }

    final loc = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final color = _colorTween!.evaluate(animation);

    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        LinearProgressIndicator(
          value: _scoreTween!.evaluate(animation)! / 5.0,
          valueColor: AlwaysStoppedAnimation(color),
          backgroundColor: _backgroundColorTween!.evaluate(animation),
          minHeight: 8,
          borderRadius: BorderRadius.circular(4),
        ),
        const SizedBox(height: 8),
        Text(
          '${loc.passwordScore(_score)} · ${_label(loc, _score)}',
          style: theme.textTheme.bodySmall!.copyWith(
            color: color,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          _hint(loc, _score),
          style: theme.textTheme.bodySmall,
        ),
      ],
    );
  }
}
