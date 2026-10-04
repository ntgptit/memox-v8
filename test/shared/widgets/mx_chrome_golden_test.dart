@Tags(['golden'])
library;

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:memox/shared/widgets/mx_app_bar.dart';
import 'package:memox/shared/widgets/mx_breadcrumb.dart';
import 'package:memox/shared/widgets/mx_icon_button.dart';

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

void main() {
  final Map<(String, String), Widget Function()> sheets = {
    ('app_bar', 'forms'): () => _column([
      const MxAppBar(title: 'Study'),
      MxAppBar(
        title: 'Spanish',
        leading: MxAppBarLeading.back,
        actions: [
          _icon(Icons.auto_awesome, 'Generate'),
          _icon(Icons.sell_outlined, 'Tags'),
          _icon(Icons.delete_outline, 'Trash'),
        ],
      ),
      const MxAppBar(
        title: 'Edit card',
        density: MxAppBarDensity.content,
        leading: MxAppBarLeading.back,
      ),
      MxAppBar(
        title: 'Trash',
        leading: MxAppBarLeading.back,
        textAction: MxAppBarTextAction(label: 'Select', onPressed: () {}),
      ),
      const MxAppBar(title: '3 selected', leading: MxAppBarLeading.close),
    ]),
    ('breadcrumb', 'forms'): () => _column([
      MxBreadcrumb(
        items: [
          MxBreadcrumbItem(label: 'Library', onTap: () {}),
          const MxBreadcrumbItem(label: 'Spanish'),
        ],
      ),
      MxBreadcrumb(
        items: [
          MxBreadcrumbItem(label: 'Library', onTap: () {}),
          MxBreadcrumbItem(label: 'Languages', onTap: () {}),
          MxBreadcrumbItem(label: 'Spanish for travellers', onTap: () {}),
          const MxBreadcrumbItem(label: 'Review algorithm'),
        ],
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
