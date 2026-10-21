import 'package:flutter/widgets.dart';
import 'package:memox/core/theme/app_icons.dart';
import 'package:memox/core/theme/theme_context.dart';
import 'package:memox/l10n/l10n_context.dart';
import 'package:memox/shared/widgets/mx_icon_button.dart';

/// A session's deck by its name in a card (owner 2026-10-21, spec D2): the
/// name, the [line] under it, and an ⓘ that shows where the deck sits. The
/// name is the user's own text, two lines then an ellipsis; TalkBack reads
/// it whole. The ⓘ trails the whole block, so its 48 target never pads a
/// one-line name. Screens 13 and 14 share it.
class StudySessionTitleWidget extends StatelessWidget {
  const StudySessionTitleWidget({
    super.key,
    required this.path,
    required this.line,
    required this.onShowLocation,
  });

  /// The deck's path, root first; the card shows its last level only.
  final List<String> path;

  /// The session's line under the name.
  final Widget line;

  /// Opens the Deck location sheet; null while a start runs
  /// (BR-STUDY-004).
  final VoidCallback? onShowLocation;

  static const int _nameMaxLines = 2;

  @override
  Widget build(BuildContext context) => Row(
    children: [
      Expanded(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          spacing: context.dimens.spaceRowLine,
          children: [
            Text(
              path.last,
              maxLines: _nameMaxLines,
              overflow: TextOverflow.ellipsis,
              style: context.texts.itemTitle,
            ),
            line,
          ],
        ),
      ),
      MxIconButton(
        icon: AppIcons.info,
        semanticLabel: context.l10n.studyDeckLocationTitle,
        onPressed: onShowLocation,
      ),
    ],
  );
}
