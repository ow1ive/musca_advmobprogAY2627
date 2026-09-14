import 'package:firebase_auth/firebase_auth.dart' as firebase_auth;
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import '../services/user_service.dart';

// ENHANCEMENT 2: Dedicated sign up screen matching the dummyjson.com/users fields.
class SignupScreen extends StatefulWidget {
  const SignupScreen({super.key});

  @override
  State<SignupScreen> createState() => _SignupScreenState();
}

class _SignupScreenState extends State<SignupScreen> {
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  final UserService _userService = UserService();

  final _firstNameController = TextEditingController();
  final _lastNameController = TextEditingController();
  final _ageController = TextEditingController();
  final _contactNoController = TextEditingController();
  final _usernameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  String? _selectedGender;

  bool _isLoading = false;
  bool _obscurePassword = true;

  InputDecoration _fieldDecoration(String hint) {
    return InputDecoration(
      hintText: hint,
      hintStyle: TextStyle(
        fontSize: 14.sp,
        color: const Color(0xFFB3B6C1),
        fontFamily: 'Poppins',
      ),
      contentPadding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 14.h),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14.r),
        borderSide: const BorderSide(color: Color(0xFFBFC3CF)),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14.r),
        borderSide: const BorderSide(color: Color(0xFF7A75FF), width: 1.3),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14.r),
        borderSide: const BorderSide(color: Color(0xFFBFC3CF)),
      ),
    );
  }

  Widget _fieldLabel(String label) => Padding(
    padding: EdgeInsets.only(bottom: 8.h),
    child: Text(
      label,
      style: TextStyle(
        fontSize: 14.sp,
        color: const Color(0xFF343845),
        fontFamily: 'Poppins',
      ),
    ),
  );

  // ENHANCEMENT 2: Creates the Firebase account, sets the display name, then
  // logs straight into the app (age/contact number are validated here but
  // aren't persisted since Firebase Auth only stores email/password/displayName).
  Future<void> _signUp() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    setState(() => _isLoading = true);
    try {
      await _userService.createAccount(
        email: _emailController.text.trim(),
        password: _passwordController.text,
      );
      await _userService.updateUsername(
        username: _usernameController.text.trim(),
      );

      final fbUser = _userService.currentUser;
      if (fbUser != null) {
        final token = await fbUser.getIdToken() ?? '';
        final userData = {
          'id': fbUser.uid.hashCode.abs(),
          'username': _usernameController.text.trim(),
          'email': fbUser.email ?? '',
          'firstName': _firstNameController.text.trim(),
          'lastName': _lastNameController.text.trim(),
          'gender': _selectedGender ?? '',
          'image': '',
          'accessToken': token,
          'refreshToken': '',
          'token': token,
          'loginType': 'firebase',
        };
        await _userService.saveUserData(userData);

        if (!mounted) return;
        Navigator.pushReplacementNamed(context, '/home', arguments: userData);
        return;
      }
    } on firebase_auth.FirebaseAuthException catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(e.message ?? e.code),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  void dispose() {
    _firstNameController.dispose();
    _lastNameController.dispose();
    _ageController.dispose();
    _contactNoController.dispose();
    _usernameController.dispose();
    _emailController.dispose();
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
                  SizedBox(height: 20.h),
                  Center(
                    child: Container(
                      width: 80.w,
                      height: 80.w,
                      decoration: BoxDecoration(
                        color: const Color(0xFFEDEFFF),
                        borderRadius: BorderRadius.circular(24.r),
                      ),
                      padding: EdgeInsets.all(12.r),
                      child: Image.asset(
                        'assets/images/nubdexchange_logo (1).png',
                        fit: BoxFit.contain,
                      ),
                    ),
                  ),
                  SizedBox(height: 12.h),
                  Center(
                    child: Text(
                      'Create Account',
                      style: TextStyle(
                        color: const Color(0xFF20232A),
                        fontSize: 30.sp,
                        fontWeight: FontWeight.w700,
                        fontFamily: 'Poppins',
                      ),
                    ),
                  ),
                  SizedBox(height: 6.h),
                  Center(
                    child: Text(
                      'Sign up to get started.',
                      style: TextStyle(
                        color: const Color(0xFF808393),
                        fontSize: 14.sp,
                        fontFamily: 'Poppins',
                      ),
                    ),
                  ),
                  SizedBox(height: 24.h),
                  _fieldLabel('First Name'),
                  TextFormField(
                    controller: _firstNameController,
                    style: TextStyle(fontSize: 16.sp, fontFamily: 'Poppins'),
                    decoration: _fieldDecoration('Enter your first name'),
                    validator: (value) =>
                        (value == null || value.trim().isEmpty)
                        ? 'First name is required'
                        : null,
                  ),
                  SizedBox(height: 14.h),
                  _fieldLabel('Last Name'),
                  TextFormField(
                    controller: _lastNameController,
                    style: TextStyle(fontSize: 16.sp, fontFamily: 'Poppins'),
                    decoration: _fieldDecoration('Enter your last name'),
                    validator: (value) =>
                        (value == null || value.trim().isEmpty)
                        ? 'Last name is required'
                        : null,
                  ),
                  SizedBox(height: 14.h),
                  _fieldLabel('Age'),
                  TextFormField(
                    controller: _ageController,
                    keyboardType: TextInputType.number,
                    style: TextStyle(fontSize: 16.sp, fontFamily: 'Poppins'),
                    decoration: _fieldDecoration('Enter your age'),
                    validator: (value) {
                      final age = int.tryParse(value?.trim() ?? '');
                      if (age == null || age <= 0) {
                        return 'Enter a valid age';
                      }
                      return null;
                    },
                  ),
                  SizedBox(height: 14.h),
                  _fieldLabel('Contact Number'),
                  TextFormField(
                    controller: _contactNoController,
                    keyboardType: TextInputType.phone,
                    style: TextStyle(fontSize: 16.sp, fontFamily: 'Poppins'),
                    decoration: _fieldDecoration('Enter your contact number'),
                    validator: (value) =>
                        (value == null || value.trim().isEmpty)
                        ? 'Contact number is required'
                        : null,
                  ),
                  SizedBox(height: 14.h),
                  _fieldLabel('Gender'),
                  DropdownButtonFormField<String>(
                    initialValue: _selectedGender,
                    style: TextStyle(
                      fontSize: 16.sp,
                      fontFamily: 'Poppins',
                      color: const Color(0xFF20232A),
                    ),
                    decoration: _fieldDecoration('Select your gender'),
                    items: const [
                      DropdownMenuItem(value: 'male', child: Text('Male')),
                      DropdownMenuItem(value: 'female', child: Text('Female')),
                    ],
                    onChanged: (value) =>
                        setState(() => _selectedGender = value),
                    validator: (value) =>
                        value == null ? 'Gender is required' : null,
                  ),
                  SizedBox(height: 14.h),
                  _fieldLabel('Username'),
                  TextFormField(
                    controller: _usernameController,
                    style: TextStyle(fontSize: 16.sp, fontFamily: 'Poppins'),
                    decoration: _fieldDecoration('Choose a username'),
                    validator: (value) =>
                        (value == null || value.trim().isEmpty)
                        ? 'Username is required'
                        : null,
                  ),
                  SizedBox(height: 14.h),
                  _fieldLabel('Email Address'),
                  TextFormField(
                    controller: _emailController,
                    keyboardType: TextInputType.emailAddress,
                    style: TextStyle(fontSize: 16.sp, fontFamily: 'Poppins'),
                    decoration: _fieldDecoration('Enter your email'),
                    validator: (value) {
                      final email = value?.trim() ?? '';
                      if (email.isEmpty) {
                        return 'Email is required';
                      }
                      if (!RegExp(
                        r'^[^@\s]+@[^@\s]+\.[^@\s]+$',
                      ).hasMatch(email)) {
                        return 'Enter a valid email address';
                      }
                      return null;
                    },
                  ),
                  SizedBox(height: 14.h),
                  _fieldLabel('Password'),
                  TextFormField(
                    controller: _passwordController,
                    obscureText: _obscurePassword,
                    style: TextStyle(fontSize: 16.sp, fontFamily: 'Poppins'),
                    decoration: _fieldDecoration('Create a password').copyWith(
                      suffixIcon: IconButton(
                        icon: Icon(
                          _obscurePassword
                              ? Icons.visibility_off_outlined
                              : Icons.visibility_outlined,
                          color: const Color(0xFF8A8E9D),
                        ),
                        onPressed: () {
                          setState(() => _obscurePassword = !_obscurePassword);
                        },
                      ),
                    ),
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Password is required';
                      }
                      if (value.length < 6) {
                        return 'Password must be at least 6 characters';
                      }
                      return null;
                    },
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
                      onPressed: _isLoading ? null : _signUp,
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
                              'Create Account',
                              style: TextStyle(
                                fontSize: 16.sp,
                                fontWeight: FontWeight.w500,
                                fontFamily: 'Poppins',
                              ),
                            ),
                    ),
                  ),
                  SizedBox(height: 24.h),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        'Already have an account? ',
                        style: TextStyle(
                          color: const Color(0xFF6F7382),
                          fontSize: 14.sp,
                          fontFamily: 'Poppins',
                        ),
                      ),
                      GestureDetector(
                        onTap: _isLoading ? null : () => Navigator.pop(context),
                        child: Text(
                          'Sign In',
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
