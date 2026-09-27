import 'package:memox/features/card/domain/usecases/watch_card_tag_filter_use_case.dart';
import 'package:memox/features/tags/di/tag_repository_provider.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'watch_card_tag_filter_use_case_provider.g.dart';

@riverpod
WatchCardTagFilterUseCase watchCardTagFilterUseCase(Ref ref) =>
    WatchCardTagFilterUseCase(ref.watch(tagRepositoryProvider));
