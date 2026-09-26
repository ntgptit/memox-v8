import 'package:memox/features/card/di/card_transfer_repository_provider.dart';
import 'package:memox/features/transfer/domain/usecases/preview_import_use_case.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'preview_import_use_case_provider.g.dart';

@riverpod
PreviewImportUseCase previewImportUseCase(Ref ref) =>
    PreviewImportUseCase(ref.watch(cardTransferRepositoryProvider));
