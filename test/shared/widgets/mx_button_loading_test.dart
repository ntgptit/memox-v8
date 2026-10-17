import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:forui/forui.dart';
import 'package:memox/shared/widgets/mx_button.dart';
import 'package:memox/shared/widgets/mx_spinner.dart';

import '../../support/forui_expect.dart';
import '../../support/widget_harness.dart';

// MxButton while its work runs, and what TalkBack reads of it.

final _button = find.byType(FButton);

double contrast(Color a, Color b) {
  final la = a.computeLuminance();
  final lb = b.computeLuminance();
  final (light, dark) = la > lb ? (la, lb) : (lb, la);
  return (light + 0.05) / (dark + 0.05);
}

// The painter is private to the spinner, so the ring colour is read untyped.
Color _ringColor(WidgetTester tester) {
  final paint = tester.widget<CustomPaint>(
    find.descendant(
      of: find.byType(MxSpinner),
      matching: find.byType(CustomPaint),
    ),
  );
  return (paint.painter! as dynamic).color as Color;
}

void main() {
  // Work in progress is not a control that cannot be used: a caller that
  // also nulls onPressed while loading still gets the button at full
  // strength, its fill, its edge and its foreground as at rest (shared
  // widgets review 2026-10-07, SW-REV-003).
  testWidgets('loading is never dimmed, even with onPressed null', (
    tester,
  ) async {
    for (final tone in MxButtonTone.values) {
      await pumpMx(
        tester,
        MxButton(label: 'Save', tone: tone, onPressed: () {}),
      );
      final resting = paintedDecoration(tester, _button);
      final restingEdge = paintedSide(tester, _button);

      await pumpMx(
        tester,
        MxButton(label: 'Save', tone: tone, isLoading: true, onPressed: null),
      );
      final loading = paintedDecoration(tester, _button);

      expect(find.byType(MxSpinner), findsOneWidget, reason: '$tone');
      expect(loading.color, resting.color, reason: '$tone fill');
      expect(paintedSide(tester, _button), restingEdge, reason: '$tone edge');
      // The spinner keeps turning; take it off before the test ends.
      await tester.pumpWidget(const SizedBox());
    }
  });

  testWidgets('loading keeps the resting foreground and spinner colour, '
      'even with onPressed null', (tester) async {
    for (final tone in MxButtonTone.values) {
      await pumpMx(
        tester,
        MxButton(label: 'Save', tone: tone, onPressed: () {}),
      );
      final restingInk = textColor(tester, find.text('Save'));

      await pumpMx(
        tester,
        MxButton(label: 'Save', tone: tone, isLoading: true, onPressed: null),
      );

      expect(
        textColor(tester, find.text('Save')),
        restingInk,
        reason: '$tone label',
      );
      expect(_ringColor(tester), restingInk, reason: '$tone spinner');
      await tester.pumpWidget(const SizedBox());
    }
  });

  testWidgets('loading keeps the width, shows a spinner and ignores taps', (
    tester,
  ) async {
    var taps = 0;
    await pumpMx(tester, MxButton(label: 'Save changes', onPressed: () {}));
    final restingWidth = tester.getSize(_button).width;

    await pumpMx(
      tester,
      MxButton(label: 'Save changes', isLoading: true, onPressed: () => taps++),
    );
    await tester.tap(find.byType(MxButton), warnIfMissed: false);
    await tester.pump(const Duration(seconds: 1));

    expect(tester.getSize(_button).width, restingWidth);
    expect(find.byType(MxSpinner), findsOneWidget);
    expect(taps, 0);
    await tester.pumpWidget(const SizedBox());
  });

  // M3F-02 (owner 2026-10-15, supersedes ruling O2): the spinner is drawn in
  // the colour the tone paints its label with, so it is as legible as the
  // label it replaces, on every fill and in both themes.
  for (final brightness in Brightness.values) {
    for (final tone in MxButtonTone.values) {
      testWidgets('M3F-02: ${tone.name} spins in its foreground, 3:1 on its '
          'fill (${brightness.name})', (tester) async {
        await pumpMx(
          tester,
          MxButton(
            label: 'Save',
            tone: tone,
            isLoading: true,
            onPressed: () {},
          ),
          brightness: brightness,
        );
        final ground = forUiTheme(tester, _button).colors.background;
        final fill = Color.alphaBlend(
          paintedDecoration(tester, _button).color ?? Colors.transparent,
          ground,
        );
        final ring = _ringColor(tester);

        expect(contrast(ring, fill), greaterThanOrEqualTo(3));
        expect(ring, textColor(tester, find.text('Save')));
        await tester.pumpWidget(const SizedBox());
      });
    }
  }

  testWidgets('a loading button keeps its name for TalkBack', (tester) async {
    final handle = tester.ensureSemantics();
    await pumpMx(
      tester,
      MxButton(label: 'Save', isLoading: true, onPressed: () {}),
    );

    expect(find.bySemanticsLabel('Save'), findsOneWidget);
    await tester.pumpWidget(const SizedBox());
    handle.dispose();
  });

  // SW-REV-005: a caller that needs TalkBack to read more than the painted
  // label names it here, and the button keeps its tap and its state.
  testWidgets('semanticLabel: one node with the label, the tap and the state', (
    tester,
  ) async {
    final handle = tester.ensureSemantics();
    await pumpMx(
      tester,
      MxButton(
        label: '20:00',
        semanticLabel: 'Reminder time, 20:00',
        size: MxButtonSize.small,
        onPressed: () {},
      ),
    );
    expect(
      tester.getSemantics(find.bySemanticsLabel('Reminder time, 20:00')),
      isSemantics(
        isButton: true,
        hasTapAction: true,
        hasEnabledState: true,
        isEnabled: true,
        hasSelectedState: true,
      ),
    );

    await pumpMx(
      tester,
      const MxButton(
        label: '20:00',
        semanticLabel: 'Reminder time, 20:00',
        size: MxButtonSize.small,
        onPressed: null,
      ),
    );
    expect(
      tester.getSemantics(find.bySemanticsLabel('Reminder time, 20:00')),
      isSemantics(
        isButton: true,
        hasEnabledState: true,
        isEnabled: false,
        hasSelectedState: true,
      ),
    );
    handle.dispose();
  });

  group('a loading spinner sits on the centre of the whole button', () {
    // The padding beside a glyph is asymmetric (start 16, end 24 for filled
    // and outlined), so the content box is not centred on the button.
    for (final direction in TextDirection.values) {
      for (final size in [
        MxButtonSize.regular,
        MxButtonSize.small,
        MxButtonSize.chip,
        MxButtonSize.study,
      ]) {
        for (final tone in [
          MxButtonTone.primary,
          MxButtonTone.outline,
          MxButtonTone.text,
        ]) {
          for (final isBlock in [false, true]) {
            testWidgets(
              '${tone.name} ${size.name} with an icon, ${direction.name}'
              '${isBlock ? ', block' : ''}',
              (tester) async {
                await pumpMx(
                  tester,
                  Directionality(
                    textDirection: direction,
                    child: MxButton(
                      label: 'Start studying',
                      icon: Icons.play_arrow,
                      tone: tone,
                      size: size,
                      isBlock: isBlock,
                      isLoading: true,
                      onPressed: () {},
                    ),
                  ),
                );

                final painted = paintedRect(tester, _button);
                expect(
                  tester.getCenter(find.byType(MxSpinner)).dx,
                  closeTo(painted.center.dx, 0.01),
                );
                expect(
                  tester.getCenter(find.byType(MxSpinner)).dy,
                  closeTo(painted.center.dy, 0.01),
                );
                await tester.pumpWidget(const SizedBox());
              },
            );
          }
        }
      }
    }
  });
}
