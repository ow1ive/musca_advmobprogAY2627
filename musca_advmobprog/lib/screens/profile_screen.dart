import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import '../models/user.dart';
import '../services/user_service.dart';
import '../widgets/custom_text.dart';

Color _profilePageBackground(BuildContext context) =>
    Theme.of(context).brightness == Brightness.dark
        ? const Color(0xFF121014)
        : const Color(0xFFFAFAFF);

Color _profileCardBackground(BuildContext context) =>
    Theme.of(context).brightness == Brightness.dark
        ? const Color(0xFF1E1C24)
        : Colors.white;

Color _profileAvatarBackground(BuildContext context) =>
    Theme.of(context).brightness == Brightness.dark
        ? const Color(0xFF2A2833)
        : const Color(0xFFF0F2FB);

Color _profileMutedText(BuildContext context) =>
    Theme.of(context).colorScheme.onSurfaceVariant;

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final UserService _userService = UserService();
  late Future<User> _userFuture;

  @override
  void initState() {
    super.initState();
    // ENHANCEMENT 3: Render profile by mapping saved session data to User model.
    _userFuture = _userService.getUser();
  }

  Future<void> _logout() async {
    await _userService.logout();

    if (!mounted) {
      return;
    }

    Navigator.pushNamedAndRemoveUntil(context, '/signin', (route) => false);
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<User>(
      future: _userFuture,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        if (snapshot.hasError) {
          return Center(
            child: Padding(
              padding: EdgeInsets.all(24.r),
              child: CustomText(
                text: 'Unable to load profile: ${snapshot.error}',
                fontSize: 14.sp,
              ),
            ),
          );
        }

        final user = snapshot.data;

        if (user == null) {
          return const Center(child: Text('No profile data available.'));
        }

        return Container(
          color: _profilePageBackground(context),
          child: SingleChildScrollView(
            padding: EdgeInsets.fromLTRB(14.w, 14.h, 14.w, 18.h),
            child: Column(
              children: [
                Container(
                  width: double.infinity,
                  padding: EdgeInsets.symmetric(
                    vertical: 16.h,
                    horizontal: 14.w,
                  ),
                  decoration: BoxDecoration(
                    color: _profileCardBackground(context),
                    borderRadius: BorderRadius.circular(16.r),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.06),
                        blurRadius: 12,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Column(
                    children: [
                      Container(
                        width: 74.w,
                        height: 74.w,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: _profileAvatarBackground(context),
                          image: user.image.isNotEmpty
                              ? DecorationImage(
                                  image: NetworkImage(user.image),
                                  fit: BoxFit.cover,
                                )
                              : const DecorationImage(
                                  image: AssetImage(
                                    'assets/images/nubdexchange_logo (1).png',
                                  ),
                                  fit: BoxFit.contain,
                                ),
                        ),
                      ),
                      SizedBox(height: 10.h),
                      Text(
                        user.displayName,
                        style: TextStyle(
                          fontSize: 23.sp,
                          fontWeight: FontWeight.w600,
                          fontFamily: 'Poppins',
                        ),
                      ),
                      SizedBox(height: 2.h),
                      Text(
                        '@${user.username}',
                        style: TextStyle(
                          color: const Color(0xFFF2B92E),
                          fontSize: 14.sp,
                          fontWeight: FontWeight.w500,
                          fontFamily: 'Poppins',
                        ),
                      ),
                    ],
                  ),
                ),
                SizedBox(height: 14.h),
                Container(
                  width: double.infinity,
                  padding: EdgeInsets.symmetric(vertical: 6.h),
                  decoration: BoxDecoration(
                    color: _profileCardBackground(context),
                    borderRadius: BorderRadius.circular(16.r),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.05),
                        blurRadius: 10,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Column(
                    children: [
                      _ProfileInfoTile(
                        icon: Icons.mail_outline,
                        label: 'Email',
                        value: user.email,
                      ),
                      Divider(
                        height: 1.h,
                        thickness: 1,
                        color: Theme.of(context).dividerColor,
                      ),
                      _ProfileInfoTile(
                        icon: Icons.wc,
                        label: 'Gender',
                        value: user.gender.isEmpty ? 'Not set' : user.gender,
                      ),
                      Divider(
                        height: 1.h,
                        thickness: 1,
                        color: Theme.of(context).dividerColor,
                      ),
                      _ProfileInfoTile(
                        icon: Icons.badge_outlined,
                        label: 'User ID',
                        value: '#${user.id}',
                      ),
                    ],
                  ),
                ),
                SizedBox(height: 18.h),
                SizedBox(
                  width: double.infinity,
                  height: 52.h,
                  child: ElevatedButton.icon(
                    onPressed: _logout,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFFFF5F50),
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12.r),
                      ),
                    ),
                    icon: Icon(Icons.logout, size: 18.sp),
                    label: Text(
                      'Log Out',
                      style: TextStyle(
                        fontSize: 16.sp,
                        fontWeight: FontWeight.w600,
                        fontFamily: 'Poppins',
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

class _ProfileInfoTile extends StatelessWidget {
  const _ProfileInfoTile({
    required this.icon,
    required this.label,
    required this.value,
  });

  final IconData icon;
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 10.h),
      child: Row(
        children: [
          Icon(icon, size: 18.sp, color: const Color(0xFFF2B92E)),
          SizedBox(width: 10.w),
          Expanded(
            child: Text(
              label,
              style: TextStyle(
                fontSize: 13.sp,
                fontWeight: FontWeight.w500,
                fontFamily: 'Poppins',
              ),
            ),
          ),
          Expanded(
            child: Align(
              alignment: Alignment.centerRight,
              child: Text(
                value,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                textAlign: TextAlign.right,
                style: TextStyle(
                  fontSize: 13.sp,
                  color: _profileMutedText(context),
                  fontWeight: FontWeight.w500,
                  fontFamily: 'Poppins',
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
