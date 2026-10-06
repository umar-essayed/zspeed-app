import 'package:equatable/equatable.dart';
import 'package:image_picker/image_picker.dart';
import 'package:z_speed/core/errors/failures.dart';
import 'package:z_speed/core/widgets/view_state.dart';

class DriverApplicationState extends Equatable {
  final int currentStep;
  final ViewState state;
  final Failure? failure;
  final String uploadStageLabel;
  final Map<String, XFile> pickedDocuments;
  final Map<String, String> uploadStatuses;

  const DriverApplicationState({
    this.currentStep = 0,
    this.state = ViewState.initial,
    this.failure,
    this.uploadStageLabel = '',
    this.pickedDocuments = const {},
    this.uploadStatuses = const {},
  });

  bool get allDocumentsPicked {
    // There are 7 required documents
    return pickedDocuments.length >= 7;
  }

  DriverApplicationState copyWith({
    int? currentStep,
    ViewState? state,
    Failure? failure,
    String? uploadStageLabel,
    Map<String, XFile>? pickedDocuments,
    Map<String, String>? uploadStatuses,
    bool clearFailure = false,
  }) {
    return DriverApplicationState(
      currentStep: currentStep ?? this.currentStep,
      state: state ?? this.state,
      failure: clearFailure ? null : (failure ?? this.failure),
      uploadStageLabel: uploadStageLabel ?? this.uploadStageLabel,
      pickedDocuments: pickedDocuments ?? this.pickedDocuments,
      uploadStatuses: uploadStatuses ?? this.uploadStatuses,
    );
  }

  @override
  List<Object?> get props => [
        currentStep,
        state,
        failure,
        uploadStageLabel,
        pickedDocuments,
        uploadStatuses,
      ];
}
