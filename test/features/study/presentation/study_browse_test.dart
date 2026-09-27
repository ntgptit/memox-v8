import 'package:flutter/material.dart';
import 'package:flutter/semantics.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:memox/core/error/outcome.dart';
import 'package:memox/features/study/domain/failures/study_failure.dart';
import 'package:memox/features/study/presentation/controllers/study_session_controller.dart';
import 'package:memox/features/study/presentation/providers/study_session_provider.dart';
import 'package:memox/features/study/presentation/widgets/sections/study_browse_widget.dart';
import 'package:memox/features/study/domain/models/study_session_view_model.dart';
import 'package:memox/features/study_mode/domain/models/study_answer_model.dart';
import 'package:memox/l10n/generated/app_localizations.dart';
import 'package:memox/shared/widgets/mx_badge.dart';

import '../../../support/card_fixtures.dart';
import '../../../support/deck_fixtures.dart';
import '../../../support/library_harness.dart';
import '../../../support/study_fixtures.dart';

// Screen 16: IT-MODE-002; BR-STUDY-048; FE-A6 D20.

final _en = lookupAppLocalizations(const Locale('en'));

/// Browse over [sessionId]'s live view, answering through the controller.
class _Host extends ConsumerWidget {
  const _Host(this.sessionId);
  final String sessionId;

  void _advance(WidgetRef ref, StudyItem item) => ref
      .read(studySessionControllerProvider(sessionId).notifier)
      .answer(item, const AdvanceAnswer());

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final turn = ref.watch(studySessionControllerProvider(sessionId));
    return switch (ref.watch(studySessionProvider(sessionId))) {
      AsyncData(value: Ok(:final value)) when value.currentItem != null =>
        Material(
          child: StudyBrowseWidget(
            view: value,
            item: value.currentItem!,
            isBusy: turn.isBusy,
            onAdvance: () => _advance(ref, value.currentItem!),
          ),
        ),
      _ => const SizedBox.shrink(),
    };
  }
}

/// A learning session on a leaf (a root holds no card, BR-DECK-004), on the
/// harness's day.
Future<String> _session(LibraryEnv env, List<String> ids) async {
  final root = await env.decks.root('Korean');
  final leaf = await env.decks.sub(root.id, 'Lesson');
  for (final id in ids) {
    await insertCard(
      env.db,
      id: id,
      deckId: leaf.id,
      front: 'front $id',
      back: 'back $id',
    );
  }
  final opened = await studyEntryRepository(
    env.db,
    env.clock.now,
  ).openLearningSession(deckId: leaf.id);
  return (opened as Ok<String, StudyRejection>).value;
}

Future<void> _swipe(WidgetTester tester, double dx) async {
  await tester.drag(find.byType(StudyBrowseWidget), Offset(dx, 0));
  await tester.pumpAndSettle();
}

String _front(WidgetTester tester) => tester
    .widgetList<Text>(find.textContaining(RegExp(r'^front ')))
    .single
    .data!;

void main() {
  libraryTest('both faces show at once, labelled, with no grading control '
      '(IT-MODE-002 steps 1–3)', (tester, env) async {
    final id = await _session(env, ['a', 'b', 'c']);
    await pumpLibraryScreen(tester, env, _Host(id));
    await tester.pumpAndSettle();

    expect(find.text(_en.studyBrowseTerm.toUpperCase()), findsOneWidget);
    expect(find.text(_en.studyBrowseMeaning.toUpperCase()), findsOneWidget);
    expect(find.textContaining(RegExp(r'^back ')), findsOneWidget);
    expect(find.byType(ElevatedButton), findsNothing);
    expect(find.text(_en.studyBrowseHint), findsOneWidget);
  });

  libraryTest('left advances one stop; right looks back without writing; '
      'left from a look-back returns and does not answer twice '
      '(IT-MODE-002 steps 4–6, BR-STUDY-048)', (tester, env) async {
    final id = await _session(env, ['a', 'b', 'c']);
    await pumpLibraryScreen(tester, env, _Host(id));
    await tester.pumpAndSettle();
    final first = _front(tester);

    await _swipe(tester, -300);
    final second = _front(tester);
    expect(second, isNot(first));
    expect((await watchSessionOnce(env.db, id)).progress!.completed, 1);

    await _swipe(tester, 300);
    expect(_front(tester), first);
    expect(
      find.widgetWithText(MxBadge, _en.studyBrowseLookingBack),
      findsOneWidget,
    );
    expect((await watchSessionOnce(env.db, id)).progress!.completed, 1);

    await _swipe(tester, -300);
    expect(_front(tester), second);
    expect((await watchSessionOnce(env.db, id)).progress!.completed, 1);

    await _swipe(tester, -300);
    expect((await watchSessionOnce(env.db, id)).progress!.completed, 2);
  });

  libraryTest('a right swipe on the round\'s first card does nothing '
      '(FE-A6 D20)', (tester, env) async {
    final id = await _session(env, ['a', 'b']);
    await pumpLibraryScreen(tester, env, _Host(id));
    await tester.pumpAndSettle();
    final first = _front(tester);

    await _swipe(tester, 300);

    expect(_front(tester), first);
    expect(find.byType(MxBadge), findsNothing);
  });

  libraryTest('the card offers Next always and Previous only when there is a '
      'card behind (IT-MODE-002 step 7)', (tester, env) async {
    final handle = tester.ensureSemantics();
    final id = await _session(env, ['a', 'b', 'c']);
    await pumpLibraryScreen(tester, env, _Host(id));
    await tester.pumpAndSettle();

    bool hasAction(String label) => tester
        .getSemantics(
          // The card's node, which carries the swipe actions.
          find
              .descendant(
                of: find.byType(StudyBrowseWidget),
                matching: find.byType(GestureDetector),
              )
              .first,
        )
        .getSemanticsData()
        .customSemanticsActionIds!
        .map(CustomSemanticsAction.getAction)
        .any((action) => action?.label == label);

    expect(hasAction(_en.studyBrowseNext), isTrue);
    expect(hasAction(_en.studyBrowsePrevious), isFalse);
    await _swipe(tester, -300);
    expect(hasAction(_en.studyBrowsePrevious), isTrue);
    handle.dispose();
  });
}
