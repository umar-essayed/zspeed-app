import 'package:equatable/equatable.dart';
import 'package:z_speed/core/errors/failures.dart';
import 'package:z_speed/features/auth/model/user_model.dart';

enum AuthStatus {
  initial,
  loading,
  authenticated,
  unauthenticated,
  guest,
  blocked,
  error,
}

class AuthState extends Equatable {
  final AuthStatus status;
  final AppUser? user;
  final Failure? failure;
  final dynamic confirmationResult; // For web phone auth
  final AppUser?
      pendingGoogleUser; // New Google user waiting for role selection

  const AuthState({
    this.status = AuthStatus.initial,
    this.user,
    this.failure,
    this.confirmationResult,
    this.pendingGoogleUser,
  });

  AuthState copyWith({
    AuthStatus? status,
    AppUser? user,
    Failure? failure,
    dynamic confirmationResult,
    bool clearFailure = false,
    AppUser? pendingGoogleUser,
    bool clearPendingGoogleUser = false,
    bool clearConfirmationResult = false,
  }) {
    return AuthState(
      status: status ?? this.status,
      user: user ?? this.user,
      failure: clearFailure ? null : (failure ?? this.failure),
      confirmationResult: clearConfirmationResult
          ? null
          : (confirmationResult ?? this.confirmationResult),
      pendingGoogleUser: clearPendingGoogleUser
          ? null
          : (pendingGoogleUser ?? this.pendingGoogleUser),
    );
  }

  bool get isAuthenticated =>
      status == AuthStatus.authenticated && user != null && !isBlocked;
  bool get isLoading => status == AuthStatus.loading;
  bool get hasError => status == AuthStatus.error && failure != null;
  bool get isBlocked =>
      status == AuthStatus.blocked ||
      (user != null &&
          (user!.status == UserStatus.banned ||
              user!.status == UserStatus.suspended));
  bool get needsRoleSelection =>
      status == AuthStatus.unauthenticated && pendingGoogleUser != null;

  /// Whether the current user needs to provide their name (phone signup).
  bool get needsName => user != null && user!.name.trim().isEmpty;

  /// Whether the current customer needs to verify their phone.
  bool get customerNeedsPhone =>
      user != null &&
      user!.type == UserType.customer &&
      (user!.phone == null || user!.phone!.trim().isEmpty);

  bool get isGuest =>
      status == AuthStatus.guest || status == AuthStatus.unauthenticated;

  @override
  List<Object?> get props =>
      [status, user, failure, confirmationResult, pendingGoogleUser];
}
