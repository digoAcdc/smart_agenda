import '../../core/result/result.dart';
import '../entities/agenda_transfer_bundle.dart';

abstract class IAgendaTransferService {
  Future<Result<AgendaTransferExportData>> exportToFile();
  Future<Result<AgendaTransferImportReport>> importFromFile(String filePath);
}
