import '../../domain/entities/school_record.dart';
import '../../domain/repositories/i_school_record_datasource.dart';
import '../../domain/repositories/i_sync_service.dart';

/// Sempre local (offline-first); cada alteracao pede um sync, que so envia
/// no Pro (pessoais) e na Familia (compartilhados).
class SchoolRecordDataSourceOrchestrator implements ISchoolRecordDataSource {
  SchoolRecordDataSourceOrchestrator(this._local, this._syncService);

  final ISchoolRecordDataSource _local;
  final ISyncService _syncService;

  @override
  Future<List<SchoolRecord>> getRecords(String scheduleId) =>
      _local.getRecords(scheduleId);

  @override
  Future<void> saveRecord(SchoolRecord record) async {
    await _local.saveRecord(record);
    _syncService.syncNow();
  }

  @override
  Future<void> deleteRecord(String id) async {
    await _local.deleteRecord(id);
    _syncService.syncNow();
  }
}
