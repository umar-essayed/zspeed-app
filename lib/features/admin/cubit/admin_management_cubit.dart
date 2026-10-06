import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:injectable/injectable.dart' hide Order;
import 'package:z_speed/core/errors/failures.dart';
import 'package:z_speed/features/admin/cubit/admin_management_state.dart';
import 'package:z_speed/features/admin/model/admin_models.dart';
import 'package:z_speed/features/admin/repository/admin_repository.dart';

@injectable
class AdminManagementCubit extends Cubit<AdminManagementState> {
  final AdminRepository _repository;
  List<AppUser> _allAdmins = [];

  AdminManagementCubit({required this._repository})
    : super(const AdminManagementState());

  /// Load admin-type users from Firestore.
  Future<void> loadAdmins() async {
    emit(state.copyWith(isBusy: true, hasError: false, failure: null));

    try {
      final result = await _repository.getUsers(type: UserType.admin);

      if (result.isSuccess) {
        final users = result.data!.$1;
        _allAdmins = users;
        emit(
          state.copyWith(
            isBusy: false,
            admins: _mapToAdminUsers(_allAdmins, state.searchQuery),
          ),
        );
      } else {
        emit(
          state.copyWith(isBusy: false, hasError: true, failure: result.error),
        );
      }
    } catch (e) {
      emit(
        state.copyWith(
          isBusy: false,
          hasError: true,
          failure: ServerFailure(e.toString()),
        ),
      );
    }
  }

  /// Create a new admin user (Firebase Auth + Firestore).
  Future<void> createAdmin({
    required String name,
    required String email,
    required String password,
  }) async {
    emit(
      state.copyWith(isCreating: true, createError: null, createSuccess: false),
    );

    try {
      final result = await _repository.createAdminUser(
        name: name,
        email: email,
        password: password,
        role: UserType.admin,
      );

      if (result.isSuccess) {
        emit(state.copyWith(isCreating: false, createSuccess: true));
        // Reload the admin list
        await loadAdmins();
      } else {
        emit(
          state.copyWith(
            isCreating: false,
            createError: result.error?.message ?? 'Failed to create admin',
          ),
        );
      }
    } catch (e) {
      emit(state.copyWith(isCreating: false, createError: e.toString()));
    }
  }

  void setSearchQuery(String query) {
    emit(
      state.copyWith(
        searchQuery: query,
        admins: _mapToAdminUsers(_allAdmins, query),
      ),
    );
  }

  List<AdminUser> _mapToAdminUsers(List<AppUser> users, String query) {
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
