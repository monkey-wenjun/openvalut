import 'dart:async';

import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:openvalut/l10n-generated/app_localizations.dart';
import 'package:openvalut/utils/platform.dart';
import 'package:openvalut/utils/secure_window.dart';

/// Password input field which by default is obscured, but displays
/// a suffix icon to change it to make it visible.
class PasswordInputField extends StatefulWidget {
  const PasswordInputField({
    super.key,
    required this.labelText,
    this.autofocus = true,
    this.focusNode,
    this.validator,
    this.onEditingComplete,
    this.onFieldSubmitted,
    this.onChanged,
    this.controller,
    this.autovalidateMode,
    this.showVisibilityToggle = true,
    this.hintText,
    this.helperText,
  });

  final FocusNode? focusNode;
  final bool autofocus;
  final String labelText;
  final FormFieldValidator<String>? validator;
  final VoidCallback? onEditingComplete;
  final ValueChanged<String>? onFieldSubmitted;
  final ValueChanged<String>? onChanged;
  final TextEditingController? controller;
  final AutovalidateMode? autovalidateMode;
  final bool showVisibilityToggle;
  final String? hintText;
  final String? helperText;

  @override
  _PasswordInputFieldState createState() => _PasswordInputFieldState();
}

class _PasswordInputFieldState extends State<PasswordInputField> {
  bool _obscureText = true;
  late FocusNode _focusNode;
  late bool _ownsFocusNode;

  @override
  void initState() {
    super.initState();
    _attachFocusNode(widget.focusNode);
  }

  @override
  void didUpdateWidget(PasswordInputField oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.controller != oldWidget.controller) {
      _obscureText = true;
    }
    if (widget.focusNode != oldWidget.focusNode) {
      _detachFocusNode();
      _attachFocusNode(widget.focusNode);
    }
  }

  void _attachFocusNode(FocusNode? focusNode) {
    _ownsFocusNode = focusNode == null;
    _focusNode = focusNode ?? FocusNode();
    _focusNode.addListener(_handleFocusChanged);
  }

  void _detachFocusNode() {
    _focusNode.removeListener(_handleFocusChanged);
    if (_focusNode.hasFocus && OpenValutPlatform.isMacOS) {
      unawaited(SecureWindow.setSecureEventInput(false));
    }
    if (_ownsFocusNode) {
      _focusNode.dispose();
    }
  }

  void _handleFocusChanged() {
    if (OpenValutPlatform.isMacOS) {
      unawaited(SecureWindow.setSecureEventInput(_focusNode.hasFocus));
    }
  }

  @override
  void dispose() {
    _detachFocusNode();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context);
    final isDesktop =
        !OpenValutPlatform.isIOS && !OpenValutPlatform.isAndroid;
    return TextFormField(
      autofocus: widget.autofocus,
      focusNode: _focusNode,
      controller: widget.controller,
      onFieldSubmitted: widget.onFieldSubmitted,
      decoration: InputDecoration(
        labelText: widget.labelText,
        hintText: widget.hintText,
        helperText: widget.helperText,
        contentPadding: isDesktop
            ? const EdgeInsets.symmetric(vertical: 18, horizontal: 12)
            : null,
        suffixIcon: widget.showVisibilityToggle
            ? IconButton(
                icon: _obscureText
                    ? const FaIcon(FontAwesomeIcons.eye)
                    : const FaIcon(FontAwesomeIcons.eyeSlash),
                onPressed: () {
                  setState(() {
                    _obscureText = !_obscureText;
                  });
                },
                tooltip: loc.passwordPlainText,
              )
            : null,
      ),
      autocorrect: false,
      enableSuggestions: false,
      keyboardType: TextInputType.visiblePassword,
      autovalidateMode: widget.autovalidateMode,
      obscureText: _obscureText,
      validator: widget.validator,
      onEditingComplete: widget.onEditingComplete,
      onChanged: widget.onChanged,
    );
  }
}
