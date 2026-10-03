import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/semantics.dart';
import 'package:memox/core/theme/foundations/app_durations.dart';
import 'package:memox/l10n/l10n_context.dart';
import 'package:memox/shared/widgets/mx_button.dart';
import 'package:memox/shared/widgets/mx_inline_banner.dart';

/// The draft kept on this device, offered back above the fields (SP2a R9).
/// Neutral: nothing is wrong. Restore is secondary, since the footer's Save
/// is the screen's one primary (the One Indigo Rule); Discard is outline, and
/// the primary-weight action sits last.
///
/// The offer arrives after the form is on screen, so its slot eases open and
/// shut instead of shifting the fields under the finger (SP2a audit m2). The
/// banner and its focused button go when it is answered, so focus moves to
/// [frontFocus] and the result is announced (audit m1, WCAG 2.4.3, 4.1.3).
class CardDraftBannerWidget extends StatelessWidget {
  const CardDraftBannerWidget({
    super.key,
    required this.isOffered,
    required this.frontFocus,
    required this.onRestore,
    required this.onDiscard,
  });

  final bool isOffered;
  final FocusNode frontFocus;
  final VoidCallback onRestore;
  final VoidCallback onDiscard;

  @override
  Widget build(BuildContext context) {
    final slot = isOffered
        ? _banner(context)
        : const SizedBox(width: double.infinity);
    // A zero-length AnimatedSize asserts in layout, so Remove animations
    // skips it.
    if (MediaQuery.disableAnimationsOf(context)) return slot;
    return AnimatedSize(
      duration: AppDurations.standard,
      curve: Easing.standard,
      child: slot,
    );
  }

  void _answer(BuildContext context, VoidCallback act, String message) {
    act();
    frontFocus.requestFocus();
    unawaited(
      SemanticsService.sendAnnouncement(
        View.of(context),
        message,
        Directionality.of(context),
      ),
    );
  }

  Widget _banner(BuildContext context) {
    final l10n = context.l10n;
    return MxInlineBanner(
      tone: MxBannerTone.neutral,
      title: l10n.cardDraftTitle,
      message: l10n.cardDraftBody,
      actions: [
        MxButton(
          label: l10n.cardDiscard,
          size: MxButtonSize.compact,
          tone: MxButtonTone.outline,
          onPressed: () =>
              _answer(context, onDiscard, l10n.cardDraftDiscardedAnnounce),
        ),
        MxButton(
          label: l10n.cardDraftRestore,
          size: MxButtonSize.compact,
          tone: MxButtonTone.secondary,
          onPressed: () =>
              _answer(context, onRestore, l10n.cardDraftRestoredAnnounce),
        ),
      ],
    );
  }
}
