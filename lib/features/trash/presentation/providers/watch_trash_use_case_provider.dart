import 'package:memox/features/trash/di/trash_repository_provider.dart';
import 'package:memox/features/trash/domain/usecases/watch_trash_use_case.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'watch_trash_use_case_provider.g.dart';

@riverpod
WatchTrashUseCase watchTrashUseCase(Ref ref) =>
    WatchTrashUseCase(ref.watch(trashRepositoryProvider));
