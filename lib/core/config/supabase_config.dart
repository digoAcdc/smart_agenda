/// Configuracao do Supabase para autenticacao.
/// Valores padrao para o projeto smart-agenda-supabase (Easypanel).
/// Para sobrescrever: flutter run --dart-define=SUPABASE_URL=... --dart-define=SUPABASE_ANON_KEY=...
class SupabaseConfig {
  SupabaseConfig._();

  static const String url = String.fromEnvironment(
    'SUPABASE_URL',
    defaultValue: 'https://smart-agenda-supabase.vybg0t.easypanel.host',
  );
  static const String anonKey = String.fromEnvironment(
    'SUPABASE_ANON_KEY',
    defaultValue:
        'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJyb2xlIjoiYW5vbiIsImlzcyI6InN1cGFiYXNlIiwiaWF0IjoxNzkxNDg2NTI1LCJleHAiOjIxMDY4NDY1MjV9.2NBfjcKT3AXBJ9fYWAuDiDiaOQvSK34ZmOwu9Xrz2jw',
  );

  static bool get isConfigured => url.isNotEmpty && anonKey.isNotEmpty;
}
