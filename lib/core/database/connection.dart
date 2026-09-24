import 'package:drift_flutter/drift_flutter.dart';
import 'package:memox/core/database/app_database.dart';

AppDatabase openAppDatabase() => AppDatabase(driftDatabase(name: 'memox'));
