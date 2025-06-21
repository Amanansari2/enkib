
import 'dart:async';
import 'package:flutter/cupertino.dart';

class Bouncer {
  final int milliseconds;
  VoidCallback? action;
  Timer? _timer;

  Bouncer({required this.milliseconds});

  void run(VoidCallback action) {
    if (_timer != null) {
      _timer!.cancel();
    }
    _timer = Timer(Duration(milliseconds: milliseconds), action);
  }
}