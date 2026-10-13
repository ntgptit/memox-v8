import 'package:memox/core/database/app_database.dart';
import 'package:memox/core/database/connection.dart';
import 'package:memox/core/logging/di/logging_providers.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'database_provider.g.dart';

@Riverpod(keepAlive: true)
AppDatabase database(Ref ref) {
  final db = openAppDatabase(sqlLog: ref.watch(sqlLogSwitchProvider));
  ref.onDispose(db.close);
  return db;
}
