/// Supabase configuration for BongoPortus mobile app.
///
/// Credentials are shared with the website via the single backend/.env file.
/// The same Supabase project powers both the mobile app and web frontend.
///
/// To override at build time, use:
///   flutter build apk --dart-define-from-file=../backend/.env
class SupabaseConfig {
  SupabaseConfig._();

  /// Your Supabase project URL (from backend/.env → SUPABASE_URL)
  static const String url = String.fromEnvironment(
    'SUPABASE_URL',
    defaultValue: 'https://rgzvlxhimentlidcdvtp.supabase.co',
  );

  /// Your Supabase anonymous/public key (from backend/.env → SUPABASE_ANON_KEY)
  static const String anonKey = String.fromEnvironment(
    'SUPABASE_ANON_KEY',
    defaultValue:
        'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6InJnenZseGhpbWVudGxpZGNkdnRwIiwicm9sZSI6ImFub24iLCJpYXQiOjE3NzA5ODk5NDMsImV4cCI6MjA4NjU2NTk0M30.wpy1fITfTXXLW9K8WHHdkyNSHEgdRjeXFXRgG-4ktgA',
  );

  /// Google OAuth Client ID for mobile (Android)
  static const String googleClientIdAndroid = String.fromEnvironment(
    'GOOGLE_CLIENT_ID_ANDROID',
    defaultValue: '',
  );

  /// Google OAuth Client ID for mobile (iOS)
  static const String googleClientIdIos = String.fromEnvironment(
    'GOOGLE_CLIENT_ID_IOS',
    defaultValue: '',
  );
}
