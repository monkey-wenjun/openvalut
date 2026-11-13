import 'package:openvalut/bloc/app_data.dart';
import 'package:openvalut/bloc/kdbx/file_source.dart';
import 'package:openvalut/bloc/kdbx/file_source_openvalut_cloud.dart';
import 'package:openvalut/bloc/kdbx_bloc.dart';
import 'package:openvalut/l10n-generated/app_localizations.dart';
import 'package:openvalut/ui/screens/create_file.dart';
import 'package:clock/clock.dart';
import 'package:openvalut/ui/widgets/password_input_field.dart';
import 'package:openvalut/ui/widgets/primary_button.dart';
import 'package:openvalut/utils/constants.dart';
import 'package:openvalut/utils/dialog_utils.dart';
import 'package:flutter/material.dart';
import 'package:flutter_async_utils/flutter_async_utils.dart';
import 'package:kdbx/kdbx.dart';
import 'package:logging/logging.dart';
import 'package:provider/provider.dart';
import 'package:recase/recase.dart';
import 'package:zxcvbn/zxcvbn.dart';

final _logger = Logger('master_password_change');

class MasterPasswordChangeScreen extends StatelessWidget {
  const MasterPasswordChangeScreen({
    super.key,
    required this.fileSource,
  });

  static Route<void> route({
    required FileSource fileSource,
  }) => MaterialPageRoute(
    builder: (context) => MasterPasswordChangeScreen(fileSource: fileSource),
    settings: const RouteSettings(name: 'masterPasswordChange'),
  );

  final FileSource fileSource;

  @override
  Widget build(BuildContext context) {
    final kdbxBloc = Provider.of<KdbxBloc>(context);
    final loc = AppLocalizations.of(context);

    return Scaffold(
      appBar: AppBar(
        title: Text(loc.changeMasterPasswordScreenTitle),
      ),
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(32),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 560),
            child: MasterPasswordChangeForm(
              fileSource: fileSource,
              file: kdbxBloc.fileForFileSource(fileSource)!.kdbxFile,
            ),
          ),
        ),
      ),
    );
  }
}

class MasterPasswordChangeForm extends StatefulWidget {
  const MasterPasswordChangeForm({
    super.key,
    required this.fileSource,
    required this.file,
  });

  final FileSource fileSource;
  final KdbxFile file;

  @override
  _MasterPasswordChangeFormState createState() =>
      _MasterPasswordChangeFormState();
}

class _MasterPasswordChangeFormState extends State<MasterPasswordChangeForm>
    with FutureTaskStateMixin {
  static final _zxcvbn = Zxcvbn();

  final _databaseName = TextEditingController();
  final TextEditingController _password = TextEditingController();
  final TextEditingController _passwordConfirm = TextEditingController();

  final FocusNode _passwordFocus = FocusNode();
  final FocusNode _passwordConfirmFocus = FocusNode();

  final GlobalKey<FormState> _formKey = GlobalKey();
  Result? _strength;

  @override
  void initState() {
    super.initState();
    _databaseName.text = widget.file.body.rootGroup.name.get()!;
  }

  @override
  void dispose() {
    _databaseName.dispose();
    _password.dispose();
    _passwordConfirm.dispose();
    _passwordFocus.dispose();
    _passwordConfirmFocus.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final loc = AppLocalizations.of(context);
    return Form(
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
              TextFormField(
                controller: _databaseName,
                decoration: InputDecoration(
                  labelText: loc.nameNewPasswordDatabase,
                  suffixText: '.kdbx', // NON-NLS
                  filled: true,
                ),
                readOnly: true,
                textInputAction: TextInputAction.next,
                onFieldSubmitted: (val) => _passwordFocus.requestFocus(),
                validator: (val) {
                  if (val!.isEmpty) {
                    return loc.validatorNameMissing;
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              PasswordInputField(
                labelText: loc.inputMasterPasswordText,
                controller: _password,
                focusNode: _passwordFocus,
                autofocus: true,
                onFieldSubmitted: (val) => _passwordConfirmFocus.requestFocus(),
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
                  return null;
                },
              ),
              const SizedBox(height: 8),
              PasswordStrengthDisplay(strength: _strength),
              const SizedBox(height: 8),
              PasswordInputField(
                labelText: loc.changeMasterPasswordConfirmLabel,
                controller: _passwordConfirm,
                focusNode: _passwordConfirmFocus,
                onFieldSubmitted: (val) => _submitCallback()!(),
                autovalidateMode: AutovalidateMode.onUserInteraction,
                validator: (val) {
                  if (val == null || val != _password.text) {
                    return loc.cloudPasswordMismatch;
                  }
                  return null;
                },
              ),
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
                        child: Text(loc.changeMasterPasswordFormSubmit),
                      ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  VoidCallback? _submitCallback() => asyncTaskCallback((progress) async {
    if (_formKey.currentState!.validate()) {
      final loc = AppLocalizations.of(context);
      final kdbxBloc = Provider.of<KdbxBloc>(context, listen: false);
      if (widget.file.credentials is TransformedKeyCredentials) {
        // A file opened with the remembered (transformed) key is read-only;
        // the master password must be entered once before it can be changed.
        await DialogUtils.showSimpleAlertDialog(
          context,
          loc.changeMasterPasswordScreenTitle,
          loc.masterChangeLockedFirst,
          routeAppend: 'masterPasswordChangeReadonly',
        );
        return;
      }
      final cloud = widget.fileSource is FileSourceopenvalutCloud
          ? widget.fileSource as FileSourceopenvalutCloud
          : null;
      if (cloud != null) {
        // Cloud vaults encrypt the whole blob with a key derived from the
        // master password, so the new password must also rotate the vault
        // key before the re-encrypted blob is uploaded.
        cloud.masterPassword = _password.text;
        cloud.invalidateVaultKeyCache();
      }
      await kdbxBloc.saveFile(
        widget.file,
        updateCredentials: Credentials.composite(
          ProtectedValue.fromString(_password.text),
          null,
        ),
      );
      if (cloud != null) {
        // The save only diffs plaintext payloads, so unchanged rows would
        // keep their old-key ciphertext on the server. Force a full
        // re-encryption of every row and the blob under the new key.
        try {
          await cloud.rotateVaultKey(widget.file);
        } catch (e, stackTrace) {
          _logger.warning('Cloud vault key rotation failed.', e, stackTrace);
          // ignore: use_build_context_synchronously
          await DialogUtils.showSimpleAlertDialog(
            // ignore: use_build_context_synchronously
            context,
            loc.changeMasterPasswordRotationFailedTitle,
            loc.changeMasterPasswordRotationFailedBody('$e'),
            routeAppend: 'masterPasswordChangeRotationFailed',
          );
          return;
        }
      }
      final appDataBloc = Provider.of<AppDataBloc>(context, listen: false);
      // The old remembered credentials are stale now; drop them so the next
      // unlock asks for the new password.
      await kdbxBloc.clearRememberedUnlock();
      await kdbxBloc.disableQuickUnlock();
      await appDataBloc.update(
        (builder, data) => builder.lastPasswordChangeDate = clock.now().toUtc(),
      );
      // ignore: use_build_context_synchronously
      context.showSnackBar(loc.changeMasterPasswordSuccess);
      if (!mounted) {
        return;
      }
      // ignore: use_build_context_synchronously
      await DialogUtils.showSimpleAlertDialog(
        context,
        loc.changeMasterPasswordCleanupTitle,
        <String>[
          loc.changeMasterPasswordCleanupDevices,
          loc.changeMasterPasswordCleanupBackups,
          loc.changeMasterPasswordCleanupQuickUnlock,
        ].join('\n\n'),
        routeAppend: 'masterPasswordChangeCleanup',
      );
      if (!mounted) {
        return;
      }
      Navigator.of(context).pop();
    }
  });
}
