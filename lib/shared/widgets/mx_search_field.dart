import 'package:flutter/material.dart';
import 'package:memox/core/theme/foundations/app_icon_size.dart';
import 'package:memox/core/theme/foundations/app_icons.dart';
import 'package:memox/core/theme/foundations/app_radius.dart';
import 'package:memox/core/theme/foundations/app_size.dart';
import 'package:memox/core/theme/foundations/app_spacing.dart';
import 'package:memox/core/theme/foundations/app_stroke.dart';
import 'package:memox/core/theme/theme_context.dart';
import 'package:memox/shared/widgets/mx_icon_button.dart';

/// The library search input: a leading glyph, a single-line query, and a
/// clear button that appears only once there is something to clear. What the
/// query filters is the caller's.
class MxSearchField extends StatefulWidget {
  const MxSearchField({
    super.key,
    required this.controller,
    required this.hintText,
    required this.clearLabel,
    this.onChanged,
    this.focusNode,
  });

  final TextEditingController controller;
  final String hintText;

  /// The clear button's accessible name.
  final String clearLabel;

  /// Also called with '' when the query is cleared.
  final ValueChanged<String>? onChanged;
  final FocusNode? focusNode;

  @override
  State<MxSearchField> createState() => _MxSearchFieldState();
}

class _MxSearchFieldState extends State<MxSearchField> {
  FocusNode? _ownFocusNode;

  FocusNode get _focusNode =>
      widget.focusNode ?? (_ownFocusNode ??= FocusNode());

  @override
  void initState() {
    super.initState();
    widget.controller.addListener(_rebuild);
    _focusNode.addListener(_rebuild);
  }

  @override
  void didUpdateWidget(MxSearchField oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.controller != widget.controller) {
      oldWidget.controller.removeListener(_rebuild);
      widget.controller.addListener(_rebuild);
    }
    if (oldWidget.focusNode != widget.focusNode) {
      (oldWidget.focusNode ?? _ownFocusNode)?.removeListener(_rebuild);
      _focusNode.addListener(_rebuild);
    }
  }

  @override
  void dispose() {
    widget.controller.removeListener(_rebuild);
    _focusNode.removeListener(_rebuild);
    _ownFocusNode?.dispose();
    super.dispose();
  }

  void _rebuild() => setState(() {});

  void _clear() {
    widget.controller.clear();
    widget.onChanged?.call(widget.controller.text);
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final styles = context.textStyles;
    final isFocused = _focusNode.hasFocus;
    final hasQuery = widget.controller.text.isNotEmpty;
    OutlineInputBorder edge(Color color) => OutlineInputBorder(
      borderRadius: BorderRadius.circular(AppRadius.md),
      borderSide: BorderSide(color: color, width: AppStroke.hairline),
    );
    final resting = edge(context.derivedColors.ghostBorder);
    // As in MxTextField: padding centres the line in the 52 floor, so the
    // decorator paints the full box and scaled text still grows it.
    final valueStyle = styles.searchValue;
    final lineHeight = valueStyle.fontSize! * valueStyle.height!;
    return TextField(
      controller: widget.controller,
      focusNode: _focusNode,
      onChanged: widget.onChanged,
      maxLines: 1,
      textInputAction: TextInputAction.search,
      style: valueStyle,
      cursorColor: colors.primary,
      textAlignVertical: TextAlignVertical.center,
      decoration: InputDecoration(
        hintText: widget.hintText,
        hintStyle: styles.searchHint,
        filled: true,
        fillColor: isFocused
            ? colors.surfaceContainerLowest
            : colors.surfaceContainer,
        isDense: true,
        contentPadding: EdgeInsets.symmetric(
          vertical: (AppSize.input - lineHeight) / 2,
        ),
        prefixIcon: Padding(
          padding: const EdgeInsetsDirectional.only(
            start: AppSpacing.gutter,
            end: AppSpacing.control,
          ),
          child: Icon(
            AppIcons.search,
            size: AppIconSize.compact,
            color: isFocused ? colors.primary : colors.onSurfaceVariant,
          ),
        ),
        prefixIconConstraints: const BoxConstraints(),
        // The clear button owns its inset; an empty field keeps a 12 spacer.
        suffixIcon: hasQuery
            ? Padding(
                padding: const EdgeInsetsDirectional.only(
                  end: AppSpacing.micro,
                ),
                child: MxIconButton(
                  icon: AppIcons.close,
                  semanticLabel: widget.clearLabel,
                  onPressed: _clear,
                ),
              )
            : const SizedBox(width: AppSpacing.grouped),
        suffixIconConstraints: const BoxConstraints(),
        border: resting,
        enabledBorder: resting,
        focusedBorder: edge(colors.primary),
      ),
    );
  }
}
