import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../core/constants/route_constants.dart';
import '../../../core/utils/validators.dart';
import '../../../data/models/request/forgot_password_request.dart';
import '../../../data/services/auth_service.dart';
import '../../widgets/auth/auth_feedback_banner.dart';
import '../../widgets/auth/auth_form_shell.dart';

class ForgotPasswordScreen extends StatefulWidget {
  const ForgotPasswordScreen({super.key, this.authService});

  final AuthService? authService;

  @override
  State<ForgotPasswordScreen> createState() => _ForgotPasswordScreenState();
}

class _ForgotPasswordScreenState extends State<ForgotPasswordScreen> {
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  final TextEditingController _emailController = TextEditingController();

  late final AuthService _authService;

  bool _isLoading = false;
  bool _hasSubmitted = false;
  bool _emailSent = false;
  String? _errorMessage;
  String? _successMessage;

  @override
  void initState() {
    super.initState();
    _authService = widget.authService ?? AuthService();
  }

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

    try {
      final response = await _authService.forgotPassword(
        ForgotPasswordRequest(email: _emailController.text),
      );

      if (!mounted) {
        return;
      }

      setState(() {
        _emailSent = true;
        _successMessage = response.message;
      });

      ScaffoldMessenger.of(context)
        ..hideCurrentSnackBar()
        ..showSnackBar(SnackBar(content: Text(response.message)));
    } on AuthServiceException catch (error) {
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
            'Enter the email linked to your account and we will send you a secure reset link.',
        child: AnimatedSwitcher(
          duration: const Duration(milliseconds: 200),
          child: _emailSent ? _buildSuccessState(context) : _buildForm(context),
        ),
      ),
    );
  }

  Widget _buildForm(BuildContext context) {
    return Form(
      key: _formKey,
      autovalidateMode: _hasSubmitted
          ? AutovalidateMode.onUserInteraction
          : AutovalidateMode.disabled,
      child: Column(
        key: const ValueKey('forgot-form'),
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
                  : const Text('Send reset link'),
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
    );
  }

  Widget _buildSuccessState(BuildContext context) {
    final theme = Theme.of(context);

    return Column(
      key: const ValueKey('forgot-success'),
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        AuthFeedbackBanner(
          message:
              _successMessage ??
              'If the account exists, a reset link has been sent.',
          tone: AuthFeedbackTone.success,
        ),
        const SizedBox(height: 20),
        Text(
          'Check your inbox and follow the reset instructions. If you do not see the email, check your spam folder or try again.',
          style: theme.textTheme.bodyMedium?.copyWith(
            color: theme.colorScheme.onSurfaceVariant,
            height: 1.5,
          ),
        ),
        const SizedBox(height: 24),
        FilledButton(
          onPressed: _isLoading
              ? null
              : () {
                  setState(() {
                    _emailSent = false;
                    _errorMessage = null;
                  });
                },
          style: FilledButton.styleFrom(
            minimumSize: const Size.fromHeight(54),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(18),
            ),
          ),
          child: const Text('Send to another email'),
        ),
        const SizedBox(height: 12),
        TextButton(
          onPressed: () => context.go(RouteConstants.login),
          child: const Text('Back to login'),
        ),
      ],
    );
  }
}
