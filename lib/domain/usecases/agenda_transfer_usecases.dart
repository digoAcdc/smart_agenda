import '../../core/result/result.dart';
import '../entities/agenda_transfer_bundle.dart';
import '../repositories/i_agenda_transfer_service.dart';

class ExportAgendaToFile {
  const ExportAgendaToFile(this._service);
  final IAgendaTransferService _service;

  Future<Result<AgendaTransferExportData>> call() {
    return _service.exportToFile();
  }
}

class ImportAgendaFromFile {
  const ImportAgendaFromFile(this._service);
  final IAgendaTransferService _service;

  Future<Result<AgendaTransferImportReport>> call(String filePath) {
    return _service.importFromFile(filePath);
  }
}
