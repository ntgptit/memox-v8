import 'package:memox/features/starter_decks/di/starter_library_repository_provider.dart';
import 'package:memox/features/starter_decks/domain/usecases/add_starter_deck_use_case.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'add_starter_deck_use_case_provider.g.dart';

@riverpod
AddStarterDeckUseCase addStarterDeckUseCase(Ref ref) =>
    AddStarterDeckUseCase(ref.watch(starterLibraryRepositoryProvider));
