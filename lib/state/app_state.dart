import 'dart:async';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter/foundation.dart';
import '../models/models.dart';
import '../services/database_helper.dart';
import '../services/preferences_service.dart';

enum Period { week, month, year }

class Notice {
  final String id, title, body;
  Notice(this.id, this.title, this.body);
}

/// Estado central (MVVM con Provider): movimientos, límites, activos y ajustes.
class AppState extends ChangeNotifier {
  final Prefs prefs;
  final _db = DatabaseHelper.instance;
  StreamSubscription? _conn;

  AppState(this.prefs) {
    _conn = Connectivity().onConnectivityChanged.listen((r) => _setOnline(r));
    Connectivity().checkConnectivity().then(_setOnline);
  }

  void _setOnline(List<ConnectivityResult> r) {
    online = r.isNotEmpty && !r.contains(ConnectivityResult.none);
    notifyListeners();
  }

  List<Movement> movements = [];
  List<AssetItem> assets = [];
  List<LimitItem> limits = [];
  bool loading = true, failed = false, online = true;

  Future<void> load() async {
    loading = true;
    failed = false;
    notifyListeners();
    try {
      movements = await _db.movements();
      assets = await _db.assets();
      limits = await _db.limits();
    } catch (_) {
      failed = true;
    }
    loading = false;
    notifyListeners();
  }

  // ---- Ajustes
  bool get dark => prefs.dark;
  Future<void> refresh() async => notifyListeners();
  Future<void> setFlag(String k, bool v) async {
    await prefs.setBool(k, v);
    notifyListeners();
  }

  // ---- Escrituras
  Future<void> add(Movement m) async {
    await _db.addMovement(m);
    await load();
  }

  Future<void> update(Movement m) async {
    await _db.updateMovement(m);
    await load();
  }

  Future<void> remove(int id) async {
    await _db.deleteMovement(id);
    await load();
  }

  Future<void> addAsset(AssetItem a) async {
    await _db.addAsset(a);
    await load();
  }

  Future<void> removeAsset(int id) async {
    await _db.deleteAsset(id);
    await load();
  }

  Future<void> saveLimit(LimitItem l) async {
    l.id == null ? await _db.addLimit(l) : await _db.updateLimit(l);
    await load();
  }

  Future<void> removeLimit(int id) async {
    await _db.deleteLimit(id);
    await load();
  }

  // ---- Cálculos
  static DateTime _day(DateTime d) => DateTime(d.year, d.month, d.day);
  static DateTime weekStart(DateTime d) => _day(d).subtract(Duration(days: d.weekday - 1));

  (DateTime, DateTime) range(Period p) {
    final n = DateTime.now();
    switch (p) {
      case Period.week:
        final s = weekStart(n);
        return (s, s.add(const Duration(days: 7)));
      case Period.month:
        return (DateTime(n.year, n.month), DateTime(n.year, n.month + 1));
      case Period.year:
        return (DateTime(n.year), DateTime(n.year + 1));
    }
  }

  List<Movement> inPeriod(Period p, {bool? income}) {
    final (a, b) = range(p);
    return movements
        .where((m) => !m.date.isBefore(a) && m.date.isBefore(b) && (income == null || m.isIncome == income))
        .toList();
  }

  static double sum(Iterable<Movement> l) => l.fold(0.0, (s, m) => s + m.amount);

  double get totalIncome => sum(movements.where((m) => m.isIncome));
  double get totalExpense => sum(movements.where((m) => !m.isIncome));
  double get balance => totalIncome - totalExpense;

  double get assetsTotal => _sumA(assets.where((a) => !a.isLiability));
  double get liabilitiesTotal => _sumA(assets.where((a) => a.isLiability));
  double get netWorth => assetsTotal - liabilitiesTotal + balance;
  static double _sumA(Iterable<AssetItem> l) => l.fold(0.0, (s, a) => s + a.amount);

  /// Gasto por día de la semana en curso (lunes a domingo).
  List<double> get weekSeries {
    final s = weekStart(DateTime.now());
    return List.generate(7, (i) {
      final d = s.add(Duration(days: i));
      return sum(movements.where((m) => !m.isIncome && _day(m.date) == d));
    });
  }

  double get weekSpent => sum(inPeriod(Period.week, income: false));

  /// «Dinero invisible»: el gasto hormiga de la semana en cosas cotidianas.
  String? get antEquivalence {
    final ant = sum(inPeriod(Period.week, income: false).where((m) => m.isAnt));
    if (ant <= 0) return null;
    if (ant >= 12000) return 'Tu gasto hormiga de esta semana equivale a ${(ant / 12000).toStringAsFixed(1).replaceAll('.', ',')} almuerzos.';
    final cafes = (ant / 2500).round();
    return 'Tu gasto hormiga de esta semana equivale a $cafes ${cafes == 1 ? 'café' : 'cafés'}.';
  }

  /// Límite que se superaría al agregar este gasto (para la pausa de «fricción consciente»).
  LimitItem? limitExceededBy(String category, double amount) {
    final ant = classify(category, amount) == kHormiga;
    for (final l in limits) {
      if (l.amount <= 0 || (l.category == null ? !ant : l.category != category)) continue;
      if (spentFor(l) < l.amount && spentFor(l) + amount > l.amount) return l;
    }
    return null;
  }

  /// Variación del gasto frente a la semana anterior (null si no hay base).
  double? get weekDelta {
    final s = weekStart(DateTime.now());
    final prev = sum(movements.where(
        (m) => !m.isIncome && !m.date.isBefore(s.subtract(const Duration(days: 7))) && m.date.isBefore(s)));
    return prev == 0 ? null : (weekSpent - prev) / prev * 100;
  }

  Map<String, double> byKind(Period p) {
    final r = {kFijo: 0.0, kNecesario: 0.0, kHormiga: 0.0};
    for (final m in inPeriod(p, income: false)) {
      r[m.kind] = (r[m.kind] ?? 0) + m.amount;
    }
    return r;
  }

  List<MapEntry<String, double>> byCategory(Period p, {bool income = false}) {
    final r = <String, double>{};
    for (final m in inPeriod(p, income: income)) {
      r[m.category] = (r[m.category] ?? 0) + m.amount;
    }
    return r.entries.toList()..sort((a, b) => b.value.compareTo(a.value));
  }

  /// Gastado frente a un límite (hormiga o por categoría) en su periodo.
  double spentFor(LimitItem l) {
    final list = inPeriod(l.period == 'week' ? Period.week : Period.month, income: false);
    return sum(l.category == null ? list.where((m) => m.isAnt) : list.where((m) => m.category == l.category));
  }

  /// Avisos generados a partir de los datos (sin servidor).
  List<Notice> get notices {
    final out = <Notice>[];
    final wk = weekStart(DateTime.now()).toIso8601String();
    final ant = sum(inPeriod(Period.week, income: false).where((m) => m.isAnt));
    if (prefs.antAlerts && ant > 0) {
      out.add(Notice('ant-$wk-${ant.round()}', 'Gasto hormiga detectado',
          'Llevas ${money(ant)} en gastos hormiga esta semana.'));
    }
    final d = weekDelta;
    if (d != null && d < 0) {
      out.add(Notice('good-$wk', 'Vas por buen camino', 'Gastaste ${d.abs().round()} % menos que la semana pasada.'));
    }
    if (prefs.warn80) {
      final mo = DateTime(DateTime.now().year, DateTime.now().month).toIso8601String();
      for (final l in limits) {
        final pct = l.amount <= 0 ? 0.0 : spentFor(l) / l.amount;
        if (pct >= .8) {
          out.add(Notice('lim-${l.id}-${pct >= 1 ? 'over' : 'near'}-${l.period == 'week' ? wk : mo}',
              pct >= 1 ? 'Superaste tu límite' : 'Cerca de tu límite',
              '${l.category ?? 'Gasto hormiga'} · ${l.period == 'week' ? 'semanal' : 'mensual'}: llevas ${(pct * 100).round()} %.'));
        }
      }
    }
    return out;
  }

  Future<void> markRead(Iterable<String> ids) async {
    await prefs.setRead({...prefs.read, ...ids});
    notifyListeners();
  }

  int get unread => notices.where((n) => !prefs.read.contains(n.id)).length;

  @override
  void dispose() {
    _conn?.cancel();
    super.dispose();
  }
}

/// $ 63.350 (pesos colombianos, sin decimales).
String money(num v, {bool sign = false}) {
  final s = v.abs().round().toString().replaceAllMapped(RegExp(r'\B(?=(\d{3})+(?!\d))'), (_) => '.');
  final pre = v < 0 ? '-' : (sign && v > 0 ? '+' : '');
  return '$pre\$ $s';
}
