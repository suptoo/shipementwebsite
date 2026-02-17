import 'package:flutter/material.dart';
import '../models/user_profile.dart';
import '../services/auth_service.dart';

class AuthProvider extends ChangeNotifier {
  final AuthService _authService = AuthService();

  UserProfile? _profile;
  bool _isLoading = true;
  String? _error;

  UserProfile? get profile => _profile;
  bool get isLoading => _isLoading;
  bool get isAuthenticated => _profile != null;
  String? get error => _error;
  String? get userId => _authService.currentUser?.id;

  AuthProvider() {
    _init();
  }

  void _init() {
    // Check current session
    final user = _authService.currentUser;
    if (user != null) {
      _loadProfile(user.id);
    } else {
      _isLoading = false;
      notifyListeners();
    }

    // Listen to auth state changes
    _authService.authStateChanges.listen((state) {
      if (state.session?.user != null) {
        _loadProfile(state.session!.user.id);
      } else {
        _profile = null;
        _isLoading = false;
        notifyListeners();
      }
    });
  }

  Future<void> _loadProfile(String userId) async {
    try {
      _isLoading = true;
      notifyListeners();

      _profile = await _authService.getProfile(userId);
      _error = null;
    } catch (e) {
      _error = e.toString();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> signUp({
    required String email,
    required String password,
    required String fullName,
  }) async {
    try {
      _isLoading = true;
      _error = null;
      notifyListeners();

      final response = await _authService.signUp(
        email: email,
        password: password,
        fullName: fullName,
      );

      if (response.user != null) {
        await _loadProfile(response.user!.id);
      }
    } catch (e) {
      _error = _parseAuthError(e);
      _isLoading = false;
      notifyListeners();
      rethrow;
    }
  }

  Future<void> signIn({
    required String email,
    required String password,
  }) async {
    try {
      _isLoading = true;
      _error = null;
      notifyListeners();

      await _authService.signIn(email: email, password: password);
    } catch (e) {
      _error = _parseAuthError(e);
      _isLoading = false;
      notifyListeners();
      rethrow;
    }
  }

  Future<void> signInWithGoogle() async {
    try {
      _error = null;
      await _authService.signInWithGoogle();
    } catch (e) {
      _error = _parseAuthError(e);
      notifyListeners();
      rethrow;
    }
  }

  Future<void> signOut() async {
    await _authService.signOut();
    _profile = null;
    notifyListeners();
  }

  Future<void> updateProfile({
    String? fullName,
    String? phone,
    String? avatarUrl,
  }) async {
    if (_profile == null) return;

    try {
      _profile = await _authService.updateProfile(
        userId: _profile!.id,
        fullName: fullName,
        phone: phone,
        avatarUrl: avatarUrl,
      );
      notifyListeners();
    } catch (e) {
      _error = e.toString();
      notifyListeners();
      rethrow;
    }
  }

  Future<void> resetPassword(String email) async {
    await _authService.resetPassword(email);
  }

  Future<void> refreshProfile() async {
    if (userId != null) {
      await _loadProfile(userId!);
    }
  }

  String _parseAuthError(dynamic error) {
    final msg = error.toString().toLowerCase();

    // Authentication errors
    if (msg.contains('invalid login') || msg.contains('invalid credentials')) {
      return 'Incorrect email or password. Please try again.';
    }
    if (msg.contains('email not confirmed') || msg.contains('not confirmed')) {
      return 'Please verify your email first. Check your inbox for a confirmation link.';
    }
    if (msg.contains('already registered') ||
        msg.contains('already exists') ||
        msg.contains('unique_violation')) {
      return 'This email is already registered. Try signing in instead.';
    }
    if (msg.contains('rate limit') || msg.contains('too many')) {
      return 'Too many attempts. Please wait a moment and try again.';
    }
    if (msg.contains('user not found')) {
      return 'No account found with this email. Please sign up first.';
    }

    // Database / trigger errors
    if (msg.contains('database error saving new user') ||
        msg.contains('database error')) {
      return 'Signup failed due to a server issue. Please try again shortly.';
    }

    // Password errors
    if (msg.contains('weak password') ||
        (msg.contains('password') && msg.contains('short'))) {
      return 'Password is too weak. Use at least 6 characters with mixed case and numbers.';
    }
    if (msg.contains('password') &&
        (msg.contains('length') || msg.contains('characters'))) {
      return 'Password must be at least 6 characters.';
    }

    // Email errors
    if (msg.contains('valid email') ||
        msg.contains('invalid email') ||
        msg.contains('unable to validate')) {
      return 'Please enter a valid email address.';
    }

    // OAuth / social login errors
    if (msg.contains('oauth') || msg.contains('provider')) {
      return 'Social login failed. Please try again or use email instead.';
    }
    if (msg.contains('popup') ||
        msg.contains('cancelled') ||
        msg.contains('canceled')) {
      return 'Login was cancelled. Please try again.';
    }

    // Signup disabled
    if (msg.contains('signup') && msg.contains('disabled')) {
      return 'Registration is currently disabled. Please try again later.';
    }

    // Email change errors
    if (msg.contains('email_change') || msg.contains('email change')) {
      return 'Email change is not allowed at this time.';
    }

    // Anonymous user errors
    if (msg.contains('anonymous')) {
      return 'Anonymous access is not supported. Please sign in.';
    }

    // Network errors
    if (msg.contains('network') ||
        msg.contains('socket') ||
        msg.contains('timeout') ||
        msg.contains('connection') ||
        msg.contains('dns') ||
        msg.contains('unreachable')) {
      return 'Network error. Please check your internet connection and try again.';
    }

    // Server errors
    if (msg.contains('500') ||
        msg.contains('internal server') ||
        msg.contains('server error')) {
      return 'Server is temporarily unavailable. Please try again later.';
    }
    if (msg.contains('503') || msg.contains('service unavailable')) {
      return 'Service is temporarily down for maintenance. Please try again later.';
    }

    // Session errors
    if (msg.contains('session') &&
        (msg.contains('expired') || msg.contains('invalid'))) {
      return 'Your session has expired. Please sign in again.';
    }

    // Generic fallback — strip prefix and provide cleaner message
    final cleaned = error.toString().replaceAll(RegExp(r'^Exception:\s*'), '');
    if (cleaned.length > 100) {
      return 'Something went wrong. Please try again.';
    }
    return cleaned;
  }
}
