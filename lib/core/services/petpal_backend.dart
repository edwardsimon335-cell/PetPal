import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../config/backend_config.dart';

class PetPalBackend {
  PetPalBackend._();

  static bool _initialized = false;

  static bool get isEnabled => _initialized && BackendConfig.hasSupabase;

  static SupabaseClient get client {
    if (!isEnabled) {
      throw StateError('Supabase is not configured for this build.');
    }
    return Supabase.instance.client;
  }

  static Future<void> initialize() async {
    if (!BackendConfig.hasSupabase) {
      debugPrint(
          'PetPalBackend: Supabase dart-defines are not set; using local demo mode.');
      return;
    }

    await Supabase.initialize(
      url: BackendConfig.supabaseUrl,
      publishableKey: BackendConfig.supabaseAnonKey,
    );
    _initialized = true;

    try {
      if (client.auth.currentSession == null) {
        await client.auth.signInAnonymously();
      }
    } catch (error) {
      debugPrint('PetPalBackend: anonymous sign-in failed: $error');
    }
  }
}
