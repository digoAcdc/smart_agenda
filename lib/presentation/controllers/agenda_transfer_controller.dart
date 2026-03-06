import 'package:file_picker/file_picker.dart';
import 'package:get/get.dart';
import 'package:share_plus/share_plus.dart';

import '../../domain/entities/agenda_transfer_bundle.dart';
import '../../domain/usecases/agenda_transfer_usecases.dart';
import 'agenda_controller.dart';

class AgendaTransferController extends GetxController {
  AgendaTransferController({
    required ExportAgendaToFile exportAgendaToFile,
    required ImportAgendaFromFile importAgendaFromFile,
    required AgendaController agendaController,
  })  : _exportAgendaToFile = exportAgendaToFile,
        _importAgendaFromFile = importAgendaFromFile,
        _agendaController = agendaController;

  final ExportAgendaToFile _exportAgendaToFile;
  final ImportAgendaFromFile _importAgendaFromFile;
  final AgendaController _agendaController;

  final loading = false.obs;
  final message = RxnString();

  Future<bool> shareAgenda() async {
    loading.value = true;
    message.value = null;
    try {
      final result = await _exportAgendaToFile();
      if (!result.isSuccess || result.data == null) {
        message.value = result.errorMessage ?? 'Falha ao exportar agenda.';
        return false;
      }
      final exportData = result.data!;
      await SharePlus.instance.share(
        ShareParams(
          files: [XFile(exportData.filePath)],
          text:
              'Agenda exportada do Smart Agenda (${exportData.itemCount} eventos).',
          subject: 'Compartilhamento de agenda',
        ),
      );
      message.value = 'Arquivo gerado e compartilhado com sucesso.';
      return true;
    } catch (e) {
      message.value = 'Erro ao compartilhar agenda: $e';
      return false;
    } finally {
      loading.value = false;
    }
  }

  Future<AgendaTransferImportReport?> importAgenda() async {
    loading.value = true;
    message.value = null;
    try {
      final picked = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: const ['json'],
        withData: false,
      );
      final path = picked?.files.single.path;
      if (path == null || path.trim().isEmpty) {
        message.value = 'Importacao cancelada.';
        return null;
      }

      final result = await _importAgendaFromFile(path);
      if (!result.isSuccess || result.data == null) {
        message.value = result.errorMessage ?? 'Falha ao importar agenda.';
        return null;
      }

      await _agendaController.loadByDay(_agendaController.selectedDate.value);
      await _agendaController.loadToday();
      message.value = 'Agenda importada com sucesso.';
      return result.data;
    } catch (e) {
      message.value = 'Erro ao importar agenda: $e';
      return null;
    } finally {
      loading.value = false;
    }
  }
}
