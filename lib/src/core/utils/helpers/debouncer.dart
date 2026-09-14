import 'dart:async';

import 'package:flutter/foundation.dart';

class Debouncer {
  final int inMilliseconds;
  Timer? _timer;

  Debouncer({required this.inMilliseconds});

  Future<void> run(VoidCallback action) async {
    if (_timer?.isActive ?? false) {
      _timer?.cancel();
    }
    _timer = Timer(Duration(milliseconds: inMilliseconds), action);
  }

  void dispose() {
    _timer?.cancel();
  }
}
