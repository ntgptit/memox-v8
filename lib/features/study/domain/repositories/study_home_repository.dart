import 'package:memox/features/study/domain/models/study_home_model.dart';

/// The Study tab's read (UC-STUDY-002). The one implementation is
/// `StudyHomeRepositoryImpl` (data layer); the contract exists for ADR-010's
/// reason: domain stays framework-free and tests substitute a fake.
abstract interface class StudyHomeRepository {
  /// UC-STUDY-002 step 1 (Study Home spec §6): the session Resume takes up
  /// and every root deck with its workload as of [now], Overdue before
  /// [startOfToday], read as one snapshot; again after every write it can
  /// see. It writes nothing (BR-STUDY-075).
  Stream<StudyHome> watchHome({
    required DateTime now,
    required DateTime startOfToday,
  });
}
