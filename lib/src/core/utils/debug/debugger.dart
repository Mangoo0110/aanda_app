part of 'debug_service.dart';

class Debugger {
  final DebugLabel debugLabel;

  Debugger({required this.debugLabel});

  void log(dynamic data) {
    DebugService.instance(allowsOnly: {debugLabel}).log(debugLabel, data);
  }
}

class ServiceDebugger extends Debugger {
  ServiceDebugger() : super(debugLabel: DebugLabel.service);
}

class AuthDebugger extends Debugger {
  AuthDebugger() : super(debugLabel: DebugLabel.auth);
}

class UIDebugger extends Debugger {
  UIDebugger() : super(debugLabel: DebugLabel.ui);
}

class ControllerDebugger extends Debugger {
  ControllerDebugger() : super(debugLabel: DebugLabel.controller);
}
