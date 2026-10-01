import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:memox/core/theme/app_color_schemes.dart';
import 'package:memox/core/theme/foundations/app_icons.dart';
import 'package:memox/core/theme/mx_derived_colors.dart';
import 'package:memox/core/theme/mx_semantic_colors.dart';
import 'package:memox/shared/widgets/mx_button.dart';
import 'package:memox/shared/widgets/mx_card.dart';
import 'package:memox/shared/widgets/mx_error_state.dart';

import '../../support/widget_harness.dart';

const _title = 'Could not load decks';
const _body = 'Nothing was lost. Try again in a moment.';

void main() {
  final scheme = AppColorSchemes.light;

  testWidgets('a 52 danger-soft tile with a 24 error glyph, 40 from the top', (
    tester,
  ) async {
    final derived = MxDerivedColors.resolve(scheme, MxSemanticColors.light);
    await pumpMx(tester, const MxErrorState(title: _title, body: _body));
    final tile = find.descendant(
      of: find.byType(MxErrorState),
      matching: find.byWidgetPredicate(
        (widget) =>
            widget is DecoratedBox &&
            (widget.decoration as BoxDecoration).color == derived.dangerSoft,
      ),
    );

    expect(tester.getSize(tile), const Size.square(52));
    expect(
      (tester.widget<DecoratedBox>(tile).decoration as BoxDecoration)
          .borderRadius,
      BorderRadius.circular(16),
    );
    final glyph = tester.widget<Icon>(find.byIcon(AppIcons.alert));
    expect((glyph.size, glyph.color), (24, scheme.error));
    expect(
      tester.getTopLeft(tile).dy - tester.getTopLeft(find.byType(MxCard)).dy,
      40,
    );
  });

  testWidgets('title 16/700, 4 above a 14 body at 1.55; no Retry by default', (
    tester,
  ) async {
    await pumpMx(tester, const MxErrorState(title: _title, body: _body));
    final title = tester.widget<Text>(find.text(_title)).style!;
    final body = tester.widget<Text>(find.text(_body)).style!;

    expect((title.fontSize, title.fontWeight), (16, FontWeight.w700));
    expect(title.color, scheme.onSurface);
    expect((body.fontSize, body.height), (14, 1.55));
    expect(body.color, scheme.onSurfaceVariant);
    expect(
      tester.getTopLeft(find.text(_body)).dy -
          tester.getBottomLeft(find.text(_title)).dy,
      4,
    );
    expect(find.byType(MxButton), findsNothing);
  });

  testWidgets('a primary Retry with the refresh glyph, 16 below the body', (
    tester,
  ) async {
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
      16,
    );
    await tester.tap(find.byType(MxButton));
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
}
