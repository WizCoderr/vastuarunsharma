import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../../core/constants/route_constants.dart';
import '../../../core/theme/app_colors.dart';
import '../../providers/auth_provider.dart';

class ProfileScreen extends ConsumerStatefulWidget {
  const ProfileScreen({super.key});

  @override
  ConsumerState<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends ConsumerState<ProfileScreen> {
  String _getAvatarInitials(String name) {
    final parts = name.trim().split(RegExp(r'\s+'));
    if (parts.length >= 3) {
      return parts.first[0].toUpperCase();
    } else if (parts.length == 2) {
      return '${parts[0][0]}${parts[1][0]}'.toUpperCase();
    } else {
      return parts.first.isNotEmpty ? parts.first[0].toUpperCase() : '?';
    }
  }

  String _getAvatarUrl(String name) {
    final initials = _getAvatarInitials(name);
    return 'https://ui-avatars.com/api/?name=$initials&background=D7A417&color=fff&size=128&bold=true';
  }

  void _handleLogout() {
    final authNotifier = ref.read(authStateProvider.notifier);
    authNotifier.logout();
  }

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authStateProvider);
    final user = authState.value;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Profile'),
        backgroundColor: Colors.transparent,
        foregroundColor: Colors.black,
        elevation: 0,
      ),
      body: user == null
          ? _buildGuestView(context)
          : RefreshIndicator(
              onRefresh: () async {
                // Refresh auth state - effectively re-fetches user details
                return ref.read(authStateProvider.notifier).checkAuthStatus();
              },
              child: SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.all(24),
                child: Column(
                  children: [
                    // Avatar
                    Container(
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(
                            color: AppColors.primary.withOpacity(0.3),
                            blurRadius: 20,
                            offset: const Offset(0, 8),
                          ),
                        ],
                      ),
                      child: CircleAvatar(
                        radius: 56,
                        backgroundColor: AppColors.primary,
                        backgroundImage: NetworkImage(_getAvatarUrl(user.name)),
                      ),
                    ),
                    const SizedBox(height: 20),

                    // Name
                    Text(
                      user.name,
                      style: const TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        color: AppColors.onBackground,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 6),

                    // Email
                    Text(
                      user.email,
                      style: TextStyle(fontSize: 15, color: Colors.grey[600]),
                    ),
                    if (user.mobileNumber != null &&
                        user.mobileNumber!.isNotEmpty) ...[
                      const SizedBox(height: 4),
                      Text(
                        user.mobileNumber!,
                        style: TextStyle(fontSize: 15, color: Colors.grey[600]),
                      ),
                    ],
                    const SizedBox(height: 12),

                    // Role Badge
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 6,
                      ),
                      decoration: BoxDecoration(
                        color: AppColors.secondary,
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(
                        user.role[0].toUpperCase() + user.role.substring(1),
                        style: const TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: AppColors.onSecondary,
                        ),
                      ),
                    ),
                    const SizedBox(height: 32),

                    // Stats Card
                    _buildStatsCard(
                      context,
                      count: user.enrolledCourseIds.length,
                      onTap: () => context.push(RouteConstants.myCourses),
                      label: 'My Courses',
                      iconColor: AppColors.primaryVariant,
                      backgroundColor: AppColors.secondaryVariant,
                    ),
                    const SizedBox(height: 48),

                    // Contact Section
                    _buildStatsCard(
                      context,
                      count: null,
                      onTap: () => _callWhatsAppChat("+919810520104"), 
                      label: 'Contact Us',
                      iconColor: AppColors.primaryVariant,
                      backgroundColor: AppColors.secondaryVariant,
                    ),

                    const SizedBox(height: 48),

                    // Logout Button
                    // Logout Button (Updated UI)
                    Container(
                      width: double.infinity,
                      margin: const EdgeInsets.only(bottom: 32),
                      child: OutlinedButton.icon(
                        onPressed: _handleLogout,
                        icon: const Icon(Icons.logout),
                        label: const Text(
                          'Sign Out',
                          style: TextStyle(
                            fontWeight: FontWeight.w600,
                            fontSize: 16,
                          ),
                        ),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: AppColors.error,
                          side: BorderSide(
                            color: AppColors.error.withOpacity(0.6),
                            width: 1.5,
                          ),
                          padding: const EdgeInsets.symmetric(vertical: 18),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(14),
                          ),
                        ),
                      ),
                    ),
                    // Footer
                    Column(
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Container(
                              width: 40,
                              height: 1,
                              color: Colors.grey.shade300,
                            ),
                            const SizedBox(width: 8),
                            const Icon(
                              Icons.verified_user,
                              size: 16,
                              color: Colors.grey,
                            ),
                            const SizedBox(width: 8),
                            Container(
                              width: 40,
                              height: 1,
                              color: Colors.grey.shade300,
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Vastu Arun Sharma',
                          style: TextStyle(
                            fontSize: 12,
                            letterSpacing: 1.2,
                            color: Colors.grey.shade500,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
    );
  }

  Widget _buildStatsCard<T>(
    BuildContext context, {
    required T?
    count, // Optional, can be null or any type (e.g., int, double, String)
    required VoidCallback onTap,
    required String label, // e.g., "My Courses", "Completed", "Total"
    IconData? leadingIcon = Icons.school,
    Color? backgroundColor = AppColors.secondaryVariant,
    Color? iconColor = AppColors.primaryVariant,
    TextStyle? labelStyle,
    TextStyle? countStyle,
    Color? countColor = AppColors.primary,
    double? iconSize = 28,
    double? labelFontSize = 14,
    double? countFontSize = 28,
    FontWeight? labelFontWeight = FontWeight.w600,
    FontWeight? countFontWeight = FontWeight.bold,
    Color? labelColor = AppColors.onBackground,
    Color? countColorOverride, // Optional override for count color
  }) {
    final shouldShowCount = count != null && count != 0;

    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: backgroundColor ?? AppColors.background,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: AppColors.primary.withOpacity(0.05),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: backgroundColor ?? AppColors.secondaryVariant,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(leadingIcon, color: iconColor, size: iconSize ?? 28),
            ),
            const SizedBox(width: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  label,
                  style:
                      labelStyle ??
                      TextStyle(
                        fontSize: labelFontSize ?? 14,
                        color: labelColor ?? AppColors.onBackground,
                        fontWeight: labelFontWeight ?? FontWeight.w600,
                      ),
                ),
                shouldShowCount ? SizedBox(width: 4) : SizedBox.shrink(),
                shouldShowCount
                    ? Text(
                        count.toString(),
                        style:
                            countStyle ??
                            TextStyle(
                              fontSize: countFontSize ?? 28,
                              fontWeight: countFontWeight ?? FontWeight.bold,
                              color:
                                  countColorOverride ??
                                  countColor ??
                                  AppColors.primary,
                            ),
                      )
                    : SizedBox.shrink(),
              ],
            ),
            const Spacer(),
            Icon(
              Icons.arrow_forward_ios,
              size: 18,
              color: AppColors.onBackground,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildGuestView(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.lock_outline, size: 64, color: AppColors.onBackground),
          const SizedBox(height: 24),
          Text(
            'Please login to view profile',
            style: TextStyle(fontSize: 16, color: AppColors.onBackground),
          ),
          const SizedBox(height: 24),
          ElevatedButton(
            onPressed: () => context.push(RouteConstants.login),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
              foregroundColor: AppColors.onPrimary,
              padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 12),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            child: const Text('Login'),
          ),
        ],
      ),
    );
  }

  void _callWhatsAppChat(String phoneNumber) {
    try {
      final uri = Uri.parse('https://api.whatsapp.com/send?phone=$phoneNumber');
      launchUrl(uri);
    } catch (e) {
      AlertDialog(
        title: const Text('Error'),
        content: const Text('Failed to open WhatsApp'),
        actions: [
          TextButton(
            child: const Text('OK'),
            onPressed: () => Navigator.pop(context),
          ),
        ],
      );
    }
  }
}
