import 'package:flutter/material.dart';

class AppStateProvider with ChangeNotifier {
  bool _isAppInForeground = true;

  bool get isAppInForeground => _isAppInForeground;

  void setAppState(bool isInForeground) {
    _isAppInForeground = isInForeground;
    notifyListeners();
  }
}