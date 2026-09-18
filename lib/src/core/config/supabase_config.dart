class SupabaseConfig {
  const SupabaseConfig._();

  static const String _rawUrl = String.fromEnvironment(
    'SUPABASE_URL',
    defaultValue: 'https://lispzcvxmulhiutlayds.supabase.co',
  );

  static const String anonKey = String.fromEnvironment(
    'SUPABASE_ANON_KEY',
    defaultValue:
        'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6Imxpc3B6Y3Z4bXVsaGl1dGxheWRzIiwicm9sZSI6ImFub24iLCJpYXQiOjE3ODk0NzkwMjQsImV4cCI6MjEwNTA1NTAyNH0.LeY0_rDw6wT0RCkWAwTjpS5nHOeK5m7qaQUrWv7SSpU',
  );

  /// Sanitized Supabase URL without whitespace, quotes, or /rest/v1 path
  static String get url {
    var cleaned = _rawUrl.trim();
    // Remove accidental quotes
    cleaned = cleaned
        .replaceAll('"', '')
        .replaceAll('“', '')
        .replaceAll('”', '')
        .trim();
    // Strip trailing /rest/v1 or /rest/v1/
    if (cleaned.endsWith('/rest/v1/')) {
      cleaned = cleaned.substring(0, cleaned.length - 9);
    } else if (cleaned.endsWith('/rest/v1')) {
      cleaned = cleaned.substring(0, cleaned.length - 8);
    }
    // Strip trailing slash
    if (cleaned.endsWith('/')) {
      cleaned = cleaned.substring(0, cleaned.length - 1);
    }
    return cleaned;
  }
}
