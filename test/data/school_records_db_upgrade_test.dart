import 'dart:io';

import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:smart_agenda/data/datasources/class_schedule_local_datasource.dart';
import 'package:smart_agenda/data/datasources/school_record_local_datasource.dart';
import 'package:smart_agenda/data/local/app_database.dart';

void main() {
  setUp(() => SharedPreferences.setMockInitialValues({}));

  test(
    'banco da versao em producao (v10) abre na v11 sem perder nada',
    () async {
      final dir = await Directory.systemTemp.createTemp('smart_agenda_v10');
      addTearDown(() => dir.delete(recursive: true));
      final file = File('${dir.path}/app.sqlite');

      // Aparelho na versao atual: grade com aulas, sem a tabela nova.
      var db = AppDatabase(NativeDatabase(file));
      final schedules = ClassScheduleLocalDataSource(db);
      final g = await schedules.createSchedule(name: 'Minha grade');
      await schedules.addTimeRange(g, 420, 470);
      await db.customStatement('DROP TABLE school_records_table');
      await db.customStatement('PRAGMA user_version = 10');
      await db.close();

      // Atualizou o app: a migracao so cria a tabela nova.
      db = AppDatabase(NativeDatabase(file));
      addTearDown(db.close);
      final reopened = ClassScheduleLocalDataSource(db);
      final list = await reopened.getSchedules();
      expect(list.single.name, 'Minha grade');
      expect((await reopened.getSlots(list.single)).length, 5);
      expect(await SchoolRecordLocalDataSource(db).getRecords(g.id), isEmpty);
    },
  );
}
