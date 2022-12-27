import 'dart:io';

import 'package:calender_scheduler/modal/category_color.dart';
import 'package:calender_scheduler/modal/schedule.dart';
import 'package:calender_scheduler/modal/schedule_with_color.dart';
import 'package:drift/drift.dart';
import 'package:drift/native.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

part 'drift_database.g.dart';

@DriftDatabase(tables: [
  Schedules,
  CategoryColors,
])
class LocalDatabase extends _$LocalDatabase {
  LocalDatabase() : super(_openConnection());

  //Schedule INSERT
  Future<int> createSchedule(SchedulesCompanion data) =>
      into(schedules).insert(data);
  //CategoryColor INSERT
  Future<int> createCategoryColor(CategoryColorsCompanion data) =>
      into(categoryColors).insert(data);
  //Category Color SELECT
  Future<List<CategoryColor>> getCategoryColors() =>
      select(categoryColors).get();
  
  Future<int> removeSchedule(int id) =>
  (delete(schedules)..where((tbl) => tbl.id.equals(id))).go();

  Future<int> updateScheduleById(int id, SchedulesCompanion data) =>
    (update(schedules)..where((tbl) => tbl.id.equals(id))).write(data);

  Future<Schedule> getScheduleById(int id) =>
    (select(schedules)..where((tbl) => tbl.id.equals(id))).getSingle();


  Stream<List<ScheduleWithColor>> watchSchedules(DateTime date) {
    final query = select(schedules).join([
      innerJoin(categoryColors, categoryColors.id.equalsExp(schedules.ColorId))
    ]);
    query.where(schedules.date.equals(date));

    query.orderBy([
      OrderingTerm.asc(schedules.startTime)
    ]);

    return query.watch().map(
          (rows) => rows.map(
            (row) => ScheduleWithColor(
              schedule: row.readTable(schedules),
              categoryColor: row.readTable(categoryColors),
            ),
          ).toList(),
        );
  }

  @override
  int get schemaVersion => 1;
}

LazyDatabase _openConnection() {
  return LazyDatabase(() async {
    final dbfolder = await getApplicationDocumentsDirectory();
    final file = File(p.join(dbfolder.path, 'db.sqlite'));
    return NativeDatabase(file);
  });
}
