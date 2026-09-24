import 'package:flutter/material.dart';
import 'package:memox/core/theme/foundations/app_spacing.dart';
import 'package:memox/features/card/domain/models/card_list_query_model.dart';
import 'package:memox/features/card/domain/models/card_list_view_model.dart';
import 'package:memox/features/card/presentation/states/card_list_request_state.dart';
import 'package:memox/features/card/presentation/widgets/support/card_list_labels_widget.dart';
import 'package:memox/l10n/l10n_context.dart';
import 'package:memox/shared/widgets/mx_filter_chip.dart';

/// The four filters with their counts (screen 07). The search shows above
/// them once the app bar asks for it; the sort sits in the header; the Tags
/// filter waits under Coming soon (spec A4, amended).
class CardListToolbarWidget extends StatelessWidget {
  const CardListToolbarWidget({
    super.key,
    required this.request,
    required this.counts,
    required this.onFilter,
  });

  final CardListRequestState request;
  final CardListCounts counts;
  final ValueChanged<CardListFilter> onFilter;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.control),
      // The chips never shrink or wrap, so their row scrolls.
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(
          spacing: AppSpacing.micro,
          children: [
            for (final filter in CardListFilter.values)
              MxFilterChip(
                label: l10n.cardFilter(filter),
                count: counts.of(filter),
                isSelected: filter == request.filter,
                onSelected: (_) => onFilter(filter),
              ),
          ],
        ),
      ),
    );
  }
}
