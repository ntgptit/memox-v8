import 'package:memox/features/study/di/study_entry_repository_provider.dart';
import 'package:memox/features/study/domain/usecases/find_other_deck_session_use_case.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'find_other_deck_session_use_case_provider.g.dart';

@riverpod
FindOtherDeckSessionUseCase findOtherDeckSessionUseCase(Ref ref) =>
    FindOtherDeckSessionUseCase(ref.watch(studyEntryRepositoryProvider));
