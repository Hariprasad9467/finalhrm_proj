import 'package:flutter/material.dart';

class UserProvider extends ChangeNotifier {
  String? _employeeId;
  String? _employeeName;
  String? _position;
  String? _domain;

  String? get employeeId => _employeeId;
  String? get employeeName => _employeeName;
  String? get position => _position;
  String? get domain => _domain;

  void setEmployeeId(String id) {
    _employeeId = id;
    notifyListeners();
  }

  void setEmployeeName(String name) {
    _employeeName = name;
    notifyListeners();
  }

  void setPosition(String position) {
    _position = position;
    notifyListeners();
  }

  void setDomain(String domain) {
    _domain = domain;
    notifyListeners();
  }

  void clearUser() {
    _employeeId = null;
    _employeeName = null;
    _position = null;
    _domain = null;
    notifyListeners();
  }
}