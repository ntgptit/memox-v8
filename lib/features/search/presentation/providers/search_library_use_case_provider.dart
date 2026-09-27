import 'package:memox/features/search/di/search_repository_provider.dart';
import 'package:memox/features/search/domain/usecases/search_library_use_case.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'search_library_use_case_provider.g.dart';

@riverpod
SearchLibraryUseCase searchLibraryUseCase(Ref ref) =>
    SearchLibraryUseCase(ref.watch(searchRepositoryProvider));
