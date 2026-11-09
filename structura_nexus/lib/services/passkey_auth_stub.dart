// Stub implementation for non-web environments (tests and desktop/mobile stubs)

class PasskeyAuthPlatform {
  static Future<bool> isSupported() async => false;

  static Future<Map<String, dynamic>> registerPasskey(String email, String displayName) async {
    return {'success': false, 'error': 'Passkeys are currently only supported on Web.'};
  }

  static Future<Map<String, dynamic>> authenticatePasskey() async {
    return {'success': false, 'error': 'Passkeys are currently only supported on Web.'};
  }

  static List<Map<String, dynamic>> getSavedAccounts() => [];
}

