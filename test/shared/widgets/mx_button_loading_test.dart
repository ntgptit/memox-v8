import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:memox/shared/widgets/mx_button.dart';
import 'package:memox/shared/widgets/mx_spinner.dart';

import '../../core/theme/token_source.dart' show contrast;
import '../../support/widget_harness.dart';

// MxButton while its work runs, and what TalkBack reads of it.

final _painted = find.descendant(
  of: find.byType(TextButton),
  matching: find.byType(Material),
);

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
      final resting = tester.widget<Material>(_painted.first);

      await pumpMx(
        tester,
        MxButton(label: 'Save', tone: tone, isLoading: true, onPressed: null),
      );
      final loading = tester.widget<Material>(_painted.first);

      expect(find.byType(MxSpinner), findsOneWidget, reason: '$tone');
      expect(loading.color, resting.color, reason: '$tone fill');
      expect(loading.shape, resting.shape, reason: '$tone edge');
      expect(
        loading.textStyle?.color,
        resting.textStyle?.color,
        reason: '$tone',
      );
    }
  });

  testWidgets('loading keeps the width, shows a spinner and ignores taps', (
    tester,
  ) async {
    var taps = 0;
    await pumpMx(tester, MxButton(label: 'Save changes', onPressed: () {}));
    final restingWidth = tester.getSize(_painted.first).width;

    await pumpMx(
      tester,
      MxButton(label: 'Save changes', isLoading: true, onPressed: () => taps++),
    );
    await tester.tap(find.byType(MxButton), warnIfMissed: false);

    expect(tester.getSize(_painted.first).width, restingWidth);
    expect(find.byType(MxSpinner), findsOneWidget);
    expect(taps, 0);
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
        final material = tester.widget<Material>(_painted.first);
        final ground = Theme.of(tester.element(find.byType(MxSpinner)))
            .scaffoldBackgroundColor;
        final fill = Color.alphaBlend(
          material.color ?? Colors.transparent,
          ground,
        );
        final ring = _ringColor(tester);

        expect(contrast(ring, fill), greaterThanOrEqualTo(3));
        expect(ring, material.textStyle!.color);
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
      isSemantics(isButton: true, hasEnabledState: true, isEnabled: false),
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

                expect(
                  tester.getCenter(find.byType(MxSpinner)).dx,
                  closeTo(tester.getCenter(_painted.first).dx, 0.01),
                );
                expect(
                  tester.getCenter(find.byType(MxSpinner)).dy,
                  closeTo(tester.getCenter(_painted.first).dy, 0.01),
                );
              },
            );
          }
        }
      }
    }
  });
}
