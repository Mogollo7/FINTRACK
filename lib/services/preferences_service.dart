import 'package:shared_preferences/shared_preferences.dart';

class PreferencesService {
  static const String _keyWeeklyBudget = 'fintrack_weekly_budget';
  static const String _keyDarkMode = 'fintrack_dark_mode';

  Future<double> getWeeklyBudget() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getDouble(_keyWeeklyBudget) ?? 50000.0; // Valor por defecto COP
  }

  Future<void> saveWeeklyBudget(double budget) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setDouble(_keyWeeklyBudget, budget);
  }

  Future<bool> getDarkMode() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_keyDarkMode) ?? false;
  }

  Future<void> saveDarkMode(bool enabled) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_keyDarkMode, enabled);
  }
}

