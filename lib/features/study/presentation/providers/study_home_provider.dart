import 'package:memox/features/study/domain/models/study_home_model.dart';
import 'package:memox/features/study/presentation/providers/watch_study_home_use_case_provider.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'study_home_provider.g.dart';

/// The Study tab, again on every change it can see and at each local
/// midnight (UC-STUDY-002; BR-STUDY-075: it writes nothing).
@riverpod
Stream<StudyHome> studyHome(Ref ref) =>
    ref.watch(watchStudyHomeUseCaseProvider)();
