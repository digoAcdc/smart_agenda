import 'package:equatable/equatable.dart';

class AgendaGroup extends Equatable {
  const AgendaGroup({
    required this.id,
    this.familyId,
    required this.name,
    this.colorHex,
    this.iconCode,
    required this.createdAt,
    required this.updatedAt,
    this.deletedAt,
  });

  final String id;

  /// Familia dona da categoria (nulo = pessoal).
  final String? familyId;
  final String name;
  final String? colorHex;
  final int? iconCode;
  final DateTime createdAt;
  final DateTime updatedAt;
  final DateTime? deletedAt;

  AgendaGroup copyWith({
    String? id,
    String? familyId,
    String? name,
    String? colorHex,
    int? iconCode,
    DateTime? createdAt,
    DateTime? updatedAt,
    DateTime? deletedAt,
  }) {
    return AgendaGroup(
      id: id ?? this.id,
      familyId: familyId ?? this.familyId,
      name: name ?? this.name,
      colorHex: colorHex ?? this.colorHex,
      iconCode: iconCode ?? this.iconCode,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      deletedAt: deletedAt ?? this.deletedAt,
    );
  }

  @override
  List<Object?> get props => [
    id,
    familyId,
    name,
    colorHex,
    iconCode,
    createdAt,
    updatedAt,
    deletedAt,
  ];
}
