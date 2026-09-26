import 'package:memox/features/study/presentation/providers/preview_self_assess_intervals_use_case_provider.dart';
import 'package:memox/features/study_mode/domain/models/session_kind_model.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'self_assess_preview_provider.g.dart';

/// The interval preview of one turn of screen 16a (FE-A6 D11), read when the
/// card is served so the grades show it at the reveal.
@riverpod
Future<Map<Object, int>?> selfAssessPreview(
  Ref ref, {
  required SessionKind kind,
  required String cardId,
  required int round,
  required int answersInSession,
}) => ref.watch(previewSelfAssessIntervalsUseCaseProvider)(
  kind: kind,
  cardId: cardId,
  round: round,
  answersInSession: answersInSession,
);
