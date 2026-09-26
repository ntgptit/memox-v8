import 'package:memox/features/card/di/card_transfer_repository_provider.dart';
import 'package:memox/features/transfer/domain/usecases/commit_import_use_case.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'commit_import_use_case_provider.g.dart';

@riverpod
CommitImportUseCase commitImportUseCase(Ref ref) =>
    CommitImportUseCase(ref.watch(cardTransferRepositoryProvider));
