import 'package:flutter/material.dart';

enum AuthFeedbackTone { success, error, info }

class AuthFeedbackBanner extends StatelessWidget {
  const AuthFeedbackBanner({
    super.key,
    required this.message,
    this.tone = AuthFeedbackTone.info,
  });

  final String message;
  final AuthFeedbackTone tone;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    final BannerStyle style = switch (tone) {
      AuthFeedbackTone.success => BannerStyle(
        backgroundColor: const Color(0xFFEAF7EE),
        foregroundColor: const Color(0xFF1E6B3A),
        icon: Icons.check_circle_rounded,
      ),
      AuthFeedbackTone.error => BannerStyle(
        backgroundColor: const Color(0xFFFCECEC),
        foregroundColor: colorScheme.error,
        icon: Icons.error_rounded,
      ),
      AuthFeedbackTone.info => BannerStyle(
        backgroundColor: colorScheme.surfaceContainerHighest,
        foregroundColor: colorScheme.onSurfaceVariant,
        icon: Icons.info_rounded,
      ),
    };

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: style.backgroundColor,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(style.icon, color: style.foregroundColor),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              message,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: style.foregroundColor,
                height: 1.4,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class BannerStyle {
  const BannerStyle({
    required this.backgroundColor,
    required this.foregroundColor,
    required this.icon,
  });

  final Color backgroundColor;
  final Color foregroundColor;
  final IconData icon;
}
