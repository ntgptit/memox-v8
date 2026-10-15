import 'package:memox/features/topik/domain/models/topik_views_model.dart';
import 'package:memox/features/topik/presentation/providers/watch_topik_attempt_use_case_provider.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'topik_attempt_provider.g.dart';

/// Screen 37's data: the attempt with its answers and its test; null once
/// the attempt is gone (deleted, or the account switched).
@riverpod
Stream<TopikAttemptView?> topikAttempt(Ref ref, String attemptId) =>
    ref.watch(watchTopikAttemptUseCaseProvider)(attemptId);
