import 'package:flutter/foundation.dart';
part 'debugger.dart';

enum DebugLabel {
  ui("UI"),
  controller("Controller"),
  service("Service"),
  auth("Auth"),
  setting("Setting"),
  notification("Notification"),
  audio("Audio");

  final String label;

  const DebugLabel(this.label);
}

class DebugService {
  final Set<DebugLabel> _allowsOnly;

  DebugService._(this._allowsOnly);

  static DebugService? _instance;

  /// Singletone
  factory DebugService.instance({required Set<DebugLabel> allowsOnly}) {
    _instance ??= DebugService._(allowsOnly);
    return _instance!;
  }

  void log(DebugLabel label, dynamic data, {int code = 32}) {
    if (!_allowsOnly.contains(label)) return;
    // Print, only if the debug label is present in the _allowOnly list.
    if (kDebugMode) {
      print(
        '\x1B[${code}mDebug >> ${label.label} >> ${data.toString()}\x1B[0m',
      );
    }
  }
}
