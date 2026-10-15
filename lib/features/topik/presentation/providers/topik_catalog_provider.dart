import 'package:memox/features/topik/domain/models/topik_catalog_model.dart';
import 'package:memox/features/topik/presentation/providers/watch_topik_catalog_use_case_provider.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'topik_catalog_provider.g.dart';

/// Every valid test with the person's status (UC-TOPIK-001), again on each
/// attempt write. Screens 13, 34 and 35 read it.
@riverpod
Stream<List<TopikCatalogEntry>> topikCatalog(Ref ref) =>
    ref.watch(watchTopikCatalogUseCaseProvider)();
