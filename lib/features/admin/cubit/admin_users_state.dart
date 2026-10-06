import 'package:equatable/equatable.dart';
import 'package:z_speed/core/errors/failures.dart';
import 'package:z_speed/features/admin/model/admin_models.dart';

class AdminUsersState extends Equatable {
  final bool isBusy;
  final bool hasError;
  final Failure? failure;
  final List<AppUser> users;
  final List<AdminUser> filteredAdminUsers;
  final String searchQuery;
  final UserType? typeFilter;
  final UserStatus? statusFilter;
  final bool hasMore;
  final bool isLoadingMore;
  final String? actionError;

  const AdminUsersState({
    this.isBusy = false,
    this.hasError = false,
    this.failure,
    this.users = const [],
    this.filteredAdminUsers = const [],
    this.searchQuery = '',
    this.typeFilter,
    this.statusFilter,
    this.hasMore = false,
    this.isLoadingMore = false,
    this.actionError,
  });

  AdminUsersState copyWith({
    bool? isBusy,
    bool? hasError,
    Failure? failure,
    List<AppUser>? users,
    List<AdminUser>? filteredAdminUsers,
    String? searchQuery,
    UserType? typeFilter,
    UserStatus? statusFilter,
    bool? hasMore,
    bool? isLoadingMore,
    String? actionError,
  }) {
    return AdminUsersState(
      isBusy: isBusy ?? this.isBusy,
      hasError: hasError ?? this.hasError,
      failure: failure ?? this.failure,
      users: users ?? this.users,
      filteredAdminUsers: filteredAdminUsers ?? this.filteredAdminUsers,
      searchQuery: searchQuery ?? this.searchQuery,
      typeFilter: typeFilter ?? this.typeFilter,
      statusFilter: statusFilter ?? this.statusFilter,
      hasMore: hasMore ?? this.hasMore,
      isLoadingMore: isLoadingMore ?? this.isLoadingMore,
      actionError: actionError,
    );
  }

  @override
  List<Object?> get props => [
        isBusy,
        hasError,
        failure,
        users,
        filteredAdminUsers,
        searchQuery,
        typeFilter,
        statusFilter,
        hasMore,
        isLoadingMore,
        actionError,
      ];
}
