import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:memox/core/theme/foundations/app_size.dart';
import 'package:memox/shared/widgets/mx_button.dart';
import 'package:memox/shared/widgets/mx_error_state.dart';

import 'support/mx_harness.dart';

void main() {
  testWidgets('a load failure offers Retry', (tester) async {
    var retries = 0;
    await pumpMx(
      tester,
      SizedBox(
        width: 360,
        child: MxErrorState(
          title: "Couldn't load your library",
          message: 'Nothing was lost. Try again in a moment.',
          retryLabel: 'Retry',
          onRetry: () => retries++,
        ),
      ),
    );
    expect(find.byIcon(Icons.error_outline), findsOneWidget);
    await tester.tap(find.text('Retry'));
    expect(retries, 1);
    expect(
      tester.getSize(
        find
            .descendant(
              of: find.byType(MxErrorState),
              matching: find.byType(SizedBox),
            )
            .first,
      ),
      const Size.square(AppSize.emptyTile),
    );
  });

  testWidgets('without Retry it is the not-found form', (tester) async {
    await pumpMx(
      tester,
      const SizedBox(
        width: 360,
        child: MxErrorState(title: 'This deck is gone'),
      ),
    );
    expect(find.byType(MxButton), findsNothing);
  });

  testWidgets('a network failure shows cloud-off', (tester) async {
    await pumpMx(
      tester,
      SizedBox(
        width: 360,
        child: MxErrorState(
          title: "Couldn't reach the server",
          retryLabel: 'Retry',
          onRetry: () {},
          isNetwork: true,
        ),
      ),
    );
    expect(find.byIcon(Icons.cloud_off_outlined), findsOneWidget);
  });
}
