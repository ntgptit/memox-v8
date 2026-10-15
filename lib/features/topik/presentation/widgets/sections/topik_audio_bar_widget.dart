import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:memox/core/theme/app_icons.dart';
import 'package:memox/core/theme/theme_context.dart';
import 'package:memox/features/topik/domain/models/topik_audio_model.dart';
import 'package:memox/features/topik/presentation/controllers/topik_audio_controller.dart';
import 'package:memox/features/topik/presentation/widgets/overlays/topik_speed_sheet_widget.dart';
import 'package:memox/features/topik/presentation/widgets/support/topik_labels_widget.dart';
import 'package:memox/l10n/l10n_context.dart';
import 'package:memox/shared/widgets/mx_button.dart';
import 'package:memox/shared/widgets/mx_chip_trigger.dart';
import 'package:memox/shared/widgets/mx_icon_button.dart';
import 'package:memox/shared/widgets/mx_inline_banner.dart';
import 'package:memox/shared/widgets/mx_slider.dart';

/// A listening group's player (spec §5.5, detail file 37): play or pause, a
/// seek bar over the group's clip, "0:42 / 1:33", and the speed. It loads
/// its clip when it shows and never plays on its own; it stays as it is
/// between the questions of one group (BR-TOPIK-017). A clip that fails is
/// a warning with Retry, and the answers are untouched.
class TopikAudioBarWidget extends ConsumerStatefulWidget {
  const TopikAudioBarWidget({super.key, required this.clip});

  final TopikAudioClip clip;

  @override
  ConsumerState<TopikAudioBarWidget> createState() =>
      _TopikAudioBarWidgetState();
}

class _TopikAudioBarWidgetState extends ConsumerState<TopikAudioBarWidget> {
  /// Where a drag holds the handle, in ms of the clip; null shows where the
  /// player is.
  double? _dragMs;

  TopikAudioController get _audio =>
      ref.read(topikAudioControllerProvider.notifier);

  @override
  void initState() {
    super.initState();
    unawaited(_audio.show(widget.clip));
  }

  @override
  void didUpdateWidget(TopikAudioBarWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.clip != widget.clip) unawaited(_audio.show(widget.clip));
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final audio =
        ref.watch(topikAudioControllerProvider).value ??
        TopikAudioState.initial;
    final isOwn = audio.clip == widget.clip;
    if (isOwn && audio.status == TopikAudioStatus.failed) {
      return MxInlineBanner(
        tone: MxBannerTone.warning,
        title: l10n.topikAudioFailed,
        message: l10n.topikAudioFailedBody,
        hasBottomMargin: false,
        actions: [
          MxButton(
            label: l10n.commonRetry,
            size: MxButtonSize.small,
            onPressed: () => unawaited(_audio.retry()),
          ),
        ],
      );
    }
    final isReady =
        isOwn &&
        audio.status != TopikAudioStatus.idle &&
        audio.status != TopikAudioStatus.loading;
    final isPlaying = isOwn && audio.isPlaying;
    final lengthMs = widget.clip.lengthMs;
    final positionMs = _dragMs ?? (isOwn ? audio.positionMs : 0).toDouble();
    String timeOf(double ms) => l10n.topikClockOfTotal(
      topikClockText(ms.round()),
      topikClockText(lengthMs),
    );
    // Two lines, so the seek bar has the width of the pane at 360 dp: play
    // and the bar, then the time and the speed (impeccable after 6b).
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          spacing: context.dimens.space4,
          children: [
            MxIconButton(
              icon: isPlaying ? AppIcons.pause : AppIcons.study,
              semanticLabel: isPlaying ? l10n.topikPause : l10n.topikPlay,
              onPressed: isReady ? () => unawaited(_audio.toggle()) : null,
            ),
            Expanded(
              child: MxSlider(
                value: positionMs,
                max: isReady ? lengthMs.toDouble() : 0,
                onChanged: (ms) => setState(() => _dragMs = ms),
                onChangeEnd: _seek,
                semanticLabel: l10n.topikAudioPosition,
                semanticFormatter: timeOf,
              ),
            ),
          ],
        ),
        Row(
          children: [
            Expanded(
              child: Text(
                timeOf(positionMs),
                style: context.texts.labelSmall?.copyWith(
                  color: context.colors.onSurfaceVariant,
                ),
              ),
            ),
            MxChipTrigger(
              label: l10n.topikSpeed(l10n.topikSpeedText(audio.speed)),
              onPressed: () => unawaited(_pickSpeed(audio.speed)),
            ),
          ],
        ),
      ],
    );
  }

  void _seek(double ms) {
    setState(() => _dragMs = null);
    unawaited(_audio.seek(ms.round()));
  }

  Future<void> _pickSpeed(double current) async {
    final speed = await showTopikSpeedSheet(context, selected: current);
    if (speed == null || !mounted) return;
    await _audio.setSpeed(speed);
  }
}
