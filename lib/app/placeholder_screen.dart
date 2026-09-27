import 'package:flutter/material.dart';
import 'package:memox/core/theme/foundations/app_icons.dart';
import 'package:memox/l10n/l10n_context.dart';
import 'package:memox/shared/widgets/mx_app_bar.dart';
import 'package:memox/shared/widgets/mx_app_shell.dart';
import 'package:memox/shared/widgets/mx_empty_state.dart';
import 'package:memox/shared/widgets/mx_screen_scroll.dart';

/// The stand-in for a tab whose feature screen is not built yet. The
/// feature's first real screen replaces it in its branch.
class PlaceholderScreen extends StatelessWidget {
  const PlaceholderScreen({super.key, required this.title});

  final String title;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return MxAppShell(
      appBar: MxAppBar(title: title),
      body: MxScreenScroll(
        children: [
          // Ruling G4: a fact, not a failure.
          MxEmptyState(
            icon: AppIcons.inbox,
            title: l10n.placeholderTitle,
            body: l10n.placeholderBody,
            tone: MxEmptyStateTone.neutral,
          ),
        ],
      ),
    );
  }
}
