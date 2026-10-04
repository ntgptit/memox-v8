import 'package:flutter/material.dart';
import 'package:memox/core/theme/components/field_style.dart';
import 'package:memox/core/theme/foundations/app_icon_size.dart';
import 'package:memox/core/theme/foundations/app_radius.dart';
import 'package:memox/core/theme/theme_context.dart';
import 'package:memox/shared/widgets/mx_text_field.dart';
import 'package:memox/shared/widgets/primitives/mx_row_ink.dart';

/// A search input, or (with [onOpen]) a trigger that looks like one and
/// opens the search screen instead of typing here (SCR-DECK-001, Root).
/// The input is an `MxTextField`; the trigger draws with the same field
/// decoration, so the two never drift (DESIGN.md, The One Field Rule).
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
        return MxTextField(
          controller: field,
          focusNode: focusNode,
          hint: hint,
          onChanged: onChanged,
          leadingIcon: Icons.search,
          textInputAction: TextInputAction.search,
          trailingAction: value.text.isEmpty || clear == null
              ? null
              : MxTextFieldAction(
                  icon: Icons.close,
                  semanticLabel: clear,
                  onPressed: () {
                    field.clear();
                    onChanged?.call('');
                  },
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
    final InputDecoration decoration = mxFieldDecoration(
      colors: context.colors,
      texts: context.texts,
      variant: MxTextFieldVariant.form,
      hint: hint,
      prefixIcon: Icon(
        Icons.search,
        size: AppIconSize.medium,
        color: context.colors.onSurfaceVariant,
      ),
    );
    return Semantics(
      button: true,
      label: hint,
      onTap: onOpen,
      excludeSemantics: true,
      child: Stack(
        children: [
          InputDecorator(
            decoration: decoration,
            isEmpty: true,
            child: Text('', style: context.texts.bodyMedium, maxLines: 1),
          ),
          // The ripple sits above the field's fill, inside its corners.
          Positioned.fill(
            child: MxRowInk(
              onTap: onOpen,
              borderRadius: BorderRadius.circular(AppRadius.md),
              child: const SizedBox.expand(),
            ),
          ),
        ],
      ),
    );
  }
}
