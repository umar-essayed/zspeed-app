import 'package:equatable/equatable.dart';

class AdminReportsState extends Equatable {
  final bool isBusy;

  const AdminReportsState({
    this.isBusy = false,
  });

  AdminReportsState copyWith({
    bool? isBusy,
  }) {
    return AdminReportsState(
      isBusy: isBusy ?? this.isBusy,
    );
  }

  @override
  List<Object?> get props => [isBusy];
}
