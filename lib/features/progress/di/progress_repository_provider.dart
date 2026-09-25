import 'package:memox/core/database/di/database_provider.dart';
import 'package:memox/features/progress/data/repositories/progress_repository_impl.dart';
import 'package:memox/features/progress/domain/repositories/progress_repository.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'progress_repository_provider.g.dart';

@riverpod
ProgressRepository progressRepository(Ref ref) =>
    ProgressRepositoryImpl(ref.watch(databaseProvider));
