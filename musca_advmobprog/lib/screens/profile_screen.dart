import 'package:firebase_auth/firebase_auth.dart' as firebase_auth;
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
  String _loginType = 'dummyjson';
  String? _displayNameOverride;
  bool _isEditingUsername = false;
  final TextEditingController _usernameEditController = TextEditingController();

  bool _isChangingPassword = false;
  final _cpEmailController = TextEditingController();
  final _cpCurrentPasswordController = TextEditingController();
  final _cpNewPasswordController = TextEditingController();

  bool _isDeletingAccount = false;
  final _delEmailController = TextEditingController();
  final _delPasswordController = TextEditingController();

  @override
  void initState() {
    super.initState();
    // ENHANCEMENT 3: Render profile by mapping saved session data to User model.
    _userFuture = _userService.getUser();
    // ENHANCEMENT 3: Show user details depending on the LoginType.
    _userService.getLoginType().then((value) {
      if (mounted) setState(() => _loginType = value);
    });
  }

  @override
  void dispose() {
    _usernameEditController.dispose();
    _cpEmailController.dispose();
    _cpCurrentPasswordController.dispose();
    _cpNewPasswordController.dispose();
    _delEmailController.dispose();
    _delPasswordController.dispose();
    super.dispose();
  }

  void _showSnack(String message, {bool isError = false}) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: isError ? Colors.red : Colors.green,
      ),
    );
  }

  // ENHANCEMENT 1: Edited inline (no dialog/route) so opening the keyboard
  // can't tear down a separate dialog route mid-frame.
  void _startEditUsername(String currentName) {
    if (_userService.currentUser == null) {
      _showSnack(
        'Sign in with a Firebase account on the Sign In screen first.',
        isError: true,
      );
      return;
    }
    _usernameEditController.text = currentName;
    setState(() => _isEditingUsername = true);
  }

  void _cancelEditUsername() {
    setState(() => _isEditingUsername = false);
  }

  Future<void> _saveUsername() async {
    final newName = _usernameEditController.text.trim();
    if (newName.isEmpty) {
      setState(() => _isEditingUsername = false);
      return;
    }

    try {
      await _userService.updateUsername(username: newName);
      if (!mounted) return;
      setState(() {
        _displayNameOverride = newName;
        _isEditingUsername = false;
      });
      _showSnack('Username updated.');
    } on firebase_auth.FirebaseAuthException catch (e) {
      _showSnack(e.message ?? e.code, isError: true);
    }
  }

  // ENHANCEMENT 1: Edited inline (no dialog/route) so opening the keyboard
  // can't tear down a separate dialog route mid-frame.
  void _startChangePassword(String prefillEmail) {
    if (_userService.currentUser == null) {
      _showSnack(
        'Sign in with a Firebase account on the Sign In screen first.',
        isError: true,
      );
      return;
    }
    _cpEmailController.text = prefillEmail;
    _cpCurrentPasswordController.clear();
    _cpNewPasswordController.clear();
    setState(() => _isChangingPassword = true);
  }

  void _cancelChangePassword() {
    setState(() => _isChangingPassword = false);
  }

  Future<void> _saveChangePassword() async {
    try {
      await _userService.resetPasswordFromCurrentPassword(
        email: _cpEmailController.text.trim(),
        currentPassword: _cpCurrentPasswordController.text,
        newPassword: _cpNewPasswordController.text,
      );
      if (!mounted) return;
      setState(() => _isChangingPassword = false);
      _showSnack('Password changed.');
    } on firebase_auth.FirebaseAuthException catch (e) {
      _showSnack(e.message ?? e.code, isError: true);
    }
  }

  // ENHANCEMENT 1: Edited inline (no dialog/route) so opening the keyboard
  // can't tear down a separate dialog route mid-frame.
  void _startDeleteAccount(String prefillEmail) {
    if (_userService.currentUser == null) {
      _showSnack(
        'Sign in with a Firebase account on the Sign In screen first.',
        isError: true,
      );
      return;
    }
    _delEmailController.text = prefillEmail;
    _delPasswordController.clear();
    setState(() => _isDeletingAccount = true);
  }

  void _cancelDeleteAccount() {
    setState(() => _isDeletingAccount = false);
  }

  Future<void> _confirmDeleteAccount() async {
    try {
      await _userService.deleteAccount(
        email: _delEmailController.text.trim(),
        password: _delPasswordController.text,
      );
      await _userService.logout();

      if (!mounted) return;
      Navigator.pushNamedAndRemoveUntil(
        context,
        '/signin',
        (route) => false,
        arguments: 'Account deleted successfully.',
      );
    } on firebase_auth.FirebaseAuthException catch (e) {
      _showSnack(e.message ?? e.code, isError: true);
    } catch (e) {
      _showSnack('Failed to delete account: $e', isError: true);
    }
  }

  Future<void> _logout() async {
    // Clear both DummyJSON session data and any active Firebase session.
    await _userService.logout();
    await _userService.signOut();

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

        // ENHANCEMENT 1: Disable Firebase-only actions upfront instead of erroring after tapping.
        // Read synchronously (no Stream) to avoid resubscribing on every rebuild.
        final hasFirebaseSession = _userService.currentUser != null;

        return _ProfileBody(
          user: user,
          displayNameOverride: _displayNameOverride,
          hasFirebaseSession: hasFirebaseSession,
          loginType: _loginType,
          isEditingUsername: _isEditingUsername,
          usernameEditController: _usernameEditController,
          onStartEditUsername: () =>
              _startEditUsername(_displayNameOverride ?? user.displayName),
          onSaveUsername: _saveUsername,
          onCancelEditUsername: _cancelEditUsername,
          isChangingPassword: _isChangingPassword,
          cpEmailController: _cpEmailController,
          cpCurrentPasswordController: _cpCurrentPasswordController,
          cpNewPasswordController: _cpNewPasswordController,
          onStartChangePassword: () => _startChangePassword(user.email),
          onSaveChangePassword: _saveChangePassword,
          onCancelChangePassword: _cancelChangePassword,
          onLogout: _logout,
          isDeletingAccount: _isDeletingAccount,
          delEmailController: _delEmailController,
          delPasswordController: _delPasswordController,
          onStartDeleteAccount: () => _startDeleteAccount(user.email),
          onConfirmDeleteAccount: _confirmDeleteAccount,
          onCancelDeleteAccount: _cancelDeleteAccount,
        );
      },
    );
  }
}

class _ProfileBody extends StatelessWidget {
  const _ProfileBody({
    required this.user,
    required this.displayNameOverride,
    required this.hasFirebaseSession,
    required this.loginType,
    required this.isEditingUsername,
    required this.usernameEditController,
    required this.onStartEditUsername,
    required this.onSaveUsername,
    required this.onCancelEditUsername,
    required this.isChangingPassword,
    required this.cpEmailController,
    required this.cpCurrentPasswordController,
    required this.cpNewPasswordController,
    required this.onStartChangePassword,
    required this.onSaveChangePassword,
    required this.onCancelChangePassword,
    required this.onLogout,
    required this.isDeletingAccount,
    required this.delEmailController,
    required this.delPasswordController,
    required this.onStartDeleteAccount,
    required this.onConfirmDeleteAccount,
    required this.onCancelDeleteAccount,
  });

  final User user;
  final String? displayNameOverride;
  final bool hasFirebaseSession;
  final String loginType;
  final bool isEditingUsername;
  final TextEditingController usernameEditController;
  final VoidCallback onStartEditUsername;
  final VoidCallback onSaveUsername;
  final VoidCallback onCancelEditUsername;
  final bool isChangingPassword;
  final TextEditingController cpEmailController;
  final TextEditingController cpCurrentPasswordController;
  final TextEditingController cpNewPasswordController;
  final VoidCallback onStartChangePassword;
  final VoidCallback onSaveChangePassword;
  final VoidCallback onCancelChangePassword;
  final VoidCallback onLogout;
  final bool isDeletingAccount;
  final TextEditingController delEmailController;
  final TextEditingController delPasswordController;
  final VoidCallback onStartDeleteAccount;
  final VoidCallback onConfirmDeleteAccount;
  final VoidCallback onCancelDeleteAccount;

  @override
  Widget build(BuildContext context) {
    return Container(
      color: _profilePageBackground(context),
      child: SingleChildScrollView(
        padding: EdgeInsets.fromLTRB(14.w, 14.h, 14.w, 18.h),
        child: Column(
          children: [
            Container(
              width: double.infinity,
              padding: EdgeInsets.symmetric(vertical: 16.h, horizontal: 14.w),
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
                  if (isEditingUsername)
                    Row(
                      children: [
                        Expanded(
                          child: TextField(
                            controller: usernameEditController,
                            autofocus: true,
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              fontSize: 20.sp,
                              fontWeight: FontWeight.w600,
                              fontFamily: 'Poppins',
                            ),
                            decoration: const InputDecoration(
                              isDense: true,
                              border: OutlineInputBorder(),
                            ),
                            onSubmitted: (_) => onSaveUsername(),
                          ),
                        ),
                        IconButton(
                          onPressed: onSaveUsername,
                          icon: Icon(
                            Icons.check,
                            size: 20.sp,
                            color: Colors.green,
                          ),
                          visualDensity: VisualDensity.compact,
                        ),
                        IconButton(
                          onPressed: onCancelEditUsername,
                          icon: Icon(
                            Icons.close,
                            size: 20.sp,
                            color: Colors.red,
                          ),
                          visualDensity: VisualDensity.compact,
                        ),
                      ],
                    )
                  else
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          displayNameOverride ?? user.displayName,
                          style: TextStyle(
                            fontSize: 23.sp,
                            fontWeight: FontWeight.w600,
                            fontFamily: 'Poppins',
                          ),
                        ),
                        SizedBox(width: 4.w),
                        // ENHANCEMENT 1: Edit affordance for UserService.updateUsername.
                        IconButton(
                          onPressed: hasFirebaseSession
                              ? onStartEditUsername
                              : null,
                          icon: Icon(Icons.edit, size: 18.sp),
                          tooltip: hasFirebaseSession
                              ? null
                              : 'Sign in with a Firebase account to edit',
                          visualDensity: VisualDensity.compact,
                        ),
                      ],
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
                  Divider(
                    height: 1.h,
                    thickness: 1,
                    color: Theme.of(context).dividerColor,
                  ),
                  // ENHANCEMENT 3: Show user details depending on the LoginType.
                  _ProfileInfoTile(
                    icon: Icons.verified_user_outlined,
                    label: 'Login Type',
                    value: loginType == 'firebase' ? 'Firebase' : 'DummyJSON',
                  ),
                ],
              ),
            ),
            SizedBox(height: 18.h),
            if (!hasFirebaseSession) ...[
              Padding(
                padding: EdgeInsets.symmetric(horizontal: 4.w),
                child: Text(
                  'Signed in with DummyJSON. Sign in with a Firebase account '
                  'on the Sign In screen to edit username, change password, '
                  'or delete account.',
                  style: TextStyle(
                    fontSize: 12.sp,
                    color: _profileMutedText(context),
                    fontFamily: 'Poppins',
                  ),
                ),
              ),
              SizedBox(height: 10.h),
            ],
            if (isChangingPassword)
              Container(
                width: double.infinity,
                padding: EdgeInsets.all(14.w),
                decoration: BoxDecoration(
                  color: _profileCardBackground(context),
                  borderRadius: BorderRadius.circular(16.r),
                ),
                child: Column(
                  children: [
                    TextField(
                      controller: cpEmailController,
                      decoration: const InputDecoration(labelText: 'Email'),
                    ),
                    SizedBox(height: 8.h),
                    TextField(
                      controller: cpCurrentPasswordController,
                      obscureText: true,
                      decoration: const InputDecoration(
                        labelText: 'Current password',
                      ),
                    ),
                    SizedBox(height: 8.h),
                    TextField(
                      controller: cpNewPasswordController,
                      obscureText: true,
                      decoration: const InputDecoration(
                        labelText: 'New password',
                      ),
                    ),
                    SizedBox(height: 10.h),
                    Row(
                      children: [
                        Expanded(
                          child: OutlinedButton(
                            onPressed: onCancelChangePassword,
                            child: const Text('Cancel'),
                          ),
                        ),
                        SizedBox(width: 8.w),
                        Expanded(
                          child: ElevatedButton(
                            onPressed: onSaveChangePassword,
                            child: const Text('Save'),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              )
            else
              SizedBox(
                width: double.infinity,
                height: 52.h,
                child: OutlinedButton.icon(
                  onPressed: hasFirebaseSession ? onStartChangePassword : null,
                  icon: Icon(Icons.lock_outline, size: 18.sp),
                  label: Text(
                    'Change Password',
                    style: TextStyle(fontSize: 16.sp, fontFamily: 'Poppins'),
                  ),
                ),
              ),
            SizedBox(height: 10.h),
            if (isDeletingAccount)
              Container(
                width: double.infinity,
                padding: EdgeInsets.all(14.w),
                decoration: BoxDecoration(
                  color: _profileCardBackground(context),
                  borderRadius: BorderRadius.circular(16.r),
                  border: Border.all(color: Colors.red.withValues(alpha: 0.4)),
                ),
                child: Column(
                  children: [
                    const Row(
                      children: [
                        Icon(Icons.warning_amber_rounded, color: Colors.red),
                        SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            'This permanently deletes your account.',
                            style: TextStyle(color: Colors.red),
                          ),
                        ),
                      ],
                    ),
                    SizedBox(height: 10.h),
                    TextField(
                      controller: delEmailController,
                      decoration: const InputDecoration(labelText: 'Email'),
                    ),
                    SizedBox(height: 8.h),
                    TextField(
                      controller: delPasswordController,
                      obscureText: true,
                      decoration: const InputDecoration(labelText: 'Password'),
                    ),
                    SizedBox(height: 10.h),
                    Row(
                      children: [
                        Expanded(
                          child: OutlinedButton(
                            onPressed: onCancelDeleteAccount,
                            child: const Text('Cancel'),
                          ),
                        ),
                        SizedBox(width: 8.w),
                        Expanded(
                          child: ElevatedButton(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.red,
                              foregroundColor: Colors.white,
                            ),
                            onPressed: onConfirmDeleteAccount,
                            child: const Text('Delete'),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              )
            else
              SizedBox(
                width: double.infinity,
                height: 52.h,
                child: TextButton.icon(
                  onPressed: hasFirebaseSession ? onStartDeleteAccount : null,
                  style: TextButton.styleFrom(
                    foregroundColor: const Color(0xFFFF5F50),
                  ),
                  icon: Icon(Icons.delete_outline, size: 18.sp),
                  label: Text(
                    'Delete Account',
                    style: TextStyle(fontSize: 16.sp, fontFamily: 'Poppins'),
                  ),
                ),
              ),
            SizedBox(height: 10.h),
            SizedBox(
              width: double.infinity,
              height: 52.h,
              child: ElevatedButton.icon(
                onPressed: onLogout,
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
