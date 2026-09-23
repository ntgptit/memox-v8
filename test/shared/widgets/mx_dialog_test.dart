import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:memox/core/theme/app_color_schemes.dart';
import 'package:memox/core/theme/foundations/app_shadows.dart';
import 'package:memox/shared/widgets/mx_button.dart';
import 'package:memox/shared/widgets/mx_dialog.dart';
import 'package:memox/shared/widgets/mx_sheet_actions.dart';

import '../../support/widget_harness.dart';

Material _surface(WidgetTester tester) => tester.widget<Material>(
  find
      .descendant(of: find.byType(MxDialog), matching: find.byType(Material))
      .first,
);

Widget _still(Widget child) => Builder(
  builder: (context) => MediaQuery(
    data: MediaQuery.of(context).copyWith(disableAnimations: true),
    child: child,
  ),
);

void main() {
  final scheme = AppColorSchemes.light;

  testWidgets('surfaceContainerHigh at radius 20 with the overlay shadow', (
    tester,
  ) async {
    await pumpMx(tester, const MxDialog(title: 'Delete deck?'));
    final shadow =
        (tester
                    .widget<DecoratedBox>(
                      find
                          .descendant(
                            of: find.byType(MxDialog),
                            matching: find.byType(DecoratedBox),
                          )
                          .first,
                    )
                    .decoration
                as BoxDecoration)
            .boxShadow;

    expect(_surface(tester).color, scheme.surfaceContainerHigh);
    expect(
      (_surface(tester).shape! as RoundedRectangleBorder).borderRadius,
      BorderRadius.circular(20),
    );
    expect(shadow, AppShadows.overlay(scheme));
  });

  testWidgets('width: the column 20 in from each edge, capped at 340/320/300', (
    tester,
  ) async {
    await pumpMx(tester, const MxDialog(title: 'Delete deck?'));
    expect(tester.getSize(find.byType(Material).last).width, 320);

    tester.view.physicalSize = const Size(600, 800);
    for (final (width, cap) in [
      (MxDialogWidth.large, 340.0),
      (MxDialogWidth.medium, 320.0),
      (MxDialogWidth.small, 300.0),
    ]) {
      await tester.pumpWidget(const SizedBox());
      await pumpMxAt(tester, MxDialog(title: 'Delete deck?', width: width));

      expect(tester.getSize(find.byType(Material).last).width, cap);
    }
  });

  testWidgets('title 16/700 over a 14 body, 20 in; the route is named', (
    tester,
  ) async {
    final handle = tester.ensureSemantics();
    await pumpMx(
      tester,
      const MxDialog(title: 'Delete deck?', body: 'Its cards move to Trash.'),
    );
    final surface = tester.getTopLeft(find.byType(Material).last);

    expect(tester.widget<Text>(find.text('Delete deck?')).style!.fontSize, 16);
    expect(
      tester.widget<Text>(find.text('Its cards move to Trash.')).style!.color,
      scheme.onSurface,
    );
    expect(
      tester.getTopLeft(find.text('Delete deck?')) - surface,
      const Offset(20, 20),
    );
    expect(
      tester.getSemantics(find.byType(MxDialog)),
      isSemantics(label: 'Delete deck?', namesRoute: true, scopesRoute: true),
    );
    handle.dispose();
  });

  testWidgets('at 2x a long body scrolls and the actions stay', (tester) async {
    await pumpMx(
      tester,
      MxDialog(
        title: 'Delete deck?',
        body: List.filled(40, 'Its cards move to Trash.').join(' '),
        actions: MxSheetActions(
          cancelLabel: 'Cancel',
          onCancel: () {},
          confirmLabel: 'Delete',
          onConfirm: () {},
        ),
      ),
      textScale: 2,
    );

    expect(tester.takeException(), isNull);
    expect(
      tester.getBottomLeft(find.byType(MxSheetActions)).dy,
      lessThanOrEqualTo(800),
    );
  });

  testWidgets('showMxDialog: a 45% scrim; a scrim tap returns null (RF2)', (
    tester,
  ) async {
    String? result = 'unset';
    await pumpMx(
      tester,
      Builder(
        builder: (context) => MxButton(
          label: 'Open',
          onPressed: () async => result = await showMxDialog<String>(
            context,
            builder: (_) => const MxDialog(title: 'Delete deck?'),
          ),
        ),
      ),
    );
    await tester.tap(find.text('Open'));
    await tester.pumpAndSettle();

    expect(find.byType(MxDialog), findsOneWidget);
    expect(
      tester.widget<ModalBarrier>(find.byType(ModalBarrier).last).color,
      scheme.scrim.withValues(alpha: 0.45),
    );
    await tester.tapAt(const Offset(8, 8));
    await tester.pumpAndSettle();
    expect(find.byType(MxDialog), findsNothing);
    expect(result, isNull);
  });

  testWidgets('reduced motion opens with no transition (RF4)', (tester) async {
    await pumpMx(
      tester,
      _still(
        Builder(
          builder: (context) => MxButton(
            label: 'Open',
            onPressed: () => showMxDialog<void>(
              context,
              builder: (_) => const MxDialog(title: 'Delete deck?'),
            ),
          ),
        ),
      ),
    );
    await tester.tap(find.text('Open'));
    await tester.pump();

    expect(
      tester
          .widget<FadeTransition>(
            find
                .ancestor(
                  of: find.byType(MxDialog),
                  matching: find.byType(FadeTransition),
                )
                .first,
          )
          .opacity
          .value,
      1,
    );
  });
}
