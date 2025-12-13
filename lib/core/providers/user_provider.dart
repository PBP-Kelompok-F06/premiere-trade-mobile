import 'package:flutter/material.dart';

class UserProvider with ChangeNotifier {
  String _username = "";
  bool _isClubAdmin = false;

  String get username => _username;
  bool get isClubAdmin => _isClubAdmin;

  void setUsername(String value) {
    _username = value;
    notifyListeners();
  }

  void setIsClubAdmin(bool value) {
    _isClubAdmin = value;
    notifyListeners();
  }

  void clear() {
    _username = "";
    _isClubAdmin = false;
    notifyListeners();
  }
}
