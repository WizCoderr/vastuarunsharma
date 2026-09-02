import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/constants/route_constants.dart';
import '../../../core/errors/auth_action_exception.dart';
import '../../../core/utils/validators.dart';
import '../../../data/models/request/reset_password_request.dart';
import '../../../data/models/request/verify_reset_otp_request.dart';
import '../../providers/auth_provider.dart';
import '../../widgets/auth/auth_feedback_banner.dart';
import '../../widgets/auth/auth_form_shell.dart';

class ResetPasswordScreen extends ConsumerStatefulWidget {
  const ResetPasswordScreen({
    super.key,
    required this.email,
    this.devOtp,
  });

  final String? email;
  final String? devOtp;

  @override
  ConsumerState<ResetPasswordScreen> createState() =>
      _ResetPasswordScreenState();
}

class _ResetPasswordScreenState extends ConsumerState<ResetPasswordScreen> {
  final GlobalKey<FormState> _otpFormKey = GlobalKey<FormState>();
  final GlobalKey<FormState> _passwordFormKey = GlobalKey<FormState>();
  final TextEditingController _otpController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final TextEditingController _confirmPasswordController =
      TextEditingController();

  bool _isVerifying = false;
  bool _isResetting = false;
  bool _hasSubmittedOtp = false;
  bool _hasSubmittedPassword = false;
  bool _isPasswordVisible = false;
  bool _isConfirmPasswordVisible = false;
  String? _errorMessage;
  String? _infoMessage;
  String? _resetToken;

  String get _email => widget.email?.trim().toLowerCase() ?? '';

  bool get _emailMissing => _email.isEmpty;

  bool get _otpVerified => _resetToken != null && _resetToken!.isNotEmpty;

  @override
  void initState() {
    super.initState();
    final devOtp = widget.devOtp?.trim();
    if (devOtp != null && devOtp.isNotEmpty) {
      _otpController.text = devOtp;
      _infoMessage =
          'Email delivery is not configured on this server. Use the development code below.';
    }
  }

  @override
  void dispose() {
    _otpController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  Future<void> _verifyOtp() async {
    FocusScope.of(context).unfocus();
    setState(() {
      _hasSubmittedOtp = true;
      _errorMessage = null;
    });

    if (_emailMissing) {
      setState(() {
        _errorMessage =
            'Email is missing. Request a new reset code and try again.';
      });
      return;
    }

    if (!_otpFormKey.currentState!.validate()) {
      return;
    }

    setState(() {
      _isVerifying = true;
    });

    try {
      final response = await ref.read(authRepositoryProvider).verifyResetOtp(
        VerifyResetOtpRequest(email: _email, otp: _otpController.text),
      );

      if (!mounted) {
        return;
      }

      setState(() {
        _resetToken = response.resetToken;
        _infoMessage = response.message;
      });
    } on AuthActionException catch (error) {
      if (!mounted) {
        return;
      }

      setState(() {
        _errorMessage = error.message;
      });
    } finally {
      if (mounted) {
        setState(() {
          _isVerifying = false;
        });
      }
    }
  }

  Future<void> _resetPassword() async {
    FocusScope.of(context).unfocus();
    setState(() {
      _hasSubmittedPassword = true;
      _errorMessage = null;
    });

    if (!_otpVerified) {
      setState(() {
        _errorMessage = 'Verify the reset code before setting a new password.';
      });
      return;
    }

    if (!_passwordFormKey.currentState!.validate()) {
      return;
    }

    setState(() {
      _isResetting = true;
    });

    try {
      final response = await ref.read(authRepositoryProvider).resetPassword(
        ResetPasswordRequest(
          token: _resetToken!,
          password: _passwordController.text,
        ),
      );

      if (!mounted) {
        return;
      }

      ScaffoldMessenger.of(context)
        ..hideCurrentSnackBar()
        ..showSnackBar(SnackBar(content: Text(response.message)));

      await Future<void>.delayed(const Duration(milliseconds: 900));

      if (!mounted) {
        return;
      }

      context.go(RouteConstants.login);
    } on AuthActionException catch (error) {
      if (!mounted) {
        return;
      }

      setState(() {
        _errorMessage = error.message;
      });
    } finally {
      if (mounted) {
        setState(() {
          _isResetting = false;
        });
      }
    }
  }

  InputDecoration _inputDecoration(
    BuildContext context, {
    required String label,
    required String hint,
    required IconData icon,
    bool isObscured = false,
    VoidCallback? onToggleVisibility,
    bool readOnly = false,
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
      suffixIcon: onToggleVisibility == null
          ? null
          : IconButton(
              onPressed: onToggleVisibility,
              icon: Icon(
                isObscured
                    ? Icons.visibility_off_rounded
                    : Icons.visibility_rounded,
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

  String? _validateOtp(String? value) {
    final otp = value?.trim() ?? '';
    if (!RegExp(r'^\d{6}$').hasMatch(otp)) {
      return 'Enter the 6-digit code from your email';
    }
    return null;
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
        subtitle: _otpVerified
            ? 'Choose a secure password with at least 6 characters.'
            : 'Enter the 6-digit code we sent to your email to continue.',
        child: _emailMissing
            ? Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  AuthFeedbackBanner(
                    message:
                        'Email is missing from this reset request. Request a new reset code and try again.',
                    tone: AuthFeedbackTone.error,
                  ),
                  const SizedBox(height: 16),
                  OutlinedButton(
                    onPressed: () => context.go(RouteConstants.forgotPassword),
                    child: const Text('Request new code'),
                  ),
                ],
              )
            : Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  if (_infoMessage != null) ...[
                    AuthFeedbackBanner(
                      message: _infoMessage!,
                      tone: AuthFeedbackTone.success,
                    ),
                    const SizedBox(height: 16),
                  ],
                  if (_errorMessage != null) ...[
                    AuthFeedbackBanner(
                      message: _errorMessage!,
                      tone: AuthFeedbackTone.error,
                    ),
                    const SizedBox(height: 16),
                  ],
                  TextFormField(
                    initialValue: _email,
                    readOnly: true,
                    decoration: _inputDecoration(
                      context,
                      label: 'Email',
                      hint: _email,
                      icon: Icons.alternate_email_rounded,
                      readOnly: true,
                    ),
                  ),
                  const SizedBox(height: 16),
                  if (!_otpVerified)
                    Form(
                      key: _otpFormKey,
                      autovalidateMode: _hasSubmittedOtp
                          ? AutovalidateMode.onUserInteraction
                          : AutovalidateMode.disabled,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          TextFormField(
                            controller: _otpController,
                            keyboardType: TextInputType.number,
                            textInputAction: TextInputAction.done,
                            autofillHints: const [AutofillHints.oneTimeCode],
                            inputFormatters: [
                              FilteringTextInputFormatter.digitsOnly,
                              LengthLimitingTextInputFormatter(6),
                            ],
                            decoration: _inputDecoration(
                              context,
                              label: 'Reset code',
                              hint: '000000',
                              icon: Icons.pin_rounded,
                            ),
                            validator: _validateOtp,
                            onFieldSubmitted: (_) {
                              if (!_isVerifying) {
                                _verifyOtp();
                              }
                            },
                          ),
                          const SizedBox(height: 20),
                          FilledButton(
                            onPressed: _isVerifying ? null : _verifyOtp,
                            style: FilledButton.styleFrom(
                              minimumSize: const Size.fromHeight(54),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(18),
                              ),
                            ),
                            child: _isVerifying
                                ? const SizedBox(
                                    width: 20,
                                    height: 20,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                    ),
                                  )
                                : const Text('Verify code'),
                          ),
                        ],
                      ),
                    )
                  else
                    Form(
                      key: _passwordFormKey,
                      autovalidateMode: _hasSubmittedPassword
                          ? AutovalidateMode.onUserInteraction
                          : AutovalidateMode.disabled,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
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
                              onToggleVisibility: () {
                                setState(() {
                                  _isPasswordVisible = !_isPasswordVisible;
                                });
                              },
                            ),
                            validator: Validators.password,
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
                              onToggleVisibility: () {
                                setState(() {
                                  _isConfirmPasswordVisible =
                                      !_isConfirmPasswordVisible;
                                });
                              },
                            ),
                            validator: _validateConfirmPassword,
                            onFieldSubmitted: (_) {
                              if (!_isResetting) {
                                _resetPassword();
                              }
                            },
                          ),
                          const SizedBox(height: 20),
                          FilledButton(
                            onPressed: _isResetting ? null : _resetPassword,
                            style: FilledButton.styleFrom(
                              minimumSize: const Size.fromHeight(54),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(18),
                              ),
                            ),
                            child: _isResetting
                                ? const SizedBox(
                                    width: 20,
                                    height: 20,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                    ),
                                  )
                                : const Text('Reset password'),
                          ),
                        ],
                      ),
                    ),
                  const SizedBox(height: 12),
                  TextButton(
                    onPressed: (_isVerifying || _isResetting)
                        ? null
                        : () => context.go(RouteConstants.forgotPassword),
                    child: const Text('Request new code'),
                  ),
                  TextButton(
                    onPressed: (_isVerifying || _isResetting)
                        ? null
                        : () => context.go(RouteConstants.login),
                    child: const Text('Back to login'),
                  ),
                ],
              ),
      ),
    );
  }
}
