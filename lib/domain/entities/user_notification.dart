import 'package:equatable/equatable.dart';

class UserNotification extends Equatable {
  const UserNotification({
    required this.id,
    required this.type,
    required this.referenceDate,
    required this.title,
    required this.body,
    required this.createdAt,
    this.readAt,
  });

  final String id;
  final String type;
  final DateTime referenceDate;
  final String title;
  final String body;
  final DateTime createdAt;
  final DateTime? readAt;

  bool get isRead => readAt != null;

  @override
  List<Object?> get props => [id, type, referenceDate, title, body, createdAt, readAt];
}
