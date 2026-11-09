import 'dart:convert';

import 'package:drift/drift.dart' show Value;
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:smart_agenda/data/datasources/backpack_json_codec.dart';
import 'package:smart_agenda/data/datasources/class_schedule_local_datasource.dart';
import 'package:smart_agenda/data/local/app_database.dart';
import 'package:smart_agenda/domain/entities/backpack_item.dart';

/// O que a versao antiga do app (1.2.0) faz com o bring_json: le so os
/// textos, muda uma materia e grava o mapa de volta (mesma logica de
/// decodeBringItems/setBringItems daquela versao).
String? oldAppSetBring(String? json, String subject, String text) {
  final map = <String, String>{};
  if (json != null) {
    final raw = jsonDecode(json) as Map;
    for (final e in raw.entries) {
      if (e.value is String) map[e.key.toString()] = e.value as String;
    }
  }
  if (text.trim().isEmpty) {
    map.remove(subject);
  } else {
    map[subject] = text.trim();
  }
  final clean = {
    for (final e in map.entries)
      if (e.key.trim().isNotEmpty && e.value.trim().isNotEmpty)
        e.key.trim(): e.value.trim(),
  };
  return clean.isEmpty ? null : jsonEncode(clean);
}

/// Como o app antigo le: so os textos por materia.
Map<String, String> oldAppRead(String? json) {
  if (json == null) return {};
  final raw = jsonDecode(json) as Map;
  return {
    for (final e in raw.entries)
      if (e.value is String) e.key.toString(): e.value as String,
  };
}

final _due = DateTime(2026, 11, 10);

void main() {
  group('dado antigo (texto por materia)', () {
    test('cada texto vira um item "toda semana", com o texto exato', () {
      final items = decodeBackpackItems(
        jsonEncode({'Ed. Física': 'tênis e uniforme', 'Inglês': 'livro'}),
      );
      expect(items.map((i) => '${i.subject}: ${i.label}'), [
        'Ed. Física: tênis e uniforme',
        'Inglês: livro',
      ]);
      expect(items.every((i) => i.isWeekly), isTrue);
    });

    test('ids fixos: ler duas vezes da os mesmos itens', () {
      final json = jsonEncode({'Inglês': 'livro'});
      expect(decodeBackpackItems(json), decodeBackpackItems(json));
    });

    test('vazio, nulo ou JSON invalido nao quebram', () {
      expect(decodeBackpackItems(null), isEmpty);
      expect(decodeBackpackItems(''), isEmpty);
      expect(decodeBackpackItems('{nao e json'), isEmpty);
      expect(decodeBackpackItems('[1, 2]'), isEmpty);
      expect(decodeBackpackItems(jsonEncode({'Inglês': '  '})), isEmpty);
    });
  });

  group('formato novo', () {
    final items = [
      const BackpackItem(id: '1', subject: 'Ed. Física', label: 'tênis'),
      const BackpackItem(id: '2', subject: 'Ed. Física', label: 'uniforme'),
      BackpackItem(
        id: '3',
        subject: 'Ed. Física',
        label: 'garrafinha',
        frequency: BackpackFrequency.nextClass,
        dueDate: _due,
      ),
      BackpackItem(
        id: '4',
        subject: 'Artes',
        label: 'tinta',
        frequency: BackpackFrequency.nextClass,
        dueDate: _due,
      ),
    ];

    test('ida e volta sem perder nada', () {
      expect(decodeBackpackItems(encodeBackpackItems(items)), items);
      expect(encodeBackpackItems(const []), isNull);
    });

    test('app antigo continua lendo os itens de toda semana como texto', () {
      expect(oldAppRead(encodeBackpackItems(items)), {
        'Ed. Física': 'tênis e uniforme',
        backpackV2Key: isA<String>(),
      });
    });

    test('app antigo muda uma materia: o texto dele vale, o resto fica', () {
      final json = oldAppSetBring(
        encodeBackpackItems(items),
        'Ed. Física',
        'tênis e toalha',
      );
      final after = decodeBackpackItems(json);
      expect(after.where((i) => i.isWeekly).map((i) => i.label), [
        'tênis e toalha',
      ]);
      // "So na proxima aula" (que o app antigo nem ve) nao se perde.
      expect(after.where((i) => !i.isWeekly).map((i) => i.label), [
        'garrafinha',
        'tinta',
      ]);
    });

    test('app antigo apaga uma materia: os itens de toda semana saem', () {
      final json = oldAppSetBring(encodeBackpackItems(items), 'Ed. Física', '');
      final after = decodeBackpackItems(json);
      expect(after.where((i) => i.isWeekly), isEmpty);
      expect(after.length, 2);
    });

    test('app antigo adiciona outra materia: entra como toda semana', () {
      final json = oldAppSetBring(
        encodeBackpackItems(items),
        'Inglês',
        'livro',
      );
      final after = decodeBackpackItems(json);
      expect(after.length, 5);
      expect(after.singleWhere((i) => i.subject == 'Inglês').label, 'livro');
    });

    test('item com formato desconhecido e ignorado, os outros ficam', () {
      final json = jsonEncode({
        backpackV2Key: jsonEncode([
          items.first.toJson(),
          {'id': 'x'},
          // "so na proxima aula" sem data nao tem como vencer: descartado.
          {'id': 'y', 'subject': 'A', 'label': 'b', 'frequency': 'nextClass'},
          'lixo',
        ]),
        'Ed. Física': 'tênis',
      });
      expect(decodeBackpackItems(json), [items.first]);
    });
  });

  group('lembrete por item (campo remind)', () {
    test('item sem o campo (gravado antes) vem com lembrete ligado', () {
      final json = jsonEncode({
        backpackV2Key: jsonEncode([
          {
            'id': '1',
            'subject': 'Inglês',
            'label': 'livro',
            'frequency': 'weekly',
          },
        ]),
        'Inglês': 'livro',
      });
      expect(decodeBackpackItems(json).single.remind, isTrue);
    });

    test('lembrete desligado ida e volta; ligado nao grava o campo', () {
      final items = [
        const BackpackItem(id: '1', subject: 'Inglês', label: 'livro'),
        BackpackItem(
          id: '2',
          subject: 'Artes',
          label: 'tinta',
          frequency: BackpackFrequency.nextClass,
          dueDate: _due,
          remind: false,
        ),
        const BackpackItem(
          id: '3',
          subject: 'Inglês',
          label: 'dicionário',
          remind: false,
        ),
      ];
      final json = encodeBackpackItems(items);
      expect(decodeBackpackItems(json), items);
      expect(items.first.toJson().containsKey('remind'), isFalse);
      expect(items[1].toJson()['remind'], isFalse);
      // O app antigo continua lendo o texto, com ou sem lembrete.
      expect(oldAppRead(json)['Inglês'], 'livro e dicionário');
    });

    test('app antigo mexe em outra materia: o lembrete desligado fica', () {
      final items = [
        const BackpackItem(
          id: '1',
          subject: 'Inglês',
          label: 'livro',
          remind: false,
        ),
      ];
      final json = oldAppSetBring(encodeBackpackItems(items), 'Artes', 'tinta');
      final after = decodeBackpackItems(json);
      expect(after.singleWhere((i) => i.subject == 'Inglês').remind, isFalse);
      expect(after.singleWhere((i) => i.subject == 'Artes').remind, isTrue);
    });

    test('valor estranho no campo conta como ligado', () {
      final item = BackpackItem.fromJson({
        'id': '1',
        'subject': 'Inglês',
        'label': 'livro',
        'remind': 'talvez',
      });
      expect(item?.remind, isTrue);
    });
  });

  group('no banco (grade gravada pela versao antiga)', () {
    late AppDatabase db;
    late ClassScheduleLocalDataSource ds;

    setUp(() {
      SharedPreferences.setMockInitialValues({});
      db = AppDatabase(NativeDatabase.memory());
      ds = ClassScheduleLocalDataSource(db);
    });
    tearDown(() => db.close());

    test('le o texto antigo e grava no formato novo sem perder nada', () async {
      final g = await ds.createSchedule(name: 'Escola', familyId: 'fam');
      await (db.update(
        db.classSchedulesTable,
      )..where((t) => t.id.equals(g.id))).write(
        ClassSchedulesTableCompanion(
          bringJson: Value(jsonEncode({'Ed. Física': 'tênis e uniforme'})),
        ),
      );

      final migrated = (await ds.getSchedules()).single.backpackItems;
      expect(migrated.single.label, 'tênis e uniforme');
      expect(migrated.single.isWeekly, isTrue);

      await ds.setBackpackItems(g.id, [
        ...migrated,
        BackpackItem(
          id: 'novo',
          subject: 'Ed. Física',
          label: 'garrafinha',
          frequency: BackpackFrequency.nextClass,
          dueDate: _due,
        ),
      ]);

      final saved = (await ds.getSchedules()).single;
      expect(saved.backpackItems.map((i) => i.label), [
        'tênis e uniforme',
        'garrafinha',
      ]);
      // Vai para o sync como pendente, e o app antigo ainda le o texto.
      final row = await (db.select(
        db.classSchedulesTable,
      )..where((t) => t.id.equals(g.id))).getSingle();
      expect(row.syncState, 'pending');
      expect(oldAppRead(row.bringJson)['Ed. Física'], 'tênis e uniforme');
    });

    test('lista vazia limpa o bring_json', () async {
      final g = await ds.createSchedule(name: 'Minha grade');
      await ds.setBackpackItems(g.id, [
        const BackpackItem(id: '1', subject: 'Inglês', label: 'livro'),
      ]);
      await ds.setBackpackItems(g.id, const []);
      final row = await (db.select(
        db.classSchedulesTable,
      )..where((t) => t.id.equals(g.id))).getSingle();
      expect(row.bringJson, isNull);
      expect((await ds.getSchedules()).single.backpackItems, isEmpty);
    });
  });
}
