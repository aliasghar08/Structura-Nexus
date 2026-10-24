import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart' show debugPrint, kIsWeb;

class FirebaseAuthService {
  static final FirebaseAuthService _instance = FirebaseAuthService._internal();
  factory FirebaseAuthService() => _instance;
  FirebaseAuthService._internal();

  bool _initialized = false;
  bool get isFirebaseAvailable => _initialized;

  Future<void> initialize() async {
    try {
      if (Firebase.apps.isNotEmpty) {
        _initialized = true;
        await _ensureLocalPersistence();
        _ensureListener();
      }
    } catch (e) {
      debugPrint('Firebase Auth initialization note: $e');
      _initialized = false;
    }
  }

  FirebaseAuth? get _auth {
    try {
      if (!_initialized && Firebase.apps.isEmpty) return null;
      _initialized = true;
      return FirebaseAuth.instance;
    } catch (_) {
      return null;
    }
  }

  FirebaseFirestore? get _db {
    try {
      if (!_initialized && Firebase.apps.isEmpty) return null;
      return FirebaseFirestore.instance;
    } catch (_) {
      return null;
    }
  }

  StreamSubscription<User?>? _authSub;
  bool _listenerAttached = false;
  bool _persistenceConfigured = false;
  DateTime? _lastSyncedAt;
  String? _lastSyncedUid;

  User? get currentUser => _auth?.currentUser;

  Stream<User?> get authStateChanges {
    final a = _auth;
    if (a == null) return const Stream.empty();
    return a.authStateChanges();
  }

  Future<void> _ensureLocalPersistence() async {
    if (!kIsWeb) return;
    if (_persistenceConfigured) return;
    _persistenceConfigured = true;
    try {
      await _auth?.setPersistence(Persistence.LOCAL);
    } catch (e) {
      debugPrint('Persistence config note: $e');
    }
  }

  void _ensureListener() {
    if (_listenerAttached) return;
    final a = _auth;
    if (a == null) return;
    _listenerAttached = true;
    _authSub = a.authStateChanges().listen((User? user) {
      if (user != null) {
        unawaited(_syncUserProfile(user));
      }
    });
  }

  Future<void> _syncUserProfile(User user) async {
    final now = DateTime.now();
    if (_lastSyncedUid == user.uid &&
        _lastSyncedAt != null &&
        now.difference(_lastSyncedAt!).inHours < 12) {
      return;
    }
    try {
      final db = _db;
      if (db == null) return;
      final docRef = db.collection('users').doc(user.uid);
      final snapshot = await docRef.get();
      final data = <String, dynamic>{
        'uid': user.uid,
        'email': user.email,
        'displayName': user.displayName ?? (user.isAnonymous ? 'Guest Engineer' : user.email?.split('@').first),
        'isAnonymous': user.isAnonymous,
        'lastSeen': FieldValue.serverTimestamp(),
        if (!snapshot.exists) 'createdAt': FieldValue.serverTimestamp(),
      };
      await docRef.set(data, SetOptions(merge: true));
      _lastSyncedAt = now;
      _lastSyncedUid = user.uid;
    } catch (e) {
      debugPrint('Firestore profile sync note: $e');
    }
  }

  Future<UserCredential?> signInWithEmail(String email, String password) async {
    final a = _auth;
    if (a == null) throw Exception('Firebase is not initialized.');
    _ensureListener();
    await _ensureLocalPersistence();
    final cred = await a.signInWithEmailAndPassword(email: email.trim(), password: password);
    if (cred.user != null) {
      await _syncUserProfile(cred.user!);
    }
    return cred;
  }

  Future<UserCredential?> registerWithEmail(String email, String password, {String? displayName}) async {
    final a = _auth;
    if (a == null) throw Exception('Firebase is not initialized.');
    _ensureListener();
    await _ensureLocalPersistence();
    final cred = await a.createUserWithEmailAndPassword(email: email.trim(), password: password);
    if (cred.user != null) {
      if (displayName != null && displayName.trim().isNotEmpty) {
        try {
          await cred.user!.updateDisplayName(displayName.trim());
        } catch (_) {}
      }
      await _syncUserProfile(cred.user!);
    }
    return cred;
  }

  Future<UserCredential?> signInAnonymously() async {
    final a = _auth;
    if (a == null) throw Exception('Firebase is not initialized.');
    _ensureListener();
    await _ensureLocalPersistence();
    final cred = await a.signInAnonymously();
    if (cred.user != null) {
      try {
        await cred.user!.updateDisplayName('Engineer (Guest)');
      } catch (_) {}
      await _syncUserProfile(cred.user!);
    }
    return cred;
  }

  Future<UserCredential?> signInWithGoogle() async {
    final a = _auth;
    if (a == null) throw Exception('Firebase is not initialized.');
    _ensureListener();
    await _ensureLocalPersistence();
    final googleProvider = GoogleAuthProvider();
    final cred = await a.signInWithPopup(googleProvider);
    if (cred.user != null) {
      await _syncUserProfile(cred.user!);
    }
    return cred;
  }

  Future<void> sendPasswordReset(String email) async {
    final a = _auth;
    if (a == null) throw Exception('Firebase is not initialized.');
    await a.sendPasswordResetEmail(email: email.trim());
  }

  Future<void> signOut() async {
    await _auth?.signOut();
  }

  void dispose() {
    _authSub?.cancel();
    _authSub = null;
    _listenerAttached = false;
  }
}
