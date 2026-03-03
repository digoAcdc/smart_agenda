import 'package:equatable/equatable.dart';

class ReminderConfig extends Equatable {
  const ReminderConfig({
    required this.enabled,
    required this.minutesBefore,
    required this.notificationId,
    this.channelKey,
  }) : assert(
          enabled || minutesBefore == null,
          'minutesBefore must be null when reminder disabled',
        );

  final bool enabled;
  final int? minutesBefore;
  final int notificationId;
  final String? channelKey;

  ReminderConfig copyWith({
    bool? enabled,
    int? minutesBefore,
    int? notificationId,
    String? channelKey,
  }) {
    return ReminderConfig(
      enabled: enabled ?? this.enabled,
      minutesBefore: (enabled ?? this.enabled)
          ? minutesBefore ?? this.minutesBefore
          : null,
      notificationId: notificationId ?? this.notificationId,
      channelKey: channelKey ?? this.channelKey,
    );
  }

  Map<String, dynamic> toJson() => {
        'enabled': enabled,
        'minutesBefore': minutesBefore,
        'notificationId': notificationId,
        'channelKey': channelKey,
      };

  factory ReminderConfig.fromJson(Map<String, dynamic> json) {
    return ReminderConfig(
      enabled: json['enabled'] as bool? ?? false,
      minutesBefore: json['minutesBefore'] as int?,
      notificationId: json['notificationId'] as int? ?? 0,
      channelKey: json['channelKey'] as String?,
    );
  }

  @override
  List<Object?> get props =>
      [enabled, minutesBefore, notificationId, channelKey];
}
