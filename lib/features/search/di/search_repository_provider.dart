import 'package:memox/core/database/di/database_provider.dart';
import 'package:memox/features/search/data/repositories/search_repository_impl.dart';
import 'package:memox/features/search/domain/repositories/search_repository.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'search_repository_provider.g.dart';

@riverpod
SearchRepository searchRepository(Ref ref) =>
    SearchRepositoryImpl(ref.watch(databaseProvider));
