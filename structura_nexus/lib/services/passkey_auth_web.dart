// Web implementation using modern dart:js_interop

import 'dart:convert';
import 'dart:js_interop';

@JS('StructuraPasskey.isSupported')
external JSPromise<JSBoolean>? _jsIsSupported();

@JS('StructuraPasskey.registerPasskey')
external JSPromise<JSString>? _jsRegisterPasskey(JSString email, JSString displayName);

@JS('StructuraPasskey.authenticatePasskey')
external JSPromise<JSString>? _jsAuthenticatePasskey();

@JS('StructuraPasskey.getSavedAccounts')
external JSString? _jsGetSavedAccounts();

class PasskeyAuthPlatform {
  static Future<bool> isSupported() async {
    try {
      final promise = _jsIsSupported();
      if (promise == null) return false;
      final result = await promise.toDart;
      return result.toDart;
    } catch (_) {
      return false;
    }
  }

  static Future<Map<String, dynamic>> registerPasskey(String email, String displayName) async {
    try {
      final promise = _jsRegisterPasskey(email.toJS, displayName.toJS);
      if (promise == null) {
        return {'success': false, 'error': 'Passkey JS subsystem not loaded.'};
      }
      final jsStr = await promise.toDart;
      final decoded = jsonDecode(jsStr.toDart);
      if (decoded is Map<String, dynamic>) {
        return decoded;
      }
      return {'success': false, 'error': 'Malformed response.'};
    } catch (e) {
      return {'success': false, 'error': e.toString()};
    }
  }

  static Future<Map<String, dynamic>> authenticatePasskey() async {
    try {
      final promise = _jsAuthenticatePasskey();
      if (promise == null) {
        return {'success': false, 'error': 'Passkey JS subsystem not loaded.'};
      }
      final jsStr = await promise.toDart;
      final decoded = jsonDecode(jsStr.toDart);
      if (decoded is Map<String, dynamic>) {
        return decoded;
      }
      return {'success': false, 'error': 'Malformed response.'};
    } catch (e) {
      return {'success': false, 'error': e.toString()};
    }
  }

  static List<Map<String, dynamic>> getSavedAccounts() {
    try {
      final jsStr = _jsGetSavedAccounts();
      if (jsStr == null) return [];
      final list = jsonDecode(jsStr.toDart);
      if (list is List) {
        return list.map((e) => Map<String, dynamic>.from(e as Map)).toList();
      }
      return [];
    } catch (_) {
      return [];
    }
  }
}
