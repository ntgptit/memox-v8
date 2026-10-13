import 'package:flutter/material.dart';
import 'package:memox/core/theme/app_icons.dart';
import 'package:memox/core/theme/theme_context.dart';
import 'package:memox/shared/widgets/mx_icon_button.dart';
import 'package:memox/core/theme/theme_rules.dart';

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
    final isFocused = _focusNode.hasFocus;
    final hasQuery = _controller.text.isNotEmpty;
    // As in MxTextField: padding centres the line in the `sizeSearch` floor, so the
    // decorator paints the full box and scaled text still grows it.
    final valueStyle = context.texts.labelMedium!;
    final lineHeight = valueStyle.fontSize! * valueStyle.height!;
    final edge = OutlineInputBorder(
      gapPadding: 0,
      borderRadius: BorderRadius.circular(context.dimens.sizeSearch / 2),
      borderSide: BorderSide.none,
    );
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
        hintStyle: context.texts.labelMedium?.copyWith(
          color: context.colors.onSurfaceVariant,
        ),
        // The search bar is a stadium on its own surface, with no edge in any
        // state (Design System: SearchBar).
        fillColor: context.mxColors.searchSurface,
        border: edge,
        enabledBorder: edge,
        focusedBorder: edge,
        contentPadding: EdgeInsets.symmetric(
          vertical: (context.dimens.sizeSearch - lineHeight) / 2,
        ),
        prefixIcon: Padding(
          padding: EdgeInsetsDirectional.only(
            start: context.dimens.space16,
            end: context.dimens.space8,
          ),
          child: Icon(
            AppIcons.search,
            size: context.dimens.sizeIcon,
            color: isFocused ? context.accentColor : colors.onSurfaceVariant,
          ),
        ),
        prefixIconConstraints: const BoxConstraints(),
        // The clear button owns its inset; an empty field keeps a 12 spacer.
        suffixIcon: hasQuery
            ? Padding(
                padding: EdgeInsetsDirectional.only(end: context.dimens.space4),
                child: MxIconButton(
                  icon: AppIcons.close,
                  // A trigger never holds a query, so a clear button always
                  // belongs to the default constructor, which requires it.
                  semanticLabel: widget.clearLabel!,
                  onPressed: _clear,
                ),
              )
            : SizedBox(width: context.dimens.space12),
        suffixIconConstraints: const BoxConstraints(),
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
