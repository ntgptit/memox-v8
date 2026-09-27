import 'package:memox/features/tags/di/tag_repository_provider.dart';
import 'package:memox/features/tags/domain/usecases/rename_tag_use_case.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'rename_tag_use_case_provider.g.dart';

@riverpod
RenameTagUseCase renameTagUseCase(Ref ref) =>
    RenameTagUseCase(ref.watch(tagRepositoryProvider));
