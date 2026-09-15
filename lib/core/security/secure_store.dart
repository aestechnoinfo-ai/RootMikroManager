import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class SecureStore {
  static const _s = FlutterSecureStorage();
  Future<void> saveRouterPassword(int id, String password) =>
      _s.write(key: 'router_password_$id', value: password);
  Future<String?> readRouterPassword(int id) =>
      _s.read(key: 'router_password_$id');
  Future<void> deleteRouterPassword(int id) =>
      _s.delete(key: 'router_password_$id');
}
