import 'package:flutter/material.dart';

class UserProvider with ChangeNotifier {
  String _username = "";

  String get username => _username;

  void setUsername(String value) {
    _username = value;
    notifyListeners();
  }

  void clear() {
    _username = "";
    notifyListeners();
  }
}
