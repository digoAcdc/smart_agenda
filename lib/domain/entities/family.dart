import 'package:equatable/equatable.dart';

import 'agenda_enums.dart';

enum FamilyRole { admin, editor, viewer }

extension FamilyRoleLabel on FamilyRole {
  String get label => switch (this) {
    FamilyRole.admin => 'Administrador',
    FamilyRole.editor => 'Editor',
    FamilyRole.viewer => 'Visualizador',
  };

  String get description => switch (this) {
    FamilyRole.admin => 'Gerencia a Família, pessoas, filhos e a agenda.',
    FamilyRole.editor => 'Cria, edita e conclui eventos e tarefas.',
    FamilyRole.viewer => 'Acompanha a agenda, sem editar.',
  };
}

FamilyRole familyRoleFromName(String? name) =>
    enumByName(FamilyRole.values, name, FamilyRole.viewer);

/// Situacao do usuario logado: plano e Familia (se participa de uma).
class FamilyContext extends Equatable {
  const FamilyContext({
    this.hasPro = false,
    this.familyId,
    this.familyName,
    this.myRole,
    this.isOwner = false,
    this.isActive = false,
    this.memberCount = 0,
    this.maxMembers = 5,
    this.pendingInvites = 0,
  });

  static const empty = FamilyContext();

  final bool hasPro;
  final String? familyId;
  final String? familyName;
  final FamilyRole? myRole;
  final bool isOwner;

  /// Familia ativa = dono com Pro ativo. Inativa fica somente leitura.
  final bool isActive;
  final int memberCount;
  final int maxMembers;
  final int pendingInvites;

  bool get hasFamily => familyId != null;
  bool get canCreateFamily => hasPro && !hasFamily;
  bool get canEditAgenda =>
      hasFamily &&
      isActive &&
      (myRole == FamilyRole.admin || myRole == FamilyRole.editor);
  bool get canAdmin => hasFamily && isActive && myRole == FamilyRole.admin;
  bool get isAdmin => myRole == FamilyRole.admin;
  int get availableSlots =>
      (maxMembers - memberCount - pendingInvites).clamp(0, maxMembers);

  factory FamilyContext.fromJson(Map<String, dynamic> json) {
    return FamilyContext(
      hasPro: json['has_pro'] as bool? ?? false,
      familyId: json['family_id'] as String?,
      familyName: json['family_name'] as String?,
      myRole: json['my_role'] == null
          ? null
          : familyRoleFromName(json['my_role'] as String),
      isOwner: json['is_owner'] as bool? ?? false,
      isActive: json['family_is_active'] as bool? ?? false,
      memberCount: (json['member_count'] as num?)?.toInt() ?? 0,
      maxMembers: (json['max_members'] as num?)?.toInt() ?? 5,
      pendingInvites: (json['pending_invites'] as num?)?.toInt() ?? 0,
    );
  }

  Map<String, dynamic> toJson() => {
    'has_pro': hasPro,
    'family_id': familyId,
    'family_name': familyName,
    'my_role': myRole?.name,
    'is_owner': isOwner,
    'family_is_active': isActive,
    'member_count': memberCount,
    'max_members': maxMembers,
    'pending_invites': pendingInvites,
  };

  @override
  List<Object?> get props => [
    hasPro,
    familyId,
    familyName,
    myRole,
    isOwner,
    isActive,
    memberCount,
    maxMembers,
    pendingInvites,
  ];
}

class FamilyMember extends Equatable {
  const FamilyMember({
    required this.userId,
    required this.role,
    this.nickname,
    this.displayName,
    this.isOwner = false,
    required this.joinedAt,
  });

  final String userId;
  final FamilyRole role;

  /// Como a pessoa aparece na Familia (ex.: "Mamae"). Tem prioridade sobre o nome.
  final String? nickname;
  final String? displayName;
  final bool isOwner;
  final DateTime joinedAt;

  String get label {
    final n = nickname?.trim();
    if (n != null && n.isNotEmpty) return n;
    final d = displayName?.trim();
    if (d != null && d.isNotEmpty) return d;
    return 'Membro';
  }

  factory FamilyMember.fromJson(Map<String, dynamic> json) => FamilyMember(
    userId: json['user_id'] as String,
    role: familyRoleFromName(json['role'] as String?),
    nickname: json['nickname'] as String?,
    displayName: json['display_name'] as String?,
    isOwner: json['is_owner'] as bool? ?? false,
    joinedAt: DateTime.parse(json['joined_at'] as String),
  );

  Map<String, dynamic> toJson() => {
    'user_id': userId,
    'role': role.name,
    'nickname': nickname,
    'display_name': displayName,
    'is_owner': isOwner,
    'joined_at': joinedAt.toIso8601String(),
  };

  @override
  List<Object?> get props => [
    userId,
    role,
    nickname,
    displayName,
    isOwner,
    joinedAt,
  ];
}

/// Filho da Familia. Nao e usuario do app e nao conta no limite de membros.
class FamilyChild extends Equatable {
  const FamilyChild({
    required this.id,
    required this.familyId,
    required this.name,
    this.birthDate,
    this.colorHex,
    this.avatarUrl,
    this.notes,
    this.archivedAt,
  });

  final String id;
  final String familyId;
  final String name;
  final DateTime? birthDate;
  final String? colorHex;
  final String? avatarUrl;
  final String? notes;
  final DateTime? archivedAt;

  bool get isArchived => archivedAt != null;

  factory FamilyChild.fromJson(Map<String, dynamic> json) => FamilyChild(
    id: json['id'] as String,
    familyId: json['family_id'] as String,
    name: json['name'] as String,
    birthDate: json['birth_date'] == null
        ? null
        : DateTime.parse(json['birth_date'] as String),
    colorHex: json['color_hex'] as String?,
    avatarUrl: json['avatar_url'] as String?,
    notes: json['notes'] as String?,
    archivedAt: json['archived_at'] == null
        ? null
        : DateTime.parse(json['archived_at'] as String),
  );

  Map<String, dynamic> toJson() => {
    'id': id,
    'family_id': familyId,
    'name': name,
    'birth_date': birthDate == null
        ? null
        : '${birthDate!.year.toString().padLeft(4, '0')}-'
              '${birthDate!.month.toString().padLeft(2, '0')}-'
              '${birthDate!.day.toString().padLeft(2, '0')}',
    'color_hex': colorHex,
    'avatar_url': avatarUrl,
    'notes': notes,
    'archived_at': archivedAt?.toIso8601String(),
  };

  @override
  List<Object?> get props => [
    id,
    familyId,
    name,
    birthDate,
    colorHex,
    avatarUrl,
    notes,
    archivedAt,
  ];
}

/// Convite pendente. Do lado do admin, [email] e conhecido;
/// do lado do convidado, [familyName] e [invitedByName] vem preenchidos.
class FamilyInvite extends Equatable {
  const FamilyInvite({
    required this.id,
    required this.familyId,
    required this.role,
    this.email,
    this.familyName,
    this.invitedByName,
    required this.createdAt,
    required this.expiresAt,
  });

  final String id;
  final String familyId;
  final FamilyRole role;
  final String? email;
  final String? familyName;
  final String? invitedByName;
  final DateTime createdAt;
  final DateTime expiresAt;

  @override
  List<Object?> get props => [
    id,
    familyId,
    role,
    email,
    familyName,
    invitedByName,
    createdAt,
    expiresAt,
  ];
}
