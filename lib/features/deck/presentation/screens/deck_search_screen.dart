import 'dart:async';

import 'package:flutter/material.dart';
import 'package:memox/core/theme/foundations/app_icons.dart';
import 'package:memox/core/theme/foundations/app_spacing.dart';
import 'package:memox/features/deck/presentation/widgets/sections/deck_search_results_widget.dart';
import 'package:memox/l10n/l10n_context.dart';
import 'package:memox/shared/widgets/mx_app_bar.dart';
import 'package:memox/shared/widgets/mx_app_shell.dart';
import 'package:memox/shared/widgets/mx_icon_button.dart';
import 'package:memox/shared/widgets/mx_search_field.dart';

/// Finds a deck anywhere in the library by name (spec §6.3, ruling P2-L9).
/// Navigation arrives as a callback (spec §4).
class DeckSearchScreen extends StatefulWidget {
  const DeckSearchScreen({super.key, required this.onOpenDeck});

  final ValueChanged<String> onOpenDeck;

  @override
  State<DeckSearchScreen> createState() => _DeckSearchScreenState();
}

class _DeckSearchScreenState extends State<DeckSearchScreen> {
  final _query = TextEditingController();
  final _focus = FocusNode();
  var _term = '';

  @override
  void initState() {
    super.initState();
    // The person came here to type.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) _focus.requestFocus();
    });
  }

  @override
  void dispose() {
    _query.dispose();
    _focus.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return MxAppShell(
      appBar: MxAppBar(
        title: l10n.deckSearchTitle,
        density: MxAppBarDensity.content,
        leading: MxIconButton(
          icon: AppIcons.back,
          semanticLabel: l10n.commonBack,
          onPressed: () => unawaited(Navigator.of(context).maybePop()),
        ),
      ),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(
              AppSpacing.gutter,
              AppSpacing.control,
              AppSpacing.gutter,
              AppSpacing.grouped,
            ),
            child: MxSearchField(
              controller: _query,
              focusNode: _focus,
              hintText: l10n.deckSearchHint,
              clearLabel: l10n.deckSearchClear,
              onChanged: (term) => setState(() => _term = term),
            ),
          ),
          Expanded(
            child: DeckSearchResultsWidget(
              term: _term,
              onOpenDeck: widget.onOpenDeck,
            ),
          ),
        ],
      ),
    );
  }
}
