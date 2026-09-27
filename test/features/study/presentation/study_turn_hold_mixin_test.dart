import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:memox/features/study/domain/models/study_session_view_model.dart';
import 'package:memox/features/study/domain/models/turn_result_model.dart';
import 'package:memox/features/study/presentation/widgets/support/study_turn_hold_mixin.dart';

StudyItem _item(String cardId) => StudyItem(
  cardId: cardId,
  front: 'front $cardId',
  back: 'back $cardId',
  example: null,
  hint: null,
  pronunciation: null,
  round: 1,
  answersInSession: 0,
  direction: null,
  remainingMs: null,
  isRevealed: false,
);

class _Host extends StatefulWidget {
  const _Host({required this.liveItem});

  final StudyItem? liveItem;

  @override
  State<_Host> createState() => HostState();
}

class HostState extends State<_Host> with StudyTurnHoldMixin<_Host> {
  @override
  Widget build(BuildContext context) =>
      Text(shownItem(widget.liveItem)?.cardId ?? 'none');
}

void main() {
  testWidgets('holds the answered item until continueTurn (BR-STUDY-063, '
      'BR-STUDY-064)', (tester) async {
    await tester.pumpWidget(MaterialApp(home: _Host(liveItem: _item('a'))));
    expect(find.text('a'), findsOneWidget);

    final state = tester.state<HostState>(find.byType(_Host));
    state.holdTurn(_item('a'), const TurnResult(isCorrect: true));

    // The stream moved on to a new item, but the hold keeps the old one on
    // screen (BR-STUDY-064: the unit stays on screen between turns).
    await tester.pumpWidget(MaterialApp(home: _Host(liveItem: _item('b'))));
    expect(find.text('a'), findsOneWidget);
    expect(state.heldResult?.isCorrect, isTrue);

    state.continueTurn();
    await tester.pump();
    expect(find.text('b'), findsOneWidget);
    expect(state.heldResult, isNull);
  });
}
