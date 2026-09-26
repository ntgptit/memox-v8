import 'package:memox/features/study/domain/models/study_session_view_model.dart';
import 'package:memox/features/study/domain/models/turn_result_model.dart';
import 'package:memox/features/study_mode/domain/models/study_answer_model.dart';

/// What the session screen holds that its stream cannot show (spec D4, D5).
final class StudyTurnState {
  const StudyTurnState({this.isBusy = false, this.held, this.unsaved});

  /// A write is running; every other command is dropped (BR-STUDY-004).
  final bool isBusy;

  /// A graded turn's item and result, on screen until its mode releases it
  /// (spec D5).
  final HeldTurn? held;

  /// The answer a busy database refused, kept for Retry (UC-STUDY-001 E2).
  final PendingAnswer? unsaved;
}

/// A turn whose outcome stays on screen after its write committed
/// (BR-STUDY-063, BR-STUDY-064).
final class HeldTurn {
  const HeldTurn(this.item, this.result);

  final StudyItem item;
  final TurnResult result;
}

/// An answer not yet written.
final class PendingAnswer {
  const PendingAnswer(this.item, this.answer, {required this.holdsFeedback});

  final StudyItem item;
  final StudyAnswer answer;
  final bool holdsFeedback;
}
