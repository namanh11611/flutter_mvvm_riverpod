import 'package:flutter/material.dart';

import '/theme/app_colors.dart';
import '/theme/app_theme.dart';

class CommonTextFormField extends StatefulWidget {
  final String label;
  final TextEditingController? controller;
  final String? Function(String?)? validator;
  final String? errorText;
  final bool isPassword;

  const CommonTextFormField({
    super.key,
    required this.label,
    this.controller,
    this.validator,
    this.errorText,
    this.isPassword = false,
  });

  @override
  State<CommonTextFormField> createState() => _CommonTextFormFieldState();
}

class _CommonTextFormFieldState extends State<CommonTextFormField> {
  bool _isObscure = false;
  String? _errorText;
  final FocusNode _focus = FocusNode();

  @override
  void initState() {
    super.initState();
    _isObscure = widget.isPassword;
    _focus.addListener(_onFocusChange);
  }

  @override
  void dispose() {
    _focus.removeListener(_onFocusChange);
    _focus.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return TextFormField(
      controller: widget.controller,
      validator: widget.validator,
      obscureText: _isObscure,
      decoration: InputDecoration(
        labelText: widget.label,
        labelStyle: AppTheme.body16,
        border: const OutlineInputBorder(
          borderRadius: BorderRadius.all(Radius.circular(8)),
        ),
        suffixIcon: widget.isPassword
            ? IconButton(
                icon: Icon(
                  _isObscure ? Icons.visibility : Icons.visibility_off,
                ),
                onPressed: () {
                  setState(() {
                    _isObscure = !_isObscure;
                  });
                },
              )
            : null,
        errorText: widget.errorText ?? _errorText,
        errorStyle: AppTheme.body12.copyWith(color: AppColors.rambutan100),
      ),
      onChanged: (value) {
        final error = widget.validator?.call(widget.controller?.text);
        if (error == null) {
          setState(() {
            _errorText = null;
          });
        }
      },
      focusNode: _focus,
    );
  }

  void _onFocusChange() {
    if (!_focus.hasFocus) {
      setState(() {
        _errorText = widget.validator?.call(widget.controller?.text);
      });
    }
  }
}
