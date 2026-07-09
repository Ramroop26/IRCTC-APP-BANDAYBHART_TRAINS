import 'package:flutter/foundation.dart';

class ApiConfig {
  // Use relative path for web so that it dynamically fits the host,
  // and fallback to localhost:3000 for mobile/desktop/emulator.
  static const String baseUrl = kIsWeb ? '' : 'http://localhost:3000';
}
