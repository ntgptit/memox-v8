@Tags(['golden'])
library;

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:memox/shared/widgets/mx_app_bar.dart';
import 'package:memox/shared/widgets/mx_breadcrumb.dart';
import 'package:memox/shared/widgets/mx_card.dart';
import 'package:memox/shared/widgets/mx_fab.dart';
import 'package:memox/shared/widgets/mx_footer_bar.dart';
import 'package:memox/shared/widgets/mx_icon_button.dart';
import 'package:memox/shared/widgets/mx_list_row.dart';
import 'package:memox/shared/widgets/mx_screen_scaffold.dart';
import 'package:memox/shared/widgets/mx_screen_scroll.dart';
import 'package:memox/shared/widgets/mx_sheet_actions.dart';

import 'support/mx_harness.dart';

Widget _column(List<Widget> children) => SizedBox(
  width: 380,
  child: Column(
    crossAxisAlignment: CrossAxisAlignment.stretch,
    mainAxisSize: MainAxisSize.min,
    spacing: 12,
    children: children,
  ),
);

MxIconButton _icon(IconData icon, String label) =>
    MxIconButton(icon: icon, semanticLabel: label, onPressed: () {});

Widget _frame(MxScreenScaffold screen) =>
    SizedBox(height: 420, child: ClipRect(child: screen));

const List<String> _decks = [
  'Spanish',
  'Japanese kana',
  'French verbs',
  'Anatomy',
  'Chemistry',
  'Music theory',
];

void main() {
  final Map<(String, String), Widget Function()> sheets = {
    ('screen_scaffold', 'frames'): () => _column([
      _frame(
        MxScreenScaffold(
          appBar: MxAppBar(
            title: 'Library',
            actions: [
              _icon(Icons.search, 'Search'),
              _icon(Icons.more_vert, 'More'),
            ],
          ),
          body: MxScreenScroll(
            children: [
              MxCard(
                isFullBleed: true,
                child: Column(
                  children: [
                    for (final deck in _decks)
                      MxListRow(
                        title: deck,
                        subtitle: '24 cards',
                        icon: Icons.style,
                        trailing: const MxListRowTrailing.chevron(),
                        onTap: () {},
                      ),
                  ],
                ),
              ),
            ],
          ),
          fab: MxFab(
            icon: Icons.add,
            semanticLabel: 'New deck',
            onPressed: () {},
          ),
        ),
      ),
      _frame(
        MxScreenScaffold(
          appBar: const MxAppBar(
            title: 'New card',
            density: MxAppBarDensity.content,
            leading: MxAppBarLeading.close,
          ),
          breadcrumb: MxBreadcrumb(
            items: [
              MxBreadcrumbItem(label: 'Library', onTap: () {}),
              MxBreadcrumbItem(label: 'Spanish', onTap: () {}),
              const MxBreadcrumbItem(label: 'New card'),
            ],
          ),
          body: const MxScreenScroll(children: [SizedBox(height: 120)]),
          footer: MxFooterBar(
            caption: 'Saved on this phone',
            actions: MxSheetActions(
              cancelLabel: 'Cancel',
              onCancel: () {},
              confirmLabel: 'Save card',
              onConfirm: () {},
            ),
          ),
        ),
      ),
    ]),
    ('footer_bar', 'forms'): () => _column([
      const MxFooterBar(caption: 'Read-only · resets change nothing here'),
      MxFooterBar(
        caption: 'Saved on this phone',
        actions: MxSheetActions(
          cancelLabel: 'Cancel',
          onCancel: () {},
          confirmLabel: 'Save card',
          onConfirm: () {},
        ),
      ),
      MxFooterBar(
        caption: 'Starting…',
        actions: MxSheetActions(
          confirmLabel: 'Study this deck',
          onConfirm: () {},
          isConfirmLoading: true,
        ),
      ),
    ]),
  };
  for (final MapEntry(key: (component, state), value: sheet)
      in sheets.entries) {
    for (final variant in mxThemes.keys) {
      testWidgets('mx_$component $state $variant', (tester) async {
        await expectMxGolden(
          tester,
          component: component,
          state: state,
          variant: variant,
          sheet: sheet(),
        );
      });
    }
  }
}
