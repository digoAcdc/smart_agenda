import '../entities/school_record.dart';

/// Notas e faltas das materias de uma grade.
abstract class ISchoolRecordDataSource {
  /// Lancamentos da grade (sem os excluidos), mais recentes primeiro.
  Future<List<SchoolRecord>> getRecords(String scheduleId);

  /// Cria ou atualiza.
  Future<void> saveRecord(SchoolRecord record);

  Future<void> deleteRecord(String id);
}
