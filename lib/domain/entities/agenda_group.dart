import 'package:equatable/equatable.dart';

class AgendaGroup extends Equatable {
  const AgendaGroup({
    required this.id,
    required this.name,
    this.colorHex,
    this.iconCode,
    required this.createdAt,
    required this.updatedAt,
    this.deletedAt,
  });

  final String id;
  final String name;
  final String? colorHex;
  final int? iconCode;
  final DateTime createdAt;
  final DateTime updatedAt;
  final DateTime? deletedAt;

  AgendaGroup copyWith({
    String? id,
    String? name,
    String? colorHex,
    int? iconCode,
    DateTime? createdAt,
    DateTime? updatedAt,
    DateTime? deletedAt,
  }) {
    return AgendaGroup(
      id: id ?? this.id,
      name: name ?? this.name,
      colorHex: colorHex ?? this.colorHex,
      iconCode: iconCode ?? this.iconCode,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      deletedAt: deletedAt ?? this.deletedAt,
    );
  }

  @override
  List<Object?> get props =>
      [id, name, colorHex, iconCode, createdAt, updatedAt, deletedAt];
}
