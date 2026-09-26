import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:memox/core/theme/foundations/app_icons.dart';
import 'package:memox/features/search/presentation/controllers/search_screen_controller.dart';
import 'package:memox/features/search/presentation/widgets/sections/search_body_widget.dart';
import 'package:memox/l10n/l10n_context.dart';
import 'package:memox/shared/widgets/mx_app_bar.dart';
import 'package:memox/shared/widgets/mx_app_shell.dart';
import 'package:memox/shared/widgets/mx_icon_button.dart';
import 'package:memox/shared/widgets/mx_search_field.dart';

/// Screen 04: the whole library — deck names, card faces, tag names — from
/// the Library header, at any level (UC-SEARCH-001). Navigation arrives as
/// callbacks.
class LibrarySearchScreen extends ConsumerStatefulWidget {
  const LibrarySearchScreen({
    super.key,
    required this.onOpenDeck,
    required this.onOpenCard,
  });

  final ValueChanged<String> onOpenDeck;
  final ValueChanged<String> onOpenCard;

  @override
  ConsumerState<LibrarySearchScreen> createState() =>
      _LibrarySearchScreenState();
}

class _LibrarySearchScreenState extends ConsumerState<LibrarySearchScreen> {
  final _query = TextEditingController();
  final _focus = FocusNode();

  @override
  void initState() {
    super.initState();
    // The person came here to type (step 1).
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

  void _search(String term) =>
      ref.read(searchScreenControllerProvider.notifier).search(term);

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return MxAppShell(
      appBar: MxAppBar(
        density: MxAppBarDensity.content,
        leading: MxIconButton(
          icon: AppIcons.back,
          semanticLabel: l10n.commonBack,
          onPressed: () => unawaited(Navigator.of(context).maybePop()),
        ),
        titleWidget: MxSearchField(
          controller: _query,
          focusNode: _focus,
          hintText: l10n.searchFieldHint,
          clearLabel: l10n.searchClear,
          onChanged: _search,
        ),
      ),
      body: SearchBodyWidget(
        onOpenDeck: widget.onOpenDeck,
        onOpenCard: widget.onOpenCard,
      ),
    );
  }
}
