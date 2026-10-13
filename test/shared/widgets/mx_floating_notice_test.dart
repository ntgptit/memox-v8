import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:memox/core/theme/color_tint.dart';
import 'package:memox/core/theme/generated/mx_colors_extension.g.dart';
import 'package:memox/core/theme/generated/color_schemes.g.dart';
import 'package:memox/core/theme/app_icons.dart';
import 'package:memox/shared/widgets/mx_button.dart';
import 'package:memox/shared/widgets/mx_floating_notice.dart';

import '../../support/widget_harness.dart';

const _message = '2 changes are kept only on this device';

Widget _width(Widget child) => SizedBox(width: 328, child: child);

MxButton _action(String label) =>
    MxButton(label: label, size: MxButtonSize.small, onPressed: () {});

void main() {
  final scheme = lightColorScheme;
  const mx = MxColorsExtension.light;

  testWidgets('the warning card, lifted by the overlay shadow', (tester) async {
    await pumpMx(tester, _width(const MxFloatingNotice(message: _message)));
    final glyph = tester.widget<Icon>(find.byIcon(AppIcons.alert));

    final ground = tester.widget<Material>(
      find
          .descendant(
            of: find.byType(MxFloatingNotice),
            matching: find.byType(Material),
          )
          .first,
    );
    expect(ground.color, mx.warning.tintOver(scheme.surface));
    expect(ground.elevation, greaterThan(0));
    expect((glyph.size, glyph.color), (16, mx.warningContainer));
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
