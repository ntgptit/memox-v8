import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:memox/core/theme/app_color_schemes.dart';
import 'package:memox/core/theme/app_decorations.dart';
import 'package:memox/core/theme/foundations/app_icons.dart';
import 'package:memox/core/theme/foundations/app_shadows.dart';
import 'package:memox/core/theme/mx_derived_colors.dart';
import 'package:memox/core/theme/mx_semantic_colors.dart';
import 'package:memox/shared/widgets/mx_button.dart';
import 'package:memox/shared/widgets/mx_floating_notice.dart';

import '../../support/widget_harness.dart';

const _message = '2 changes are kept only on this device';

Widget _width(Widget child) => SizedBox(width: 328, child: child);

MxButton _action(String label) =>
    MxButton(label: label, size: MxButtonSize.compact, onPressed: () {});

BoxDecoration _ground(WidgetTester tester) =>
    tester
            .widget<DecoratedBox>(
              find
                  .descendant(
                    of: find.byType(MxFloatingNotice),
                    matching: find.byType(DecoratedBox),
                  )
                  .first,
            )
            .decoration
        as BoxDecoration;

void main() {
  final scheme = AppColorSchemes.light;
  final semantic = MxSemanticColors.light;
  final derived = MxDerivedColors.resolve(scheme, semantic);

  testWidgets('the warning card, lifted by the overlay shadow', (tester) async {
    await pumpMx(tester, _width(const MxFloatingNotice(message: _message)));
    final glyph = tester.widget<Icon>(find.byIcon(AppIcons.alert));

    expect(
      _ground(tester),
      AppDecorations.warningCard(
        scheme,
        semantic,
      ).copyWith(boxShadow: AppShadows.overlay(scheme)),
    );
    expect((glyph.size, glyph.color), (16, derived.warningInk));
  });

  testWidgets('one action sits on the message line, at the end', (
    tester,
  ) async {
    await pumpMx(
      tester,
      _width(
        MxFloatingNotice(message: 'Waiting', actions: [_action('Details')]),
      ),
    );
    final text = tester.getRect(find.text('Waiting'));
    final action = tester.getRect(find.text('Details'));

    expect(action.left, greaterThan(text.right));
    expect((action.center.dy - text.center.dy).abs(), lessThan(1));
  });

  testWidgets('two actions go under the message, at the end', (tester) async {
    await pumpMx(
      tester,
      _width(
        MxFloatingNotice(
          message: _message,
          actions: [_action('Try again'), _action('Keep on this device')],
        ),
      ),
    );
    final text = tester.getRect(find.text(_message));
    final keep = tester.getRect(find.byType(MxButton).last);
    final card = tester.getRect(find.byType(MxFloatingNotice));

    expect(
      tester.getRect(find.byType(MxButton).first).top,
      greaterThan(text.bottom),
    );
    expect(card.right - keep.right, lessThan(20));
  });

  testWidgets('a live region that reads the message', (tester) async {
    await pumpMx(tester, _width(const MxFloatingNotice(message: _message)));

    expect(
      find.byWidgetPredicate(
        (w) => w is Semantics && (w.properties.liveRegion ?? false),
      ),
      findsOneWidget,
    );
  });
}
