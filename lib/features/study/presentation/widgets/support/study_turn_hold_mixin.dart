import 'package:flutter/widgets.dart';
import 'package:memox/features/study/domain/models/study_session_view_model.dart';
import 'package:memox/features/study/domain/models/turn_result_model.dart';

/// Keeps the card just answered, and its result, on screen until the mode's
/// continue condition fires (spec D5; BR-STUDY-063, BR-STUDY-064): the
/// stream's next current item never replaces it before then. `browse` has
/// no result to show, so its continue condition is met the instant the
/// write commits (`continueTurn` right after `holdTurn`); the graded modes
/// of P2–P4 hold for an auto-advance delay or a Continue tap instead.
mixin StudyTurnHoldMixin<T extends StatefulWidget> on State<T> {
  StudyItem? _heldItem;
  TurnResult? _heldResult;

  /// [liveItem] while nothing is held, else the item being held.
  StudyItem? shownItem(StudyItem? liveItem) => _heldItem ?? liveItem;

  /// Null while nothing is held.
  TurnResult? get heldResult => _heldResult;

  /// Call right after an answer commits, with the item it was for.
  void holdTurn(StudyItem item, TurnResult result) {
    if (!mounted) return;
    setState(() {
      _heldItem = item;
      _heldResult = result;
    });
  }

  /// The continue condition fired: reveal the stream's current item.
  void continueTurn() {
    if (!mounted || _heldItem == null) return;
    setState(() {
      _heldItem = null;
      _heldResult = null;
    });
  }
}
