import 'package:memox/features/starter_decks/di/starter_library_repository_provider.dart';
import 'package:memox/features/starter_decks/domain/usecases/watch_starter_library_use_case.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'watch_starter_library_use_case_provider.g.dart';

@riverpod
WatchStarterLibraryUseCase watchStarterLibraryUseCase(Ref ref) =>
    WatchStarterLibraryUseCase(ref.watch(starterLibraryRepositoryProvider));
