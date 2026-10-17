import 'package:flutter/material.dart';
import 'package:memox/core/theme/app_icons.dart';
import 'package:memox/core/theme/theme_context.dart';
import 'package:memox/core/theme/theme_rules.dart';
import 'package:memox/features/topik/domain/models/topik_audio_model.dart';
import 'package:memox/features/topik/domain/models/topik_question_group_model.dart';
import 'package:memox/features/topik/presentation/widgets/sections/topik_audio_bar_widget.dart';
import 'package:memox/features/topik/presentation/widgets/support/topik_labels_widget.dart';
import 'package:memox/l10n/l10n_context.dart';
import 'package:memox/shared/widgets/mx_button.dart';
import 'package:memox/shared/widgets/mx_icon_button.dart';
import 'package:memox/shared/widgets/mx_scroll_fade.dart';
import 'package:memox/shared/widgets/mx_tint_base.dart';

/// A group's shared material (detail file 37, critique F5, F12):
/// - its instruction;
/// - for listening, the audio bar;
/// - the passage or its picture;
/// - for a group with a script, the toggle, then the script and its
///   translation once the current question is answered or by the toggle
///   (spec §5.5, D15).
///
/// It sits on the recessed ground and scrolls on its own, fading its bottom
/// edge into that ground while more lies below. Collapsed, it keeps
/// the instruction on one line and the audio bar, so the audio is never lost
/// to a collapse.
class TopikGroupPaneWidget extends StatelessWidget {
  const TopikGroupPaneWidget({
    super.key,
    required this.group,
    required this.audio,
    required this.isCollapsed,
    required this.isScriptShown,
    required this.onToggleCollapsed,
    required this.onToggleScript,
  });

  final TopikQuestionGroup group;

  /// The group's clip; null for a group without audio.
  final TopikAudioClip? audio;
  final bool isCollapsed;
  final bool isScriptShown;
  final VoidCallback onToggleCollapsed;
  final VoidCallback onToggleScript;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final dimens = context.dimens;
    final ground = context.colors.surfaceContainerLow;
    final hasMaterial = group.passage != null || group.script != null;
    // The screen keeps one collapse for the whole attempt; a group with
    // nothing to hide shows its instruction whole, or a collapse carried
    // into it would cut the task's words with no way to open them.
    final isShut = isCollapsed && hasMaterial;
    return MxTintBase(
      color: ground,
      child: ColoredBox(
        color: ground,
        child: MxScrollFade(
          ground: MxScrollFadeGround.recessed,
          child: SingleChildScrollView(
            padding: EdgeInsets.symmetric(
              horizontal: context.screenMargin,
              vertical: dimens.space12,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              spacing: dimens.space12,
              children: [
                Row(
                  spacing: dimens.space8,
                  children: [
                    Expanded(
                      child: Text(
                        group.instructionKo,
                        maxLines: isShut ? 1 : null,
                        overflow: isShut ? TextOverflow.ellipsis : null,
                        style: context.texts.bodyMedium?.copyWith(
                          color: context.colors.onSurfaceVariant,
                        ),
                      ),
                    ),
                    // A chevron named for TalkBack (critique F5, Q-P6b-4).
                    if (hasMaterial)
                      MxIconButton(
                        icon: isCollapsed
                            ? AppIcons.chevronDown
                            : AppIcons.chevronUp,
                        semanticLabel: isCollapsed
                            ? l10n.topikShowPassage
                            : l10n.topikHidePassage,
                        onPressed: onToggleCollapsed,
                      ),
                  ],
                ),
                if (audio case final clip?) TopikAudioBarWidget(clip: clip),
                if (!isShut) ..._material(context),
              ],
            ),
          ),
        ),
      ),
    );
  }

  List<Widget> _material(BuildContext context) {
    final l10n = context.l10n;
    final passage = group.passage;
    final script = group.script;
    final translation = group.scriptTranslation;
    return [
      if (passage?.textKo case final text?)
        Text(text, style: context.texts.bodyLarge),
      if (passage?.image case final image?)
        Image.asset(
          image,
          fit: BoxFit.contain,
          semanticLabel: l10n.topikPicture,
        ),
      if (script != null)
        Align(
          alignment: AlignmentDirectional.centerStart,
          child: MxButton(
            label: isScriptShown ? l10n.topikHideScript : l10n.topikShowScript,
            tone: MxButtonTone.text,
            size: MxButtonSize.small,
            onPressed: onToggleScript,
          ),
        ),
      if (script != null && isScriptShown) ...[
        Text(script, style: context.texts.bodyMedium),
        if (translation != null)
          Text(
            l10n.topikText(translation),
            style: context.texts.bodyMedium?.copyWith(
              color: context.colors.onSurfaceVariant,
            ),
          ),
      ],
    ];
  }
}
