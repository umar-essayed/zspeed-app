import 'package:shared_preferences/shared_preferences.dart';

import 'package:z_speed/features/auth/model/user_model.dart';
import 'package:injectable/injectable.dart' hide Order;

@lazySingleton
class AuthLocalDatasource {
  static final AuthLocalDatasource _instance = AuthLocalDatasource._internal();
  factory AuthLocalDatasource() => _instance;
  AuthLocalDatasource._internal();

  final List<AppUser> _users = [
    AppUser(
      id: '1',
      name: 'Admin User',
      email: 'admin@zspeed.com',
      password: 'admin123',
      type: UserType.admin,
      phone: '+201234567890',
    ),
    AppUser(
      id: '2',
      name: 'Restaurant Owner',
      email: 'restaurant@zspeed.com',
      password: 'vendor123',
      type: UserType.vendor,
      phone: '+201234567891',
    ),
    AppUser(
      id: '3',
      name: 'Customer',
      email: 'customer@example.com',
      password: 'customer123',
      type: UserType.customer,
      phone: '+201234567892',
      address: '12 Street, NAC - Home',
    ),
    AppUser(
      id: '4',
      name: 'Driver',
      email: 'driver@zspeed.com',
      password: 'driver123',
      type: UserType.driver,
      phone: '+201234567893',
    ),
  ];

  Future<AppUser?> findUserByCredentials(String email, String password) async {
    await Future.delayed(const Duration(seconds: 1));

    try {
      return _users.firstWhere(
        (user) => user.email == email && user.password == password,
      );
    } catch (_) {
      return null;
    }
  }

  AppUser createAutoCustomer(String email, String password) {
    return AppUser(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      name: 'Customer',
      email: email,
      password: password,
      type: UserType.customer,
    );
  }

  void addUser(AppUser user) {
    final exists = _users.any((existingUser) => existingUser.id == user.id);
    if (!exists) {
      _users.add(user);
    }
  }

  Future<void> saveSession(AppUser user) async {
    final prefs = await SharedPreferences.getInstance();

    await prefs.setString('user_id', user.id);
    await prefs.setString('user_name', user.name);
    await prefs.setString('user_email', user.email);
    await prefs.setString('user_type', user.type.toString().split('.').last);

    if (user.phone != null) {
      await prefs.setString('user_phone', user.phone!);
    }
    if (user.address != null) {
      await prefs.setString('user_address', user.address!);
    }
  }

  Future<void> clearSession() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.clear();
  }

  Future<String?> getSavedUserId() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('user_id');
  }

  Future<AppUser?> findUserById(String userId) async {
    try {
      return _users.firstWhere((user) => user.id == userId);
    } catch (_) {
      return null;
    }
  }

  Future<bool> hasSession() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.containsKey('user_id');
  }
}
