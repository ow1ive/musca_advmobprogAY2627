import 'package:firebase_auth/firebase_auth.dart' as firebase_auth;

import 'dart:convert';

import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

import '../constants.dart';
import '../models/user.dart';

class UserService {
  static const String _dummyJsonBaseUrl = 'https://dummyjson.com';
  Map<String, dynamic> data = {};

  Future<Map<String, dynamic>> loginUser(
    String username,
    String password,
  ) async {
    // ENHANCEMENT 2: Sign in is authenticated against DummyJSON auth API.
    final response = await http.post(
      Uri.parse('$_dummyJsonBaseUrl/auth/login'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        'username': username,
        'password': password,
        'expiresInMins': 60,
      }),
    );

    if (response.statusCode == 200) {
      data = jsonDecode(response.body);
      await saveUserData(data);
      return data;
    } else {
      final body = jsonDecode(response.body) as Map<String, dynamic>?;
      final message = body?['message'] ?? 'Invalid username or password';
      throw Exception(message);
    }
  }

  Future<void> saveUserData(Map<String, dynamic> userData) async {
    final prefs = await SharedPreferences.getInstance();

    await prefs.setInt('id', userData['id'] ?? 0);
    await prefs.setString('username', userData['username'] ?? '');
    await prefs.setString('email', userData['email'] ?? '');

    // Keep optional user fields if present in API payload.
    await prefs.setString('firstName', userData['firstName'] ?? '');
    await prefs.setString('lastName', userData['lastName'] ?? '');
    await prefs.setString('gender', userData['gender'] ?? '');
    await prefs.setString('image', userData['image'] ?? '');

    await prefs.setString('accessToken', userData['accessToken'] ?? '');
    await prefs.setString('refreshToken', userData['refreshToken'] ?? '');

    if (userData.containsKey('token')) {
      await prefs.setString('token', userData['token'] ?? '');
    } else {
      await prefs.setString('token', userData['accessToken'] ?? '');
    }

    // ENHANCEMENT 3: Remember how the user signed in (dummyjson vs firebase).
    await prefs.setString('loginType', userData['loginType'] ?? 'dummyjson');
  }

  Future<Map<String, dynamic>> getUserData() async {
    final prefs = await SharedPreferences.getInstance();

    return {
      'id': prefs.getInt('id') ?? 0,
      'username': prefs.getString('username') ?? '',
      'email': prefs.getString('email') ?? '',
      'firstName': prefs.getString('firstName') ?? '',
      'lastName': prefs.getString('lastName') ?? '',
      'gender': prefs.getString('gender') ?? '',
      'image': prefs.getString('image') ?? '',
      'accessToken': prefs.getString('accessToken') ?? '',
      'refreshToken': prefs.getString('refreshToken') ?? '',
      'token': prefs.getString('token') ?? prefs.getString('accessToken') ?? '',
      'loginType': prefs.getString('loginType') ?? 'dummyjson',
    };
  }

  Future<User> getUser() async {
    final userData = await getUserData();
    return User.fromJson(userData);
  }

  // ENHANCEMENT 3: Drives the profile screen's "show details based on LoginType" behavior.
  Future<String> getLoginType() async {
    final userData = await getUserData();
    return userData['loginType'] as String;
  }

  Future<bool> isLoggedIn() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('accessToken') ?? prefs.getString('token');
    return token != null && token.isNotEmpty;
  }

  // ENHANCEMENT 3: Resolve the current user's id from saved session data.
  Future<int> getLoggedInUserId({int fallback = 1}) async {
    final prefs = await SharedPreferences.getInstance();
    final id = prefs.getInt('id') ?? fallback;
    return id > 0 ? id : fallback;
  }

  Future<void> logout() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.clear();
  }

  Future<User> getUserById(int userId) async {
    final response = await http.get(Uri.parse('$host/users/$userId'));

    if (response.statusCode == 200) {
      return User.fromJson(jsonDecode(response.body));
    }

    throw Exception('Failed to load user');
  }

  // ENHANCEMENT 1: Firebase Auth-backed session management.
  final firebase_auth.FirebaseAuth firebaseAuth =
      firebase_auth.FirebaseAuth.instance;

  firebase_auth.User? get currentUser => firebaseAuth.currentUser;

  // Cached so widgets subscribing to this stream don't resubscribe to a new
  // Stream instance on every rebuild (the plugin returns a new one per call).
  late final Stream<firebase_auth.User?> authStateChanges = firebaseAuth
      .authStateChanges();

  Future<firebase_auth.UserCredential> signIn({
    required String email,
    required String password,
  }) async {
    return await firebaseAuth.signInWithEmailAndPassword(
      email: email,
      password: password,
    );
  }

  Future<firebase_auth.UserCredential> createAccount({
    required String email,
    required String password,
  }) async {
    return await firebaseAuth.createUserWithEmailAndPassword(
      email: email,
      password: password,
    );
  }

  Future<void> signOut() async {
    await firebaseAuth.signOut();
  }

  Future<void> updateUsername({required String username}) async {
    await currentUser!.updateDisplayName(username);
  }

  Future<void> deleteAccount({
    required String email,
    required String password,
  }) async {
    final credential = firebase_auth.EmailAuthProvider.credential(
      email: email,
      password: password,
    );

    await currentUser!.reauthenticateWithCredential(credential);
    await currentUser!.delete();
    await firebaseAuth.signOut();
  }

  Future<void> resetPasswordFromCurrentPassword({
    required String currentPassword,
    required String newPassword,
    required String email,
  }) async {
    final credential = firebase_auth.EmailAuthProvider.credential(
      email: email,
      password: currentPassword,
    );
    await currentUser!.reauthenticateWithCredential(credential);
    await currentUser!.updatePassword(newPassword);
  }
}
