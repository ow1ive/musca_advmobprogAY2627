import 'package:firebase_auth/firebase_auth.dart' as firebase_auth;
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import '../services/user_service.dart';

class SigninScreen extends StatefulWidget {
  const SigninScreen({super.key});

  @override
  State<SigninScreen> createState() => _SigninScreenState();
}

class _SigninScreenState extends State<SigninScreen> {
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  final TextEditingController _usernameController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final UserService _userService = UserService();
  bool _isLoading = false;
  bool _rememberMe = false;
  bool _obscurePassword = true;
  bool _handledArrivalMessage = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // Shows messages passed via navigation arguments, e.g. after account deletion.
    if (_handledArrivalMessage) return;
    _handledArrivalMessage = true;
    final message = ModalRoute.of(context)?.settings.arguments as String?;
    if (message != null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(message), backgroundColor: Colors.green),
        );
      });
    }
  }

  // ENHANCEMENT: Authenticate against DummyJSON, falling back to Firebase
  // so accounts created with "Create Account" can sign back in here too.
  Future<void> _login() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    setState(() => _isLoading = true);

    final identifier = _usernameController.text.trim();
    final password = _passwordController.text;

    try {
      final response = await _userService.loginUser(identifier, password);
      await _userService.saveUserData(response);

      if (!mounted) return;
      setState(() => _isLoading = false);
      Navigator.pushReplacementNamed(context, '/home', arguments: response);
      return;
    } catch (_) {
      // Not a DummyJSON test account — fall back to Firebase below.
    }

    try {
      // Firebase Auth requires an email, so resolve a plain username to the
      // email stored in Firestore when the user didn't type one.
      String firebaseIdentifier = identifier;
      if (!identifier.contains('@')) {
        final resolvedEmail = await _userService.getEmailByUsername(
          identifier,
        );
        if (resolvedEmail != null && resolvedEmail.isNotEmpty) {
          firebaseIdentifier = resolvedEmail;
        }
      }

      await _userService.signIn(
        email: firebaseIdentifier,
        password: password,
      );
      if (await _enterHomeWithFirebaseUser()) {
        if (mounted) setState(() => _isLoading = false);
        return;
      }
    } catch (_) {
      // Neither backend recognized these credentials.
    }

    if (!mounted) return;
    setState(() => _isLoading = false);
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Invalid username or password.')),
    );
  }

  // Builds a local session from the signed-in Firebase user and opens Home.
  Future<bool> _enterHomeWithFirebaseUser() async {
    final fbUser = _userService.currentUser;
    if (fbUser == null) {
      return false;
    }

    final token = await fbUser.getIdToken() ?? '';
    final username =
        fbUser.displayName ?? (fbUser.email ?? 'user').split('@').first;
    final userData = {
      'id': fbUser.uid.hashCode.abs(),
      'uid': fbUser.uid,
      'username': username,
      'email': fbUser.email ?? '',
      'firstName': '',
      'lastName': '',
      'gender': '',
      'image': fbUser.photoURL ?? '',
      'accessToken': token,
      'refreshToken': '',
      'token': token,
      'loginType': 'firebase',
    };
    await _userService.saveUserData(userData);
    // Merge so an existing signup profile (firstName/lastName) isn't wiped out.
    await _userService.upsertFirestoreProfile(
      uid: fbUser.uid,
      email: fbUser.email ?? '',
      username: username,
      image: fbUser.photoURL ?? '',
    );

    if (!mounted) return true;
    Navigator.pushReplacementNamed(context, '/home', arguments: userData);
    return true;
  }

  // Sends a Firebase password-reset email so a locked-out user can recover access.
  Future<void> _forgotPassword() async {
    final emailController = TextEditingController(
      text: _usernameController.text.trim().contains('@')
          ? _usernameController.text.trim()
          : '',
    );

    final email = await showDialog<String>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Reset password'),
        content: TextField(
          controller: emailController,
          keyboardType: TextInputType.emailAddress,
          decoration: const InputDecoration(
            labelText: 'Account email',
            hintText: 'you@gmail.com',
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () =>
                Navigator.pop(dialogContext, emailController.text.trim()),
            child: const Text('Send reset link'),
          ),
        ],
      ),
    );

    if (email == null || email.isEmpty) return;

    try {
      await _userService.sendPasswordResetEmail(email: email);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Password reset email sent to $email.')),
      );
    } on firebase_auth.FirebaseAuthException catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(e.message ?? e.code),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  @override
  void dispose() {
    _usernameController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        color: const Color(0xFFFAFAFF),
        child: SafeArea(
          child: SingleChildScrollView(
            padding: EdgeInsets.symmetric(horizontal: 22.w, vertical: 20.h),
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  SizedBox(height: 42.h),
                  Center(
                    child: Container(
                      width: 92.w,
                      height: 92.w,
                      decoration: BoxDecoration(
                        color: const Color(0xFFEDEFFF),
                        borderRadius: BorderRadius.circular(28.r),
                      ),
                      padding: EdgeInsets.all(14.r),
                      child: Image.asset(
                        'assets/images/nubdexchange_logo (1).png',
                        fit: BoxFit.contain,
                      ),
                    ),
                  ),
                  SizedBox(height: 14.h),
                  Center(
                    child: Text(
                      'Welcome Back',
                      style: TextStyle(
                        color: const Color(0xFF20232A),
                        fontSize: 36.sp,
                        fontWeight: FontWeight.w700,
                        fontFamily: 'Poppins',
                      ),
                    ),
                  ),
                  SizedBox(height: 8.h),
                  Center(
                    child: Text(
                      'Log in to your account to continue.',
                      style: TextStyle(
                        color: const Color(0xFF808393),
                        fontSize: 14.sp,
                        fontFamily: 'Poppins',
                      ),
                    ),
                  ),
                  SizedBox(height: 30.h),
                  Text(
                    'Username or Email',
                    style: TextStyle(
                      fontSize: 14.sp,
                      color: const Color(0xFF343845),
                      fontFamily: 'Poppins',
                    ),
                  ),
                  SizedBox(height: 8.h),
                  TextFormField(
                    controller: _usernameController,
                    keyboardType: TextInputType.text,
                    style: TextStyle(fontSize: 16.sp, fontFamily: 'Poppins'),
                    decoration: InputDecoration(
                      hintText: 'Enter your username or email',
                      hintStyle: TextStyle(
                        fontSize: 14.sp,
                        color: const Color(0xFFB3B6C1),
                        fontFamily: 'Poppins',
                      ),
                      contentPadding: EdgeInsets.symmetric(
                        horizontal: 16.w,
                        vertical: 14.h,
                      ),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(14.r),
                        borderSide: const BorderSide(color: Color(0xFFBFC3CF)),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(14.r),
                        borderSide: const BorderSide(
                          color: Color(0xFF7A75FF),
                          width: 1.3,
                        ),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(14.r),
                        borderSide: const BorderSide(color: Color(0xFFBFC3CF)),
                      ),
                    ),
                    validator: (value) {
                      if (value == null || value.trim().isEmpty) {
                        return 'Username or email is required';
                      }
                      return null;
                    },
                  ),
                  SizedBox(height: 16.h),
                  Text(
                    'Password',
                    style: TextStyle(
                      fontSize: 14.sp,
                      color: const Color(0xFF343845),
                      fontFamily: 'Poppins',
                    ),
                  ),
                  SizedBox(height: 8.h),
                  TextFormField(
                    controller: _passwordController,
                    obscureText: _obscurePassword,
                    style: TextStyle(fontSize: 16.sp, fontFamily: 'Poppins'),
                    decoration: InputDecoration(
                      hintText: 'Enter your password',
                      hintStyle: TextStyle(
                        fontSize: 14.sp,
                        color: const Color(0xFFB3B6C1),
                        fontFamily: 'Poppins',
                      ),
                      contentPadding: EdgeInsets.symmetric(
                        horizontal: 16.w,
                        vertical: 14.h,
                      ),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(14.r),
                        borderSide: const BorderSide(color: Color(0xFFBFC3CF)),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(14.r),
                        borderSide: const BorderSide(
                          color: Color(0xFF7A75FF),
                          width: 1.3,
                        ),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(14.r),
                        borderSide: const BorderSide(color: Color(0xFFBFC3CF)),
                      ),
                      suffixIcon: IconButton(
                        icon: Icon(
                          _obscurePassword
                              ? Icons.visibility_off_outlined
                              : Icons.visibility_outlined,
                          color: const Color(0xFF8A8E9D),
                        ),
                        onPressed: () {
                          setState(() {
                            _obscurePassword = !_obscurePassword;
                          });
                        },
                      ),
                    ),
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Password is required';
                      }
                      return null;
                    },
                  ),
                  SizedBox(height: 10.h),
                  Row(
                    children: [
                      SizedBox(
                        width: 22.w,
                        child: Checkbox(
                          value: _rememberMe,
                          activeColor: const Color(0xFF3A4A9F),
                          onChanged: (value) {
                            setState(() {
                              _rememberMe = value ?? false;
                            });
                          },
                        ),
                      ),
                      SizedBox(width: 8.w),
                      Text(
                        'Remember me',
                        style: TextStyle(
                          fontSize: 13.sp,
                          color: const Color(0xFF8A8E9D),
                          fontFamily: 'Poppins',
                        ),
                      ),
                      const Spacer(),
                      TextButton(
                        onPressed: _forgotPassword,
                        style: TextButton.styleFrom(
                          padding: EdgeInsets.zero,
                          minimumSize: const Size(0, 0),
                          tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                        ),
                        child: Text(
                          'Forgot Password?',
                          style: TextStyle(
                            fontSize: 13.sp,
                            color: const Color(0xFF343845),
                            fontFamily: 'Poppins',
                          ),
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: 24.h),
                  SizedBox(
                    height: 54.h,
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF3A4A9F),
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(30.r),
                        ),
                      ),
                      onPressed: _isLoading ? null : _login,
                      child: _isLoading
                          ? SizedBox(
                              width: 18.w,
                              height: 18.w,
                              child: const CircularProgressIndicator(
                                color: Colors.white,
                                strokeWidth: 2,
                              ),
                            )
                          : Text(
                              'Sign In',
                              style: TextStyle(
                                fontSize: 16.sp,
                                fontWeight: FontWeight.w500,
                                fontFamily: 'Poppins',
                              ),
                            ),
                    ),
                  ),
                  SizedBox(height: 34.h),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        "Don't have an account? ",
                        style: TextStyle(
                          color: const Color(0xFF6F7382),
                          fontSize: 14.sp,
                          fontFamily: 'Poppins',
                        ),
                      ),
                      // ENHANCEMENT 2: Opens the dedicated Sign Up screen.
                      GestureDetector(
                        onTap: _isLoading
                            ? null
                            : () => Navigator.pushNamed(context, '/signup'),
                        child: Text(
                          'Create Account',
                          style: TextStyle(
                            color: const Color(0xFF4D58E5),
                            fontSize: 14.sp,
                            fontWeight: FontWeight.w600,
                            fontFamily: 'Poppins',
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
