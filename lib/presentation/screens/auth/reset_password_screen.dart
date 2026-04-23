import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../core/constants/route_constants.dart';
import '../../../core/utils/validators.dart';
import '../../../data/models/request/reset_password_request.dart';
import '../../../data/services/auth_service.dart';
import '../../widgets/auth/auth_feedback_banner.dart';
import '../../widgets/auth/auth_form_shell.dart';

class ResetPasswordScreen extends StatefulWidget {
  const ResetPasswordScreen({super.key, required this.token, this.authService});

  final String? token;
  final AuthService? authService;

  @override
  State<ResetPasswordScreen> createState() => _ResetPasswordScreenState();
}

class _ResetPasswordScreenState extends State<ResetPasswordScreen> {
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  final TextEditingController _passwordController = TextEditingController();
  final TextEditingController _confirmPasswordController =
      TextEditingController();

  late final AuthService _authService;

  bool _isLoading = false;
  bool _hasSubmitted = false;
  bool _isPasswordVisible = false;
  bool _isConfirmPasswordVisible = false;
  bool _isTokenInvalid = false;
  String? _errorMessage;

  String get _token => widget.token?.trim() ?? '';

  bool get _hasToken => _token.isNotEmpty;

  @override
  void initState() {
    super.initState();
    _authService = widget.authService ?? AuthService();

    if (!_hasToken) {
      _isTokenInvalid = true;
      _errorMessage =
          'This reset link is incomplete or missing. Request a new password reset email and try again.';
    }
  }

  @override
  void dispose() {
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    FocusScope.of(context).unfocus();
    setState(() {
      _hasSubmitted = true;
      if (!_isTokenInvalid) {
        _errorMessage = null;
      }
    });

    if (!_hasToken) {
      setState(() {
        _isTokenInvalid = true;
        _errorMessage =
            'This reset link is incomplete or missing. Request a new password reset email and try again.';
      });
      return;
    }

    if (!_formKey.currentState!.validate()) {
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      final response = await _authService.resetPassword(
        ResetPasswordRequest(token: _token, password: _passwordController.text),
      );

      if (!mounted) {
        return;
      }

      final messenger = ScaffoldMessenger.of(context);
      messenger
        ..hideCurrentSnackBar()
        ..showSnackBar(SnackBar(content: Text(response.message)));

      await Future<void>.delayed(const Duration(milliseconds: 900));

      if (!mounted) {
        return;
      }

      context.go(RouteConstants.login);
    } on AuthServiceException catch (error) {
      if (!mounted) {
        return;
      }

      setState(() {
        _errorMessage = error.message;
        _isTokenInvalid = error.isInvalidToken || !_hasToken;
      });
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  InputDecoration _inputDecoration(
    BuildContext context, {
    required String label,
    required String hint,
    required IconData icon,
    required bool isObscured,
    required VoidCallback onToggle,
  }) {
    final colorScheme = Theme.of(context).colorScheme;

    OutlineInputBorder buildBorder(Color color) {
      return OutlineInputBorder(
        borderRadius: BorderRadius.circular(18),
        borderSide: BorderSide(color: color),
      );
    }

    return InputDecoration(
      labelText: label,
      hintText: hint,
      prefixIcon: Icon(icon),
      suffixIcon: IconButton(
        onPressed: onToggle,
        icon: Icon(
          isObscured ? Icons.visibility_off_rounded : Icons.visibility_rounded,
        ),
      ),
      filled: true,
      fillColor: colorScheme.surface,
      border: buildBorder(colorScheme.outlineVariant),
      enabledBorder: buildBorder(colorScheme.outlineVariant),
      focusedBorder: buildBorder(colorScheme.primary),
      errorBorder: buildBorder(colorScheme.error),
      focusedErrorBorder: buildBorder(colorScheme.error),
      contentPadding: const EdgeInsets.symmetric(horizontal: 18, vertical: 18),
    );
  }

  String? _validatePassword(String? value) {
    return Validators.password(value);
  }

  String? _validateConfirmPassword(String? value) {
    if (value == null || value.isEmpty) {
      return 'Confirm your new password';
    }
    if (value != _passwordController.text) {
      return 'Passwords do not match';
    }
    return null;
  }

  @override
  Widget build(BuildContext context) {
    final bool disableSubmit = _isLoading || !_hasToken;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Reset Password'),
        backgroundColor: Theme.of(context).scaffoldBackgroundColor,
        foregroundColor: Theme.of(context).colorScheme.onSurface,
        elevation: 0,
      ),
      body: AuthFormShell(
        icon: Icons.lock_reset_outlined,
        title: 'Create new password',
        subtitle:
            'Choose a secure password with at least 6 characters. You will use it the next time you sign in.',
        child: Form(
          key: _formKey,
          autovalidateMode: _hasSubmitted
              ? AutovalidateMode.onUserInteraction
              : AutovalidateMode.disabled,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              if (_errorMessage != null) ...[
                AuthFeedbackBanner(
                  message: _errorMessage!,
                  tone: AuthFeedbackTone.error,
                ),
                const SizedBox(height: 16),
              ],
              TextFormField(
                controller: _passwordController,
                obscureText: !_isPasswordVisible,
                autofillHints: const [AutofillHints.newPassword],
                textInputAction: TextInputAction.next,
                decoration: _inputDecoration(
                  context,
                  label: 'New password',
                  hint: 'Enter your new password',
                  icon: Icons.lock_outline_rounded,
                  isObscured: !_isPasswordVisible,
                  onToggle: () {
                    setState(() {
                      _isPasswordVisible = !_isPasswordVisible;
                    });
                  },
                ),
                validator: _validatePassword,
                onChanged: (_) {
                  if (_errorMessage != null && !_isTokenInvalid) {
                    setState(() {
                      _errorMessage = null;
                    });
                  }
                },
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _confirmPasswordController,
                obscureText: !_isConfirmPasswordVisible,
                autofillHints: const [AutofillHints.newPassword],
                textInputAction: TextInputAction.done,
                decoration: _inputDecoration(
                  context,
                  label: 'Confirm password',
                  hint: 'Re-enter your new password',
                  icon: Icons.lock_person_outlined,
                  isObscured: !_isConfirmPasswordVisible,
                  onToggle: () {
                    setState(() {
                      _isConfirmPasswordVisible = !_isConfirmPasswordVisible;
                    });
                  },
                ),
                validator: _validateConfirmPassword,
                onFieldSubmitted: (_) {
                  if (!disableSubmit) {
                    _submit();
                  }
                },
              ),
              const SizedBox(height: 20),
              SizedBox(
                width: double.infinity,
                child: FilledButton(
                  onPressed: disableSubmit ? null : _submit,
                  style: FilledButton.styleFrom(
                    minimumSize: const Size.fromHeight(54),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(18),
                    ),
                  ),
                  child: _isLoading
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Text('Reset password'),
                ),
              ),
              const SizedBox(height: 12),
              if (_isTokenInvalid)
                OutlinedButton(
                  onPressed: _isLoading
                      ? null
                      : _hasToken
                      ? _submit
                      : () => context.go(RouteConstants.forgotPassword),
                  style: OutlinedButton.styleFrom(
                    minimumSize: const Size.fromHeight(50),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(18),
                    ),
                  ),
                  child: Text(_hasToken ? 'Retry' : 'Request new link'),
                ),
              if (_isTokenInvalid) const SizedBox(height: 8),
              TextButton(
                onPressed: _isLoading
                    ? null
                    : () => context.go(RouteConstants.login),
                child: const Text('Back to login'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
