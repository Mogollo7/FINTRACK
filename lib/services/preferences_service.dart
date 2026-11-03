import 'dart:convert';
import 'package:crypto/crypto.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Cuenta local + ajustes (SharedPreferences). La contraseña se guarda con sal + SHA-256.
class Prefs {
  final SharedPreferences p;
  Prefs(this.p);
  static Future<Prefs> load() async => Prefs(await SharedPreferences.getInstance());

  String get name => p.getString('name') ?? '';
  String get email => p.getString('email') ?? '';
  bool get hasAccount => email.isNotEmpty;
  bool get loggedIn => p.getBool('loggedIn') ?? false;
  bool get onboarded => p.getBool('onboarded') ?? false;
  bool get dark => p.getBool('dark') ?? false;
  bool get antAlerts => p.getBool('antAlerts') ?? true;
  bool get remind => p.getBool('remind') ?? false;
  bool get warn80 => p.getBool('warn80') ?? true;
  bool get cloud => p.getBool('cloud') ?? false;
  Set<String> get read => (p.getStringList('read') ?? []).toSet();

  Future<void> setBool(String k, bool v) => p.setBool(k, v);
  Future<void> setRead(Set<String> s) => p.setStringList('read', s.toList());

  String _hash(String pass, String salt) => sha256.convert(utf8.encode('$salt:$pass')).toString();

  Future<void> register(String name, String email, String pass) async {
    final salt = DateTime.now().microsecondsSinceEpoch.toString();
    await p.setString('name', name);
    await p.setString('email', email.trim().toLowerCase());
    await p.setString('salt', salt);
    await p.setString('hash', _hash(pass, salt));
    await p.setBool('loggedIn', true);
  }

  bool check(String email, String pass) =>
      email.trim().toLowerCase() == this.email && _hash(pass, p.getString('salt') ?? '') == p.getString('hash');

  Future<void> updateProfile(String name, String email) async {
    await p.setString('name', name);
    await p.setString('email', email.trim().toLowerCase());
  }

  Future<void> deleteAccount() async {
    for (final k in ['name', 'email', 'salt', 'hash', 'loggedIn', 'cloud', 'read']) {
      await p.remove(k);
    }
  }
}
