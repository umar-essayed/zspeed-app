import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:injectable/injectable.dart' hide Order;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:firebase_auth/firebase_auth.dart' as firebase_auth;
import 'package:google_sign_in/google_sign_in.dart';
import 'package:z_speed/core/core.dart';
import 'package:z_speed/core/services/crashlytics_service.dart';
import 'package:z_speed/core/services/analytics_service.dart';
import 'package:z_speed/features/auth/repository/auth_repository.dart';
import 'package:z_speed/features/auth/repository/auth_repository_impl.dart';
import 'package:z_speed/features/auth/model/user_model.dart';
import 'package:z_speed/features/customer/model/saved_address.dart';
import 'package:z_speed/features/auth/cubit/auth_state.dart';
import 'package:z_speed/features/cart/cubit/cart_cubit.dart';
import 'package:z_speed/core/injection.dart';

@lazySingleton
class AuthCubit extends Cubit<AuthState> {
  final AuthRepository _repository;
  StreamSubscription<AppUser?>? _userSubscription;

  AuthCubit({AuthRepository? repository})
    : _repository = repository ?? AuthRepositoryImpl(),
      super(const AuthState());

  AppUser? get currentUser => state.user;
  bool get isAuthenticated => state.isAuthenticated;
  UserType? get userType => state.user?.type;

  void _subscribeToUser(String uid) {
    _userSubscription?.cancel();
    _userSubscription = _repository.watchCurrentUser(uid).listen(
      (updatedUser) {
        if (updatedUser == null) return;
        if (updatedUser.status == UserStatus.banned ||
            updatedUser.status == UserStatus.suspended) {
          debugPrint('AuthCubit: User $uid has been banned/suspended in real-time');
          _userSubscription?.cancel();
          _userSubscription = null;
          firebase_auth.FirebaseAuth.instance.signOut().catchError((_) {});
          emit(AuthState(
            status: AuthStatus.blocked,
            user: updatedUser,
            failure: UserBlockedFailure(),
          ));
        } else if (state.user != updatedUser) {
          emit(state.copyWith(user: updatedUser));
        }
      },
      onError: (err) {
        debugPrint('AuthCubit: error watching user: $err');
      },
    );
  }

  @override
  void emit(AuthState state) {
    if (kIsWeb && state.isAuthenticated && state.user != null) {
      final role = state.user!.type;
      if (role == UserType.customer || role == UserType.driver) {
        firebase_auth.FirebaseAuth.instance.signOut();
        final webRestrictionFailure = AuthFailure(
          'Web access is restricted to vendors and administrators. Please use the mobile app.',
        );
        super.emit(
          AuthState(status: AuthStatus.error, failure: webRestrictionFailure),
        );
        return;
      }
    }

    // If transitioning to authenticated state, clear the logout flag.
    if (state.isAuthenticated && !this.state.isAuthenticated) {
      SharedPreferences.getInstance()
          .then((prefs) {
            prefs.remove(_kLoggedOutKey);
          })
          .catchError((_) {});
    }
    super.emit(state);
  }

  void clearError() {
    if (state.hasError) {
      emit(state.copyWith(status: AuthStatus.initial, clearFailure: true));
    }
  }

  void enterGuestMode() {
    emit(state.copyWith(status: AuthStatus.guest));
  }

  static const _kLoggedOutKey = 'user_logged_out';

  Future<void> checkAuthStatus() async {
    // Only emit loading state if there is no user currently logged in.
    // This prevents background refreshes from flashing the loading/login screens.
    if (state.user == null) {
      emit(state.copyWith(status: AuthStatus.loading, clearFailure: true));
    } else {
      emit(state.copyWith(clearFailure: true));
    }

    // Belt-and-suspenders: if a previous logout set the flag but Firebase Auth
    // still has a cached session (race / offline write), force sign-out now.
    try {
      final prefs = await SharedPreferences.getInstance();
      if (prefs.getBool(_kLoggedOutKey) == true) {
        await firebase_auth.FirebaseAuth.instance.signOut();
        if (!kIsWeb) {
          try {
            await GoogleSignIn.instance.signOut();
          } catch (_) {}
        }
        await prefs.remove(_kLoggedOutKey);
        emit(const AuthState(status: AuthStatus.unauthenticated));
        return;
      }
    } catch (_) {}

    final loginResult = await _repository.isLoggedIn();
    switch (loginResult) {
      case Success(data: true):
        final userResult = await _repository.getCurrentUser();
        switch (userResult) {
          case Success(:final data):
            if (data.status == UserStatus.banned ||
                data.status == UserStatus.suspended) {
              emit(AuthState(
                status: AuthStatus.blocked,
                user: data,
                failure: UserBlockedFailure(),
              ));
            } else {
              emit(state.copyWith(status: AuthStatus.authenticated, user: data));
              _subscribeToUser(data.id);
            }
          case Err(:final failure):
            if (failure is UserBlockedFailure) {
              emit(AuthState(status: AuthStatus.blocked, failure: failure));
            } else {
              // Could not load profile — treat as unauthenticated to avoid
              // landing on an inconsistent home screen.
              emit(const AuthState(status: AuthStatus.unauthenticated));
              debugPrint(
                'checkAuthStatus: profile fetch failed: ${failure.message}',
              );
            }
        }
      case Success(data: false):
        emit(const AuthState(status: AuthStatus.unauthenticated));
      case Err(:final failure):
        if (failure is UserBlockedFailure) {
          emit(AuthState(status: AuthStatus.blocked, failure: failure));
        } else {
          emit(state.copyWith(status: AuthStatus.error, failure: failure));
        }
    }
  }

  Future<void> login(String email, String password, {bool rememberMe = false}) async {
    emit(
      state.copyWith(
        status: AuthStatus.loading,
        clearFailure: true,
        clearPendingGoogleUser: true,
        clearConfirmationResult: true,
      ),
    );

    final result = await _repository.login(email, password, rememberMe: rememberMe);
    switch (result) {
      case Success(:final data):
        if (data.status == UserStatus.banned ||
            data.status == UserStatus.suspended) {
          emit(AuthState(
            status: AuthStatus.blocked,
            user: data,
            failure: UserBlockedFailure(),
          ));
          return;
        }
        if (!kIsWeb) CrashlyticsService.setUserId(data.id);
        AnalyticsService.setUserId(data.id); // Track user in analytics
        AnalyticsService.setUserRole(data.type.toString().split('.').last);
        emit(state.copyWith(status: AuthStatus.authenticated, user: data));
        _subscribeToUser(data.id);
      case Err(:final failure):
        if (failure is UserBlockedFailure) {
          emit(AuthState(status: AuthStatus.blocked, failure: failure));
        } else {
          emit(state.copyWith(status: AuthStatus.error, failure: failure));
        }
    }
  }

  Future<void> signInWithGoogle() async {
    emit(
      state.copyWith(
        status: AuthStatus.loading,
        clearFailure: true,
        clearPendingGoogleUser: true,
        clearConfirmationResult: true,
      ),
    );

    final result = await _repository.signInWithGoogle();
    switch (result) {
      case Success(:final data):
        if (data.isNewUser) {
          // New user — needs to pick a role first
          emit(
            state.copyWith(
              status: AuthStatus.unauthenticated,
              pendingGoogleUser: data.user,
              clearFailure: true,
            ),
          );
        } else {
          if (data.user.status == UserStatus.banned ||
              data.user.status == UserStatus.suspended) {
            emit(AuthState(
              status: AuthStatus.blocked,
              user: data.user,
              failure: UserBlockedFailure(),
            ));
            return;
          }
          if (!kIsWeb) CrashlyticsService.setUserId(data.user.id);
          AnalyticsService.setUserId(data.user.id);
          AnalyticsService.setUserRole(
            data.user.type.toString().split('.').last,
          );
          emit(
            state.copyWith(status: AuthStatus.authenticated, user: data.user),
          );
          _subscribeToUser(data.user.id);
        }
      case Err(:final failure):
        if (failure is UserBlockedFailure) {
          emit(AuthState(status: AuthStatus.blocked, failure: failure));
        } else {
          emit(state.copyWith(status: AuthStatus.error, failure: failure));
        }
    }
  }

  Future<void> signInWithApple() async {
    emit(
      state.copyWith(
        status: AuthStatus.loading,
        clearFailure: true,
        clearPendingGoogleUser: true,
        clearConfirmationResult: true,
      ),
    );

    final result = await _repository.signInWithApple();
    switch (result) {
      case Success(:final data):
        if (data.isNewUser) {
          // New Apple user — save to Firestore as customer directly
          final customerUser = data.user.copyWith(type: UserType.customer);
          final saveResult = await _repository.completeGoogleRegistration(
            customerUser,
          );
          switch (saveResult) {
            case Success(:final data):
              if (!kIsWeb) CrashlyticsService.setUserId(data.id);
              AnalyticsService.setUserId(data.id);
              AnalyticsService.setUserRole(
                data.type.toString().split('.').last,
              );
              AnalyticsService.logSignUp(method: 'apple');
              emit(
                state.copyWith(
                  status: AuthStatus.authenticated,
                  user: data,
                  clearPendingGoogleUser: true,
                ),
              );
              _subscribeToUser(data.id);
            case Err(:final failure):
              if (failure is UserBlockedFailure) {
                emit(AuthState(status: AuthStatus.blocked, failure: failure));
              } else {
                emit(state.copyWith(status: AuthStatus.error, failure: failure));
              }
          }
        } else {
          if (data.user.status == UserStatus.banned ||
              data.user.status == UserStatus.suspended) {
            emit(AuthState(
              status: AuthStatus.blocked,
              user: data.user,
              failure: UserBlockedFailure(),
            ));
            return;
          }
          if (!kIsWeb) CrashlyticsService.setUserId(data.user.id);
          AnalyticsService.setUserId(data.user.id);
          AnalyticsService.setUserRole(
            data.user.type.toString().split('.').last,
          );
          emit(
            state.copyWith(status: AuthStatus.authenticated, user: data.user),
          );
          _subscribeToUser(data.user.id);
        }
      case Err(:final failure):
        if (failure is UserBlockedFailure) {
          emit(AuthState(status: AuthStatus.blocked, failure: failure));
        } else {
          emit(state.copyWith(status: AuthStatus.error, failure: failure));
        }
    }
  }

  /// Called after a new Google user picks their role (and optionally fills extra info).
  Future<void> completeGoogleRegistration(AppUser userWithRole) async {
    emit(
      state.copyWith(
        status: AuthStatus.loading,
        clearFailure: true,
        clearPendingGoogleUser: true,
        clearConfirmationResult: true,
      ),
    );

    final result = await _repository.completeGoogleRegistration(userWithRole);
    switch (result) {
      case Success(:final data):
        if (!kIsWeb) CrashlyticsService.setUserId(data.id);
        AnalyticsService.setUserId(data.id);
        AnalyticsService.setUserRole(data.type.toString().split('.').last);
        AnalyticsService.logSignUp(method: 'google');
        emit(
          state.copyWith(
            status: AuthStatus.authenticated,
            user: data,
            clearPendingGoogleUser: true,
          ),
        );
        _subscribeToUser(data.id);
      case Err(:final failure):
        if (failure is UserBlockedFailure) {
          emit(AuthState(status: AuthStatus.blocked, failure: failure));
        } else {
          emit(state.copyWith(status: AuthStatus.error, failure: failure));
        }
    }
  }

  Future<void> logout() async {
    debugPrint('logout called');
    _userSubscription?.cancel();
    _userSubscription = null;

    final userId = state.user?.id;
    emit(
      state.copyWith(
        status: AuthStatus.loading,
        clearFailure: true,
        clearPendingGoogleUser: true,
        clearConfirmationResult: true,
      ),
    );

    // Clear cart on logout to prevent session leak
    try {
      getIt<CartCubit>().clearCart();
    } catch (e) {
      debugPrint('Error clearing cart on logout: $e');
    }

    // ── Step 1: Write logout flag BEFORE signing out ─────────────────────────
    // This ensures that even if the app crashes mid-logout, checkAuthStatus()
    // on the next launch will force sign-out and never restore the old session.
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool(_kLoggedOutKey, true);
    } catch (e) {
      debugPrint("Error setting logout flag: $e");
    }

    // ── Step 1.5: Best-effort FCM token removal from Firestore BEFORE sign-out ──
    if (!kIsWeb && userId != null) {
      try {
        final fcmService = FcmService();
        await fcmService.removeTokenFromFirestore(userId);
      } catch (e) {
        debugPrint('Error removing FCM token from Firestore: $e');
      }
    }

    // ── Step 2: Sign out from Firebase Auth (always runs) ────────────────────
    final result = await _repository.logout();
    switch (result) {
      case Success():
        if (!kIsWeb) CrashlyticsService.setUserId('');
        AnalyticsService.setUserId(null);
        // Emit unauthenticated immediately — UI goes to LoginPage right away.
        emit(const AuthState(status: AuthStatus.unauthenticated));
      case Err(:final failure):
        emit(state.copyWith(status: AuthStatus.error, failure: failure));
        return; // Don't continue cleanup if logout itself failed
    }

    // ── Step 3: Best-effort FCM device cleanup (after session is already cleared) ───
    if (!kIsWeb && userId != null) {
      try {
        final fcmService = FcmService();
        await fcmService.unsubscribeFromAllTopics();
        await fcmService.removeToken(
          userId,
        ); // cancels listener + deletes token
        await fcmService.clearAllNotifications();
      } catch (e) {
        debugPrint('Error during post-logout notification cleanup: $e');
      }
    }

    // We intentionally DO NOT clear _kLoggedOutKey here.
    // It must remain true so that if the app is killed before Firebase Auth
    // fully flushes its signed-out state to disk (or if an in-flight offline write resurrects it),
    // checkAuthStatus() on the next launch will know to force a sign-out.
    // The flag will be cleared automatically the next time the user successfully logs in.
  }

  Future<void> register(AppUser newUser) async {
    emit(
      state.copyWith(
        status: AuthStatus.loading,
        clearFailure: true,
        clearPendingGoogleUser: true,
        clearConfirmationResult: true,
      ),
    );

    final result = await _repository.register(newUser);
    switch (result) {
      case Success():
        // After Firebase registration, fetch the real user with server-assigned id
        final userResult = await _repository.getCurrentUser();
        switch (userResult) {
          case Success(:final data):
            if (!kIsWeb) CrashlyticsService.setUserId(data.id);
            AnalyticsService.setUserId(data.id); // Track user in analytics
            AnalyticsService.setUserRole(data.type.toString().split('.').last);
            AnalyticsService.logSignUp(method: 'email'); // Log signup event
            emit(state.copyWith(status: AuthStatus.authenticated, user: data));
            _subscribeToUser(data.id);
          case Err():
            // Registration succeeded but profile fetch failed — use input as fallback
            if (!kIsWeb) CrashlyticsService.setUserId(newUser.id);
            AnalyticsService.setUserId(newUser.id);
            AnalyticsService.setUserRole(
              newUser.type.toString().split('.').last,
            );
            AnalyticsService.logSignUp(method: 'email');
            emit(
              state.copyWith(status: AuthStatus.authenticated, user: newUser),
            );
            _subscribeToUser(newUser.id);
        }
      case Err(:final failure):
        if (failure is UserBlockedFailure) {
          emit(AuthState(status: AuthStatus.blocked, failure: failure));
        } else {
          emit(state.copyWith(status: AuthStatus.error, failure: failure));
        }
    }
  }

  // ── Phone Auth ─────────────────────────────────────────────────────────────

  /// Start phone sign-in on web. Returns the ConfirmationResult via callback.
  Future<dynamic> signInWithPhoneWeb(String phoneNumber) async {
    emit(
      state.copyWith(
        status: AuthStatus.loading,
        clearFailure: true,
        clearPendingGoogleUser: true,
        clearConfirmationResult: true,
      ),
    );

    final result = await _repository.signInWithPhoneWeb(phoneNumber);
    switch (result) {
      case Success(:final data):
        emit(
          state.copyWith(status: AuthStatus.initial, confirmationResult: data),
        );
        return data;
      case Err(:final failure):
        emit(state.copyWith(status: AuthStatus.error, failure: failure));
        return null;
    }
  }

  /// Confirm phone OTP on web.
  Future<void> confirmPhoneCodeWeb(dynamic confirmation, String smsCode) async {
    emit(
      state.copyWith(
        status: AuthStatus.loading,
        clearFailure: true,
        clearPendingGoogleUser: true,
      ),
    );

    final result = await _repository.confirmPhoneCodeWeb(confirmation, smsCode);
    switch (result) {
      case Success(:final data):
        if (data.status == UserStatus.banned ||
            data.status == UserStatus.suspended) {
          emit(AuthState(
            status: AuthStatus.blocked,
            user: data,
            failure: UserBlockedFailure(),
          ));
          return;
        }
        if (!kIsWeb) CrashlyticsService.setUserId(data.id);
        AnalyticsService.setUserId(data.id);
        AnalyticsService.setUserRole(data.type.toString().split('.').last);
        if (data.name.trim().isEmpty) {
          AnalyticsService.logSignUp(method: 'phone');
        }
        emit(state.copyWith(status: AuthStatus.authenticated, user: data));
        _subscribeToUser(data.id);
      case Err(:final failure):
        if (failure is UserBlockedFailure) {
          emit(AuthState(status: AuthStatus.blocked, failure: failure));
        } else {
          emit(state.copyWith(status: AuthStatus.error, failure: failure));
        }
    }
  }

  /// Confirm phone OTP on mobile.
  Future<void> confirmPhoneCodeMobile({
    required String verificationId,
    required String smsCode,
  }) async {
    emit(
      state.copyWith(
        status: AuthStatus.loading,
        clearFailure: true,
        clearPendingGoogleUser: true,
      ),
    );

    final result = await _repository.confirmPhoneCodeMobile(
      verificationId: verificationId,
      smsCode: smsCode,
    );
    switch (result) {
      case Success(:final data):
        if (data.status == UserStatus.banned ||
            data.status == UserStatus.suspended) {
          emit(AuthState(
            status: AuthStatus.blocked,
            user: data,
            failure: UserBlockedFailure(),
          ));
          return;
        }
        if (!kIsWeb) CrashlyticsService.setUserId(data.id);
        AnalyticsService.setUserId(data.id);
        AnalyticsService.setUserRole(data.type.toString().split('.').last);
        if (data.name.trim().isEmpty) {
          AnalyticsService.logSignUp(method: 'phone');
        }
        emit(state.copyWith(status: AuthStatus.authenticated, user: data));
        _subscribeToUser(data.id);
      case Err(:final failure):
        if (failure is UserBlockedFailure) {
          emit(AuthState(status: AuthStatus.blocked, failure: failure));
        } else {
          emit(state.copyWith(status: AuthStatus.error, failure: failure));
        }
    }
  }

  /// Update full profile (name, email, phone, profileImage) in Firestore and local state.
  Future<bool> updateProfile({
    required String name,
    required String email,
    required String phone,
    String? profileImage,
  }) async {
    final currentUser = state.user;
    if (currentUser == null) return false;

    final updates = <String, dynamic>{
      'name': name.trim(),
      'email': email.trim(),
      'phone': phone.trim(),
      'profileImage': ?profileImage,
    };

    final result = await _repository.updateUserProfile(currentUser.id, updates);
    switch (result) {
      case Success():
        final updatedUser = currentUser.copyWith(
          name: name.trim(),
          email: email.trim(),
          phone: phone.trim(),
          profileImage: profileImage ?? currentUser.profileImage,
        );
        emit(state.copyWith(user: updatedUser));
        return true;
      case Err():
        return false;
    }
  }

  /// Update user's display name (after phone signup).
  Future<void> updateUserName(String name) async {
    final currentUser = state.user;
    if (currentUser == null) return;

    final result = await _repository.updateUserName(currentUser.id, name);
    switch (result) {
      case Success():
        final updatedUser = currentUser.copyWith(name: name.trim());
        emit(state.copyWith(user: updatedUser));
      case Err():
        break; // Silent fail for name update
    }
  }

  /// Update user's phone number.
  Future<void> updateUserPhone(String phone) async {
    final currentUser = state.user;
    if (currentUser == null) return;

    final result = await _repository.updateUserPhone(currentUser.id, phone);
    switch (result) {
      case Success():
        final updatedUser = currentUser.copyWith(phone: phone.trim());
        emit(state.copyWith(user: updatedUser));
      case Err():
        break;
    }
  }

  // ── Saved Addresses ────────────────────────────────────────────────────────

  Future<void> addSavedAddress(SavedAddress address) async {
    final currentUser = state.user;
    if (currentUser == null) return;

    final updatedAddresses = List<SavedAddress>.from(currentUser.savedAddresses);
    final index = updatedAddresses.indexWhere((e) => e.id == address.id);
    if (index != -1) {
      updatedAddresses[index] = address;
    } else {
      updatedAddresses.add(address);
    }

    final result = await _repository.updateUserProfile(currentUser.id, {
      'savedAddresses': updatedAddresses.map((e) => e.toMap()).toList(),
    });

    switch (result) {
      case Success():
        final updatedUser = currentUser.copyWith(
          savedAddresses: updatedAddresses,
        );
        emit(state.copyWith(user: updatedUser));
      case Err():
        break; // Silent fail
    }
  }

  Future<void> removeSavedAddress(String addressId) async {
    final currentUser = state.user;
    if (currentUser == null) return;

    final updatedAddresses = currentUser.savedAddresses
        .where((addr) => addr.id != addressId)
        .toList();

    final result = await _repository.updateUserProfile(currentUser.id, {
      'savedAddresses': updatedAddresses.map((e) => e.toMap()).toList(),
    });

    switch (result) {
      case Success():
        final updatedUser = currentUser.copyWith(
          savedAddresses: updatedAddresses,
        );
        emit(state.copyWith(user: updatedUser));
      case Err():
        break; // Silent fail
    }
  }

  // ── Email Verification ─────────────────────────────────────────────────────

  /// Send email verification link to current user.
  Future<bool> sendEmailVerification() async {
    final result = await _repository.sendEmailVerification();
    switch (result) {
      case Success():
        return true;
      case Err(:final failure):
        emit(state.copyWith(status: AuthStatus.error, failure: failure));
        return false;
    }
  }

  /// Check if current user's email is verified.
  Future<bool> checkEmailVerified() async {
    final result = await _repository.isEmailVerified();
    switch (result) {
      case Success(:final data):
        return data;
      case Err():
        return false;
    }
  }

  /// Change password — re-authenticates with [currentPassword] then sets [newPassword].
  /// Returns `null` on success, or an error message string on failure.
  Future<String?> changePassword({
    required String currentPassword,
    required String newPassword,
  }) async {
    final result = await _repository.changePassword(
      currentPassword: currentPassword,
      newPassword: newPassword,
    );
    switch (result) {
      case Success():
        return null;
      case Err(:final failure):
        // Extract a user-friendly message from FirebaseAuthException
        final msg = failure.message;
        if (msg.contains('wrong-password') ||
            msg.contains('invalid-credential')) {
          return 'Current password is incorrect.';
        }
        if (msg.contains('too-many-requests')) {
          return 'Too many attempts. Please try again later.';
        }
        return 'Failed to change password. Please try again.';
    }
  }

  /// Permanently delete the current account from Firebase Auth and Firestore.
  /// Returns `null` on success, or an error message on failure.
  Future<String?> deleteAccount() async {
    final userId = state.user?.id;
    emit(state.copyWith(status: AuthStatus.loading, clearFailure: true));

    // Clear notifications and remove FCM token from Firestore for deleted account
    if (!kIsWeb && userId != null) {
      try {
        final fcmService = FcmService();
        await fcmService.removeTokenFromFirestore(userId);
        await fcmService.unsubscribeFromAllTopics();
        await fcmService.removeToken(userId);
        await fcmService.clearAllNotifications();
      } catch (e) {
        debugPrint('Error during notification cleanup: $e');
      }
    }

    final result = await _repository.deleteAccount();
    switch (result) {
      case Success():
        if (!kIsWeb) CrashlyticsService.setUserId('');
        AnalyticsService.setUserId(null);
        emit(const AuthState(status: AuthStatus.unauthenticated));
        return null;
      case Err(:final failure):
        emit(state.copyWith(status: AuthStatus.error, failure: failure));
        return failure.message;
    }
  }

  /// Send a password-reset email. Returns `true` on success.
  Future<bool> forgotPassword(String email) async {
    emit(state.copyWith(status: AuthStatus.loading, clearFailure: true));
    final result = await _repository.forgotPassword(email);
    switch (result) {
      case Success():
        emit(state.copyWith(status: AuthStatus.initial, clearFailure: true));
        return true;
      case Err(:final failure):
        emit(state.copyWith(status: AuthStatus.error, failure: failure));
        return false;
    }
  }

  @override
  Future<void> close() {
    _userSubscription?.cancel();
    return super.close();
  }
}
