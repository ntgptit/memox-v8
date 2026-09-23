import 'package:drift/native.dart';
import 'package:memox/core/database/app_database.dart';

AppDatabase openTestDatabase() => AppDatabase(NativeDatabase.memory());
