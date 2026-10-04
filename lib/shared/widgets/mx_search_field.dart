import 'package:flutter/material.dart';
import 'package:memox/core/theme/foundations/app_icon_size.dart';
import 'package:memox/core/theme/foundations/app_radius.dart';
import 'package:memox/core/theme/foundations/app_size.dart';
import 'package:memox/core/theme/foundations/app_spacing.dart';
import 'package:memox/core/theme/theme_context.dart';
import 'package:memox/shared/widgets/mx_icon_button.dart';
import 'package:memox/shared/widgets/primitives/mx_row_ink.dart';

/// A search input, or (with [onOpen]) a trigger that looks like one and
/// opens the search screen instead of typing here (SCR-DECK-001, Root).
class MxSearchField extends StatelessWidget {
  const MxSearchField({
    required this.hint,
    this.controller,
    this.onChanged,
    this.clearLabel,
    this.onOpen,
    this.focusNode,
    super.key,
  }) : assert(
         (controller == null) == (onOpen != null),
         'A search field either types (controller) or opens search (onOpen).',
       );

  final String hint;
  final TextEditingController? controller;
  final ValueChanged<String>? onChanged;

  /// The clear button's name, read aloud; it shows while there is text.
  final String? clearLabel;

  /// Trigger mode: a tap opens the search screen.
  final VoidCallback? onOpen;
  final FocusNode? focusNode;

  @override
  Widget build(BuildContext context) {
    final VoidCallback? open = onOpen;
    if (open != null) {
      return _Trigger(hint: hint, onOpen: open);
    }
    final TextEditingController field = controller!;
    return ValueListenableBuilder<TextEditingValue>(
      valueListenable: field,
      builder: (context, value, _) {
        final String? clear = clearLabel;
        return TextField(
          controller: field,
          focusNode: focusNode,
          onChanged: onChanged,
          style: context.texts.bodyMedium,
          textInputAction: TextInputAction.search,
          decoration: InputDecoration(
            hintText: hint,
            prefixIcon: Icon(
              Icons.search,
              size: AppIconSize.medium,
              color: context.colors.onSurfaceVariant,
            ),
            suffixIcon: value.text.isEmpty || clear == null
                ? null
                : MxIconButton(
                    icon: Icons.close,
                    semanticLabel: clear,
                    onPressed: () {
                      field.clear();
                      onChanged?.call('');
                    },
                  ),
          ),
        );
      },
    );
  }
}

class _Trigger extends StatelessWidget {
  const _Trigger({required this.hint, required this.onOpen});

  final String hint;
  final VoidCallback onOpen;

  @override
  Widget build(BuildContext context) {
    final BorderRadius radius = BorderRadius.circular(AppRadius.md);
    return Semantics(
      button: true,
      label: hint,
      onTap: onOpen,
      excludeSemantics: true,
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: context.colors.surfaceContainerLow,
          borderRadius: radius,
          border: Border.all(color: context.colors.outlineVariant),
        ),
        child: MxRowInk(
          onTap: onOpen,
          borderRadius: radius,
          child: ConstrainedBox(
            constraints: const BoxConstraints(minHeight: AppSize.field),
            // The input's geometry: the glyph centred in a 48 box where a
            // prefix icon sits, the hint where typed text starts.
            child: Padding(
              padding: const EdgeInsetsDirectional.only(
                end: AppSpacing.grouped,
              ),
              child: Row(
                children: [
                  SizedBox(
                    width: AppSize.tapTarget,
                    child: Icon(
                      Icons.search,
                      size: AppIconSize.medium,
                      color: context.colors.onSurfaceVariant,
                    ),
                  ),
                  const SizedBox(width: AppSpacing.micro),
                  Expanded(
                    child: Text(
                      hint,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: context.texts.bodyMedium?.apply(
                        color: context.colors.onSurfaceVariant,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
