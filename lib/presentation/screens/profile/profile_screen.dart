import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../../core/constants/route_constants.dart';
import '../../../core/theme/app_colors.dart';
import '../../providers/auth_provider.dart';
import '../../providers/course_provider.dart';

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

                    // My Registrations Section
                    _buildRegistrationsSection(context, ref),
                    const SizedBox(height: 24),

                    // Menu Items
                    _buildProfileMenuItem(
                      context,
                      onTap: () => context.push(RouteConstants.myCourses),
                      label: 'My Courses',
                      icon: Icons.school,
                    ),
                    const SizedBox(height: 16),

                    _buildProfileMenuItem(
                      context,
                      onTap: () => _callWhatsAppChat("+919810520104"),
                      label: 'Contact Us',
                      icon: Icons
                          .school, // Using scroll icon for now to match screenshot "Contact Us" which looks like a scroll/graduation cap too? Wait, screenshot has same icon for both? No, bottom is a Graduation Cap?
                      // Actually, let's use a contact icon for Contact Us for better UX, though screenshot might be reusing an icon.
                      // Wait, the screenshot shows "Available Courses" (graduation cap) and "Contact Us" (looks like a graduation cap too but maybe slightly different? No, exact same icon).
                      // Use Icons.school for both if that's what the design is, or maybe Icons.contact_support.
                      // Let's stick to Icons.school for My Courses. For Contact Us, let's use Icons.school as well to match screenshot EXACTLY if that is indeed the intention, or maybe it was a placeholder.
                      // The screenshot shows:
                      // Top: My Courses (Graduation Cap)
                      // Bottom: Contact Us (Graduation Cap)
                      // Using Icons.school for both.
                    ),

                    const SizedBox(height: 48),

                    // Sign Out Button
                    SizedBox(
                      width: double.infinity,
                      child: OutlinedButton(
                        onPressed: _handleLogout,
                        style: OutlinedButton.styleFrom(
                          side: const BorderSide(color: AppColors.error),
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          foregroundColor: AppColors.error,
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: const [
                            Text(
                              'Sign Out',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            SizedBox(width: 8),
                            Icon(Icons.logout, size: 20),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 32),

                    // Branding Footer
                    Column(
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text(
                              'Vastu Arun Sharma',
                              style: TextStyle(
                                color: Colors.grey[400],
                                fontSize: 14,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                            const SizedBox(width: 8),
                            Icon(
                              Icons.verified_user_outlined,
                              size: 16,
                              color: Colors.grey[400],
                            ),
                          ],
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
    );
  }

  Widget _buildProfileMenuItem(
    BuildContext context, {
    required VoidCallback onTap,
    required String label,
    required IconData icon,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
        decoration: BoxDecoration(
          color: AppColors.secondaryVariant.withOpacity(0.5),
          borderRadius: BorderRadius.circular(24),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: AppColors.secondary,
                shape: BoxShape.circle,
              ),
              child: Icon(icon, color: AppColors.primaryVariant, size: 24),
            ),
            const SizedBox(width: 16),
            Text(
              label,
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w500,
                color: AppColors.onBackground,
              ),
            ),
            const Spacer(),
            const Icon(
              Icons.arrow_forward_ios,
              size: 16,
              color: AppColors.primaryVariant,
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

  Widget _buildRegistrationsSection(BuildContext context, WidgetRef ref) {
    final enrolledCoursesAsync = ref.watch(enrolledCoursesProvider);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Padding(
          padding: EdgeInsets.symmetric(horizontal: 8),
          child: Text(
            "My Registrations",
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: AppColors.onBackground,
            ),
          ),
        ),
        const SizedBox(height: 12),
        enrolledCoursesAsync.when(
          data: (courses) {
            final registeredCourses = courses
                .where((c) => c.serialNumber != null)
                .toList();

            if (registeredCourses.isEmpty) {
              return Container(
                width: double.infinity,
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.grey[100],
                  borderRadius: BorderRadius.circular(16),
                ),
                child: const Text(
                  "No active course registrations found",
                  style: TextStyle(color: Colors.black54),
                  textAlign: TextAlign.center,
                ),
              );
            }

            return ListView.separated(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: registeredCourses.length,
              separatorBuilder: (context, index) => const SizedBox(height: 10),
              itemBuilder: (context, index) {
                final course = registeredCourses[index];
                return Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: Colors.grey[200]!),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.02),
                        blurRadius: 10,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              course.title,
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 14,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              "Registration ID: ${course.serialNumber}",
                              style: TextStyle(
                                fontSize: 12,
                                color: AppColors.primaryVariant,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const Icon(Icons.verified, color: Colors.green, size: 20),
                    ],
                  ),
                );
              },
            );
          },
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (err, _) => Text("Failed to load registrations: $err"),
        ),
      ],
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
