@Tags(['golden'])
library;

import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:memox/features/card/presentation/widgets/overlays/card_delete_dialog_widget.dart';

import '../../../support/golden_harness.dart';
import '../../../support/library_harness.dart';

// "Move 12 cards to Trash" on a 360dp phone, in English, light and dark
// (SP2a audit M3): the pair stacks, so the label is whole.

final _ids = {for (var i = 0; i < 12; i++) 'card$i'};

final _host = Scaffold(
  body: Builder(
    builder: (context) => Center(
      child: TextButton(
        onPressed: () =>
            unawaited(showDeleteCardsDialog(context, cardIds: _ids)),
        child: const Text('go'),
      ),
    ),
  ),
);

void main() {
  for (final brightness in Brightness.values) {
    final theme = brightness.name;
    libraryTest('delete dialog with twelve cards, $theme', (tester, env) async {
      await withRealShadows(() async {
        await pumpLibraryGolden(tester, env, _host, brightness);
        await tester.tap(find.text('go'));
        await tester.pumpAndSettle();
        await expectBoundaryGolden(
          tester,
          'goldens/card_delete_count_$theme.png',
        );
      });
    });
  }
}
