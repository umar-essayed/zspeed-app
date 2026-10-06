import 'package:firebase_auth/firebase_auth.dart' as firebase_auth;
import 'package:z_speed/core/core.dart';
import 'package:z_speed/features/auth/datasource/auth_firebase_datasource.dart';
import 'package:z_speed/features/auth/repository/auth_repository.dart';
import 'package:z_speed/features/auth/model/user_model.dart';
import 'package:injectable/injectable.dart' hide Order;

/// Production implementation of [AuthRepository] backed by Firebase.
///
/// Every public method catches exceptions and returns [Result<T>]:
/// - [Success] on happy path
/// - [Err] with typed [Failure] on error
@LazySingleton(as: AuthRepository)
class AuthRepositoryImpl implements AuthRepository {
  final AuthFirebaseDatasource _datasource;

  AuthRepositoryImpl({AuthFirebaseDatasource? datasource})
      : _datasource = datasource ?? AuthFirebaseDatasource();

  /// Expose cached user for quick access (e.g. after register).
  AppUser? get cachedUser => _datasource.cachedUser;

  @override
  Future<Result<AppUser>> login(String email, String password, {bool rememberMe = false}) async {
    try {
      final user = await _datasource.login(email, password, rememberMe: rememberMe);
      return Success(user);
    } on Failure catch (f) {
      return Err(f);
    } on firebase_auth.FirebaseAuthException catch (e, st) {
      return Err(AuthFailure(
        AuthFirebaseDatasource.translateFirebaseError(e),
        st,
      ));
    } catch (e, st) {
      return Err(AuthFailure('Login failed: $e', st));
    }
  }

  @override
  Future<Result<({AppUser user, bool isNewUser})>> signInWithGoogle() async {
    try {
      final result = await _datasource.signInWithGoogle();
      return Success(result);
    } on Failure catch (f) {
      return Err(f);
    } on firebase_auth.FirebaseAuthException catch (e, st) {
      return Err(AuthFailure(
        AuthFirebaseDatasource.translateFirebaseError(e),
        st,
      ));
    } catch (e, st) {
      return Err(AuthFailure('Google sign-in failed: $e', st));
    }
  }

  @override
  Future<Result<({AppUser user, bool isNewUser})>> signInWithApple() async {
    try {
      final result = await _datasource.signInWithApple();
      return Success(result);
    } on Failure catch (f) {
      return Err(f);
    } on firebase_auth.FirebaseAuthException catch (e, st) {
      return Err(AuthFailure(
        AuthFirebaseDatasource.translateFirebaseError(e),
        st,
      ));
    } catch (e, st) {
      return Err(AuthFailure('Apple sign-in failed: $e', st));
    }
  }

  @override
  Future<Result<AppUser>> completeGoogleRegistration(AppUser user) async {
    try {
      final saved = await _datasource.completeGoogleRegistration(user);
      return Success(saved);
    } on Failure catch (f) {
      return Err(f);
    } catch (e, st) {
      return Err(AuthFailure('Failed to complete registration: $e', st));
    }
  }

  @override
  Future<Result<void>> logout() async {
    try {
      await _datasource.logout();
      return Success(null);
    } catch (e, st) {
      return Err(AuthFailure('Logout failed: $e', st));
    }
  }

  @override
  Future<Result<AppUser>> getCurrentUser() async {
    try {
      final user = await _datasource.getCurrentUser();
      if (user == null) {
        return Err(AuthFailure('No active session'));
      }
      return Success(user);
    } on Failure catch (f) {
      return Err(f);
    } catch (e, st) {
      return Err(AuthFailure('Failed to get user: $e', st));
    }
  }

  @override
  Stream<AppUser?> watchCurrentUser(String uid) => _datasource.watchUser(uid);

  @override
  Future<Result<bool>> isLoggedIn() async {
    try {
      return Success(_datasource.hasSession());
    } catch (e, st) {
      return Err(AuthFailure('Session check failed: $e', st));
    }
  }

  @override
  Future<Result<void>> register(AppUser newUser) async {
    try {
      await _datasource.register(
        name: newUser.name,
        email: newUser.email,
        password: newUser.password ?? '',
        type: newUser.type,
        phone: newUser.phone,
        address: newUser.address,
        applicationStatus: newUser.applicationStatus,
        latitude: newUser.latitude,
        longitude: newUser.longitude,
      );
      return Success(null);
    } on Failure catch (f) {
      return Err(f);
    } on firebase_auth.FirebaseAuthException catch (e, st) {
      return Err(AuthFailure(
        AuthFirebaseDatasource.translateFirebaseError(e),
        st,
      ));
    } catch (e, st) {
      return Err(AuthFailure('Registration failed: $e', st));
    }
  }

  // ── Phone Auth ─────────────────────────────────────────────────────────────

  @override
  Future<Result<dynamic>> signInWithPhoneWeb(String phoneNumber) async {
    try {
      final confirmation = await _datasource.signInWithPhoneWeb(phoneNumber);
      return Success(confirmation);
    } catch (e, st) {
      return Err(AuthFailure('Failed to send SMS: $e', st));
    }
  }

  @override
  Future<Result<AppUser>> confirmPhoneCodeWeb(
      dynamic confirmation, String smsCode) async {
    try {
      final user = await _datasource.confirmPhoneCodeWeb(
        confirmation as firebase_auth.ConfirmationResult,
        smsCode,
      );
      return Success(user);
    } on Failure catch (f) {
      return Err(f);
    } catch (e, st) {
      return Err(AuthFailure('Phone verification failed: $e', st));
    }
  }

  @override
  Future<Result<AppUser>> confirmPhoneCodeMobile({
    required String verificationId,
    required String smsCode,
  }) async {
    try {
      final user = await _datasource.confirmPhoneCodeMobile(
        verificationId: verificationId,
        smsCode: smsCode,
      );
      return Success(user);
    } on Failure catch (f) {
      return Err(f);
    } catch (e, st) {
      return Err(AuthFailure('Phone verification failed: $e', st));
    }
  }

  @override
  Future<Result<void>> updateUserName(String uid, String name) async {
    try {
      await _datasource.updateUserName(uid, name);
      return Success(null);
    } catch (e, st) {
      return Err(AuthFailure('Failed to update name: $e', st));
    }
  }

  @override
  Future<Result<void>> updateUserPhone(String uid, String phone) async {
    try {
      await _datasource.updateUserPhone(uid, phone);
      return Success(null);
    } catch (e, st) {
      return Err(AuthFailure('Failed to update phone: $e', st));
    }
  }

  @override
  Future<Result<void>> updateUserProfile(
      String uid, Map<String, dynamic> updates) async {
    try {
      await _datasource.updateUserProfile(uid, updates);
      return Success(null);
    } catch (e, st) {
      return Err(AuthFailure('Failed to update profile: $e', st));
    }
  }

  // ── Email Verification ─────────────────────────────────────────────────────

  @override
  Future<Result<void>> sendEmailVerification() async {
    try {
      await _datasource.sendEmailVerification();
      return Success(null);
    } catch (e, st) {
      return Err(AuthFailure('Failed to send verification email: $e', st));
    }
  }

  @override
  Future<Result<bool>> isEmailVerified() async {
    try {
      final verified = await _datasource.isEmailVerified();
      return Success(verified);
    } catch (e, st) {
      return Err(AuthFailure('Failed to check email verification: $e', st));
    }
  }

  @override
  Future<Result<void>> forgotPassword(String email) async {
    try {
      await _datasource.sendPasswordResetEmail(email);
      return Success(null);
    } catch (e, st) {
      return Err(AuthFailure('Failed to send reset email: $e', st));
    }
  }

  @override
  Future<Result<void>> changePassword({
    required String currentPassword,
    required String newPassword,
  }) async {
    try {
      await _datasource.changePassword(
        currentPassword: currentPassword,
        newPassword: newPassword,
      );
      return Success(null);
    } catch (e, st) {
      return Err(AuthFailure('$e', st));
    }
  }

  @override
  Future<Result<void>> deleteAccount() async {
    try {
      await _datasource.deleteAccount();
      return Success(null);
    } on firebase_auth.FirebaseAuthException catch (e, st) {
      return Err(AuthFailure(
        AuthFirebaseDatasource.translateFirebaseError(e),
        st,
      ));
    } catch (e, st) {
      return Err(AuthFailure('Failed to delete account: $e', st));
    }
  }
}
