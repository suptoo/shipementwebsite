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
    if (msg.contains('invalid login')) {
      return 'Invalid email or password';
    }
    if (msg.contains('already registered') || msg.contains('already exists')) {
      return 'An account with this email already exists';
    }
    if (msg.contains('password')) {
      return 'Password must be at least 6 characters';
    }
    if (msg.contains('email')) {
      return 'Please enter a valid email address';
    }
    if (msg.contains('network') || msg.contains('socket')) {
      return 'Network error. Please check your connection.';
    }
    return error.toString();
  }
}
