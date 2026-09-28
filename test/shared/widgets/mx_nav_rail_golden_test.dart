@Tags(['golden'])
library;

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:memox/core/theme/foundations/app_icons.dart';
import 'package:memox/shared/widgets/mx_bottom_nav.dart';
import 'package:memox/shared/widgets/mx_nav_rail.dart';

import '../../support/golden_harness.dart';

void main() {
  testWidgets('MxNavRail on Study (FE-C5)', (tester) async {
    await expectThemedGoldens(
      tester,
      'mx_nav_rail',
      Align(
        alignment: AlignmentDirectional.centerStart,
        child: MxNavRail(
          destinations: const [
            MxNavDestination(
              icon: AppIcons.library,
              selectedIcon: AppIcons.librarySelected,
              label: 'Library',
            ),
            MxNavDestination(
              icon: AppIcons.study,
              selectedIcon: AppIcons.studySelected,
              label: 'Study',
            ),
            MxNavDestination(
              icon: AppIcons.progress,
              selectedIcon: AppIcons.progressSelected,
              label: 'Progress',
            ),
            MxNavDestination(
              icon: AppIcons.settings,
              selectedIcon: AppIcons.settingsSelected,
              label: 'Settings',
            ),
          ],
          selectedIndex: 1,
          onSelected: (_) {},
        ),
      ),
    );
  });
}
