import 'package:flutter/material.dart';

class OnlineStatusProvider extends ChangeNotifier {
  Map<String, bool> onlineStatus = {};

  void updateUserStatus(String userId, bool status) {
    onlineStatus[userId] = status;
    notifyListeners();
  }

  bool getUserStatus(String userId) {
    return onlineStatus[userId] ?? false;
  }
}
