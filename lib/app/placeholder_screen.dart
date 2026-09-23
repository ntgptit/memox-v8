import 'package:flutter/material.dart';
import 'package:memox/core/theme/foundations/app_icons.dart';
import 'package:memox/l10n/l10n_context.dart';
import 'package:memox/shared/widgets/mx_app_bar.dart';
import 'package:memox/shared/widgets/mx_app_shell.dart';
import 'package:memox/shared/widgets/mx_empty_state.dart';
import 'package:memox/shared/widgets/mx_icon_button.dart';
import 'package:memox/shared/widgets/mx_screen_scroll.dart';

/// The stand-in for a tab whose feature screen is not built yet. The
/// feature's first real screen replaces it in its branch.
class PlaceholderScreen extends StatelessWidget {
  const PlaceholderScreen({super.key, required this.title, this.onOpenGallery});

  final String title;

  /// Debug builds only: opens the component gallery.
  final VoidCallback? onOpenGallery;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return MxAppShell(
      appBar: MxAppBar(
        title: title,
        actions: [
          if (onOpenGallery case final openGallery?)
            MxIconButton(
              icon: AppIcons.gallery,
              semanticLabel: l10n.openGallery,
              onPressed: openGallery,
            ),
        ],
      ),
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
