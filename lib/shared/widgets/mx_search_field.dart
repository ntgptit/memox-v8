import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';
import 'package:forui/forui.dart';
// FTextField's style takes its borders as material_ui's InputBorder.
import 'package:material_ui/material_ui.dart'
    show InputBorder, OutlineInputBorder;
import 'package:memox/core/theme/app_icons.dart';
import 'package:memox/core/theme/theme_context.dart';
import 'package:memox/shared/widgets/mx_icon_button.dart';
import 'package:memox/shared/widgets/mx_route_name.dart';
import 'package:memox/shared/widgets/mx_user_edits.dart';

/// The library search input, on ForUI's [FTextField]: a leading glyph, a
/// single-line query on the muted ground in a pill, and a clear button that
/// appears only once there is something to clear. What the query filters is
/// the caller's.
class MxSearchField extends StatefulWidget {
  const MxSearchField({
    super.key,
    required TextEditingController this.controller,
    required this.hintText,
    required String this.clearLabel,
    this.onChanged,
    this.focusNode,
    this.isRouteName = false,
    this.isAutofocused = false,
  }) : onTap = null;

  /// A button that looks like the resting field and opens the search
  /// elsewhere (screen 01's root search). It holds no text, never shows a
  /// clear button, and reads as a button named by [hintText].
  const MxSearchField.trigger({
    super.key,
    required this.hintText,
    required VoidCallback this.onTap,
  }) : controller = null,
       clearLabel = null,
       onChanged = null,
       focusNode = null,
       isRouteName = false,
       isAutofocused = false;

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

  /// The field names its route (screen 04), as an app bar title does: the
  /// field's own node, which reads the hint, carries the name (DEV-393).
  final bool isRouteName;

  /// Takes focus, and so opens the keyboard, when the field first appears:
  /// the person came to this screen to type.
  final bool isAutofocused;

  @override
  State<MxSearchField> createState() => _MxSearchFieldState();
}

class _MxSearchFieldState extends State<MxSearchField> {
  TextEditingController? _ownController;

  TextEditingController get _controller =>
      widget.controller ?? (_ownController ??= TextEditingController());

  @override
  void initState() {
    super.initState();
    _controller.addListener(_rebuild);
  }

  @override
  void didUpdateWidget(MxSearchField oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.controller == widget.controller) return;
    (oldWidget.controller ?? _ownController)?.removeListener(_rebuild);
    _controller.addListener(_rebuild);
  }

  @override
  void dispose() {
    _controller.removeListener(_rebuild);
    _ownController?.dispose();
    super.dispose();
  }

  /// Rebuilds for the semantics label, which follows whether a query is held.
  void _rebuild() => setState(() {});

  void _clear() {
    _controller.clear();
    widget.onChanged?.call(_controller.text);
  }

  @override
  Widget build(BuildContext context) {
    final onTap = widget.onTap;
    if (onTap != null) return _trigger(context, onTap);
    final colors = context.colors;
    final pill = context.radii.pill;
    final edits = MxUserEdits(widget.onChanged);
    final edge = OutlineInputBorder(
      gapPadding: 0,
      borderRadius: pill,
      borderSide: BorderSide.none,
    );
    final hasQuery = _controller.text.isNotEmpty;
    final field = FTextField(
      // The input's own node is the field's name: the decorator labels it
      // with the hint while empty, and the hint stays its name once it holds
      // a query, so it never reads only as its value.
      builder: (context, style, variants, input) {
        // Always this Semantics, labelled or not, so a query that comes or
        // goes never remounts the input (and drops its focus).
        final named = Semantics(
          label: hasQuery ? widget.hintText : null,
          child: input,
        );
        return widget.isRouteName ? MxRouteName(child: named) : named;
      },
      control: FTextFieldControl.managed(
        controller: _controller,
        onChange: edits.onChange,
      ),
      size: FTextFieldSizeVariant.lg,
      // The search bar is a pill on the muted ground, with no edge in any
      // state.
      style: FTextFieldStyleDelta.delta(
        color:
            FVariants<
              FTextFieldVariantConstraint,
              FTextFieldVariant,
              Color?,
              Delta
            >.all(colors.muted),
        border:
            FVariants<
              FTextFieldVariantConstraint,
              FTextFieldVariant,
              InputBorder,
              Delta
            >.all(edge),
      ),
      hint: widget.hintText,
      focusNode: widget.focusNode,
      autofocus: widget.isAutofocused,
      inputFormatters: [edits.formatter],
      textInputAction: TextInputAction.search,
      prefixBuilder: (context, _, variants) => Padding(
        padding: EdgeInsetsDirectional.only(
          start: context.dimens.space16,
          end: context.dimens.space8,
        ),
        child: Icon(
          AppIcons.search,
          size: context.dimens.sizeIcon,
          color: variants.contains(FTextFieldVariant.focused)
              ? colors.primary
              : colors.mutedForeground,
        ),
      ),
      // The clear button owns its inset.
      clearable: (value) => value.text.isNotEmpty,
      clearIconBuilder: (context, _, _) => Padding(
        padding: EdgeInsetsDirectional.only(end: context.dimens.space4),
        child: MxIconButton(
          icon: AppIcons.close,
          semanticLabel: widget.clearLabel!,
          onPressed: _clear,
        ),
      ),
    );
    return field;
  }

  /// The trigger: an [FButton] that paints the resting field, so the button
  /// semantics, the focus outline and the keyboard are ForUI's.
  Widget _trigger(BuildContext context, VoidCallback onTap) {
    final colors = context.colors;
    final dimens = context.dimens;
    final pill = context.radii.pill;
    final hint = FTheme.of(context).textFieldStyles.lg.hintTextStyle
        .resolve(const {});
    // Every state paints the same: the pill on the muted ground, the hint and
    // the glyph at rest, and the press does not shrink it.
    return FButton(
      onPress: onTap,
      size: FButtonSizeVariant.lg,
      mainAxisAlignment: MainAxisAlignment.start,
      style: FButtonStyleDelta.delta(
        decoration:
            FVariants<
              FTappableVariantConstraint,
              FTappableVariant,
              Decoration,
              DecorationDelta
            >.all(
              ShapeDecoration(
                color: colors.muted,
                shape: RoundedRectangleBorder(borderRadius: pill),
              ),
            ),
        contentStyle: FButtonContentStyleDelta.delta(
          textStyle:
              FVariants<
                FTappableVariantConstraint,
                FTappableVariant,
                TextStyle,
                TextStyleDelta
              >.all(hint),
          iconStyle:
              FVariants<
                FTappableVariantConstraint,
                FTappableVariant,
                IconThemeData,
                IconThemeDataDelta
              >.all(
                IconThemeData(
                  color: colors.mutedForeground,
                  size: dimens.sizeIcon,
                ),
              ),
          constraints: BoxConstraints(minHeight: dimens.sizeControl),
          padding: EdgeInsetsGeometryDelta.value(
            EdgeInsetsDirectional.symmetric(horizontal: dimens.space16),
          ),
          spacing: dimens.space8,
        ),
        tappableStyle: const FTappableStyleDelta.delta(
          motion: FTappableMotionDelta.delta(
            bounceTween: FTappableMotion.noBounceTween,
          ),
        ),
        focusedOutlineStyle: FFocusedOutlineStyleDelta.delta(
          borderRadius: pill,
        ),
      ),
      prefix: const Icon(AppIcons.search),
      child: Flexible(
        child: Text(
          widget.hintText,
          maxLines: 1,
          softWrap: false,
          overflow: TextOverflow.ellipsis,
        ),
      ),
    );
  }
}
