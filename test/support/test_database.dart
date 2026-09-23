import 'package:drift/native.dart';
import 'package:memox/core/database/app_database.dart';

/// Rows changed since the database opened: a refused write leaves it as it
/// was.
Future<int> totalChanges(AppDatabase db) async =>
    (await db.customSelect('SELECT total_changes() AS n').getSingle())
        .read<int>('n');

AppDatabase openTestDatabase() => AppDatabase(NativeDatabase.memory());
