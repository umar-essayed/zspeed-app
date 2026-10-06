import 'package:equatable/equatable.dart';
import 'package:z_speed/core/errors/failures.dart';
import 'package:z_speed/core/enums/user_enums.dart';
import 'package:z_speed/features/admin/model/application_model.dart';

class AdminApplicationState extends Equatable {
  final bool isBusy;
  final bool isActioning;
  final bool hasError;
  final Failure? failure;
  final List<Application> applications;
  final Application? selectedApplication;
  final ApplicationType? typeFilter;

  const AdminApplicationState({
    this.isBusy = false,
    this.isActioning = false,
    this.hasError = false,
    this.failure,
    this.applications = const [],
    this.selectedApplication,
    this.typeFilter,
  });

  // Getters for filtered lists
  List<Application> get allFiltered => typeFilter == null
      ? applications
      : applications.where((a) => a.applicationType == typeFilter).toList();

  List<Application> get pending =>
      allFiltered.where((a) => a.status == ApplicationStatus.pending).toList();

  List<Application> get approved =>
      allFiltered.where((a) => a.status == ApplicationStatus.approved).toList();

  List<Application> get rejected =>
      allFiltered.where((a) => a.status == ApplicationStatus.rejected).toList();

  AdminApplicationState copyWith({
    bool? isBusy,
    bool? isActioning,
    bool? hasError,
    Failure? failure,
    List<Application>? applications,
    Application? selectedApplication,
    ApplicationType? typeFilter,
    bool clearTypeFilter = false,
    bool clearSelectedApplication = false,
  }) {
    return AdminApplicationState(
      isBusy: isBusy ?? this.isBusy,
      isActioning: isActioning ?? this.isActioning,
      hasError: hasError ?? this.hasError,
      failure: failure ?? this.failure,
      applications: applications ?? this.applications,
      selectedApplication: clearSelectedApplication
          ? null
          : (selectedApplication ?? this.selectedApplication),
      typeFilter: clearTypeFilter ? null : (typeFilter ?? this.typeFilter),
    );
  }

  @override
  List<Object?> get props => [
        isBusy,
        isActioning,
        hasError,
        failure,
        applications,
        selectedApplication,
        typeFilter,
      ];
}
