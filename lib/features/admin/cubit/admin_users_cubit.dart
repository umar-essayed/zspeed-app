import 'package:flutter/foundation.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:z_speed/core/errors/failures.dart';
import 'package:z_speed/core/permissions/permission_service.dart';
import 'package:z_speed/features/admin/cubit/admin_users_state.dart';
import 'package:z_speed/features/admin/datasource/audit_log_datasource.dart';
import 'package:z_speed/features/admin/model/admin_models.dart';
import 'package:z_speed/features/admin/repository/admin_repository.dart';
import 'package:z_speed/features/admin/datasource/settings_datasource.dart';
import 'package:injectable/injectable.dart' hide Order;
import 'package:cloud_firestore/cloud_firestore.dart';

@injectable
class AdminUsersCubit extends Cubit<AdminUsersState> {
  final AdminRepository _repository;
  final AuditLogDatasource _auditLog;
  Object? _lastDocument;

  /// The full AppUser of the currently logged-in admin — used for permission
  /// checks and audit log authorship.
  AppUser? currentUser;

  UserType get currentUserType => currentUser?.type ?? UserType.admin;

  AdminUsersCubit({
    required this._repository,
    required AuditLogDatasource auditLogDatasource,
    this.currentUser,
  }) : _auditLog = auditLogDatasource,
       super(const AdminUsersState());

  Future<void> loadUsers({bool isLoadMore = false}) async {
    if (isLoadMore) {
      if (!state.hasMore || state.isLoadingMore) return;
      emit(state.copyWith(isLoadingMore: true));
    } else {
      emit(state.copyWith(isBusy: true, hasError: false, failure: null));
      _lastDocument = null;
    }

    try {
      final result = await _repository.getUsers(
        type: state.typeFilter,
        status: state.statusFilter,
        startAfter: _lastDocument,
        limit: 20,
      );

      if (result.isSuccess) {
        final newUsers = result.data!.$1;
        _lastDocument = result.data!.$2;

        final allUsers = isLoadMore ? [...state.users, ...newUsers] : newUsers;
        final hasMore = newUsers.length >= 20;

        emit(
          state.copyWith(
            isBusy: false,
            isLoadingMore: false,
            users: allUsers,
            hasMore: hasMore,
            filteredAdminUsers: _filterUsers(allUsers, state.searchQuery),
          ),
        );
      } else {
        emit(
          state.copyWith(
            isBusy: false,
            isLoadingMore: false,
            hasError: true,
            failure: result.error,
          ),
        );
      }
    } catch (e) {
      emit(
        state.copyWith(
          isBusy: false,
          isLoadingMore: false,
          hasError: true,
          failure: ServerFailure(e.toString()),
        ),
      );
    }
  }

  void setSearchQuery(String query) {
    emit(
      state.copyWith(
        searchQuery: query,
        filteredAdminUsers: _filterUsers(state.users, query),
      ),
    );
  }

  void setTypeFilter(UserType? type) {
    emit(state.copyWith(typeFilter: type));
    loadUsers();
  }

  void setStatusFilter(UserStatus? status) {
    emit(state.copyWith(statusFilter: status));
    loadUsers();
  }

  Future<void> updateStatus(
    String id,
    UserStatus status, {
    bool blacklist = false,
    String? reason,
  }) async {
    final target = state.users.where((u) => u.id == id).firstOrNull;
    if (target == null) return;
    if (!PermissionService.canEditUser(currentUserType, target.type)) {
      emit(
        state.copyWith(
          actionError: 'You do not have permission to edit this user.',
        ),
      );
      return;
    }
    final result = await _repository.updateUserStatus(id, status);
    if (result.isSuccess) {
      if (blacklist || status == UserStatus.banned) {
        try {
          final settingsDs = SettingsDatasource();
          if (target.phone != null && target.phone!.isNotEmpty) {
            await settingsDs.addToBlacklist(
              type: 'phone',
              value: target.phone!,
              reason: reason ?? 'User banned by admin',
            );
          }
          if (target.email.isNotEmpty) {
            await settingsDs.addToBlacklist(
              type: 'email',
              value: target.email,
              reason: reason ?? 'User banned by admin',
            );
          }
          await settingsDs.addToBlacklist(
            type: 'uid',
            value: target.id,
            reason: reason ?? 'User banned by admin',
          );
        } catch (e) {
          debugPrint('Error auto-blacklisting user: $e');
        }
      }
      final updatedUsers = state.users.map((u) {
        if (u.id == id) return u.copyWith(status: status);
        return u;
      }).toList();
      emit(
        state.copyWith(
          users: updatedUsers,
          filteredAdminUsers: _filterUsers(updatedUsers, state.searchQuery),
        ),
      );
      _writeAuditLog(
        action: AuditAction.updateStatus,
        target: target,
        extra: {'newStatus': status.name, 'oldStatus': target.status.name},
      );
    }
  }

  Future<void> updateRole(String id, UserType role) async {
    final target = state.users.where((u) => u.id == id).firstOrNull;
    if (target == null) return;
    if (!PermissionService.canEditUser(currentUserType, target.type)) {
      emit(
        state.copyWith(
          actionError:
              'You do not have permission to change this user\'s role.',
        ),
      );
      return;
    }
    final result = await _repository.updateUserType(id, role);
    if (result.isSuccess) {
      final updatedUsers = state.users.map((u) {
        if (u.id == id) return u.copyWith(type: role);
        return u;
      }).toList();
      emit(
        state.copyWith(
          users: updatedUsers,
          filteredAdminUsers: _filterUsers(updatedUsers, state.searchQuery),
        ),
      );
      _writeAuditLog(
        action: AuditAction.updateRole,
        target: target,
        extra: {'newRole': role.name, 'oldRole': target.type.name},
      );
    }
  }

  Future<void> deleteUser(String id) async {
    final target = state.users.where((u) => u.id == id).firstOrNull;
    if (target == null) return;
    if (!PermissionService.canDeleteUser(currentUserType, target.type)) {
      emit(
        state.copyWith(
          actionError: 'You do not have permission to delete this user.',
        ),
      );
      return;
    }
    final result = await _repository.deleteUser(id);
    if (result.isSuccess) {
      final updatedUsers = state.users.where((u) => u.id != id).toList();
      emit(
        state.copyWith(
          users: updatedUsers,
          filteredAdminUsers: _filterUsers(updatedUsers, state.searchQuery),
        ),
      );
      _writeAuditLog(action: AuditAction.deleteUser, target: target);
    }
  }

  Future<void> updateDriverCapabilities(
    String id, {
    bool? canTransport,
    bool? canDeliver,
  }) async {
    try {
      final updates = <String, dynamic>{};
      if (canTransport != null) updates['canTransport'] = canTransport;
      if (canDeliver != null) updates['canDeliver'] = canDeliver;

      await FirebaseFirestore.instance
          .collection('users')
          .doc(id)
          .update(updates);

      final updatedUsers = state.users.map((u) {
        if (u.id == id) {
          return u.copyWith(
            canTransport: canTransport ?? u.canTransport,
            canDeliver: canDeliver ?? u.canDeliver,
          );
        }
        return u;
      }).toList();

      emit(
        state.copyWith(
          users: updatedUsers,
          filteredAdminUsers: _filterUsers(updatedUsers, state.searchQuery),
        ),
      );
    } catch (e) {
      emit(state.copyWith(actionError: 'Failed to update capabilities: $e'));
    }
  }

  Future<void> adjustDriverWallet(
    String driverId,
    double amount,
    String description,
  ) async {
    try {
      final docRef = FirebaseFirestore.instance
          .collection('driverProfiles')
          .doc(driverId);

      await FirebaseFirestore.instance.runTransaction((transaction) async {
        final snapshot = await transaction.get(docRef);
        if (!snapshot.exists) throw Exception("Driver profile not found");

        final currentBalance =
            (snapshot.data()?['walletBalance'] as num?)?.toDouble() ?? 0.0;
        final newBalance = currentBalance + amount;

        transaction.update(docRef, {
          'walletBalance': newBalance,
          'updatedAt': FieldValue.serverTimestamp(),
        });

        final txId = FirebaseFirestore.instance
            .collection('driverWalletTransactions')
            .doc()
            .id;
        final txRef = FirebaseFirestore.instance
            .collection('driverWalletTransactions')
            .doc(txId);
        transaction.set(txRef, {
          'id': txId,
          'driverId': driverId,
          'orderId': '',
          'type': amount >= 0
              ? WalletTransactionType.credit.key
              : WalletTransactionType.debit.key,
          'amount': amount.abs(),
          'description': description,
          'status': WalletTransactionStatus.confirmed.key,
          'paymentMethod': PayoutMethod.instapay.key,
          'createdAt': FieldValue.serverTimestamp(),
          'updatedAt': FieldValue.serverTimestamp(),
        });
      });
    } catch (e) {
      emit(state.copyWith(actionError: 'Failed to adjust wallet: $e'));
    }
  }

  void _writeAuditLog({
    required AuditAction action,
    required AppUser target,
    Map<String, dynamic> extra = const {},
  }) {
    final actor = currentUser;
    if (actor == null) return;

    final extraStr = extra.isEmpty
        ? ''
        : ' | ${extra.entries.map((e) => '${e.key}: ${e.value}').join(', ')}';

    debugPrint('');
    debugPrint('╔══ AUDIT LOG ══════════════════════════════════════');
    debugPrint('║  action : ${action.name}');
    debugPrint(
      '║  actor  : ${actor.name} (${actor.email}) [${actor.type.name}]',
    );
    debugPrint(
      '║  target : ${target.name} (${target.email}) [${target.type.name}]$extraStr',
    );
    debugPrint('╚════════════════════════════════════════════════════');
    debugPrint('');

    _auditLog
        .log(
          actor: actor,
          action: action,
          targetUserId: target.id,
          targetUserName: target.name,
          targetUserEmail: target.email,
          targetUserRole: target.type,
          extra: extra,
        )
        .ignore();
  }

  List<AdminUser> _filterUsers(List<AppUser> users, String query) {
    final lowerQuery = query.toLowerCase();
    return users
        .where(
          (u) =>
              u.name.toLowerCase().contains(lowerQuery) ||
              u.email.toLowerCase().contains(lowerQuery),
        )
        .map(
          (u) => AdminUser(
            id: u.id,
            name: u.name,
            email: u.email,
            role: u.type,
            status: u.status,
            phone: u.phone ?? 'N/A',
            joinDate:
                '${u.createdAt.year}-${u.createdAt.month}-${u.createdAt.day}',
          ),
        )
        .toList();
  }
}
