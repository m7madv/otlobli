import 'dart:io';

import 'package:drift/drift.dart';
import 'package:drift/native.dart';
import 'package:path/path.dart' as path;
import 'package:path_provider/path_provider.dart';

part 'app_database.g.dart';

class SavedBriefs extends Table {
  TextColumn get id => text()();
  TextColumn get accountId => text()();
  TextColumn get payloadJson => text()();
  DateTimeColumn get processedAt => dateTime()();

  @override
  Set<Column<Object>> get primaryKey => {id};
}

@DriftDatabase(tables: [SavedBriefs])
class AppDatabase extends _$AppDatabase {
  AppDatabase([QueryExecutor? executor]) : super(executor ?? _openConnection());

  @override
  int get schemaVersion => 1;

  static QueryExecutor _openConnection() {
    return LazyDatabase(() async {
      final directory = await getApplicationDocumentsDirectory();
      final file = File(path.join(directory.path, 'voicebrief_results.sqlite'));
      return NativeDatabase.createInBackground(file);
    });
  }
}
