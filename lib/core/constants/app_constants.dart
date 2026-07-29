/// Supabase credentials are baked in as default values for local development.
/// For CI/production, override via:
///   flutter run --dart-define=SUPABASE_URL=https://xxx.supabase.co \
///               --dart-define=SUPABASE_ANON_KEY=eyJ...
class AppConstants {
  AppConstants._();

  // ── Supabase ───────────────────────────────────────────────────────────────
  static const String supabaseUrl = String.fromEnvironment(
    'SUPABASE_URL',
    defaultValue: 'https://twtnxdpvqkirdiqnyusi.supabase.co',
  );

  static const String supabaseAnonKey = String.fromEnvironment(
    'SUPABASE_ANON_KEY',
    defaultValue:
        'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6InR3dG54ZHB2cWtpcmRpcW55dXNpIiwicm9sZSI6ImFub24iLCJpYXQiOjE3ODUyOTQyOTksImV4cCI6MjEwMDg3MDI5OX0.I_qJ-14TVWMNS-G_On4eWKivsqtM_E7a1mOck8JCN_I',
  );

  // ── App metadata ───────────────────────────────────────────────────────────
  static const String appName = 'Placement Connect';
  static const String appVersion = '1.0.0';

  // ── Pagination ─────────────────────────────────────────────────────────────
  static const int defaultPageSize = 20;

  // ── Timeouts ───────────────────────────────────────────────────────────────
  static const Duration networkTimeout = Duration(seconds: 30);

  /// Throws if credentials are missing (useful in main() for early validation).
  static void validate() {
    if (supabaseUrl.isEmpty || supabaseAnonKey.isEmpty) {
      throw ArgumentError(
        'Supabase credentials missing. '
        'Pass --dart-define=SUPABASE_URL=... --dart-define=SUPABASE_ANON_KEY=...',
      );
    }
  }
}