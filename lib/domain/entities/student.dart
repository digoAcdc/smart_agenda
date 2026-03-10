import 'package:equatable/equatable.dart';

/// Aluno cadastrado em um grupo.
class Student extends Equatable {
  const Student({
    required this.id,
    required this.groupId,
    required this.name,
    this.email,
    this.phone,
    this.guardianName,
    this.guardianEmail,
    this.guardianPhone,
    required this.createdAt,
    required this.updatedAt,
  });

  final String id;
  final String groupId;
  final String name;
  final String? email;
  final String? phone;
  final String? guardianName;
  final String? guardianEmail;
  final String? guardianPhone;
  final DateTime createdAt;
  final DateTime updatedAt;

  Student copyWith({
    String? id,
    String? groupId,
    String? name,
    String? email,
    String? phone,
    String? guardianName,
    String? guardianEmail,
    String? guardianPhone,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return Student(
      id: id ?? this.id,
      groupId: groupId ?? this.groupId,
      name: name ?? this.name,
      email: email ?? this.email,
      phone: phone ?? this.phone,
      guardianName: guardianName ?? this.guardianName,
      guardianEmail: guardianEmail ?? this.guardianEmail,
      guardianPhone: guardianPhone ?? this.guardianPhone,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  @override
  List<Object?> get props => [
        id,
        groupId,
        name,
        email,
        phone,
        guardianName,
        guardianEmail,
        guardianPhone,
        createdAt,
        updatedAt,
      ];
}
