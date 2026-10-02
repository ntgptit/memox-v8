import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:memox/core/theme/app_page_transitions.dart';
import 'package:memox/core/theme/app_theme.dart';

void main() {
  test('the theme routes Android through AppPageTransitionsBuilder', () {
    expect(
      buildLightTheme().pageTransitionsTheme.builders[TargetPlatform.android],
      isA<AppPageTransitionsBuilder>(),
    );
  });

  testWidgets('remove animations: the page is the child, untransformed', (
    tester,
  ) async {
    late Widget built;
    const page = SizedBox(key: ValueKey('page'));
    await tester.pumpWidget(
      MediaQuery(
        data: const MediaQueryData(disableAnimations: true),
        child: Builder(
          builder: (context) {
            final route = MaterialPageRoute<void>(builder: (_) => page);
            built = const AppPageTransitionsBuilder().buildTransitions(
              route,
              context,
              const AlwaysStoppedAnimation(0.5),
              const AlwaysStoppedAnimation(0),
              page,
            );
            return const SizedBox();
          },
        ),
      ),
    );
    expect(identical(built, page), isTrue);
  });
}
