import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:uuid/uuid.dart';

import '../../domain/entities/class_schedule_slot.dart';
import '../../domain/repositories/i_class_schedule_datasource.dart';

/// Data source Supabase para slots de horario (plano premium).
class ClassScheduleSupabaseDataSource implements IClassScheduleDataSource {
  ClassScheduleSupabaseDataSource(this._client);

  final SupabaseClient _client;

  static const _weekdays = [1, 2, 3, 4, 5];

  String? get _userId => _client.auth.currentUser?.id;

  @override
  Future<List<ClassScheduleSlot>> getSlots() async {
    final uid = _userId;
    if (uid == null) return [];

    final rows = await _client
        .from('class_schedule_slots')
        .select()
        .eq('user_id', uid)
        .order('start_minutes')
        .order('day_of_week');

    if (rows.isEmpty) return [];
    return (rows as List)
        .map((r) => _fromRow(Map<String, dynamic>.from(r)))
        .toList();
  }

  @override
  Future<String?> addTimeRange(int start, int end) async {
    final uid = _userId;
    if (uid == null) return 'Usuario nao autenticado';
    if (end <= start) return 'Fim deve ser maior que inicio';

    final now = DateTime.now().toIso8601String();
    for (final day in _weekdays) {
      final exists = await _client
          .from('class_schedule_slots')
          .select('id')
          .eq('user_id', uid)
          .eq('day_of_week', day)
          .eq('start_minutes', start)
          .eq('end_minutes', end)
          .maybeSingle();

      if (exists == null) {
        await _client.from('class_schedule_slots').insert({
          'id': const Uuid().v4(),
          'user_id': uid,
          'day_of_week': day,
          'start_minutes': start,
          'end_minutes': end,
          'subject': null,
          'created_at': now,
          'updated_at': now,
        });
      }
    }
    debugPrint('[ClassScheduleSupabaseDS] addTimeRange $start-$end');
    return null;
  }

  @override
  Future<void> updateSlotDetails(
    String id, {
    String? subject,
    String? professorName,
    String? professorEmail,
    String? professorPhone,
  }) async {
    final uid = _userId;
    if (uid == null) return;

    String? trimOrNull(String? v) =>
        v == null || v.trim().isEmpty ? null : v.trim();

    await _client.from('class_schedule_slots').update({
      'subject': trimOrNull(subject),
      'professor_name': trimOrNull(professorName),
      'professor_email': trimOrNull(professorEmail),
      'professor_phone': trimOrNull(professorPhone),
      'updated_at': DateTime.now().toIso8601String(),
    }).eq('id', id).eq('user_id', uid);
  }

  @override
  Future<void> removeTimeRange(int start, int end) async {
    final uid = _userId;
    if (uid == null) return;

    await _client
        .from('class_schedule_slots')
        .delete()
        .eq('user_id', uid)
        .eq('start_minutes', start)
        .eq('end_minutes', end);
  }

  ClassScheduleSlot _fromRow(Map<String, dynamic> row) {
    return ClassScheduleSlot(
      id: row['id'] as String,
      dayOfWeek: row['day_of_week'] as int,
      startMinutes: row['start_minutes'] as int,
      endMinutes: row['end_minutes'] as int,
      subject: row['subject'] as String?,
      professorName: row['professor_name'] as String?,
      professorEmail: row['professor_email'] as String?,
      professorPhone: row['professor_phone'] as String?,
      createdAt: DateTime.parse(row['created_at'] as String),
      updatedAt: DateTime.parse(row['updated_at'] as String),
    );
  }
}
