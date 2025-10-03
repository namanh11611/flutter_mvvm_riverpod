// Environment variables for the app
// Note: In production, these should be loaded from a .env file using envied package
class Env {
  // Supabase Configuration
  static const String supabaseUrl = 'https://your-project.supabase.co';
  static const String supabaseAnonKey = 'your-supabase-anon-key';

  // Google Sign-In Configuration
  static const String googleClientId = 'your-google-client-id';
  static const String googleServerClientId = 'your-google-server-client-id';

  // RevenueCat Configuration
  static const String revenueCatPlayStore = 'your-revenue-cat-play-store-key';
  static const String revenueCatAppStore = 'your-revenue-cat-app-store-key';
}
