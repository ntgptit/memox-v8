import 'package:memox/core/error/outcome.dart';
import 'package:memox/features/study/domain/failures/study_failure.dart';
import 'package:memox/features/study/domain/models/study_entry_model.dart';
import 'package:memox/features/study/presentation/providers/watch_study_entry_use_case_provider.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'study_entry_provider.g.dart';

/// [deckId]'s Study Entry, again on every change and at each local
/// midnight; notFound once the deck is gone (UC-STUDY-001 E1).
@riverpod
Stream<Outcome<StudyEntry, StudyRejection>> studyEntry(
  Ref ref,
  String deckId,
) => ref.watch(watchStudyEntryUseCaseProvider)(deckId: deckId);
