import 'package:memox/features/topik/domain/models/topik_views_model.dart';
import 'package:memox/features/topik/presentation/providers/watch_topik_summary_use_case_provider.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'topik_summary_provider.g.dart';

/// Screen 38's data, from the attempt's snapshot; null once the attempt is
/// gone or is not submitted.
@riverpod
Stream<TopikSummaryView?> topikSummary(Ref ref, String attemptId) =>
    ref.watch(watchTopikSummaryUseCaseProvider)(attemptId);
