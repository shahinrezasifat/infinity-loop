import 'package:flutter/foundation.dart';
import 'package:material_ui/material_ui.dart';

import '../../l10n/l10n.dart';
import 'update_service.dart';

class AppUpdatePrompt {
  static bool get supported => defaultTargetPlatform == TargetPlatform.android;
  static bool _checking = false;
  static String? _offeredVersion;
  static DateTime? _lastCheck;

  static Future<void> check(BuildContext context, {bool manual = false}) async {
    if (!supported || _checking) return;
    final now = DateTime.now();
    final lastCheck = _lastCheck;
    if (!manual &&
        lastCheck != null &&
        now.difference(lastCheck) < const Duration(minutes: 15)) {
      return;
    }
    _checking = true;
    _lastCheck = now;
    try {
      final update = await UpdateService.instance.checkForUpdate();
      if (!context.mounted) return;
      if (update == null) {
        if (manual) _message(context, context.l10n.upToDate);
        return;
      }
      if (!manual && _offeredVersion == update.version) return;
      _offeredVersion = update.version;
      await showDialog<void>(
        context: context,
        barrierDismissible: false,
        builder: (_) => _UpdateDialog(update: update),
      );
    } catch (_) {
      if (manual && context.mounted) {
        _message(context, 'Could not check for updates. Please try again.');
      }
    } finally {
      _checking = false;
    }
  }

  static void _message(BuildContext context, String message) =>
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(message)));
}

class _UpdateDialog extends StatefulWidget {
  const _UpdateDialog({required this.update});
  final UpdateInfo update;

  @override
  State<_UpdateDialog> createState() => _UpdateDialogState();
}

class _UpdateDialogState extends State<_UpdateDialog> {
  bool _busy = false;
  double? _progress;
  String? _status;

  Future<void> _install() async {
    setState(() {
      _busy = true;
      _progress = null;
      _status = null;
    });
    try {
      final opened = await UpdateService.instance.install(
        widget.update,
        onProgress: (received, total) {
          if (mounted)
            setState(() => _progress = (received / total).clamp(0.0, 1.0));
        },
      );
      if (!mounted) return;
      if (opened) {
        Navigator.of(context).pop();
      } else {
        setState(
          () => _status =
              'Allow installs from Infinity Loop in Android settings, then return and press Update again.',
        );
      }
    } catch (_) {
      if (mounted) {
        setState(
          () => _status = 'Could not install the update. Please try again.',
        );
      }
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final update = widget.update;
    return PopScope(
      canPop: !_busy,
      child: AlertDialog(
        title: Text('Infinity Loop ${update.version} is available'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (update.notes.trim().isNotEmpty)
                Text(
                  update.notes.trim(),
                  maxLines: 8,
                  overflow: TextOverflow.ellipsis,
                ),
              Text('${(update.apkSize / (1024 * 1024)).toStringAsFixed(1)} MB'),
              if (_busy) ...[
                const SizedBox(height: 12),
                LinearProgressIndicator(value: _progress),
              ],
              if (_status != null) ...[
                const SizedBox(height: 12),
                Text(_status!),
              ],
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: _busy ? null : () => Navigator.of(context).pop(),
            child: Text(context.l10n.later),
          ),
          FilledButton(
            autofocus: true,
            onPressed: _busy ? null : _install,
            child: Text(context.l10n.update),
          ),
        ],
      ),
    );
  }
}
