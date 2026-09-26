import 'package:memox/features/study_mode/domain/models/study_mode.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'review_mode_pick_controller.g.dart';

/// The review mode picked on a deck's Study Entry (FE-A6 P3, E1): null
/// until the person picks one, then the offer falls back from it to the
/// first available mode. Not persisted: default review modes belong to
/// Study options (FE-A3).
@riverpod
class ReviewModePickController extends _$ReviewModePickController {
  @override
  StudyMode? build(String deckId) => null;

  void pick(StudyMode mode) => state = mode;
}
