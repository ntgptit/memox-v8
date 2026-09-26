import 'package:memox/core/error/outcome.dart';
import 'package:memox/features/transfer/domain/failures/transfer_failure.dart';
import 'package:memox/features/transfer/domain/models/export_artifact_model.dart';
import 'package:memox/features/transfer/domain/repositories/export_share_repository.dart';

/// UC-TRANSFER-002 steps 6–7, A3, E1, E2: the file handed to the system
/// share sheet; a dismissal is a cancel (BR-TRANSFER-014).
final class ShareExportUseCase {
  const ShareExportUseCase(this._share);

  final ExportShareRepository _share;

  Future<Outcome<ExportShareResult, TransferRejection>> call(
    ExportArtifact artifact,
  ) => _share.share(artifact);
}
