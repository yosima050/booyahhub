import 'package:flutter/material.dart';
import '../shared/models/models.dart';

class AuthService extends ChangeNotifier {
  static final AuthService _instance = AuthService._();
  factory AuthService() => _instance;
  AuthService._();

  UserRole? _role;
  String _name = '';
  String _email = '';
  int _userId = 0;

  UserRole? get role  => _role;
  String   get name   => _name;
  String   get email  => _email;
  int      get userId => _userId;
  bool     get isLoggedIn => _role != null;

  void login({
    required UserRole role,
    required String name,
    required String email,
    required int userId,
  }) {
    _role   = role;
    _name   = name;
    _email  = email;
    _userId = userId;
    notifyListeners();
  }

  void updateName(String newName) {
    _name = newName;
    notifyListeners();
  }

  void logout() {
    _role   = null;
    _name   = '';
    _email  = '';
    _userId = 0;
    notifyListeners();
  }
}
