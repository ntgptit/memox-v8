import 'package:memox/features/topik/domain/models/topik_views_model.dart';
import 'package:memox/features/topik/presentation/providers/watch_topik_review_use_case_provider.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'topik_review_provider.g.dart';

/// Screen 39's data: the attempt over the current content; null once the
/// attempt is gone.
@riverpod
Stream<TopikReviewView?> topikReview(Ref ref, String attemptId) =>
    ref.watch(watchTopikReviewUseCaseProvider)(attemptId);
