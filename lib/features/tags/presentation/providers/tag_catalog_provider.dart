import 'package:memox/features/tags/domain/models/tag_count_model.dart';
import 'package:memox/features/tags/presentation/providers/watch_tag_catalog_use_case_provider.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'tag_catalog_provider.g.dart';

/// Every tag of the library with its active cards, by folded name
/// (UC-TAG-001 steps 1-2). Screen 05 narrows it as the search is typed.
@riverpod
Stream<List<TagCount>> tagCatalog(Ref ref) =>
    ref.watch(watchTagCatalogUseCaseProvider)();
