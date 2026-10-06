import 'package:z_speed/core/errors/failures.dart';

sealed class Result<T> {
  Result();

  bool get isSuccess => this is Success<T>;
  bool get isError => this is Err<T>;

  T? get data => this is Success<T> ? (this as Success<T>).data : null;
  Failure? get failure => this is Err<T> ? (this as Err<T>).failure : null;
  Failure? get error => failure;
}

final class Success<T> extends Result<T> {
  @override
  final T data;

  Success(this.data);
}

final class Err<T> extends Result<T> {
  @override
  final Failure failure;

  Err(this.failure);
}
