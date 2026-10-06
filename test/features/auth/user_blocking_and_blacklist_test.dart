import 'package:flutter_test/flutter_test.dart';
import 'package:z_speed/core/errors/failures.dart';
import 'package:z_speed/core/utils/phone_helper.dart';
import 'package:z_speed/features/admin/datasource/settings_datasource.dart';
import 'package:z_speed/features/auth/cubit/auth_state.dart';
import 'package:z_speed/features/auth/model/user_model.dart';

void main() {
  group('User Blocking & Blacklist Tests', () {
    test('AuthState.isBlocked reflects banned or suspended status', () {
      final activeUser = AppUser(
        id: 'u1',
        name: 'John',
        email: 'john@example.com',
        type: UserType.customer,
        status: UserStatus.active,
      );

      final bannedUser = AppUser(
        id: 'u2',
        name: 'Bad Actor',
        email: 'bad@example.com',
        type: UserType.customer,
        status: UserStatus.banned,
      );

      final suspendedUser = AppUser(
        id: 'u3',
        name: 'Suspended User',
        email: 'suspended@example.com',
        type: UserType.driver,
        status: UserStatus.suspended,
      );

      // Active state
      final activeState = AuthState(
        status: AuthStatus.authenticated,
        user: activeUser,
      );
      expect(activeState.isBlocked, false);
      expect(activeState.isAuthenticated, true);

      // Banned state
      final bannedState = AuthState(
        status: AuthStatus.authenticated,
        user: bannedUser,
      );
      expect(bannedState.isBlocked, true);
      expect(bannedState.isAuthenticated, false);

      // Suspended state
      final suspendedState = AuthState(
        status: AuthStatus.authenticated,
        user: suspendedUser,
      );
      expect(suspendedState.isBlocked, true);
      expect(suspendedState.isAuthenticated, false);

      // Explicit blocked AuthStatus
      const blockedStatusState = AuthState(
        status: AuthStatus.blocked,
      );
      expect(blockedStatusState.isBlocked, true);
      expect(blockedStatusState.isAuthenticated, false);
    });

    test('UserBlockedFailure and RegistrationDisabledFailure create proper failures', () {
      final blockFail = UserBlockedFailure('Custom reason');
      expect(blockFail.message, 'Custom reason');
      expect(blockFail, isA<Failure>());

      final regFail = RegistrationDisabledFailure('Registration temporarily paused');
      expect(regFail.message, 'Registration temporarily paused');
      expect(regFail, isA<Failure>());
    });

    test('BlacklistItem serializes and deserializes correctly', () {
      final now = DateTime(2026, 9, 1, 10, 0);
      final item = BlacklistItem(
        id: 'phone_201012345678',
        type: 'phone',
        value: '+201012345678',
        reason: 'Fraudulent activity',
        createdAt: now,
      );

      final map = item.toMap();
      expect(map['type'], 'phone');
      expect(map['value'], '+201012345678');
      expect(map['reason'], 'Fraudulent activity');

      final fromMapItem = BlacklistItem.fromMap({
        'type': 'phone',
        'value': '+201012345678',
        'reason': 'Fraudulent activity',
      }, 'phone_201012345678');

      expect(fromMapItem.id, 'phone_201012345678');
      expect(fromMapItem.type, 'phone');
      expect(fromMapItem.value, '+201012345678');
      expect(fromMapItem.reason, 'Fraudulent activity');
    });

    test('Phone normalization matches Egyptian phone variants in blacklist', () {
      const input1 = '01012345678';
      const input2 = '+201012345678';
      const input3 = '00201012345678';

      final normalized1 = PhoneHelper.normalizePhone(input1);
      final normalized2 = PhoneHelper.normalizePhone(input2);
      final normalized3 = PhoneHelper.normalizePhone(input3);

      expect(normalized1, '+201012345678');
      expect(normalized2, '+201012345678');
      expect(normalized3, '+201012345678');
    });
  });
}
