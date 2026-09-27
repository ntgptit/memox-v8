import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:memox/core/error/outcome.dart';
import 'package:memox/core/theme/foundations/app_icons.dart';
import 'package:memox/features/card/presentation/providers/card_detail_provider.dart';
import 'package:memox/features/card/presentation/widgets/sections/card_editor_form_widget.dart';
import 'package:memox/features/card/presentation/widgets/sections/card_gone_widget.dart';
import 'package:memox/l10n/l10n_context.dart';
import 'package:memox/shared/widgets/mx_app_bar.dart';
import 'package:memox/shared/widgets/mx_app_shell.dart';
import 'package:memox/shared/widgets/mx_error_state.dart';
import 'package:memox/shared/widgets/mx_icon_button.dart';
import 'package:memox/shared/widgets/mx_screen_scroll.dart';
import 'package:memox/shared/widgets/mx_skeleton.dart';

/// Adds cards one after another into a deck, or edits one (spec §6.5, kit
/// 08/09). [deckContext] is the deck path `app/` passes in (ruling P4a-L7).
class CardEditorScreen extends StatelessWidget {
  const CardEditorScreen.create({
    super.key,
    required String this.deckId,
    required this.deckContext,
    this.onOpenTrash,
  }) : cardId = null;

  const CardEditorScreen.edit({
    super.key,
    required String this.cardId,
    required this.deckContext,
    this.onOpenTrash,
  }) : deckId = null;

  final String? deckId;
  final String? cardId;
  final Widget Function(String deckId, String currentLabel) deckContext;

  /// Opens the Trash from a gone state and a refused Undo (FE-B1 D11).
  final VoidCallback? onOpenTrash;

  @override
  Widget build(BuildContext context) {
    if (deckId case final deckId?) {
      return CardEditorFormWidget(
        deckId: deckId,
        deckContext: deckContext,
        onOpenTrash: onOpenTrash,
      );
    }
    return _EditLoader(
      cardId: cardId!,
      deckContext: deckContext,
      onOpenTrash: onOpenTrash,
    );
  }
}

/// The card to edit while it loads, fails or is gone (ruling P4a-L4).
class _EditLoader extends ConsumerWidget {
  const _EditLoader({
    required this.cardId,
    required this.deckContext,
    this.onOpenTrash,
  });

  final String cardId;
  final Widget Function(String deckId, String currentLabel) deckContext;
  final VoidCallback? onOpenTrash;

  static const int _skeletonRows = 4;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final provider = cardDetailProvider(cardId);
    void back() => unawaited(Navigator.of(context).maybePop());
    final bar = MxAppBar(
      title: l10n.cardEditTitle,
      density: MxAppBarDensity.content,
      leading: MxIconButton(
        icon: AppIcons.back,
        semanticLabel: l10n.commonBack,
        onPressed: back,
      ),
    );
    return switch (ref.watch(provider)) {
      AsyncData(value: Ok(:final value)) => CardEditorFormWidget(
        key: ValueKey(cardId),
        deckId: value.card.deckId,
        detail: value,
        deckContext: deckContext,
        onOpenTrash: onOpenTrash,
      ),
      AsyncData(value: Rejected()) => MxAppShell(
        appBar: bar,
        body: CardGoneWidget(
          title: l10n.cardGoneTitle,
          body: l10n.cardGoneBody,
          onBack: back,
          onOpenTrash: onOpenTrash,
        ),
      ),
      AsyncError() => MxAppShell(
        appBar: bar,
        body: MxScreenScroll(
          children: [
            MxErrorState(
              title: l10n.cardLoadErrorEditTitle,
              body: l10n.libraryLoadErrorBody,
              retryLabel: l10n.commonRetry,
              onRetry: () => ref.invalidate(provider),
            ),
          ],
        ),
      ),
      _ => MxAppShell(
        appBar: bar,
        body: MxScreenScroll(
          children: [
            MxSkeletonList(
              semanticLabel: context.l10n.commonLoading,
              rows: _skeletonRows,
            ),
          ],
        ),
      ),
    };
  }
}
