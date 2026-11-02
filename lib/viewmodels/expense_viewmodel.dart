import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import '../models/expense.dart';
import '../services/database_helper.dart';
import '../services/preferences_service.dart';

class ExpenseViewModel extends ChangeNotifier {
  final DatabaseHelper _dbHelper = DatabaseHelper.instance;
  final PreferencesService _prefsService = PreferencesService();

  List<Expense> _expenses = [];
  double _weeklyBudget = 50000.0;
  bool _isLoading = true;
  bool _isOnline = true;
  StreamSubscription? _connectivitySubscription;

  List<Expense> get expenses => _expenses;
  double get weeklyBudget => _weeklyBudget;
  bool get isLoading => _isLoading;
  bool get isOnline => _isOnline;

  double get totalSpent {
    return _expenses.fold(0.0, (sum, item) => sum + item.amount);
  }

  double get remainingBudget {
    final remaining = _weeklyBudget - totalSpent;
    return remaining > 0 ? remaining : 0.0;
  }

  double get budgetProgressPercentage {
    if (_weeklyBudget <= 0) return 1.0;
    final progress = totalSpent / _weeklyBudget;
    return progress > 1.0 ? 1.0 : progress;
  }

  bool get isNearOrExceedingBudget {
    return totalSpent >= (_weeklyBudget * 0.8);
  }

  // Equivalencias cotidianas universitarias
  String get dynamicEquivalence {
    if (totalSpent == 0) return '¡Aún no tienes gastos hormiga esta semana! Buen hábito.';
    final cafes = (totalSpent / 2500).floor();
    final almuerzos = (totalSpent / 12000).toStringAsFixed(1);
    final fotocopias = (totalSpent / 200).floor();

    if (totalSpent >= 24000) {
      return 'Tus gastos hormiga equivalen a aprox. $almuerzos almuerzos universitarios.';
    } else if (totalSpent >= 5000) {
      return 'Tus gastos hormiga equivalen a $cafes cafés de máquina o $fotocopias fotocopias.';
    } else {
      return 'Tus gastos hormiga equivalen a $cafes café(s) en la cafetería.';
    }
  }

  ExpenseViewModel() {
    _init();
  }

  Future<void> _init() async {
    _isLoading = true;
    notifyListeners();

    _weeklyBudget = await _prefsService.getWeeklyBudget();
    _expenses = await _dbHelper.getAllExpenses();

    // Monitoreo de conectividad
    final connectivityResult = await Connectivity().checkConnectivity();
    _isOnline = connectivityResult != ConnectivityResult.none;

    _connectivitySubscription = Connectivity().onConnectivityChanged.listen((result) {
      _isOnline = result != ConnectivityResult.none;
      notifyListeners();
    });

    _isLoading = false;
    notifyListeners();
  }

  Future<void> addExpense({
    required double amount,
    required String category,
    required String note,
    String? photoPath,
  }) async {
    final newExpense = Expense(
      amount: amount,
      category: category,
      note: note,
      date: DateTime.now(),
      photoPath: photoPath,
      isAnt: true,
    );

    final saved = await _dbHelper.createExpense(newExpense);
    _expenses.insert(0, saved);
    notifyListeners();
  }

  Future<void> updateExpense(Expense expense) async {
    await _dbHelper.updateExpense(expense);
    final index = _expenses.indexWhere((e) => e.id == expense.id);
    if (index != -1) {
      _expenses[index] = expense;
      notifyListeners();
    }
  }

  Future<void> deleteExpense(int id) async {
    await _dbHelper.deleteExpense(id);
    _expenses.removeWhere((e) => e.id == id);
    notifyListeners();
  }

  Future<void> updateBudget(double newBudget) async {
    _weeklyBudget = newBudget;
    await _prefsService.saveWeeklyBudget(newBudget);
    notifyListeners();
  }

  @override
  void dispose() {
    _connectivitySubscription?.cancel();
    super.dispose();
  }
}

