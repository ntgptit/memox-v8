import 'package:memox/features/tags/di/tag_repository_provider.dart';
import 'package:memox/features/tags/domain/usecases/plan_tag_rename_use_case.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'plan_tag_rename_use_case_provider.g.dart';

@riverpod
PlanTagRenameUseCase planTagRenameUseCase(Ref ref) =>
    PlanTagRenameUseCase(ref.watch(tagRepositoryProvider));
