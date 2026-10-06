import 'package:flutter/material.dart';
import 'package:z_speed/core/errors/failures.dart';

enum ViewState {
  initial,
  loading,
  success,
  error,
  empty,
}

class ViewStateBuilder extends StatelessWidget {
  final ViewState state;
  final Widget Function() onInitial;
  final Widget Function() onLoading;
  final Widget Function() onSuccess;
  final Widget Function(Failure? failure) onError;
  final Widget Function()? onEmpty;
  final Failure? failure;

  const ViewStateBuilder({
    super.key,
    required this.state,
    required this.onInitial,
    required this.onLoading,
    required this.onSuccess,
    required this.onError,
    this.onEmpty,
    this.failure,
  });

  @override
  Widget build(BuildContext context) {
    return switch (state) {
      ViewState.initial => onInitial(),
      ViewState.loading => onLoading(),
      ViewState.success => onSuccess(),
      ViewState.error => onError(failure),
      ViewState.empty => onEmpty?.call() ?? onSuccess(),
    };
  }
}
