import 'package:memox/core/error/outcome.dart';
import 'package:memox/features/study/domain/failures/study_failure.dart';
import 'package:memox/features/study/domain/models/study_entry_model.dart';
import 'package:memox/features/study/presentation/providers/watch_study_entry_use_case_provider.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'study_entry_provider.g.dart';

/// The Study Entry of [deckId] (screen 14), again on every change and at
/// local midnight; `Rejected(notFound)` once the deck is gone.
@riverpod
Stream<Outcome<StudyEntry, StudyRejection>> studyEntry(
  Ref ref,
  String deckId,
) => ref.watch(watchStudyEntryUseCaseProvider)(deckId: deckId);
