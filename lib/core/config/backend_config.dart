class BackendConfig {
  const BackendConfig._();

  static const supabaseUrl = String.fromEnvironment('SUPABASE_URL');
  static const supabaseAnonKey = String.fromEnvironment('SUPABASE_ANON_KEY');

  static bool get hasSupabase {
    return supabaseUrl.isNotEmpty && supabaseAnonKey.isNotEmpty;
  }
}
