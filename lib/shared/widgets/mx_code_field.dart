import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:memox/core/theme/foundations/app_opacity.dart';
import 'package:memox/core/theme/foundations/app_radius.dart';
import 'package:memox/core/theme/foundations/app_size.dart';
import 'package:memox/core/theme/foundations/app_spacing.dart';
import 'package:memox/core/theme/foundations/app_stroke.dart';
import 'package:memox/core/theme/theme_context.dart';
import 'package:memox/shared/widgets/mx_field_message.dart';
import 'package:memox/shared/widgets/mx_text_field.dart';

/// The code variant of [MxTextField]: six slots over one hidden field. The field fills the
/// row, so a tap on any slot focuses it and a long press offers paste; the
/// slots follow its text and focus.
///
/// Built by `MxTextField` for the code variant; features use
/// `MxTextField(variant: code)`.
class MxCodeField extends StatefulWidget {
  const MxCodeField({super.key, required this.field});

  /// A code slot, for tests that find one.
  @visibleForTesting
  static Key slotKey(int index) => ValueKey('mx-code-slot-$index');

  final MxTextField field;

  @override
  State<MxCodeField> createState() => _MxCodeFieldState();
}

class _MxCodeFieldState extends State<MxCodeField> {
  TextEditingController? _ownController;
  FocusNode? _ownFocus;

  TextEditingController get _controller =>
      widget.field.controller ?? (_ownController ??= TextEditingController());

  FocusNode get _focus => widget.field.focusNode ?? (_ownFocus ??= FocusNode());

  @override
  void initState() {
    super.initState();
    _controller.addListener(_keepCaretAtEnd);
  }

  @override
  void didUpdateWidget(MxCodeField oldWidget) {
    super.didUpdateWidget(oldWidget);
    final old = oldWidget.field.controller;
    if (old == widget.field.controller) return;
    // The slots fill left to right: the caret belongs after the last digit,
    // so a tap on any slot or a drag cannot park it mid-code.
    (old ?? _ownController)?.removeListener(_keepCaretAtEnd);
    _controller.addListener(_keepCaretAtEnd);
  }

  /// Keeps the selection collapsed after the last digit, so Backspace removes
  /// the last digit and the next-slot edge is the caret. Setting it to the
  /// value it already has notifies nobody, so this cannot loop.
  void _keepCaretAtEnd() {
    final controller = _controller;
    final end = TextSelection.collapsed(offset: controller.text.length);
    if (controller.selection == end) return;
    controller.selection = end;
  }

  @override
  void dispose() {
    _controller.removeListener(_keepCaretAtEnd);
    _ownController?.dispose();
    _ownFocus?.dispose();
    super.dispose();
  }

  BorderSide _edge(BuildContext context, int index) {
    final colors = context.colors;
    final isNext = _focus.hasFocus && index == _controller.text.length;
    // A wrong code keeps the cue of the slot that takes the next digit: the
    // same 2dp edge, in the error tone.
    if (widget.field.errorText != null) {
      return BorderSide(
        color: colors.error,
        width: isNext ? AppStroke.focus : AppStroke.hairline,
      );
    }
    if (isNext) {
      return BorderSide(
        color: context.semanticColors.primaryForeground,
        width: AppStroke.focus,
      );
    }
    // A disabled code rests on outlineVariant, as a disabled field does.
    return BorderSide(
      color: widget.field.isEnabled ? colors.outline : colors.outlineVariant,
      width: AppStroke.hairline,
    );
  }

  @override
  Widget build(BuildContext context) {
    final field = widget.field;
    // Not in the constructor, which stays const-able.
    assert(
      field.variant == MxTextFieldVariant.code,
      'MxCodeField draws the code variant; use '
      'MxTextField(variant: MxTextFieldVariant.code)',
    );
    final hidden = TextField(
      controller: _controller,
      focusNode: _focus,
      autofocus: field.isAutofocused,
      enabled: field.isEnabled,
      readOnly: field.isReadOnly,
      onChanged: field.onChanged,
      onSubmitted: field.onSubmitted,
      textInputAction: field.textInputAction,
      maxLines: 1,
      keyboardType: TextInputType.number,
      inputFormatters: [
        FilteringTextInputFormatter.digitsOnly,
        const _PasteReplacesFormatter(),
        LengthLimitingTextInputFormatter(MxTextField.codeLength),
      ],
      autofillHints: const [AutofillHints.oneTimeCode],
      showCursor: false,
      style: context.textStyles.fieldCode,
      decoration: const InputDecoration.collapsed(hintText: null),
    );
    final slots = ListenableBuilder(
      listenable: Listenable.merge([_controller, _focus]),
      builder: (context, _) {
        final text = _controller.text;
        return Row(
          mainAxisAlignment: MainAxisAlignment.center,
          spacing: AppSpacing.control,
          children: [
            for (var i = 0; i < MxTextField.codeLength; i++)
              Flexible(
                child: _CodeSlot(
                  key: MxCodeField.slotKey(i),
                  digit: i < text.length ? text[i] : '',
                  edge: _edge(context, i),
                ),
              ),
          ],
        );
      },
    );
    final column = Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Stack(
          children: [
            // TalkBack reads the field below, by its label and value, once.
            ExcludeSemantics(child: slots),
            Positioned.fill(
              child: Opacity(
                opacity: AppOpacity.hidden,
                // The field stays in the tree for TalkBack and autofill.
                alwaysIncludeSemantics: true,
                child: field.label == null
                    ? hidden
                    : Semantics(label: field.label, child: hidden),
              ),
            ),
          ],
        ),
        if (field.errorText case final message?)
          MxFieldMessage(message: message),
      ],
    );
    if (field.isEnabled) return column;
    return Opacity(opacity: AppOpacity.disabled, child: column);
  }
}

/// A paste of a whole code replaces what was typed: the caret is pinned to the
/// end, so the limiter alone would keep the typed digits and cut the paste
/// ("123" + "987654" → "123987"). One edit that adds six digits or more is a
/// paste; its first six digits are the value.
class _PasteReplacesFormatter extends TextInputFormatter {
  const _PasteReplacesFormatter();

  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    final added = newValue.text.length - oldValue.text.length;
    if (added < MxTextField.codeLength) return newValue;
    final selection = newValue.selection;
    final end = selection.isValid ? selection.end : newValue.text.length;
    final run = newValue.text.substring((end - added).clamp(0, end), end);
    final code = run.substring(0, MxTextField.codeLength);
    return TextEditingValue(
      text: code,
      selection: TextSelection.collapsed(offset: code.length),
    );
  }
}

/// One digit's box: 48 wide at most (it shrinks in a narrow column), 56 tall
/// at least, on the form fill.
class _CodeSlot extends StatelessWidget {
  const _CodeSlot({super.key, required this.digit, required this.edge});

  final String digit;
  final BorderSide edge;

  @override
  Widget build(BuildContext context) => ConstrainedBox(
    constraints: const BoxConstraints(
      maxWidth: AppSize.touchTarget,
      minHeight: AppSize.codeSlot,
    ),
    child: DecoratedBox(
      decoration: BoxDecoration(
        color: context.colors.surfaceContainerLow,
        borderRadius: BorderRadius.circular(AppRadius.md),
        border: Border.fromBorderSide(edge),
      ),
      child: Center(child: Text(digit, style: context.textStyles.fieldCode)),
    ),
  );
}
