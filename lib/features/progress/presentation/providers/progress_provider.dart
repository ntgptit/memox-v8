import 'package:memox/features/progress/domain/models/progress_model.dart';
import 'package:memox/features/progress/presentation/providers/watch_progress_use_case_provider.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'progress_provider.g.dart';

/// `/progress` (UC-PROGRESS-001, UC-PROGRESS-002 at the library level),
/// again on every write it can see and at each local midnight. It writes
/// nothing (BR-PROGRESS-009).
@riverpod
Stream<Progress> progress(Ref ref) => ref.watch(watchProgressUseCaseProvider)();
