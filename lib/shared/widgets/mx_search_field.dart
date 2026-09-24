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
    required TextEditingController this.controller,
    required this.hintText,
    required String this.clearLabel,
    this.onChanged,
    this.focusNode,
  }) : onTap = null;

  /// A read-only field that opens the search elsewhere (screen 01's root
  /// search). It takes no focus, never shows a clear button, and reads as a
  /// button named by [hintText].
  const MxSearchField.trigger({
    super.key,
    required this.hintText,
    required VoidCallback this.onTap,
  }) : controller = null,
       clearLabel = null,
       onChanged = null,
       focusNode = null;

  final TextEditingController? controller;
  final String hintText;

  /// The clear button's accessible name.
  final String? clearLabel;

  /// Also called with '' when the query is cleared.
  final ValueChanged<String>? onChanged;
  final FocusNode? focusNode;

  /// Set by [MxSearchField.trigger]: the field stands for a search that
  /// opens elsewhere.
  final VoidCallback? onTap;

  @override
  State<MxSearchField> createState() => _MxSearchFieldState();
}

class _MxSearchFieldState extends State<MxSearchField> {
  FocusNode? _ownFocusNode;
  TextEditingController? _ownController;

  FocusNode get _focusNode =>
      widget.focusNode ?? (_ownFocusNode ??= FocusNode());

  TextEditingController get _controller =>
      widget.controller ?? (_ownController ??= TextEditingController());

  @override
  void initState() {
    super.initState();
    _controller.addListener(_rebuild);
    _focusNode.addListener(_rebuild);
  }

  @override
  void didUpdateWidget(MxSearchField oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.controller != widget.controller) {
      (oldWidget.controller ?? _ownController)?.removeListener(_rebuild);
      _controller.addListener(_rebuild);
    }
    if (oldWidget.focusNode != widget.focusNode) {
      (oldWidget.focusNode ?? _ownFocusNode)?.removeListener(_rebuild);
      _focusNode.addListener(_rebuild);
    }
  }

  @override
  void dispose() {
    _controller.removeListener(_rebuild);
    _focusNode.removeListener(_rebuild);
    _ownFocusNode?.dispose();
    _ownController?.dispose();
    super.dispose();
  }

  void _rebuild() => setState(() {});

  void _clear() {
    _controller.clear();
    widget.onChanged?.call(_controller.text);
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final styles = context.textStyles;
    final isFocused = _focusNode.hasFocus;
    final hasQuery = _controller.text.isNotEmpty;
    OutlineInputBorder edge(Color color) => OutlineInputBorder(
      borderRadius: BorderRadius.circular(AppRadius.md),
      borderSide: BorderSide(color: color, width: AppStroke.hairline),
    );
    final resting = edge(context.derivedColors.ghostBorder);
    // As in MxTextField: padding centres the line in the 52 floor, so the
    // decorator paints the full box and scaled text still grows it.
    final valueStyle = styles.searchValue;
    final lineHeight = valueStyle.fontSize! * valueStyle.height!;
    final field = TextField(
      controller: _controller,
      focusNode: _focusNode,
      readOnly: widget.onTap != null,
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
                  // A trigger never holds a query, so a clear button always
                  // belongs to the default constructor, which requires it.
                  semanticLabel: widget.clearLabel!,
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
    final onTap = widget.onTap;
    if (onTap == null) return field;
    return Semantics(
      button: true,
      label: widget.hintText,
      excludeSemantics: true,
      onTap: onTap,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: onTap,
        child: IgnorePointer(child: field),
      ),
    );
  }
}
