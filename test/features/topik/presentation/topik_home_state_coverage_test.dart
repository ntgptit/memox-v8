import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:memox/features/topik/domain/models/topik_catalog_model.dart';
import 'package:memox/features/topik/presentation/providers/topik_catalog_provider.dart';
import 'package:memox/features/topik/presentation/screens/topik_home_screen.dart';
import 'package:memox/shared/widgets/mx_error_state.dart';
import 'package:memox/shared/widgets/mx_list_row.dart';

import '../../../support/library_harness.dart';
import '../../../support/topik_screen_fixtures.dart';

// The States rows of screen 34 (TOPIK home) whose detail file cites no
// executed test: "error after data".

void main() {
  libraryTest(
    'error after data: a read that errors after the levels were shown '
    'replaces them with the error; Retry brings them back',
    (tester, env) async {
      final entries = topikCatalogEntriesOf(topikScreenTests(), const {});
      final reads = <StreamController<List<TopikCatalogEntry>>>[];
      await pumpLibraryScreen(
        tester,
        env,
        TopikHomeScreen(onOpenLevel: (_) {}),
        overrides: [
          topikCatalogProvider.overrideWith((ref) {
            final read = StreamController<List<TopikCatalogEntry>>();
            reads.add(read);
            ref.onDispose(read.close);
            return read.stream;
          }),
        ],
      );
      reads.single.add(entries);
      await tester.pumpAndSettle();

      expect(find.byType(MxListRow), findsNWidgets(2));
      expect(find.byType(MxErrorState), findsNothing);

      reads.single.addError(StateError('the read died'));
      await tester.pumpAndSettle();

      expect(find.byType(MxErrorState), findsOneWidget);
      expect(find.byType(MxListRow), findsNothing);
      expect(find.text('Nothing was lost. Try again.'), findsOneWidget);
      expect(find.textContaining('read died'), findsNothing);

      await tester.tap(find.text('Retry'));
      await tester.pump();
      reads.last.add(entries);
      await tester.pumpAndSettle();

      expect(reads, hasLength(2));
      expect(find.byType(MxErrorState), findsNothing);
      expect(find.byType(MxListRow), findsNWidgets(2));
    },
  );
}
