import 'package:flutter/material.dart';
import 'package:memox/core/theme/theme_context.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:memox/core/theme/app_palette.dart';
import 'package:memox/core/theme/app_icons.dart';
import 'package:memox/features/card/presentation/widgets/items/card_add_details_widget.dart';
import 'package:memox/features/card/presentation/widgets/overlays/card_discard_dialog_widget.dart';
import 'package:memox/features/card/presentation/widgets/sections/card_editor_footer_widget.dart';
import 'package:memox/features/card/presentation/widgets/sections/card_field_widget.dart';
import 'package:memox/features/card/presentation/widgets/sections/card_optional_fields_widget.dart';
import 'package:memox/features/card/presentation/widgets/sections/card_tag_editor_widget.dart';
import 'package:memox/l10n/generated/app_localizations.dart';
import 'package:memox/l10n/meta_line.dart';
import 'package:memox/shared/widgets/mx_button.dart';
import 'package:memox/shared/widgets/mx_inline_banner.dart';
import 'package:memox/shared/widgets/mx_list_section_header.dart';

import '../../../support/forui_expect.dart';
import '../../../support/library_harness.dart';
import '../../../support/widget_harness.dart';
import '../../../support/wrap_rule.dart';

import 'package:forui/forui.dart';

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

  libraryTest('the count ends the row under the box, in the error tone with '
      'the field\'s error', (tester, env) async {
    final controller = TextEditingController(text: 'a' * 61);
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
          errorText: _en.cardRejectionFrontTooLong,
        ),
      ),
    );

    final count = find.text(_en.cardFieldCount(61, 60));
    expect(
      tester.getTopLeft(count).dy,
      greaterThanOrEqualTo(
        tester.getBottomLeft(fieldBox(find.byType(FTextField))).dy,
      ),
    );
    expect(
      tester.getTopRight(count).dx,
      tester.getTopRight(find.byType(FTextField)).dx,
    );
    expect(textColor(tester, count), tester.element(count).colors.error);
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
      expectBreaksOnlyBetweenWords(
        tester,
        find.text(metaLine(_en.cardTagsMeta(1, 10))),
      );

      for (var i = 0; i < 9; i++) {
        await add('tag $i');
      }
      expect(find.text(_en.cardTagLimit), findsOneWidget);
      expect(find.text(_en.cardAddTag), findsNothing);

      await tester.tap(find.bySemanticsLabel(_en.cardTagRemove('Verb')));
      await tester.pump();
      expect(find.text(_en.cardTagLimit), findsNothing);
      await tester.pump(const Duration(milliseconds: 200));
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
    await tester.pump(const Duration(milliseconds: 200));
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

  libraryTest('tags and fields meet the guidelines', (tester, env) async {
    await pumpLibraryScreen(tester, env, _host(const _Tags()));
    await tester.tap(find.text(_en.cardAddTag));
    await tester.pump();
    await tester.enterText(find.byType(EditableText), 'từ vựng tiếng Hàn');
    await tester.testTextInput.receiveAction(TextInputAction.done);
    await tester.pump();

    expect(tester.takeException(), isNull);
    await expectAccessibleTargets(tester);
    await tester.pump(const Duration(milliseconds: 200));
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

  libraryTest('Add details names its fields and opens them', (
    tester,
    env,
  ) async {
    final handle = tester.ensureSemantics();
    var opened = 0;
    await pumpLibraryScreen(
      tester,
      env,
      _host(CardAddDetailsWidget(onPressed: () => opened++)),
    );

    expect(find.textContaining(_en.cardAddDetails), findsOneWidget);
    expect(
      find.textContaining(metaLine(_en.cardAddDetailsFields)),
      findsOneWidget,
    );
    // A plus, not the sparkle, which implies AI (critique 2026-09-30 3a).
    final disclosure = find.byType(CardAddDetailsWidget);
    expect(
      find.descendant(of: disclosure, matching: find.byIcon(AppIcons.add)),
      findsOneWidget,
    );
    expect(find.byIcon(FLucideIcons.sparkles), findsNothing);
    expect(
      tester.getSize(find.byType(CardAddDetailsWidget)).height,
      greaterThanOrEqualTo(48),
    );
    expect(
      find.bySemanticsLabel(
        RegExp(
          '${RegExp.escape(_en.cardAddDetails)}.*'
          '${RegExp.escape(metaLine(_en.cardAddDetailsFields))}',
          dotAll: true,
        ),
      ),
      findsOneWidget,
    );

    await tester.tap(find.byType(CardAddDetailsWidget));
    expect(opened, 1);
    handle.dispose();
    await tester.pump(const Duration(milliseconds: 200));
  });

  libraryTest('the details disclosure is edged in the control edge, as the '
      'fields beside it are (DEV-166)', (tester, env) async {
    await pumpLibraryScreen(
      tester,
      env,
      _host(CardAddDetailsWidget(onPressed: () {})),
    );
    final box =
        tester
                .widget<Container>(
                  find
                      .descendant(
                        of: find.byType(CardAddDetailsWidget),
                        matching: find.byType(Container),
                      )
                      .first,
                )
                .decoration!
            as BoxDecoration;
    expect((box.border! as Border).top.color, appLightColors.border);
  });

  libraryTest('field labels are sentence case; Required is a caption '
      '(critique 2026-09-30 part 2, P3)', (tester, env) async {
    final controller = TextEditingController();
    addTearDown(controller.dispose);
    await pumpLibraryScreen(
      tester,
      env,
      _host(
        Column(
          children: [
            CardFieldWidget(
              label: _en.cardFieldFront,
              hint: _en.cardFrontHint,
              limit: 60,
              controller: controller,
              isRequired: true,
            ),
            const _Tags(),
          ],
        ),
      ),
    );

    for (final (text, role) in [
      (_en.cardFieldFront, 'paintedLabel'),
      (_en.cardTags, 'fieldLabel'),
      (_en.cardRequiredLegend, 'requiredMarker'),
    ]) {
      final label = find.text(text);
      final element = tester.element(label);
      final texts = element.texts;
      // A field's label is ForUI's form-field label; the section header's
      // stays in the label role.
      if (role == 'paintedLabel') {
        expectForUiFieldLabel(tester, label);
        continue;
      }
      expect(tester.widget<Text>(label).style, switch (role) {
        'fieldLabel' => texts.label,
        _ => texts.body.copyWith(color: element.colors.primary),
      }, reason: text);
    }
    expect(find.text(_en.cardFieldFront.toUpperCase()), findsNothing);
  });

  // SW-REV-011: the edit form names its optional group with the shared
  // section header, a heading to TalkBack like every other.
  libraryTest(
    'the optional details group is introduced by the section header',
    (tester, env) async {
      final handle = tester.ensureSemantics();
      final inputs = [for (var i = 0; i < 3; i++) TextEditingController()];
      addTearDown(() {
        for (final input in inputs) {
          input.dispose();
        }
      });
      CardOptionalInput input(TextEditingController controller) =>
          (controller: controller, errorText: null, onChanged: () {});
      await pumpLibraryScreen(
        tester,
        env,
        _host(
          CardOptionalFieldsWidget(
            isOpen: true,
            hasHeader: true,
            onOpen: () {},
            example: input(inputs[0]),
            hint: input(inputs[1]),
            pronunciation: input(inputs[2]),
          ),
        ),
      );

      expect(
        find.widgetWithText(
          MxListSectionHeader,
          _en.cardOptionalDetails.toUpperCase(),
        ),
        findsOneWidget,
      );
      handle.dispose();
    },
  );
}
