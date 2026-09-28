import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:memox/shared/widgets/mx_dot_overline.dart';

import '../../support/widget_harness.dart';

void main() {
  testWidgets('a 6px primary dot, 4 before an overline that reads the label', (
    tester,
  ) async {
    final handle = tester.ensureSemantics();
    await pumpMx(tester, const MxDotOverline(label: 'Hôm nay'));
    final dot = find.byType(DecoratedBox);
    final decoration =
        tester.widget<DecoratedBox>(dot).decoration as BoxDecoration;
    final context = tester.element(dot);

    expect(tester.getSize(dot), const Size.square(6));
    expect(decoration.shape, BoxShape.circle);
    expect(decoration.color, Theme.of(context).colorScheme.primary);
    expect(
      tester.getTopLeft(find.text('HÔM NAY')).dx - tester.getTopRight(dot).dx,
      4,
    );
    expect(
      tester.getSemantics(find.text('HÔM NAY')),
      isSemantics(label: 'Hôm nay'),
    );
    handle.dispose();
  });
}
