import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/user_profile.dart';

class AuthService {
  final SupabaseClient _supabase = Supabase.instance.client;

  User? get currentUser => _supabase.auth.currentUser;
  Session? get currentSession => _supabase.auth.currentSession;
  Stream<AuthState> get authStateChanges => _supabase.auth.onAuthStateChange;

  /// Sign up with email and password
  Future<AuthResponse> signUp({
    required String email,
    required String password,
    required String fullName,
  }) async {
    final response = await _supabase.auth.signUp(
      email: email.trim().toLowerCase(),
      password: password,
      data: {'full_name': fullName.trim()},
    );

    if (response.user != null) {
      // Ensure profile record exists
      await _ensureProfile(response.user!, fullName: fullName.trim());
    }

    return response;
  }

  /// Sign in with email and password
  Future<AuthResponse> signIn({
    required String email,
    required String password,
  }) async {
    final response = await _supabase.auth.signInWithPassword(
      email: email.trim().toLowerCase(),
      password: password,
    );

    if (response.user != null) {
      await _ensureProfile(response.user!);
    }

    return response;
  }

  /// Sign in with Google
  Future<bool> signInWithGoogle() async {
    final response = await _supabase.auth.signInWithOAuth(
      OAuthProvider.google,
      redirectTo: 'io.supabase.bongoportus://login-callback/',
    );
    return response;
  }

  /// Sign out
  Future<void> signOut() async {
    await _supabase.auth.signOut();
  }

  /// Get user profile from database
  Future<UserProfile?> getProfile(String userId) async {
    try {
      final data = await _supabase
          .from('profiles')
          .select()
          .eq('id', userId)
          .single();
      return UserProfile.fromJson(data);
    } catch (e) {
      // Fall back to creating profile from auth user
      final user = currentUser;
      if (user != null) {
        return UserProfile(
          id: user.id,
          email: user.email ?? '',
          fullName: user.userMetadata?['full_name'],
          avatarUrl: user.userMetadata?['avatar_url'],
          role: 'user',
        );
      }
      return null;
    }
  }

  /// Update user profile
  Future<UserProfile?> updateProfile({
    required String userId,
    String? fullName,
    String? phone,
    String? avatarUrl,
  }) async {
    final updates = <String, dynamic>{};
    if (fullName != null) updates['full_name'] = fullName;
    if (phone != null) updates['phone'] = phone;
    if (avatarUrl != null) updates['avatar_url'] = avatarUrl;

    final data = await _supabase
        .from('profiles')
        .update(updates)
        .eq('id', userId)
        .select()
        .single();

    return UserProfile.fromJson(data);
  }

  /// Reset password
  Future<void> resetPassword(String email) async {
    await _supabase.auth.resetPasswordForEmail(email.trim().toLowerCase());
  }

  /// Ensure profile exists in profiles table
  Future<void> _ensureProfile(User user, {String? fullName}) async {
    try {
      await _supabase.from('profiles').select().eq('id', user.id).single();
    } catch (_) {
      // Profile doesn't exist, create it
      try {
        await _supabase.from('profiles').insert({
          'id': user.id,
          'email': user.email ?? '',
          'full_name': fullName ?? user.userMetadata?['full_name'],
          'avatar_url': user.userMetadata?['avatar_url'],
          'role': 'user',
          'is_verified': false,
          'is_blocked': false,
        });
      } catch (e) {
        // Profile might already exist from a trigger, ignore
        print('Profile creation skipped: $e');
      }
    }
  }
}
