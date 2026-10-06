import 'dart:async';
import 'dart:developer';

import 'package:firebase_auth/firebase_auth.dart' as firebase_auth;
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:google_sign_in/google_sign_in.dart';
import 'package:sign_in_with_apple/sign_in_with_apple.dart';
import 'package:z_speed/core/errors/failures.dart';
import 'package:z_speed/core/services/fcm_service.dart';
import 'package:z_speed/features/admin/datasource/settings_datasource.dart';
import 'package:z_speed/features/auth/model/user_model.dart';

import 'package:injectable/injectable.dart' hide Order;

/// Firebase Auth + Firestore datasource for authentication.
///
/// This replaces [AuthLocalDatasource] for production use.
/// It handles:
/// - Email/password login & registration via Firebase Auth
/// - User profile CRUD in Firestore `users` collection
/// - Session management via Firebase Auth state
@lazySingleton
class AuthFirebaseDatasource {
  final firebase_auth.FirebaseAuth _auth;
  final FirebaseFirestore _firestore;
  final SettingsDatasource _settingsDatasource;

  AuthFirebaseDatasource({
    firebase_auth.FirebaseAuth? auth,
    FirebaseFirestore? firestore,
    SettingsDatasource? settingsDatasource,
  })  : _auth = auth ?? firebase_auth.FirebaseAuth.instance,
        _firestore = firestore ?? FirebaseFirestore.instance,
        _settingsDatasource = settingsDatasource ?? SettingsDatasource();

  // ── Blocking & Registration Checks ──────────────────────────────────────────

  void _assertUserNotBlocked(AppUser user) {
    if (user.status == UserStatus.banned ||
        user.status == UserStatus.suspended) {
      log('AuthFirebaseDatasource: Access blocked for user ${user.id} with status ${user.status.name}');
      throw UserBlockedFailure(
        'Your account has been suspended. Please contact customer support.',
      );
    }
  }

  Future<void> _assertCanRegister({
    String? phone,
    String? email,
    String? uid,
  }) async {
    final settings = await _settingsDatasource.getSettings();
    final allowNewSignups = settings['allowNewSignups'] as bool? ?? true;
    if (!allowNewSignups) {
      final customMsg = settings['signupDisabledMessage'] as String?;
      throw RegistrationDisabledFailure(
        (customMsg != null && customMsg.trim().isNotEmpty)
            ? customMsg
            : 'New account registrations are temporarily paused. Please check back soon.',
      );
    }

    final isBlocked = await _settingsDatasource.isBlacklisted(
      phone: phone,
      email: email,
      uid: uid,
    );
    if (isBlocked) {
      throw UserBlockedFailure(
        phone != null && phone.isNotEmpty
            ? 'This phone number has been blocked from registering.'
            : 'This email address has been blocked from registering.',
      );
    }
  }



  // ── State ──────────────────────────────────────────────────────────────────

  AppUser? _cachedUser;
  AppUser? get cachedUser => _cachedUser;
  bool get isAuthenticated => _auth.currentUser != null;
  Stream<firebase_auth.User?> get authStateChanges => _auth.authStateChanges();

  // ── Login ──────────────────────────────────────────────────────────────────

  /// Sign in with email and password.
  /// Returns the [AppUser] profile from Firestore.
  /// Throws [firebase_auth.FirebaseAuthException] on failure.
  Future<AppUser> login(String email, String password, {bool rememberMe = false}) async {
    if (kIsWeb) {
      await _auth.setPersistence(
        rememberMe
            ? firebase_auth.Persistence.LOCAL
            : firebase_auth.Persistence.SESSION,
      );
    }
    final credential = await _auth.signInWithEmailAndPassword(
      email: email.trim().toLowerCase(),
      password: password,
    );

    if (credential.user == null) {
      throw Exception('Login failed — no user returned');
    }

    final firebaseUser = credential.user!;
    final user = await _fetchUserProfile(firebaseUser.uid);
    if (user == null) {
      throw Exception('User profile not found in database');
    }

    _assertUserNotBlocked(user);

    _cachedUser = user;
    log('AuthFirebaseDatasource: login success for ${user.email}');
    log('AuthFirebaseDatasource: User Info -> id: ${user.id}, name: ${user.name}, email: ${user.email}, type: ${user.type.name}');
    log('AuthFirebaseDatasource: User Role -> ${user.type.name}');

    return user;
  }

  // ── Google Sign-In ─────────────────────────────────────────────────────────

  /// Sign in with Google. Creates a Firestore profile if first-time login.
  /// Uses signInWithPopup on web (redirect flow breaks on mobile Safari
  /// due to storage partitioning / ITP).
  /// Returns the [AppUser] profile.
  Future<({AppUser user, bool isNewUser})> signInWithGoogle() async {
    final firebase_auth.UserCredential userCredential;

    if (kIsWeb) {
      final googleProvider = firebase_auth.GoogleAuthProvider();
      googleProvider.addScope('email');
      googleProvider.addScope('profile');

      try {
        userCredential = await _auth.signInWithPopup(googleProvider);
      } catch (e) {
        final msg = e.toString().toLowerCase();
        if (msg.contains('popup') || msg.contains('blocked')) {
          throw Exception(
            'Popup was blocked by your browser. '
            'Please allow popups for this site and try again.',
          );
        }
        rethrow;
      }
    } else {
      final googleSignIn = GoogleSignIn.instance;
      final googleUser = await googleSignIn.authenticate();

      final idToken = googleUser.authentication.idToken;
      if (idToken == null) {
        log('AuthFirebaseDatasource: Google sign-in failed — idToken is null. Check SHA-1/SHA-256 in Firebase Console.');
        throw Exception(
            'Google sign-in failed — missing ID Token. Please verify your Android configuration (SHA fingerprints).');
      }

      final authorizationClient = googleUser.authorizationClient;
      final authorization =
          await authorizationClient.authorizeScopes(['email', 'profile']);

      final credential = firebase_auth.GoogleAuthProvider.credential(
        accessToken: authorization.accessToken,
        idToken: idToken,
      );
      userCredential = await _auth.signInWithCredential(credential);
    }

    final firebaseUser = userCredential.user;
    if (firebaseUser == null) {
      throw Exception('Google sign-in failed — no user returned');
    }

    // Check if user profile already exists in Firestore
    final existingUser = await _fetchUserProfile(firebaseUser.uid);
    if (existingUser != null) {
      _assertUserNotBlocked(existingUser);
      _cachedUser = existingUser;
      log('AuthFirebaseDatasource: Google sign-in success for ${existingUser.email}');
      return (user: existingUser, isNewUser: false);
    }

    // New user — verify registration is permitted
    try {
      await _assertCanRegister(
        email: firebaseUser.email,
        uid: firebaseUser.uid,
      );
    } catch (e) {
      await _auth.signOut();
      rethrow;
    }

    // Return partial profile without saving; caller will pick role first
    final newUser = AppUser(
      id: firebaseUser.uid,
      name: firebaseUser.displayName ?? '',
      email: firebaseUser.email ?? '',
      type: UserType.customer, // placeholder, will be overwritten
      createdAt: DateTime.now(),
      status: UserStatus.active,
    );
    log('AuthFirebaseDatasource: new Google user, needs role selection ${newUser.email}');
    return (user: newUser, isNewUser: true);
  }

  /// Save a Google user's profile to Firestore after they pick a role.
  Future<AppUser> completeGoogleRegistration(AppUser user) async {
    await _assertCanRegister(
      email: user.email,
      phone: user.phone,
      uid: user.id,
    );
    await _firestore.collection('users').doc(user.id).set(user.toMap());
    _cachedUser = user;
    log('AuthFirebaseDatasource: completed Google registration for ${user.email}');
    return user;
  }

  // ── Apple Sign-In ──────────────────────────────────────────────────────────

  /// Sign in with Apple. Creates a Firestore profile if first-time login.
  /// Only supported on iOS, macOS, and web (not Android).
  /// Returns the [AppUser] profile.
  Future<({AppUser user, bool isNewUser})> signInWithApple() async {
    final appleCredential = await SignInWithApple.getAppleIDCredential(
      scopes: [
        AppleIDAuthorizationScopes.email,
        AppleIDAuthorizationScopes.fullName,
      ],
    );

    final oauthCredential = firebase_auth.OAuthProvider('apple.com').credential(
      idToken: appleCredential.identityToken,
      accessToken: appleCredential.authorizationCode,
    );

    final userCredential = await _auth.signInWithCredential(oauthCredential);
    final firebaseUser = userCredential.user;
    if (firebaseUser == null) {
      throw Exception('Apple sign-in failed — no user returned');
    }

    // Apple only returns name on the FIRST sign-in ever — cache it before it disappears
    final displayName = appleCredential.givenName != null
        ? '${appleCredential.givenName} ${appleCredential.familyName ?? ''}'
            .trim()
        : firebaseUser.displayName ?? '';

    // Update Firebase Auth display name if we got one from Apple
    if (displayName.isNotEmpty &&
        (firebaseUser.displayName == null ||
            firebaseUser.displayName!.isEmpty)) {
      await firebaseUser.updateDisplayName(displayName);
    }

    // Check if user profile already exists in Firestore
    final existingUser = await _fetchUserProfile(firebaseUser.uid);
    if (existingUser != null) {
      _assertUserNotBlocked(existingUser);
      _cachedUser = existingUser;
      log('AuthFirebaseDatasource: Apple sign-in success for ${existingUser.email}');
      return (user: existingUser, isNewUser: false);
    }

    // New user — check registration permissions
    final email = (firebaseUser.email?.isNotEmpty == true)
        ? firebaseUser.email!
        : (appleCredential.email?.isNotEmpty == true)
            ? appleCredential.email!
            : '${firebaseUser.uid}@privaterelay.appleid.com';

    try {
      await _assertCanRegister(
        email: email,
        uid: firebaseUser.uid,
      );
    } catch (e) {
      await _auth.signOut();
      rethrow;
    }

    final newUser = AppUser(
      id: firebaseUser.uid,
      name: displayName,
      email: email,
      type: UserType.customer,
      createdAt: DateTime.now(),
      status: UserStatus.active,
    );
    log('AuthFirebaseDatasource: new Apple user ${newUser.email}');
    return (user: newUser, isNewUser: true);
  }

  // ── Register ───────────────────────────────────────────────────────────────

  /// Create a new Firebase Auth account + Firestore user profile.
  /// Returns the created [AppUser].
  /// Throws [firebase_auth.FirebaseAuthException] on failure.
  Future<AppUser> register({
    required String name,
    required String email,
    required String password,
    required UserType type,
    String? phone,
    String? address,
    ApplicationStatus? applicationStatus,
    double? latitude,
    double? longitude,
  }) async {
    await _assertCanRegister(
      phone: phone,
      email: email,
    );

    final credential = await _auth.createUserWithEmailAndPassword(
      email: email.trim().toLowerCase(),
      password: password,
    );

    if (credential.user == null) {
      throw Exception('Registration failed — no user created');
    }

    // Update Firebase Auth display name
    await credential.user!.updateDisplayName(name.trim());

    final now = DateTime.now();
    final newUser = AppUser(
      id: credential.user!.uid,
      name: name.trim(),
      email: email.trim().toLowerCase(),
      type: type,
      phone: phone?.trim(),
      address: address?.trim(),
      applicationStatus: applicationStatus,
      latitude: latitude,
      longitude: longitude,
      createdAt: now,
      status: UserStatus.active,
    );

    // Write profile to Firestore
    await _firestore
        .collection('users')
        .doc(credential.user!.uid)
        .set(newUser.toMap());

    _cachedUser = newUser;
    log('AuthFirebaseDatasource: registered ${newUser.email} as ${type.name}');

    return newUser;
  }

  // ── Logout ─────────────────────────────────────────────────────────────────

  Future<void> logout() async {
    final uid = _auth.currentUser?.uid;

    // ── Step 1: Firestore cleanup WHILE still authenticated ──────────────────
    // Must happen before signOut() — Firestore rejects writes after sign-out
    // with permission-denied.
    if (uid != null && !kIsWeb) {
      await FcmService().removeTokenFromFirestore(uid);
    }

    // ── Step 2: Sign out (local, always succeeds) ────────────────────────────
    _cachedUser = null;
    await _auth.signOut();

    // Sign out from Google to prevent silent re-authentication on next launch.
    if (!kIsWeb) {
      try {
        await GoogleSignIn.instance.signOut();
      } catch (_) {}
    }

    log('AuthFirebaseDatasource: logged out (uid=$uid)');
  }

  // ── Current User ───────────────────────────────────────────────────────────

  /// Fetch the current authenticated user's profile from Firestore.
  /// Returns null if no user is signed in or profile doesn't exist.
  Future<AppUser?> getCurrentUser() async {
    final firebaseUser = _auth.currentUser;
    if (firebaseUser == null) return null;

    try {
      final user = await _fetchUserProfile(firebaseUser.uid);
      _cachedUser = user;
      return user;
    } catch (e) {
      log('AuthFirebaseDatasource: getCurrentUser Firestore failed: $e');

      // 1. Try to return existing cache if it matches the current user
      if (_cachedUser != null && _cachedUser!.id == firebaseUser.uid) {
        log('AuthFirebaseDatasource: using existing cached user for ${firebaseUser.uid}');
        return _cachedUser;
      }

      // No fallback user to prevent silent role switches. Propagate error.
      rethrow;
    }
  }

  // ── Session ────────────────────────────────────────────────────────────────

  bool hasSession() => _auth.currentUser != null;

  // ── Profile Update ─────────────────────────────────────────────────────────

  /// Update user profile fields in Firestore.
  Future<void> updateUserProfile(
      String uid, Map<String, dynamic> updates) async {
    updates['updatedAt'] = FieldValue.serverTimestamp();
    await _firestore.collection('users').doc(uid).update(updates);

    // Refresh cache
    if (_cachedUser?.id == uid) {
      _cachedUser = await _fetchUserProfile(uid);
    }
  }

  // ── Phone Auth ─────────────────────────────────────────────────────────────

  /// Start phone sign-in on web. Returns a [ConfirmationResult] that the
  /// caller uses to confirm the SMS code.
  Future<firebase_auth.ConfirmationResult> signInWithPhoneWeb(
      String phoneNumber) async {
    return _auth.signInWithPhoneNumber(phoneNumber.replaceAll(' ', ''));
  }

  /// Start phone verification on mobile platforms.
  Future<void> verifyPhoneNumberMobile({
    required String phoneNumber,
    required void Function(firebase_auth.PhoneAuthCredential)
        verificationCompleted,
    required void Function(firebase_auth.FirebaseAuthException)
        verificationFailed,
    required void Function(String verificationId, int? resendToken) codeSent,
    required void Function(String verificationId) codeAutoRetrievalTimeout,
    int? resendToken,
  }) async {
    await _auth.verifyPhoneNumber(
      phoneNumber: phoneNumber.replaceAll(' ', ''),
      forceResendingToken: resendToken,
      timeout: const Duration(seconds: 60),
      verificationCompleted: verificationCompleted,
      verificationFailed: verificationFailed,
      codeSent: codeSent,
      codeAutoRetrievalTimeout: codeAutoRetrievalTimeout,
    );
  }

  /// Confirm phone SMS code on mobile using verificationId.
  /// Signs in and creates/fetches the Firestore profile.
  Future<AppUser> confirmPhoneCodeMobile({
    required String verificationId,
    required String smsCode,
  }) async {
    final credential = firebase_auth.PhoneAuthProvider.credential(
      verificationId: verificationId,
      smsCode: smsCode,
    );
    return _signInWithPhoneCredential(credential);
  }

  /// Confirm phone SMS code on web using ConfirmationResult.
  Future<AppUser> confirmPhoneCodeWeb(
      firebase_auth.ConfirmationResult confirmation, String smsCode) async {
    final userCredential = await confirmation.confirm(smsCode);
    final firebaseUser = userCredential.user;
    if (firebaseUser == null) {
      throw Exception('Phone sign-in failed — no user returned');
    }
    return _ensureUserProfile(firebaseUser, 'phone');
  }

  /// Shared logic: sign in with phone credential → ensure Firestore profile.
  Future<AppUser> _signInWithPhoneCredential(
      firebase_auth.PhoneAuthCredential credential) async {
    final userCredential = await _auth.signInWithCredential(credential);
    final firebaseUser = userCredential.user;
    if (firebaseUser == null) {
      throw Exception('Phone sign-in failed — no user returned');
    }
    return _ensureUserProfile(firebaseUser, 'phone');
  }

  /// Ensure user has a Firestore profile. Creates one if first sign-in.
  Future<AppUser> _ensureUserProfile(
      firebase_auth.User firebaseUser, String method) async {
    var user = await _fetchUserProfile(firebaseUser.uid);
    if (user == null) {
      // New user — check registration permissions
      try {
        await _assertCanRegister(
          phone: firebaseUser.phoneNumber,
          email: firebaseUser.email,
          uid: firebaseUser.uid,
        );
      } catch (e) {
        try {
          await firebaseUser.delete();
        } catch (_) {}
        await _auth.signOut();
        rethrow;
      }

      final now = DateTime.now();
      user = AppUser(
        id: firebaseUser.uid,
        name: '', // Name will be collected via dialog
        email: firebaseUser.email ?? '',
        phone: firebaseUser.phoneNumber,
        type: UserType.customer,
        createdAt: now,
        status: UserStatus.active,
      );
      await _firestore
          .collection('users')
          .doc(firebaseUser.uid)
          .set(user.toMap());
      log('AuthFirebaseDatasource: created profile for $method user ${firebaseUser.uid}');
    } else {
      _assertUserNotBlocked(user);
    }
    _cachedUser = user;
    return user;
  }

  /// Real-time stream of the current user's profile to detect live changes (e.g. status ban).
  Stream<AppUser?> watchUser(String uid) {
    return _firestore
        .collection('users')
        .doc(uid)
        .snapshots()
        .map((snapshot) {
      if (!snapshot.exists || snapshot.data() == null) return null;
      return AppUser.fromMap(snapshot.data()!, snapshot.id);
    });
  }

  /// Update user's display name in both Firestore and Firebase Auth.
  Future<void> updateUserName(String uid, String name) async {
    await _firestore.collection('users').doc(uid).update({
      'name': name.trim(),
      'updatedAt': FieldValue.serverTimestamp(),
    });
    final currentUser = _auth.currentUser;
    if (currentUser != null && currentUser.uid == uid) {
      await currentUser.updateDisplayName(name.trim());
    }
    if (_cachedUser?.id == uid) {
      _cachedUser = await _fetchUserProfile(uid);
    }
  }

  /// Update user's phone number in Firestore.
  Future<void> updateUserPhone(String uid, String phone) async {
    await _firestore.collection('users').doc(uid).update({
      'phone': phone.trim(),
      'updatedAt': FieldValue.serverTimestamp(),
    });
    if (_cachedUser?.id == uid) {
      _cachedUser = await _fetchUserProfile(uid);
    }
  }

  // ── Change Password ────────────────────────────────────────────────────────

  /// Re-authenticate with [currentPassword] then update to [newPassword].
  /// Throws [firebase_auth.FirebaseAuthException] on wrong current password.
  Future<void> changePassword({
    required String currentPassword,
    required String newPassword,
  }) async {
    final user = _auth.currentUser;
    if (user == null) throw Exception('No user signed in');
    if (user.email == null) throw Exception('No email on account');

    // Re-authenticate first (required by Firebase before sensitive operations)
    final credential = firebase_auth.EmailAuthProvider.credential(
      email: user.email!,
      password: currentPassword,
    );
    await user.reauthenticateWithCredential(credential);
    await user.updatePassword(newPassword);
    log('AuthFirebaseDatasource: password changed for ${user.email}');
  }

  // ── Email Verification ─────────────────────────────────────────────────────

  /// Send Firebase's built-in email verification link.
  Future<void> sendEmailVerification() async {
    final user = _auth.currentUser;
    if (user == null) throw Exception('No user signed in');
    if (user.emailVerified) return; // already verified
    await user.sendEmailVerification();
  }

  /// Check if the current user's email is verified.
  /// Reloads the Firebase user first to get latest status.
  Future<bool> isEmailVerified() async {
    final user = _auth.currentUser;
    if (user == null) return false;
    await user.reload();
    // After reload, we need to get the fresh user reference
    return _auth.currentUser?.emailVerified ?? false;
  }

  // ── Password Reset ─────────────────────────────────────────────────────────

  Future<void> sendPasswordResetEmail(String email) async {
    await _auth.sendPasswordResetEmail(email: email.trim().toLowerCase());
  }

  // ── Delete Account ─────────────────────────────────────────────────────────

  /// Permanently delete the current user's Firestore document and Firebase Auth account.
  /// Requires recent authentication — callers should re-auth first if needed.
  Future<void> deleteAccount() async {
    final user = _auth.currentUser;
    if (user == null) throw Exception('No user signed in');

    final uid = user.uid;

    // Invalidate FCM token so the messaging SDK stops refreshing it.
    try {
      await FcmService().removeToken(uid);
    } catch (_) {}

    // Flush any queued Firestore writes BEFORE deleting the auth account —
    // otherwise offline writes get replayed with a stale token and fail with
    // PERMISSION_DENIED once the account is gone.
    try {
      await _firestore.waitForPendingWrites();
    } catch (_) {}

    // Delete Firestore profile (includes fcmTokens — no need to update first)
    await _firestore.collection('users').doc(uid).delete();

    // Ensure the delete itself is acknowledged by the server before we drop
    // the auth token.
    try {
      await _firestore.waitForPendingWrites();
    } catch (_) {}

    // Delete Firebase Auth account
    await user.delete();

    // Terminate Firestore to cancel any listeners/queued writes bound to the
    // now-invalid auth session, then clear the offline cache so nothing is
    // retried on next app start.
    try {
      await _firestore.terminate();
      await _firestore.clearPersistence();
    } catch (_) {}

    _cachedUser = null;
    log('AuthFirebaseDatasource: account deleted for uid=$uid');
  }

  // ── Helpers ────────────────────────────────────────────────────────────────

  /// Timeout for Firestore reads during auth flows.
  /// Increased to 10s to handle slow mobile networks while still
  /// preventing infinite hangs.
  static const _firestoreTimeout = Duration(seconds: 10);

  Future<AppUser?> _fetchUserProfile(String uid) async {
    const maxAttempts = 3;
    var delay = const Duration(milliseconds: 500);

    for (int attempt = 1; attempt <= maxAttempts; attempt++) {
      try {
        final doc = await _firestore
            .collection('users')
            .doc(uid)
            .get(const GetOptions(source: Source.server))
            .timeout(_firestoreTimeout);
        if (!doc.exists || doc.data() == null) {
          log('AuthFirebaseDatasource: no Firestore profile for uid=$uid');
          return null;
        }
        return AppUser.fromMap(doc.data()!, doc.id);
      } catch (e) {
        log('AuthFirebaseDatasource: attempt $attempt failed to fetch profile from server for uid=$uid: $e');
        if (attempt == maxAttempts) {
          log('AuthFirebaseDatasource: All server attempts failed. Trying local cache...');
          try {
            final cacheDoc = await _firestore
                .collection('users')
                .doc(uid)
                .get(const GetOptions(source: Source.cache));
            if (cacheDoc.exists && cacheDoc.data() != null) {
              log('AuthFirebaseDatasource: successfully retrieved profile from cache for uid=$uid');
              return AppUser.fromMap(cacheDoc.data()!, cacheDoc.id);
            }
          } catch (cacheErr) {
            log('AuthFirebaseDatasource: cache fetch also failed: $cacheErr');
          }
          rethrow;
        }
        await Future.delayed(delay);
        delay *= 2;
      }
    }
    return null;
  }

  /// Translate Firebase Auth error codes into user-friendly messages.
  static String translateFirebaseError(firebase_auth.FirebaseAuthException e) {
    switch (e.code) {
      case 'user-not-found':
        return 'No account found with this email';
      case 'wrong-password':
        return 'Incorrect password';
      case 'email-already-in-use':
        return 'An account already exists with this email';
      case 'weak-password':
        return 'Password must be at least 6 characters';
      case 'invalid-email':
        return 'Invalid email address';
      case 'user-disabled':
        return 'This account has been disabled';
      case 'too-many-requests':
        return 'Too many attempts. Please try again later';
      case 'network-request-failed':
        return 'Network error. Check your connection';
      case 'invalid-credential':
        return 'Invalid email or password';
      case 'operation-not-allowed':
        return 'This sign-in method is not enabled';
      default:
        return e.message ?? 'Authentication failed (${e.code})';
    }
  }
}
