import 'package:z_speed/core/result/result.dart';
import 'package:z_speed/features/auth/model/user_model.dart';

abstract class AuthRepository {
  Future<Result<AppUser>> login(String email, String password, {bool rememberMe = false});
  Future<Result<({AppUser user, bool isNewUser})>> signInWithGoogle();
  Future<Result<({AppUser user, bool isNewUser})>> signInWithApple();
  Future<Result<AppUser>> completeGoogleRegistration(AppUser user);
  Future<Result<void>> logout();
  Future<Result<AppUser>> getCurrentUser();
  Stream<AppUser?> watchCurrentUser(String uid);
  Future<Result<bool>> isLoggedIn();
  Future<Result<void>> register(AppUser newUser);

  // ── Phone Auth ──
  Future<Result<dynamic>> signInWithPhoneWeb(String phoneNumber);
  Future<Result<AppUser>> confirmPhoneCodeWeb(
      dynamic confirmation, String smsCode);
  Future<Result<AppUser>> confirmPhoneCodeMobile({
    required String verificationId,
    required String smsCode,
  });
  Future<Result<void>> updateUserName(String uid, String name);
  Future<Result<void>> updateUserPhone(String uid, String phone);
  Future<Result<void>> updateUserProfile(
      String uid, Map<String, dynamic> updates);

  // ── Email Verification ──
  Future<Result<void>> sendEmailVerification();
  Future<Result<bool>> isEmailVerified();

  // ── Password Reset ──
  Future<Result<void>> forgotPassword(String email);

  // ── Change Password ──
  Future<Result<void>> changePassword({
    required String currentPassword,
    required String newPassword,
  });

  // ── Delete Account ──
  Future<Result<void>> deleteAccount();
}
