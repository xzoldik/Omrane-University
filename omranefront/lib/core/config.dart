import 'package:flutter/foundation.dart';
import 'dart:io' show Platform;

class AppConfig {
  // Set this to your PC's LAN IP to allow physical device access (e.g., '192.168.1.50').
  // Leave null to use platform defaults (localhost / 10.0.2.2 for emulators).
  // IMPORTANT: Use bare host only (no http://), e.g., '192.168.1.35'
  static const String hostOverride = '192.168.1.33'; // e.g., '192.168.1.50'

  // Developer convenience: automatically sign in with a default user on app start.
  // This only affects the app; the backend still validates credentials.
  static const bool autoLogin = false;
  static const String autoLoginEmail = 'admin@university.edu';
  static const String autoLoginPassword = 'admin123';

  // Platform-aware base URL for local backend
  static String get baseUrl {
    final host = hostOverride.trim();
    if (host.isNotEmpty) {
      // Normalize in case a scheme or trailing slash was mistakenly included
      final normalizedHost = host
          .replaceFirst(RegExp(r'^https?://', caseSensitive: false), '')
          .replaceAll(RegExp(r'/+$'), '');
      return 'http://$normalizedHost:3000/api';
    }

    // Web (Chrome) can use localhost and requires withCredentials
    if (kIsWeb) return 'http://localhost:3000/api';

    // Desktop/Windows
    if (Platform.isWindows || Platform.isLinux || Platform.isMacOS) {
      return 'http://localhost:3000/api';
    }

    // Android emulator uses 10.0.2.2 to reach host machine
    if (Platform.isAndroid) return 'http://10.0.2.2:3000/api';

    // iOS simulator can reach localhost directly
    if (Platform.isIOS) return 'http://localhost:3000/api';

    // Fallback
    return 'http://localhost:3000/api';
  }
}
