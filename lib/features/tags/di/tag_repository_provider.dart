import 'package:memox/core/database/di/database_provider.dart';
import 'package:memox/features/tags/data/repositories/tag_repository_impl.dart';
import 'package:memox/features/tags/domain/repositories/tag_repository.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'tag_repository_provider.g.dart';

@riverpod
TagRepository tagRepository(Ref ref) =>
    TagRepositoryImpl(ref.watch(databaseProvider));
