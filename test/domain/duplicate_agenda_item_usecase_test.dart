import 'package:flutter_test/flutter_test.dart';
import 'package:smart_agenda/core/result/result.dart';
import 'package:smart_agenda/domain/entities/agenda_item.dart';
import 'package:smart_agenda/domain/entities/attachment_ref.dart';
import 'package:smart_agenda/domain/entities/agenda_enums.dart';
import 'package:smart_agenda/domain/repositories/i_agenda_repository.dart';
import 'package:smart_agenda/domain/usecases/agenda_usecases.dart';
import 'package:smart_agenda/domain/value_objects/search_filters.dart';

class FakeAgendaRepository implements IAgendaRepository {
  final Map<String, AgendaItem> _data = {};

  @override
  Future<Result<void>> createItem(AgendaItem item) async {
    _data[item.id] = item;
    return Result.success(null);
  }

  @override
  Future<Result<void>> deleteItemSoft(String itemId) async => Result.success(null);

  @override
  Future<Result<AgendaItem?>> getItemById(String itemId) async =>
      Result.success(_data[itemId]);

  @override
  Future<Result<List<AgendaItem>>> getItemsByDay(DateTime date) async =>
      Result.success(const []);

  @override
  Future<Result<List<AgendaItem>>> getItemsByRange(DateTime start, DateTime end) async =>
      Result.success(const []);

  @override
  Future<Result<Set<DateTime>>> getMarkersByRange(DateTime start, DateTime end) async =>
      Result.success({});

  @override
  Future<Result<List<AgendaItem>>> searchItems(String query, SearchFilters filters) async =>
      Result.success(const []);

  @override
  Future<Result<void>> setStatus(String itemId, AgendaStatus status) async =>
      Result.success(null);

  @override
  Future<Result<void>> updateItem(AgendaItem item) async => Result.success(null);
}

void main() {
  test('duplicate mantém campos e gera novo id', () async {
    final repo = FakeAgendaRepository();
    final base = AgendaItem(
      id: 'old-id',
      title: 'Reuniao',
      startAt: DateTime(2026, 3, 3, 10),
      createdAt: DateTime(2026, 3, 1),
      updatedAt: DateTime(2026, 3, 1),
      attachments: [
        AttachmentRef(
          id: 'a1',
          itemId: 'old-id',
          type: AttachmentType.image,
          localPath: '/tmp/file.jpg',
          createdAt: DateTime(2026, 3, 1),
        ),
      ],
    );
    await repo.createItem(base);

    final usecase = DuplicateAgendaItem(repo, () => 'new-id');
    final result = await usecase('old-id');

    expect(result.isSuccess, true);
    final duplicated = await repo.getItemById('new-id');
    expect(duplicated.data, isNotNull);
    expect(duplicated.data!.id, 'new-id');
    expect(duplicated.data!.title, base.title);
    expect(duplicated.data!.startAt, base.startAt);
  });
}
