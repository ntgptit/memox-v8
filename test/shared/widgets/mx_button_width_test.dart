import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:forui/forui.dart';
import 'package:memox/core/theme/app_icons.dart';
import 'package:memox/shared/widgets/mx_button.dart';

import '../../support/forui_expect.dart';
import '../../support/widget_harness.dart';

final _button = find.byType(FButton);

// MxButton's measured width: the footer pair and the action rows lay out on
// it (naturalWidth), so it must match what ForUI paints.
void main() {
  testWidgets('naturalWidth is the one-line label plus icon and padding', (
    tester,
  ) async {
    late double measured;
    const button = MxButton(
      label: 'Restore',
      icon: AppIcons.restore,
      onPressed: null,
    );
    await pumpMx(
      tester,
      Builder(
        builder: (context) {
          measured = button.naturalWidth(context);
          return const UnconstrainedBox(child: button);
        },
      ),
    );
    // Unconstrained, the button lays out at its natural width.
    expect(measured, tester.getSize(_button).width.ceilToDouble());
  });

  testWidgets('naturalWidth of a loading button still measures its label', (
    tester,
  ) async {
    late double idle;
    late double loading;
    await pumpMx(
      tester,
      Builder(
        builder: (context) {
          idle = MxButton(
            label: 'Save',
            onPressed: () {},
          ).naturalWidth(context);
          loading = MxButton(
            label: 'Save',
            isLoading: true,
            onPressed: () {},
          ).naturalWidth(context);
          return const SizedBox();
        },
      ),
    );
    expect(loading, idle);
  });

  testWidgets("a brand mark is painted at 18 in the icon's place, and "
      'TalkBack reads the label only', (tester) async {
    await pumpMx(
      tester,
      MxButton(
        label: 'Continue with Google',
        mark: const AssetImage('assets/brand/google_g.png'),
        onPressed: () {},
      ),
    );
    final image = find.byType(Image);
    final spacing = forUiTheme(
      tester,
      _button,
    ).buttonStyles.primary.lg.contentStyle.spacing;

    expect(tester.getSize(image), const Size.square(18));
    expect(
      tester.getRect(find.text('Continue with Google')).left -
          tester.getRect(image).right,
      spacing,
    );
    expect(tester.widget<Image>(image).excludeFromSemantics, isTrue);
    expect(find.bySemanticsLabel('Continue with Google'), findsOneWidget);
  });

  testWidgets('naturalWidth counts the brand mark and its gap', (tester) async {
    late double plain;
    late double marked;
    late double spacing;
    await pumpMx(
      tester,
      Builder(
        builder: (context) {
          spacing = FTheme.of(context)
              .buttonStyles
              .primary
              .lg
              .contentStyle
              .spacing;
          plain = MxButton(label: 'Go', onPressed: () {}).naturalWidth(context);
          marked = MxButton(
            label: 'Go',
            mark: const AssetImage('assets/brand/google_g.png'),
            onPressed: () {},
          ).naturalWidth(context);
          return const SizedBox();
        },
      ),
    );

    expect(marked - plain, 18 + spacing);
  });
}
