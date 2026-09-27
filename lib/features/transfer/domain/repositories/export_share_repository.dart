import 'package:memox/core/error/outcome.dart';
import 'package:memox/features/transfer/domain/failures/transfer_failure.dart';
import 'package:memox/features/transfer/domain/models/export_artifact_model.dart';

/// Hands a file to the system share sheet (BR-TRANSFER-014). The one
/// implementation is `ExportShareRepositoryImpl` over `share_plus`; the
/// contract keeps the platform out of domain and out of tests (ADR-010).
abstract interface class ExportShareRepository {
  Future<Outcome<ExportShareResult, TransferRejection>> share(
    ExportArtifact artifact,
  );
}
