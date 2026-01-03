import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:gap/gap.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/di/injection_container.dart';
import '../../../../route/route_name.dart';

class ProfileTab extends ConsumerWidget {
  const ProfileTab({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(firebaseAuthProvider).currentUser;

    return SingleChildScrollView(
      padding: EdgeInsets.all(24.w),
      child: Column(
        children: [
          Gap(20.h),
          // Profile Avatar
          CircleAvatar(
            radius: 50.r,
            backgroundColor: AppColors.primary,
            child: Text(
              _getInitials(user?.email ?? 'U'),
              style: TextStyle(fontSize: 32.sp, fontWeight: FontWeight.bold, color: Colors.white),
            ),
          ),
          Gap(16.h),
          // Email
          Text(
            user?.email ?? 'No email',
            style: TextStyle(fontSize: 18.sp, fontWeight: FontWeight.w600, color: AppColors.textPrimary),
          ),
          Gap(8.h),
          // UID
          Text(
            'UID: ${user?.uid.substring(0, 8) ?? 'N/A'}...',
            style: TextStyle(fontSize: 12.sp, color: AppColors.textSecondary),
          ),
          Gap(32.h),
          // Profile Options
          _buildProfileOption(icon: Icons.person_outline, title: 'Account Settings', onTap: () {}),
          _buildProfileOption(icon: Icons.notifications_outlined, title: 'Notifications', onTap: () {}),
          _buildProfileOption(icon: Icons.help_outline, title: 'Help & Support', onTap: () {}),
          _buildProfileOption(icon: Icons.info_outline, title: 'About', onTap: () => _showAboutDialog(context)),
          Gap(24.h),
          // Logout Button
          SizedBox(
            width: double.infinity,
            child: OutlinedButton.icon(
              onPressed: () => _showLogoutDialog(context),
              icon: const Icon(Icons.logout, color: AppColors.error),
              label: const Text('Logout', style: TextStyle(color: AppColors.error)),
              style: OutlinedButton.styleFrom(
                padding: EdgeInsets.symmetric(vertical: 16.h),
                side: const BorderSide(color: AppColors.error),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12.r)),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildProfileOption({required IconData icon, required String title, required VoidCallback onTap}) {
    return ListTile(
      leading: Icon(icon, color: AppColors.primary),
      title: Text(title),
      trailing: const Icon(Icons.chevron_right),
      onTap: onTap,
    );
  }

  String _getInitials(String email) {
    if (email.isEmpty) return 'U';
    return email[0].toUpperCase();
  }

  void _showLogoutDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Logout'),
        content: const Text('Are you sure you want to logout?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
          TextButton(
            onPressed: () async {
              Navigator.pop(context);
              await FirebaseAuth.instance.signOut();
              if (context.mounted) {
                Navigator.of(context).pushNamedAndRemoveUntil(RouteName.login, (route) => false);
              }
            },
            style: TextButton.styleFrom(foregroundColor: AppColors.error),
            child: const Text('Logout'),
          ),
        ],
      ),
    );
  }

  void _showAboutDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => const AlertDialog(
        title: Text('About e-Signature'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Version: 1.0.0'),
            SizedBox(height: 8),
            Text('A simple app to upload, edit, and sign PDF documents.'),
          ],
        ),
      ),
    );
  }
}
