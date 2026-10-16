import 'dart:ui' show Tristate;

import 'package:flutter/material.dart';
import 'package:memox/core/theme/app_icons.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:memox/features/topik/di/topik_audio_repository_provider.dart';
import 'package:memox/features/topik/domain/models/topik_audio_model.dart';
import 'package:memox/features/topik/domain/models/topik_section_model.dart';
import 'package:memox/features/topik/presentation/widgets/overlays/topik_question_grid_sheet_widget.dart';
import 'package:memox/features/topik/presentation/widgets/sections/topik_attempt_footer_widget.dart';
import 'package:memox/features/topik/presentation/widgets/sections/topik_audio_bar_widget.dart';
import 'package:memox/features/topik/presentation/widgets/sections/topik_group_pane_widget.dart';
import 'package:memox/features/topik/presentation/widgets/sections/topik_question_pane_widget.dart';
import 'package:memox/features/topik/presentation/widgets/sections/topik_two_pane_widget.dart';
import 'package:memox/shared/widgets/mx_choice_tile.dart';
import 'package:memox/shared/widgets/mx_icon_button.dart';

import '../../../support/library_harness.dart';
import '../../../support/topik_content_fixtures.dart';
import '../../../support/topik_fakes.dart';

const _clip = TopikAudioClip(asset: 'a.mp3', startMs: 0, endMs: 30000);

// Screen 37's parts (detail file 37; critique F1, F5, F7, F12).
void main() {
  final reading = topikTestFixture();
  final listening = topikTestFixture(section: TopikSection.listening);

  Future<void> host(
    WidgetTester tester,
    LibraryEnv env,
    Widget child, {
    FakeTopikAudioRepository? player,
  }) async {
    await pumpLibraryScreen(
      tester,
      env,
      Scaffold(body: child),
      overrides: [
        topikAudioRepositoryProvider.overrideWithValue(
          player ?? FakeTopikAudioRepository(),
        ),
      ],
    );
    await tester.pumpAndSettle();
  }

  libraryTest('two panes: the material takes at most half, the question '
      'the rest', (tester, env) async {
    await host(
      tester,
      env,
      const TopikTwoPaneWidget(
        top: SingleChildScrollView(child: SizedBox(height: 2000)),
        bottom: SizedBox.expand(key: ValueKey('bottom')),
      ),
    );

    expect(tester.getSize(find.byType(SingleChildScrollView)).height, 400);
    expect(tester.getSize(find.byKey(const ValueKey('bottom'))).height, 400);
  });

  libraryTest('no shared material: the question takes the whole body', (
    tester,
    env,
  ) async {
    await host(
      tester,
      env,
      const TopikTwoPaneWidget(
        top: null,
        bottom: SizedBox.expand(key: ValueKey('bottom')),
      ),
    );

    expect(tester.getSize(find.byKey(const ValueKey('bottom'))).height, 800);
  });

  libraryTest('the question: its real number, four options; a pick reports '
      'its number; only idle and selected (BR-TOPIK-016)', (tester, env) async {
    final question = reading.questions.first;
    final picks = <int>[];
    await host(
      tester,
      env,
      TopikQuestionPaneWidget(
        question: question,
        selectedIdx: 3,
        onPick: picks.add,
      ),
    );

    expect(find.text('1. ${question.stemKo}'), findsOneWidget);
    final tiles = tester.widgetList<MxChoiceTile>(find.byType(MxChoiceTile));
    expect(
      [for (final tile in tiles) tile.tone],
      [
        MxChoiceTone.idle,
        MxChoiceTone.idle,
        MxChoiceTone.selected,
        MxChoiceTone.idle,
      ],
    );
    expect(tiles.elementAt(1).semanticsLabel, 'Option 2, 보기 2');
    await tester.tap(find.text('② 보기 2'));
    expect(picks, [2]);
  });

  libraryTest('the question is inert while held', (tester, env) async {
    await host(
      tester,
      env,
      TopikQuestionPaneWidget(
        question: reading.questions.first,
        selectedIdx: null,
        onPick: null,
      ),
    );

    final tiles = tester.widgetList<MxChoiceTile>(find.byType(MxChoiceTile));
    expect(tiles.every((tile) => tile.onTap == null), isTrue);
  });

  libraryTest('the group pane: instruction, passage; collapsed it keeps the '
      'instruction on one line', (tester, env) async {
    final group = reading.groups.first;
    var isCollapsed = false;
    await host(
      tester,
      env,
      StatefulBuilder(
        builder: (context, setState) => TopikGroupPaneWidget(
          group: group,
          audio: null,
          isCollapsed: isCollapsed,
          isScriptShown: false,
          onToggleCollapsed: () => setState(() => isCollapsed = !isCollapsed),
          onToggleScript: () {},
        ),
      ),
    );

    expect(find.text(group.instructionKo), findsOneWidget);
    expect(find.text(group.passage!.textKo!), findsOneWidget);
    // Q-P6b-4 (owner, 2026-10-16): a chevron, named for TalkBack (F5).
    expect(find.byIcon(AppIcons.chevronUp), findsOneWidget);
    await tester.tap(find.byTooltip('Hide passage'));
    await tester.pumpAndSettle();
    expect(find.text(group.passage!.textKo!), findsNothing);
    expect(tester.widget<Text>(find.text(group.instructionKo)).maxLines, 1);
    expect(find.byTooltip('Show passage'), findsOneWidget);
    expect(find.byIcon(AppIcons.chevronDown), findsOneWidget);
  });

  libraryTest('a listening group: the audio stays when collapsed; the script '
      'shows with its translation in the UI language', (tester, env) async {
    final group = listening.groups.first;
    await host(
      tester,
      env,
      TopikGroupPaneWidget(
        group: group,
        audio: _clip,
        isCollapsed: false,
        isScriptShown: true,
        onToggleCollapsed: () {},
        onToggleScript: () {},
      ),
    );
    expect(find.byType(TopikAudioBarWidget), findsOneWidget);
    expect(find.text(group.script!), findsOneWidget);
    expect(find.text('Hello.'), findsOneWidget);
    expect(find.text('Hide script'), findsOneWidget);

    await host(
      tester,
      env,
      TopikGroupPaneWidget(
        group: group,
        audio: _clip,
        isCollapsed: true,
        isScriptShown: true,
        onToggleCollapsed: () {},
        onToggleScript: () {},
      ),
    );
    expect(find.byType(TopikAudioBarWidget), findsOneWidget);
    expect(find.text(group.script!), findsNothing);
  });

  libraryTest('the footer: Previous is off on the first question; the last '
      'question submits; one primary (critique F1)', (tester, env) async {
    var submits = 0;
    await host(
      tester,
      env,
      TopikAttemptFooterWidget(
        onPrevious: null,
        onNext: null,
        onQuestions: () {},
        onSubmit: () => submits++,
        isSubmitting: false,
      ),
    );

    final previous = tester.widget<MxIconButton>(find.byType(MxIconButton));
    expect(previous.semanticLabel, 'Previous');
    expect(previous.onPressed, isNull);
    expect(find.text('Next'), findsNothing);
    await tester.tap(find.text('Submit'));
    expect(submits, 1);
    expect(find.text('Questions'), findsOneWidget);
  });

  libraryTest('the grid: a cell per question that says if it is answered, '
      'the current one selected; a tap goes there, Submit submits', (
    tester,
    env,
  ) async {
    final handle = tester.ensureSemantics();
    final picks = <TopikGridPick?>[];
    await host(
      tester,
      env,
      Builder(
        builder: (context) => TextButton(
          onPressed: () async => picks.add(
            await showTopikQuestionGrid(
              context,
              questionNos: const [1, 2, 3],
              answered: const {2},
              current: 1,
            ),
          ),
          child: const Text('open'),
        ),
      ),
    );

    await tester.tap(find.text('open'));
    await tester.pumpAndSettle();
    expect(find.text('Questions'), findsOneWidget);
    expect(find.bySemanticsLabel('Question 2, answered'), findsOneWidget);
    expect(find.bySemanticsLabel('Question 3, not answered'), findsOneWidget);
    final current = tester.getSemantics(
      find.bySemanticsLabel('Question 1, not answered'),
    );
    expect(
      current.getSemanticsData().flagsCollection.isSelected,
      Tristate.isTrue,
    );
    await tester.tap(find.text('3'));
    await tester.pumpAndSettle();
    expect((picks.single! as TopikGridQuestion).no, 3);

    await tester.tap(find.text('open'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Submit'));
    await tester.pumpAndSettle();
    expect(picks.last, isA<TopikGridSubmit>());
    handle.dispose();
  });

  libraryTest('a collapse carried into a group with nothing to hide keeps '
      'its whole instruction (final review 6b #1)', (tester, env) async {
    final json = topikTestJson();
    groupJson(json, 'g1')['passage'] = null;
    final group = topikTestOfFixtureJson(json).groups.first;
    await host(
      tester,
      env,
      TopikGroupPaneWidget(
        group: group,
        audio: null,
        isCollapsed: true,
        isScriptShown: false,
        onToggleCollapsed: () {},
        onToggleScript: () {},
      ),
    );

    expect(
      tester.widget<Text>(find.text(group.instructionKo)).maxLines,
      isNull,
    );
    expect(find.byTooltip('Show passage'), findsNothing);
  });
}
