import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:memox/core/error/outcome.dart';
import 'package:memox/core/theme/foundations/app_icons.dart';
import 'package:memox/features/card/domain/models/card_detail_model.dart';
import 'package:memox/features/card/presentation/providers/card_detail_provider.dart';
import 'package:memox/features/card/presentation/states/card_editor_source_state.dart';
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
      // A fresh form (and draft key) for each deck, as the edit form has for
      // each card.
      return CardEditorFormWidget(
        key: ValueKey(deckId),
        deckId: deckId,
        deckContext: deckContext,
        onOpenTrash: onOpenTrash,
      );
    }
    // Keyed so the loader's remembered card never outlives a change of card.
    return _EditLoader(
      key: ValueKey(cardId),
      cardId: cardId!,
      deckContext: deckContext,
      onOpenTrash: onOpenTrash,
    );
  }
}

/// The card to edit while it loads, fails or is gone (ruling P4a-L4). Once
/// the form has opened it stays: a card that goes away later is shown on the
/// form, never in place of it, so typed text is not thrown away (SP2a 2.17).
class _EditLoader extends ConsumerStatefulWidget {
  const _EditLoader({
    super.key,
    required this.cardId,
    required this.deckContext,
    this.onOpenTrash,
  });

  final String cardId;
  final Widget Function(String deckId, String currentLabel) deckContext;
  final VoidCallback? onOpenTrash;

  @override
  ConsumerState<_EditLoader> createState() => _EditLoaderState();
}

class _EditLoaderState extends ConsumerState<_EditLoader> {
  static const int _skeletonRows = 4;

  /// The newest present detail: the form opened with it and "Use theirs"
  /// (SP2a 2.18) loads it. It keeps the last one while the card is gone.
  CardDetail? _opened;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final provider = cardDetailProvider(widget.cardId);
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
    final value = ref.watch(provider);
    if (value case AsyncData(value: Ok(value: final detail))) {
      _opened = detail;
    }
    if (_opened case final opened?) {
      return CardEditorFormWidget(
        key: ValueKey(widget.cardId),
        deckId: opened.card.deckId,
        detail: opened,
        source: switch (value) {
          AsyncError() => CardEditorSource.unreadable,
          AsyncData(value: Rejected()) => CardEditorSource.gone,
          _ => CardEditorSource.present,
        },
        deckContext: widget.deckContext,
        onOpenTrash: widget.onOpenTrash,
      );
    }
    return switch (value) {
      AsyncData(value: Rejected()) => MxAppShell(
        appBar: bar,
        body: CardGoneWidget(
          title: l10n.cardGoneTitle,
          body: l10n.cardGoneBody,
          onBack: back,
          onOpenTrash: widget.onOpenTrash,
        ),
      ),
      AsyncError(:final isLoading) => MxAppShell(
        appBar: bar,
        body: MxScreenScroll(
          children: [
            MxErrorState(
              title: l10n.cardLoadErrorEditTitle,
              body: l10n.libraryLoadErrorBody,
              retryLabel: l10n.commonRetry,
              onRetry: () => ref.invalidate(provider),
              isRetrying: isLoading,
            ),
          ],
        ),
      ),
      _ => MxAppShell(
        appBar: bar,
        body: MxScreenScroll(
          children: [
            MxSkeletonList(
              semanticLabel: l10n.commonLoading,
              rows: _skeletonRows,
            ),
          ],
        ),
      ),
    };
  }
}
