import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/constants/route_constants.dart';
import '../../../core/errors/auth_action_exception.dart';
import '../../../core/utils/validators.dart';
import '../../../data/models/request/forgot_password_request.dart';
import '../../providers/auth_provider.dart';
import '../../widgets/auth/auth_feedback_banner.dart';
import '../../widgets/auth/auth_form_shell.dart';

class ForgotPasswordScreen extends ConsumerStatefulWidget {
  const ForgotPasswordScreen({super.key});

  @override
  ConsumerState<ForgotPasswordScreen> createState() =>
      _ForgotPasswordScreenState();
}

class _ForgotPasswordScreenState extends ConsumerState<ForgotPasswordScreen> {
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  final TextEditingController _emailController = TextEditingController();

  bool _isLoading = false;
  bool _hasSubmitted = false;
  String? _errorMessage;

  @override
  void dispose() {
    _emailController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    FocusScope.of(context).unfocus();
    setState(() {
      _hasSubmitted = true;
      _errorMessage = null;
    });

    if (!_formKey.currentState!.validate()) {
      return;
    }

    setState(() {
      _isLoading = true;
    });

    final email = _emailController.text.trim().toLowerCase();

    try {
      final response = await ref.read(authRepositoryProvider).forgotPassword(
        ForgotPasswordRequest(email: email),
      );

      if (!mounted) {
        return;
      }

      ScaffoldMessenger.of(context)
        ..hideCurrentSnackBar()
        ..showSnackBar(SnackBar(content: Text(response.message)));

      context.go(
        RouteConstants.resetPasswordPath(
          email: email,
          devOtp: response.devOtp,
        ),
      );
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
          _isLoading = false;
        });
      }
    }
  }

  InputDecoration _inputDecoration(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    OutlineInputBorder buildBorder(Color color) {
      return OutlineInputBorder(
        borderRadius: BorderRadius.circular(18),
        borderSide: BorderSide(color: color),
      );
    }

    return InputDecoration(
      labelText: 'Email address',
      hintText: 'user@example.com',
      prefixIcon: const Icon(Icons.alternate_email_rounded),
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Forgot Password'),
        backgroundColor: Theme.of(context).scaffoldBackgroundColor,
        foregroundColor: Theme.of(context).colorScheme.onSurface,
        elevation: 0,
      ),
      body: AuthFormShell(
        icon: Icons.mark_email_read_outlined,
        title: 'Reset your password',
        subtitle:
            'Enter the email linked to your account and we will send you a 6-digit reset code.',
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
                controller: _emailController,
                keyboardType: TextInputType.emailAddress,
                textInputAction: TextInputAction.send,
                autofillHints: const [AutofillHints.email],
                decoration: _inputDecoration(context),
                validator: Validators.email,
                onFieldSubmitted: (_) {
                  if (!_isLoading) {
                    _submit();
                  }
                },
                onChanged: (_) {
                  if (_errorMessage != null) {
                    setState(() {
                      _errorMessage = null;
                    });
                  }
                },
              ),
              const SizedBox(height: 20),
              SizedBox(
                width: double.infinity,
                child: FilledButton(
                  onPressed: _isLoading ? null : _submit,
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
                      : const Text('Send reset code'),
                ),
              ),
              const SizedBox(height: 12),
              Align(
                alignment: Alignment.center,
                child: TextButton(
                  onPressed: _isLoading
                      ? null
                      : () => context.go(RouteConstants.login),
                  child: const Text('Back to login'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
