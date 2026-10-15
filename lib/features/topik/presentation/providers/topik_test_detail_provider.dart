import 'package:memox/features/topik/domain/models/topik_views_model.dart';
import 'package:memox/features/topik/presentation/providers/watch_topik_test_detail_use_case_provider.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'topik_test_detail_provider.g.dart';

/// One test's progress and attempts (UC-TOPIK-002), screen 36.
@riverpod
Stream<TopikTestDetail> topikTestDetail(Ref ref, String testId) =>
    ref.watch(watchTopikTestDetailUseCaseProvider)(testId);
