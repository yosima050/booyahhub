class SupabaseConfig {
  static const String url = String.fromEnvironment('SUPABASE_URL',
    defaultValue: 'https://dacdutkuqqqwhlbqhhvf.supabase.co');
  static const String anonKey = String.fromEnvironment('SUPABASE_ANON_KEY',
    defaultValue: 'sb_publishable_H5bXNaXNcPmSjxsiGQKwjA_rkPxWm-N');
}
