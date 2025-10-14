// Environment variables for the app
// Note: In production, these should be loaded from a .env file using envied package
class Env {
  // Supabase Configuration
  static const String supabaseUrl = 'https://nvsctpfysaqcxdozwdbg.supabase.co';
  static const String supabaseAnonKey = 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6Im52c2N0cGZ5c2FxY3hkb3p3ZGJnIiwicm9sZSI6ImFub24iLCJpYXQiOjE3NTkzOTg1NDAsImV4cCI6MjA3NDk3NDU0MH0.kpBCWdcjs0I8q5EWUwb3BR0_xv-qt2gtWePhvUuIm3Q';

  // Google Sign-In Configuration
  static const String googleClientId = '234604531809-1vmkuskqcdl5hgk177m5fs2bkfj6kd0d.apps.googleusercontent.com';
  static const String googleServerClientId = '234604531809-8jgq1eiv5fouiik1dn1sd5hoio5297ct.apps.googleusercontent.com';

  // RevenueCat Configuration
  static const String revenueCatPlayStore = 'your-revenue-cat-play-store-key';
  static const String revenueCatAppStore = 'your-revenue-cat-app-store-key';
}
