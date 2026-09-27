import 'package:memox/core/database/di/database_provider.dart';
import 'package:memox/features/trash/data/repositories/trash_repository_impl.dart';
import 'package:memox/features/trash/domain/repositories/trash_repository.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'trash_repository_provider.g.dart';

@riverpod
TrashRepository trashRepository(Ref ref) =>
    TrashRepositoryImpl(ref.watch(databaseProvider));
