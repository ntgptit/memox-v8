import 'package:flutter/material.dart';
import 'package:memox/core/theme/foundations/app_spacing.dart';
import 'package:memox/l10n/l10n_context.dart';
import 'package:memox/shared/widgets/mx_bottom_sheet.dart';
import 'package:memox/shared/widgets/mx_button.dart';
import 'package:memox/shared/widgets/mx_note.dart';
import 'package:memox/shared/widgets/mx_sheet_actions.dart';
import 'package:memox/shared/widgets/mx_text_field.dart';

/// The two ids of the device and user sheet; empty text is no id.
typedef DeviceUserChoice = ({String device, String user});

final _uuid = RegExp(r'^[0-9a-fA-F]{8}-(?:[0-9a-fA-F]{4}-){3}[0-9a-fA-F]{12}$');

/// Opens the device and user sheet (monitoring spec §3.2) on [initial] and
/// returns what was applied, or null when it is dismissed.
Future<DeviceUserChoice?> showMonitoringDeviceUserSheet(
  BuildContext context, {
  required DeviceUserChoice initial,
}) => showMxBottomSheet<DeviceUserChoice>(
  context,
  builder: (_) => MonitoringDeviceUserSheetWidget(initial: initial),
);

/// Two fields, a device id and a user id: the ids the admin copies from a
/// log's details. A user id must be a uuid, since the server casts it.
class MonitoringDeviceUserSheetWidget extends StatefulWidget {
  const MonitoringDeviceUserSheetWidget({super.key, required this.initial});

  final DeviceUserChoice initial;

  @override
  State<MonitoringDeviceUserSheetWidget> createState() =>
      _MonitoringDeviceUserSheetWidgetState();
}

class _MonitoringDeviceUserSheetWidgetState
    extends State<MonitoringDeviceUserSheetWidget> {
  late final _device = TextEditingController(text: widget.initial.device);
  late final _user = TextEditingController(text: widget.initial.user);
  var _hasUserError = false;

  @override
  void dispose() {
    _device.dispose();
    _user.dispose();
    super.dispose();
  }

  void _apply() {
    final user = _user.text.trim();
    if (user.isNotEmpty && !_uuid.hasMatch(user)) {
      setState(() => _hasUserError = true);
      return;
    }
    Navigator.of(context).pop((device: _device.text.trim(), user: user));
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return MxBottomSheet(
      title: l10n.monitoringChipDevice,
      footer: MxSheetActions.custom(
        isInSheet: true,
        children: [
          Expanded(
            child: MxButton(
              label: l10n.monitoringReset,
              tone: MxButtonTone.outline,
              isBlock: true,
              onPressed: () => setState(() {
                _device.clear();
                _user.clear();
                _hasUserError = false;
              }),
            ),
          ),
          Expanded(
            child: MxButton(
              label: l10n.monitoringApply,
              isBlock: true,
              onPressed: _apply,
            ),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: AppSpacing.gutter),
        child: Column(
          spacing: AppSpacing.grouped,
          children: [
            MxTextField(
              controller: _device,
              label: l10n.monitoringDeviceLabel,
              hintText: l10n.monitoringDeviceLabel,
            ),
            MxTextField(
              controller: _user,
              label: l10n.monitoringUserLabel,
              hintText: l10n.monitoringUserLabel,
              errorText: _hasUserError ? l10n.monitoringUserInvalid : null,
              onChanged: (_) {
                if (_hasUserError) setState(() => _hasUserError = false);
              },
            ),
            MxNote(text: l10n.monitoringDeviceUserNote),
          ],
        ),
      ),
    );
  }
}
