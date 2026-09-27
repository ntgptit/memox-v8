import 'package:memox/features/tags/di/tag_repository_provider.dart';
import 'package:memox/features/tags/domain/usecases/watch_tag_catalog_use_case.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'watch_tag_catalog_use_case_provider.g.dart';

@riverpod
WatchTagCatalogUseCase watchTagCatalogUseCase(Ref ref) =>
    WatchTagCatalogUseCase(ref.watch(tagRepositoryProvider));
