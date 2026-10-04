@Tags(['golden'])
library;

import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:memox/features/tags/presentation/screens/tags_screen.dart';
import 'package:memox/features/tags/presentation/widgets/overlays/tag_rename_dialog_widget.dart';
import 'package:memox/l10n/generated/app_localizations.dart';

import '../../../support/golden_harness.dart';
import '../../../support/library_harness.dart';
import '../../../support/tag_screen_fixtures.dart';

// Screen 05 (FE-B2) against the kit's twelve frames, plus the read error
// the kit does not draw (D10). The catalog is kit 05's sixteen tags, in
// the store's folded order (BR-TAG-003).

final _en = lookupAppLocalizations(const Locale('en'));

void main() {
  for (final brightness in Brightness.values) {
    final theme = brightness.name;

    Future<void> shoot(
      WidgetTester tester,
      LibraryEnv env,
      String name, {
      bool isSeeded = true,
      void Function(TagRepositoryFake store)? arrange,
      Future<void> Function(TagRepositoryFake store)? before,
    }) async {
      if (isSeeded) await seedTags(env);
      final store = TagRepositoryFake(env);
      arrange?.call(store);
      await withRealShadows(() async {
        await pumpLibraryGolden(
          tester,
          env,
          TagsScreen(onFindCards: (_) {}),
          brightness,
          overrides: [store.asOverride],
        );
        await before?.call(store);
        await expectBoundaryGolden(tester, 'goldens/tags_${name}_$theme.png');
      });
    }

    Future<void> openActions(WidgetTester tester, String tag) async {
      await tester.tap(find.byTooltip(_en.tagsRowActions(tag)));
      await tester.pumpAndSettle();
    }

    Future<void> openRename(WidgetTester tester, String name) async {
      await openActions(tester, 'hay nhầm');
      await tester.tap(find.text(_en.tagsRename));
      await tester.pumpAndSettle();
      await tester.enterText(find.byType(TextField).last, name);
      await tester.pump(tagRenameSettle);
      await tester.pumpAndSettle();
    }

    Future<void> openDelete(WidgetTester tester) async {
      await openActions(tester, 'hay nhầm');
      await tester.tap(find.text(_en.tagsDelete));
      await tester.pumpAndSettle();
    }

    libraryTest('tags, loaded, $theme', (tester, env) async {
      await shoot(tester, env, 'loaded');
    });

    libraryTest('tags, loading, $theme', (tester, env) async {
      final loaded = Completer<void>();
      await shoot(
        tester,
        env,
        'loading',
        arrange: (store) => store.loaded = loaded.future,
      );
      loaded.complete();
    });

    libraryTest('tags, empty, $theme', (tester, env) async {
      await shoot(tester, env, 'empty', isSeeded: false);
    });

    libraryTest('tags, searchEmpty, $theme', (tester, env) async {
      await shoot(
        tester,
        env,
        'search_empty',
        before: (_) async {
          await tester.enterText(find.byType(TextField), 'phras');
          await tester.pumpAndSettle();
        },
      );
    });

    libraryTest('tags, sheet, $theme', (tester, env) async {
      await shoot(
        tester,
        env,
        'sheet',
        before: (_) => openActions(tester, 'hay nhầm'),
      );
    });

    libraryTest('tags, rename, $theme', (tester, env) async {
      await shoot(
        tester,
        env,
        'rename',
        before: (_) => openRename(tester, 'humans'),
      );
    });

    libraryTest('tags, renameMerge, $theme', (tester, env) async {
      await shoot(
        tester,
        env,
        'rename_merge',
        before: (_) => openRename(tester, 'ngữ pháp'),
      );
    });

    libraryTest('tags, nameTooLong, $theme', (tester, env) async {
      await shoot(
        tester,
        env,
        'name_too_long',
        before: (_) => openRename(
          tester,
          'Động từ bất quy tắc thường gặp trong đề thi TOPIK II phần đọc',
        ),
      );
    });

    libraryTest('tags, del, $theme', (tester, env) async {
      await shoot(tester, env, 'del', before: (_) => openDelete(tester));
    });

    libraryTest('tags, busy, $theme', (tester, env) async {
      late TagRepositoryFake held;
      await shoot(
        tester,
        env,
        'busy',
        before: (store) async {
          held = store..hold = Completer<void>();
          await openDelete(tester);
          await tester.tap(find.text(_en.tagsDeleteConfirm(14)));
          await tester.pump(const Duration(milliseconds: 300));
          await tester.pump(const Duration(milliseconds: 300));
        },
      );
      held.hold!.complete();
      await tester.pumpAndSettle();
    });

    libraryTest('tags, opError, $theme', (tester, env) async {
      await shoot(
        tester,
        env,
        'op_error',
        before: (store) async {
          store.failsWrites = true;
          await openRename(tester, 'humans');
          await tester.tap(find.text(_en.tagsRenameConfirm));
          await tester.pumpAndSettle();
        },
      );
    });

    libraryTest('tags, tagGone, $theme', (tester, env) async {
      await shoot(
        tester,
        env,
        'tag_gone',
        before: (_) async {
          await openDelete(tester);
          await env.db.customStatement(
            "DELETE FROM card_tags WHERE tag_id = 't-hay'",
          );
          await env.db.customStatement("DELETE FROM tags WHERE id = 't-hay'");
          await tester.tap(find.text(_en.tagsDeleteConfirm(14)));
          await tester.pumpAndSettle();
        },
      );
    });

    libraryTest('tags, read error, $theme', (tester, env) async {
      await shoot(
        tester,
        env,
        'read_error',
        arrange: (store) => store.failsReads = true,
        before: (_) => tester.pumpAndSettle(),
      );
    });
  }
}
