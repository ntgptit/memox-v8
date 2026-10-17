import 'package:flutter/services.dart';

/// Reports a ForUI field's text edits the way a text field's `onChanged`
/// does: once per edit the person types, pastes or deletes, never for a
/// selection move, an IME composing step or text the code sets on the
/// controller.
///
/// ForUI's managed control calls back on every change of the controller's
/// value, the code's own included. [formatter] (last in the field's input
/// formatters) sees only the person's edits, after the other formatters, and
/// marks the text they produce; [onChange] (the control's callback) forwards
/// the change that carries it.
class MxUserEdits {
  MxUserEdits(this._onChanged);

  final ValueChanged<String>? _onChanged;

  /// The text the last edit produced, until the controller takes it.
  String? _pending;

  late final TextInputFormatter formatter = TextInputFormatter.withFunction((
    oldValue,
    newValue,
  ) {
    if (newValue.text != oldValue.text) _pending = newValue.text;
    return newValue;
  });

  void onChange(TextEditingValue value) {
    final pending = _pending;
    if (pending == null || value.text != pending) return;
    _pending = null;
    _onChanged?.call(value.text);
  }
}
