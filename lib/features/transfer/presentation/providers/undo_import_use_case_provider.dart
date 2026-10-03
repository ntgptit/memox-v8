import 'package:memox/features/card/di/card_repository_provider.dart';
import 'package:memox/features/transfer/domain/usecases/undo_import_use_case.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'undo_import_use_case_provider.g.dart';

@riverpod
UndoImportUseCase undoImportUseCase(Ref ref) =>
    UndoImportUseCase(ref.watch(cardRepositoryProvider));
