import 'package:equatable/equatable.dart';
import 'package:z_speed/core/errors/failures.dart';
import 'package:z_speed/features/admin/model/admin_models.dart';

class AdminManagementState extends Equatable {
  final bool isBusy;
  final bool hasError;
  final Failure? failure;
  final List<AdminUser> admins;
  final String searchQuery;
  final bool isCreating;
  final String? createError;
  final bool createSuccess;

  const AdminManagementState({
    this.isBusy = false,
    this.hasError = false,
    this.failure,
    this.admins = const [],
    this.searchQuery = '',
    this.isCreating = false,
    this.createError,
    this.createSuccess = false,
  });

  AdminManagementState copyWith({
    bool? isBusy,
    bool? hasError,
    Failure? failure,
    List<AdminUser>? admins,
    String? searchQuery,
    bool? isCreating,
    String? createError,
    bool? createSuccess,
  }) {
    return AdminManagementState(
      isBusy: isBusy ?? this.isBusy,
      hasError: hasError ?? this.hasError,
      failure: failure ?? this.failure,
      admins: admins ?? this.admins,
      searchQuery: searchQuery ?? this.searchQuery,
      isCreating: isCreating ?? this.isCreating,
      createError: createError,
      createSuccess: createSuccess ?? this.createSuccess,
    );
  }

  @override
  List<Object?> get props => [
        isBusy,
        hasError,
        failure,
        admins,
        searchQuery,
        isCreating,
        createError,
        createSuccess,
      ];
}
