import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:memox/features/card/presentation/widgets/overlays/card_discard_dialog_widget.dart';
import 'package:memox/features/card/presentation/widgets/sections/card_editor_footer_widget.dart';
import 'package:memox/features/card/presentation/widgets/sections/card_field_widget.dart';
import 'package:memox/features/card/presentation/widgets/sections/card_tag_editor_widget.dart';
import 'package:memox/core/error/outcome.dart';
import 'package:memox/features/deck/domain/failures/deck_failure.dart';
import 'package:memox/features/deck/domain/models/deck_view_model.dart';
import 'package:memox/features/deck/presentation/providers/deck_view_provider.dart';
import 'package:memox/features/deck/presentation/widgets/sections/deck_context_header_widget.dart';
import 'package:memox/l10n/generated/app_localizations.dart';
import 'package:memox/shared/widgets/mx_breadcrumb.dart';
import 'package:memox/shared/widgets/mx_button.dart';
import 'package:memox/shared/widgets/mx_inline_banner.dart';
import 'package:memox/shared/widgets/mx_skeleton.dart';

import '../../../support/deck_fixtures.dart';
import '../../../support/library_harness.dart';
import '../../../support/widget_harness.dart';

final _en = lookupAppLocalizations(const Locale('en'));

Widget _host(Widget child) =>
    Scaffold(body: SingleChildScrollView(child: child));

/// A tag editor that keeps its own list, as the form does.
class _Tags extends StatefulWidget {
  const _Tags();

  @override
  State<_Tags> createState() => _TagsState();
}

class _TagsState extends State<_Tags> {
  var tags = <String>[];

  @override
  Widget build(BuildContext context) => CardTagEditorWidget(
    tags: tags,
    onChanged: (next) => setState(() => tags = next),
  );
}

void main() {
  libraryTest('a field counts characters as people see them (RF5)', (
    tester,
    env,
  ) async {
    final controller = TextEditingController();
    addTearDown(controller.dispose);
    await pumpLibraryScreen(
      tester,
      env,
      _host(
        CardFieldWidget(
          label: _en.cardFieldFront,
          hint: _en.cardFrontHint,
          limit: 60,
          controller: controller,
          isRequired: true,
        ),
      ),
    );
    await tester.enterText(find.byType(EditableText), '한국어');
    await tester.pump();

    expect(find.text(_en.cardFieldCount(3, 60)), findsOneWidget);
    expect(find.text(_en.cardRequiredLegend), findsOneWidget);
  });

  libraryTest('an optional field shows its count once typed', (
    tester,
    env,
  ) async {
    final controller = TextEditingController();
    addTearDown(controller.dispose);
    await pumpLibraryScreen(
      tester,
      env,
      _host(
        CardFieldWidget(
          label: _en.cardFieldHint,
          hint: _en.cardHintHint,
          limit: 240,
          controller: controller,
        ),
      ),
    );
    expect(find.text(_en.cardFieldCount(0, 240)), findsNothing);

    await tester.enterText(find.byType(EditableText), 'Việt');
    await tester.pump();
    expect(find.text(_en.cardFieldCount(4, 240)), findsOneWidget);
  });

  libraryTest(
    'tags: Add tag opens the input, duplicates fold, ten is the limit',
    (tester, env) async {
      await pumpLibraryScreen(tester, env, _host(const _Tags()));
      Future<void> add(String name) async {
        await tester.enterText(find.byType(EditableText), name);
        await tester.testTextInput.receiveAction(TextInputAction.done);
        await tester.pump();
      }

      expect(find.byType(EditableText), findsNothing);
      await tester.tap(find.text(_en.cardAddTag));
      await tester.pump();
      await add('Verb');
      await add('verb');
      expect(find.bySemanticsLabel(_en.cardTagRemove('Verb')), findsOneWidget);
      expect(find.text(_en.cardTagsMeta(1, 10)), findsOneWidget);

      for (var i = 0; i < 9; i++) {
        await add('tag $i');
      }
      expect(find.text(_en.cardTagLimit), findsOneWidget);
      expect(find.text(_en.cardAddTag), findsNothing);

      await tester.tap(find.bySemanticsLabel(_en.cardTagRemove('Verb')));
      await tester.pump();
      expect(find.text(_en.cardTagLimit), findsNothing);
    },
  );

  libraryTest('the footer turns a failure into an inline banner and a retry', (
    tester,
    env,
  ) async {
    var saves = 0;
    await pumpLibraryScreen(
      tester,
      env,
      Scaffold(
        bottomNavigationBar: CardEditorFooterWidget(
          caption: _en.cardCaptionKeepAdding,
          saveLabel: _en.cardSaveCard,
          hasFailed: true,
          isSaving: false,
          onCancel: () {},
          onSave: () => saves++,
        ),
      ),
    );

    expect(find.byType(MxInlineBanner), findsOneWidget);
    expect(find.text(_en.cardSaveFailedTitle), findsOneWidget);
    await tester.tap(find.widgetWithText(MxButton, _en.cardRetrySave));
    expect(saves, 1);
  });

  libraryTest('the discard dialog answers Discard or Keep editing', (
    tester,
    env,
  ) async {
    final answers = <bool>[];
    await pumpLibraryScreen(
      tester,
      env,
      Scaffold(
        body: Builder(
          builder: (context) => MxButton(
            label: 'Leave',
            onPressed: () async =>
                answers.add(await showCardDiscardDialog(context, isNew: true)),
          ),
        ),
      ),
    );
    await tester.tap(find.text('Leave'));
    await tester.pumpAndSettle();
    expect(find.text(_en.cardDiscardNewTitle), findsOneWidget);
    await tester.tap(find.text(_en.cardKeepEditing));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Leave'));
    await tester.pumpAndSettle();
    await tester.tap(find.text(_en.cardDiscard));
    await tester.pumpAndSettle();

    expect(answers, [false, true]);
  });

  libraryTest('the deck context names the path and the destination', (
    tester,
    env,
  ) async {
    final korean = await env.decks.root('Korean');
    final words = await env.decks.sub(korean.id, 'Words');
    await pumpLibraryScreen(
      tester,
      env,
      Scaffold(
        body: DeckContextHeaderWidget(
          deckId: words.id,
          currentLabel: _en.cardAddTitle,
        ),
      ),
    );

    for (final crumb in [_en.navLibrary, 'Korean', 'Words', _en.cardAddTitle]) {
      expect(
        find.descendant(
          of: find.byType(MxBreadcrumb),
          matching: find.text(crumb),
        ),
        findsOneWidget,
      );
    }
    expect(find.text('Words'), findsNWidgets(2));
  });

  libraryTest('tags and fields hold at 2x and meet the guidelines', (
    tester,
    env,
  ) async {
    await pumpLibraryScreen(tester, env, _host(const _Tags()), textScale: 2);
    await tester.tap(find.text(_en.cardAddTag));
    await tester.pump();
    await tester.enterText(find.byType(EditableText), 'từ vựng tiếng Hàn');
    await tester.testTextInput.receiveAction(TextInputAction.done);
    await tester.pump();

    expect(tester.takeException(), isNull);
    await expectAccessibleTargets(tester);
  });

  libraryTest('the deck context holds its place while the deck loads', (
    tester,
    env,
  ) async {
    final pending = StreamController<Outcome<DeckView, DeckRejection>>();
    addTearDown(pending.close);
    await pumpLibraryScreen(
      tester,
      env,
      Scaffold(
        body: DeckContextHeaderWidget(
          deckId: 'words',
          currentLabel: _en.cardAddTitle,
        ),
      ),
      overrides: [
        deckViewProvider('words').overrideWith((ref) => pending.stream),
      ],
    );

    expect(find.byType(MxSkeleton), findsWidgets);
    expect(find.byType(MxBreadcrumb), findsNothing);
  });

  libraryTest('a card field names its input once for TalkBack', (
    tester,
    env,
  ) async {
    final handle = tester.ensureSemantics();
    final controller = TextEditingController(text: 'gamsa');
    addTearDown(controller.dispose);
    await pumpLibraryScreen(
      tester,
      env,
      _host(
        CardFieldWidget(
          label: _en.cardFieldFront,
          hint: _en.cardFrontHint,
          limit: 60,
          controller: controller,
          isRequired: true,
        ),
      ),
    );

    expect(
      tester.getSemantics(find.byType(EditableText)).label,
      contains(_en.cardFieldFront),
    );
    expect(find.bySemanticsLabel(_en.cardFieldFront), findsOneWidget);
    handle.dispose();
  });
}
