import 'package:equatable/equatable.dart';

import 'agenda_enums.dart';

class AttachmentRef extends Equatable {
  const AttachmentRef({
    required this.id,
    required this.itemId,
    required this.type,
    this.localPath,
    this.remoteUrl,
    this.thumbPath,
    this.title,
    this.mimeType,
    this.sizeBytes,
    required this.createdAt,
  });

  final String id;
  final String itemId;
  final AttachmentType type;
  final String? localPath;
  final String? remoteUrl;
  final String? thumbPath;
  final String? title;
  final String? mimeType;
  final int? sizeBytes;
  final DateTime createdAt;

  AttachmentRef copyWith({
    String? id,
    String? itemId,
    AttachmentType? type,
    String? localPath,
    String? remoteUrl,
    String? thumbPath,
    String? title,
    String? mimeType,
    int? sizeBytes,
    DateTime? createdAt,
  }) {
    return AttachmentRef(
      id: id ?? this.id,
      itemId: itemId ?? this.itemId,
      type: type ?? this.type,
      localPath: localPath ?? this.localPath,
      remoteUrl: remoteUrl ?? this.remoteUrl,
      thumbPath: thumbPath ?? this.thumbPath,
      title: title ?? this.title,
      mimeType: mimeType ?? this.mimeType,
      sizeBytes: sizeBytes ?? this.sizeBytes,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  @override
  List<Object?> get props => [
        id,
        itemId,
        type,
        localPath,
        remoteUrl,
        thumbPath,
        title,
        mimeType,
        sizeBytes,
        createdAt,
      ];
}
