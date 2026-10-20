import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:memox/core/theme/app_icons.dart';
import 'package:memox/core/theme/app_palette.dart';
import 'package:memox/core/theme/color_tint.dart';
import 'package:memox/core/theme/theme_context.dart';
import 'package:memox/shared/widgets/mx_button.dart';
import 'package:memox/shared/widgets/mx_card.dart';
import 'package:memox/shared/widgets/mx_error_state.dart';

import '../../support/widget_harness.dart';

const _title = 'Could not load decks';
const _body = 'Nothing was lost. Try again in a moment.';

void main() {
  final colors = appLightColors;

  testWidgets('a 52 danger-soft tile with a 24 error glyph, 32 from the top, '
      'as the compact empty state\'s', (tester) async {
    await pumpMx(tester, const MxErrorState(title: _title, body: _body));
    final tile = find.descendant(
      of: find.byType(MxErrorState),
      matching: find.byWidgetPredicate(
        (widget) =>
            widget is DecoratedBox &&
            widget.decoration is BoxDecoration &&
            (widget.decoration as BoxDecoration).color ==
                colors.error.tintOver(colors.card),
      ),
    );

    expect(tester.getSize(tile), const Size.square(52));
    expect(
      (tester.widget<DecoratedBox>(tile).decoration as BoxDecoration)
          .borderRadius,
      tester.element(tile).radii.lg,
    );
    final glyph = tester.widget<Icon>(find.byIcon(AppIcons.alert));
    expect((glyph.size, glyph.color), (24, colors.error));
    expect(
      tester.getTopLeft(tile).dy - tester.getTopLeft(find.byType(MxCard)).dy,
      32,
    );
  });

  testWidgets(
    'section-title title, as an empty state\'s, 8 above a body-role body; '
    'no Retry by default',
    (tester) async {
      await pumpMx(tester, const MxErrorState(title: _title, body: _body));
      final title = tester.widget<Text>(find.text(_title)).style!;
      final body = tester.widget<Text>(find.text(_body)).style!;

      final texts = tester.element(find.text(_title)).texts;
      expect(
        (title.fontSize, title.fontWeight),
        (texts.sectionTitle.fontSize, texts.sectionTitle.fontWeight),
      );
      expect(title.color, colors.foreground);
      expect(
        (body.fontSize, body.height),
        (texts.body.fontSize, texts.body.height),
      );
      expect(body.color, colors.mutedForeground);
      expect(
        tester.getTopLeft(find.text(_body)).dy -
            tester.getBottomLeft(find.text(_title)).dy,
        8,
      );
      expect(find.byType(MxButton), findsNothing);
    },
  );

  testWidgets('a primary Retry with the refresh glyph, 24 below the body, '
      'as the empty state\'s action', (tester) async {
    var retries = 0;
    await pumpMx(
      tester,
      MxErrorState(
        title: _title,
        body: _body,
        retryLabel: 'Retry',
        onRetry: () => retries++,
      ),
    );
    final retry = tester.widget<MxButton>(find.byType(MxButton));

    expect((retry.tone, retry.icon), (MxButtonTone.primary, AppIcons.retry));
    expect(
      tester.getTopLeft(find.byType(MxButton)).dy -
          tester.getBottomLeft(find.text(_body)).dy,
      24,
    );
    await tester.tap(find.byType(MxButton));
    await tester.pumpAndSettle();
    expect(retries, 1);
  });

  testWidgets('retrying holds a spinner in the Retry', (tester) async {
    await pumpMx(
      tester,
      MxErrorState(
        title: _title,
        body: _body,
        retryLabel: 'Retry',
        onRetry: () {},
        isRetrying: true,
      ),
    );

    expect(tester.widget<MxButton>(find.byType(MxButton)).isLoading, isTrue);
    // The spinner keeps turning; take it off before the test ends.
    await tester.pumpWidget(const SizedBox());
  });

  test('retryLabel and onRetry come together', () {
    expect(
      () => MxErrorState(title: _title, body: _body, retryLabel: 'Retry'),
      throwsAssertionError,
    );
  });
  testWidgets('the action can carry another icon, as Close does', (
    tester,
  ) async {
    await pumpMx(
      tester,
      MxErrorState(
        title: _title,
        body: _body,
        retryLabel: 'Close',
        onRetry: () {},
        actionIcon: AppIcons.close,
      ),
    );

    expect(tester.widget<MxButton>(find.byType(MxButton)).icon, AppIcons.close);
    expect(find.byIcon(AppIcons.retry), findsNothing);
  });

  testWidgets('a network failure passes the cloud-off glyph (critique '
      '2026-09-30)', (tester) async {
    await pumpMx(
      tester,
      const MxErrorState(title: _title, body: _body, icon: AppIcons.offline),
    );
    expect(find.byIcon(AppIcons.offline), findsOneWidget);
    expect(find.byIcon(AppIcons.alert), findsNothing);
  });

  testWidgets('a null actionIcon draws the action with no glyph (critique '
      '2026-09-30 part 3c-2, R5)', (tester) async {
    await pumpMx(
      tester,
      MxErrorState(
        title: 'Stuck',
        body: 'Nothing to ask',
        retryLabel: 'Close the session',
        onRetry: () {},
        actionIcon: null,
      ),
    );

    expect(
      find.descendant(
        of: find.widgetWithText(MxButton, 'Close the session'),
        matching: find.byType(Icon),
      ),
      findsNothing,
    );
  });

  // SW-REV-006: a load failure swaps in for the skeleton in place, so it is
  // announced when it appears: the title and the body that says nothing
  // was lost, as one live region (audit 2026-10-17).
  testWidgets('the title and the body are one live region', (tester) async {
    final handle = tester.ensureSemantics();
    await pumpMx(
      tester,
      const MxErrorState(title: "Couldn't load", body: 'Nothing was lost.'),
    );
    final node = tester.getSemantics(find.text("Couldn't load"));
    expect(node, isSemantics(isLiveRegion: true));
    expect(node.label, contains("Couldn't load"));
    expect(node.label, contains('Nothing was lost.'));
    handle.dispose();
  });
}
