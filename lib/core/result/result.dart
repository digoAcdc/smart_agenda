import 'package:equatable/equatable.dart';

class Result<T> extends Equatable {
  const Result._({
    required this.isSuccess,
    this.data,
    this.errorMessage,
  });

  final bool isSuccess;
  final T? data;
  final String? errorMessage;

  factory Result.success(T data) {
    return Result._(isSuccess: true, data: data);
  }

  factory Result.failure(String message) {
    return Result._(isSuccess: false, errorMessage: message);
  }

  @override
  List<Object?> get props => [isSuccess, data, errorMessage];
}
