import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:z_speed/core/errors/failures.dart';
import 'package:z_speed/features/admin/cubit/admin_application_state.dart';
import 'package:z_speed/features/admin/model/application_model.dart';
import 'package:z_speed/features/admin/repository/application_repository.dart';

class AdminApplicationCubit extends Cubit<AdminApplicationState> {
  final ApplicationRepository _repository;

  AdminApplicationCubit({required this._repository})
    : super(const AdminApplicationState());

  Future<void> loadApplications() async {
    emit(state.copyWith(isBusy: true, hasError: false, failure: null));
    try {
      final result = await _repository.getApplications();
      if (result.isSuccess) {
        emit(state.copyWith(isBusy: false, applications: result.data ?? []));
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

  Future<void> loadApplicationDetail(String id) async {
    emit(state.copyWith(isBusy: true, hasError: false, failure: null));
    try {
      final result = await _repository.getApplicationById(id);
      if (result.isSuccess && result.data != null) {
        emit(state.copyWith(isBusy: false, selectedApplication: result.data));
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

  void setTypeFilter(ApplicationType? type) {
    emit(state.copyWith(typeFilter: type, clearTypeFilter: type == null));
  }

  void selectApplication(Application app) {
    emit(state.copyWith(selectedApplication: app));
  }

  void clearSelectedApplication() {
    emit(state.copyWith(clearSelectedApplication: true));
  }

  Future<void> approveApplication(String id, String adminId) async {
    emit(state.copyWith(isActioning: true, hasError: false, failure: null));
    try {
      final result = await _repository.approveApplication(
        applicationId: id,
        reviewerId: adminId,
      );
      if (result.isSuccess) {
        await loadApplications();
        if (state.selectedApplication?.id == id) {
          final updated = state.applications.firstWhere((a) => a.id == id);
          emit(
            state.copyWith(selectedApplication: updated, isActioning: false),
          );
        } else {
          emit(state.copyWith(isActioning: false));
        }
      } else {
        emit(
          state.copyWith(
            isActioning: false,
            hasError: true,
            failure: result.error,
          ),
        );
      }
    } catch (e) {
      emit(
        state.copyWith(
          isActioning: false,
          hasError: true,
          failure: ServerFailure(e.toString()),
        ),
      );
    }
  }

  Future<void> rejectApplication(
    String id,
    String adminId,
    String reason,
  ) async {
    emit(state.copyWith(isActioning: true, hasError: false, failure: null));
    try {
      final result = await _repository.rejectApplication(
        applicationId: id,
        reviewerId: adminId,
        reason: reason,
      );
      if (result.isSuccess) {
        await loadApplications();
        if (state.selectedApplication?.id == id) {
          final updated = state.applications.firstWhere((a) => a.id == id);
          emit(
            state.copyWith(selectedApplication: updated, isActioning: false),
          );
        } else {
          emit(state.copyWith(isActioning: false));
        }
      } else {
        emit(
          state.copyWith(
            isActioning: false,
            hasError: true,
            failure: result.error,
          ),
        );
      }
    } catch (e) {
      emit(
        state.copyWith(
          isActioning: false,
          hasError: true,
          failure: ServerFailure(e.toString()),
        ),
      );
    }
  }

  // Section approval/rejection mock logic or repo logic if available.
  // Assuming repo has them, or we modify locally if repo doesn't
  Future<bool> approveSection(
    String id,
    String sectionKey,
    String adminId,
  ) async {
    emit(state.copyWith(isActioning: true));
    try {
      final result = await _repository.approveSection(
        applicationId: id,
        sectionKey: sectionKey,
        reviewerId: adminId,
      );

      if (result.isSuccess) {
        var app = state.applications.firstWhere((a) => a.id == id);
        final newStatuses = Map<String, String>.from(app.sectionStatuses);
        newStatuses[sectionKey] = 'approved';
        app = app.copyWith(sectionStatuses: newStatuses);

        if (app.allSectionsApproved && !app.isApproved) {
          final approveResult = await _repository.approveApplication(
            applicationId: id,
            reviewerId: adminId,
          );
          if (approveResult.isSuccess) {
            app = app.copyWith(status: ReviewStatus.approved);
          }
        }

        final updatedList = state.applications
            .map((a) => a.id == id ? app : a)
            .toList();
        emit(
          state.copyWith(
            applications: updatedList,
            selectedApplication: app,
            isActioning: false,
          ),
        );
        return true;
      } else {
        emit(
          state.copyWith(
            isActioning: false,
            hasError: true,
            failure: result.error,
          ),
        );
        return false;
      }
    } catch (e) {
      emit(
        state.copyWith(
          isActioning: false,
          hasError: true,
          failure: ServerFailure(e.toString()),
        ),
      );
      return false;
    }
  }

  Future<bool> rejectSection(
    String id,
    String sectionKey,
    String adminId,
    String reason,
  ) async {
    emit(state.copyWith(isActioning: true));
    try {
      final result = await _repository.rejectSection(
        applicationId: id,
        sectionKey: sectionKey,
        reviewerId: adminId,
        reason: reason,
      );

      if (result.isSuccess) {
        var app = state.applications.firstWhere((a) => a.id == id);
        final newStatuses = Map<String, String>.from(app.sectionStatuses);
        newStatuses[sectionKey] = 'rejected';
        final newReasons = Map<String, String>.from(app.sectionReasons);
        newReasons[sectionKey] = reason;
        app = app.copyWith(
          sectionStatuses: newStatuses,
          sectionReasons: newReasons,
        );
        final updatedList = state.applications
            .map((a) => a.id == id ? app : a)
            .toList();
        emit(
          state.copyWith(
            applications: updatedList,
            selectedApplication: app,
            isActioning: false,
          ),
        );
        return true;
      } else {
        emit(
          state.copyWith(
            isActioning: false,
            hasError: true,
            failure: result.error,
          ),
        );
        return false;
      }
    } catch (e) {
      emit(
        state.copyWith(
          isActioning: false,
          hasError: true,
          failure: ServerFailure(e.toString()),
        ),
      );
      return false;
    }
  }
}
