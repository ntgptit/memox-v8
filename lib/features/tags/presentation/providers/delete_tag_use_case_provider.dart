import 'package:memox/features/tags/di/tag_repository_provider.dart';
import 'package:memox/features/tags/domain/usecases/delete_tag_use_case.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'delete_tag_use_case_provider.g.dart';

@riverpod
DeleteTagUseCase deleteTagUseCase(Ref ref) =>
    DeleteTagUseCase(ref.watch(tagRepositoryProvider));
