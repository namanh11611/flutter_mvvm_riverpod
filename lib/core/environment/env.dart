import 'package:envied/envied.dart';

part 'env.g.dart';

@Envied(path: '.env')
abstract class Env {
  @EnviedField(varName: 'SUPABASE_URL', obfuscate: true, defaultValue: '')
  static final String supabaseUrl = _Env.supabaseUrl;

  @EnviedField(varName: 'SUPABASE_ANON_KEY', obfuscate: true, defaultValue: '')
  static final String supabaseAnonKey = _Env.supabaseAnonKey;

  @EnviedField(varName: 'GOOGLE_CLIENT_ID', obfuscate: true, defaultValue: '')
  static final String googleClientId = _Env.googleClientId;

  @EnviedField(varName: 'GOOGLE_SERVER_CLIENT_ID', obfuscate: true, defaultValue: '')
  static final String googleServerClientId = _Env.googleServerClientId;

  @EnviedField(varName: 'REVENUE_CAT_PLAY_STORE', obfuscate: true, defaultValue: '')
  static final String revenueCatPlayStore = _Env.revenueCatPlayStore;

  @EnviedField(varName: 'REVENUE_CAT_APP_STORE', obfuscate: true, defaultValue: '')
  static final String revenueCatAppStore = _Env.revenueCatAppStore;

  static bool get hasSupabase =>
      supabaseUrl.isNotEmpty && supabaseAnonKey.isNotEmpty;
}
