import 'package:memox/features/transfer/di/export_share_repository_provider.dart';
import 'package:memox/features/transfer/domain/usecases/share_export_use_case.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'share_export_use_case_provider.g.dart';

@riverpod
ShareExportUseCase shareExportUseCase(Ref ref) =>
    ShareExportUseCase(ref.watch(exportShareRepositoryProvider));
