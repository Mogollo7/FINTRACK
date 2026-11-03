import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:path/path.dart' as pth;
import 'package:path_provider/path_provider.dart';
import 'package:provider/provider.dart';
import '../models/models.dart';
import '../services/database_helper.dart';
import '../state/app_state.dart';
import '../theme/fintrack_theme.dart';
import 'common.dart';
import 'profile_screens.dart';
import 'shell.dart';

// ----------------------------- Notificaciones -----------------------------
class NoticesScreen extends StatefulWidget {
  const NoticesScreen({super.key});
  @override
  State<NoticesScreen> createState() => _NoticesScreenState();
}

class _NoticesScreenState extends State<NoticesScreen> {
  int tab = 0;
  @override
  Widget build(BuildContext context) {
    final p = Pal.of(context);
    final s = context.watch<AppState>();
    final read = s.prefs.read;
    final all = s.notices;
    final unread = all.where((n) => !read.contains(n.id)).toList();
    final list = tab == 0 ? unread : all.where((n) => read.contains(n.id)).toList();
    return Scaffold(
      appBar: ftBar(context, 'Notificaciones', actions: [
        TextButton(
            onPressed: unread.isEmpty ? null : () => s.markRead(unread.map((n) => n.id)),
            child: Text('Limpiar todo', style: TextStyle(color: p.text, fontSize: 12))),
      ]),
      body: Column(children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(21, 4, 21, 16),
          child: Segmented(['Sin leer${unread.isEmpty ? '' : ' · ${unread.length}'}', 'Leídas'], tab, (i) => setState(() => tab = i)),
        ),
        Expanded(
          child: list.isEmpty
              ? StateView('notificaciones-vacio', 'Todo al día', 'Aquí verás avisos de gastos hormiga, metas y recordatorios.',
                  action: 'Configurar avisos', onAction: () => push(context, const SettingsScreen()))
              : ListView(padding: const EdgeInsets.fromLTRB(21, 0, 21, 30), children: [
                  for (final n in list)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 12),
                      child: Neo(
                        r: 13,
                        off: 3,
                        onTap: () => s.markRead([n.id]),
                        padding: const EdgeInsets.all(12),
                        child: Row(children: [
                          const IconDisc(Icons.pets, size: 38),
                          const SizedBox(width: 12),
                          Expanded(
                              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                            Text(n.title, style: const TextStyle(fontWeight: FontWeight.w700)),
                            const SizedBox(height: 2),
                            Text(n.body, style: TextStyle(fontSize: 12, color: p.text2)),
                          ])),
                          if (tab == 0) Container(width: 8, height: 8, decoration: BoxDecoration(color: p.expense, shape: BoxShape.circle)),
                        ]),
                      ),
                    ),
                ]),
        ),
      ]),
    );
  }
}

// --------------------------- Activos y pasivos ---------------------------
class AssetsScreen extends StatelessWidget {
  const AssetsScreen({super.key});

  Future<void> add(BuildContext c, bool liability) async {
    final name = await ask(c, liability ? 'Nuevo pasivo' : 'Nuevo activo', hint: 'Nombre (ej. Cuenta de ahorros)');
    if (name == null || name.isEmpty || !c.mounted) return;
    final v = parseMoney(await ask(c, 'Valor', hint: 'Valor en pesos', number: true));
    if (v == null || v <= 0 || !c.mounted) return;
    await c.read<AppState>().addAsset(AssetItem(name: name, amount: v, isLiability: liability));
  }

  @override
  Widget build(BuildContext context) {
    final p = Pal.of(context);
    final s = context.watch<AppState>();
    Widget group(String title, double total, Color c, bool liab) {
      final items = s.assets.where((a) => a.isLiability == liab);
      return Padding(
        padding: const EdgeInsets.only(bottom: 18),
        child: Neo(
          child: Column(children: [
            Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
              Text(title, style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 16)),
              Text(money(total), style: TextStyle(fontWeight: FontWeight.w800, fontSize: 16, color: c)),
            ]),
            if (!liab)
              Padding(
                  padding: const EdgeInsets.only(top: 10),
                  child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [const Text('Saldo en movimientos'), Text(money(s.balance))])),
            for (final a in items)
              Dismissible(
                key: ValueKey('a${a.id}'),
                direction: DismissDirection.endToStart,
                onDismissed: (_) => s.removeAsset(a.id!),
                background: Container(alignment: Alignment.centerRight, color: p.expense.withOpacity(.2), child: const Icon(Icons.delete)),
                child: Padding(
                    padding: const EdgeInsets.only(top: 10),
                    child: Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [Text(a.name), Text(money(a.amount))])),
              ),
            const SizedBox(height: 14),
            Align(
              alignment: Alignment.centerLeft,
              child: GestureDetector(
                onTap: () => add(context, liab),
                child: Row(mainAxisSize: MainAxisSize.min, children: [
                  const Icon(Icons.add_circle, size: 20),
                  const SizedBox(width: 8),
                  Text(liab ? 'Agregar pasivo' : 'Agregar activo', style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700)),
                ]),
              ),
            ),
          ]),
        ),
      );
    }

    return Scaffold(
      appBar: ftBar(context, 'Activos y pasivos'),
      body: ListView(padding: const EdgeInsets.fromLTRB(21, 8, 21, 30), children: [
        Neo(
          color: p.accent,
          padding: const EdgeInsets.all(18),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text('Patrimonio neto', style: TextStyle(fontSize: 12, color: p.onAccent)),
            FittedBox(
                fit: BoxFit.scaleDown,
                child: Text(money(s.netWorth), style: TextStyle(fontSize: 42, fontWeight: FontWeight.w600, color: p.onAccent))),
          ]),
        ),
        const SizedBox(height: 18),
        group('Activos', s.assetsTotal + (s.balance > 0 ? s.balance : 0), p.income, false),
        group('Pasivos', s.liabilitiesTotal, p.expense, true),
        Text('Desliza una fila hacia la izquierda para borrarla.', style: TextStyle(fontSize: 11, color: p.text2)),
      ]),
    );
  }
}

// ---------------------------- Límites de gasto ----------------------------
class LimitsScreen extends StatelessWidget {
  const LimitsScreen({super.key});

  Future<void> edit(BuildContext c, LimitItem l) async {
    final v = parseMoney(await ask(c, 'Nuevo límite', initial: l.amount.round().toString(), number: true));
    if (v != null && v > 0 && c.mounted) {
      await c.read<AppState>().saveLimit(LimitItem(id: l.id, category: l.category, period: l.period, amount: v));
    }
  }

  Future<void> addCat(BuildContext c) async {
    final cat = await showModalBottomSheet<String>(
      context: c,
      backgroundColor: Pal.of(c).bg,
      builder: (_) => SafeArea(
        child: ListView(shrinkWrap: true, children: [
          const Padding(padding: EdgeInsets.all(16), child: Text('Categoría', style: TextStyle(fontWeight: FontWeight.w800, fontSize: 18))),
          for (final e in expenseCats.entries) ListTile(leading: Icon(e.value), title: Text(e.key), onTap: () => Navigator.pop(c, e.key)),
        ]),
      ),
    );
    if (cat == null || !c.mounted) return;
    final v = parseMoney(await ask(c, 'Límite mensual de $cat', hint: 'Valor en pesos', number: true));
    if (v != null && v > 0 && c.mounted) await c.read<AppState>().saveLimit(LimitItem(category: cat, period: 'month', amount: v));
  }

  @override
  Widget build(BuildContext context) {
    final p = Pal.of(context);
    final s = context.watch<AppState>();
    Widget row(LimitItem l, String title) {
      final spent = s.spentFor(l);
      final pct = l.amount <= 0 ? 0.0 : spent / l.amount;
      return GestureDetector(
        onTap: () => edit(context, l),
        onLongPress: l.category == null ? null : () => s.removeLimit(l.id!),
        behavior: HitTestBehavior.opaque,
        child: Padding(
          padding: const EdgeInsets.only(bottom: 12),
          child: Column(children: [
            Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
              Text(title, style: const TextStyle(fontSize: 15)),
              Text(money(l.amount), style: const TextStyle(fontWeight: FontWeight.w800)),
            ]),
            const SizedBox(height: 6),
            PillBar(pct, color: pct >= 1 ? p.expense : p.accent),
            const SizedBox(height: 4),
            Align(
                alignment: Alignment.centerLeft,
                child: Text('Llevas ${money(spent)} · ${(pct * 100).round()} %', style: TextStyle(fontSize: 12, color: p.text2))),
          ]),
        ),
      );
    }

    final general = s.limits.where((l) => l.category == null).toList();
    final cats = s.limits.where((l) => l.category != null).toList();
    return Scaffold(
      appBar: ftBar(context, 'Límites de gasto'),
      body: ListView(padding: const EdgeInsets.fromLTRB(21, 8, 21, 30), children: [
        for (final l in general)
          Padding(
              padding: const EdgeInsets.only(bottom: 18),
              child: Neo(child: row(l, 'Gasto hormiga · ${l.period == 'week' ? 'semanal' : 'mensual'}'))),
        Neo(
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            const Text('Por categoría', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 16)),
            const SizedBox(height: 12),
            for (final l in cats) row(l, l.category!),
            if (cats.isEmpty)
              Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: Text('Aún no tienes límites por categoría.', style: TextStyle(color: p.text2))),
            GestureDetector(
              onTap: () => addCat(context),
              child: const Row(mainAxisSize: MainAxisSize.min, children: [
                Icon(Icons.add_circle, size: 20),
                SizedBox(width: 8),
                Text('Agregar límite por categoría', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700))
              ]),
            ),
          ]),
        ),
        const SizedBox(height: 18),
        SwitchRow(Icons.notifications, 'Avisarme al 80 %', 'Antes de llegar al límite', s.prefs.warn80, (v) => s.setFlag('warn80', v)),
        const SizedBox(height: 10),
        Text('Toca un límite para cambiarlo. Mantén pulsado un límite por categoría para borrarlo.',
            style: TextStyle(fontSize: 11, color: p.text2)),
      ]),
    );
  }
}

class SwitchRow extends StatelessWidget {
  final IconData icon;
  final String title, sub;
  final bool value;
  final ValueChanged<bool> onChanged;
  const SwitchRow(this.icon, this.title, this.sub, this.value, this.onChanged, {super.key});
  @override
  Widget build(BuildContext context) {
    final p = Pal.of(context);
    return Neo(
      r: 13,
      off: 3,
      padding: const EdgeInsets.all(14),
      child: Row(children: [
        IconDisc(icon, size: 34, filled: false),
        const SizedBox(width: 12),
        Expanded(
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(title, style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 16)),
            Text(sub, style: TextStyle(fontSize: 12, color: p.text2)),
          ]),
        ),
        GestureDetector(
          onTap: () => onChanged(!value),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 180),
            width: 54,
            height: 30,
            padding: const EdgeInsets.all(3),
            alignment: value ? Alignment.centerRight : Alignment.centerLeft,
            decoration: BoxDecoration(
                color: value ? p.accent : p.card, borderRadius: BorderRadius.circular(99), border: Border.all(color: p.border, width: 1.5)),
            child: Container(
                width: 22, height: 22, decoration: BoxDecoration(shape: BoxShape.circle, color: p.dark && !value ? p.text : p.ink)),
          ),
        ),
      ]),
    );
  }
}

// ---------------------------- Datos y respaldo ----------------------------
class DataScreen extends StatelessWidget {
  const DataScreen({super.key});

  Future<File> _file() async => File(pth.join((await getApplicationDocumentsDirectory()).path, 'fintrack_respaldo.json'));

  Future<void> export(BuildContext c) async {
    final s = c.read<AppState>();
    final data = {
      'version': 1,
      'movements': s.movements.map((m) => m.toMap()).toList(),
      'assets': s.assets.map((a) => a.toMap()).toList(),
      'limits': s.limits.map((l) => l.toMap()).toList(),
    };
    final f = await _file();
    await f.writeAsString(jsonEncode(data));
    if (c.mounted) toast(c, 'Copia exportada: ${pth.basename(f.path)}');
  }

  Future<void> import(BuildContext c) async {
    final s = c.read<AppState>();
    final f = await _file();
    if (!await f.exists()) {
      toast(c, 'No hay ninguna copia exportada en este teléfono');
      return;
    }
    if (!await confirm(c, 'Restaurar datos', 'Se reemplazarán los datos actuales por los de la última copia exportada.', 'Restaurar') ||
        !c.mounted) return;
    try {
      final d = jsonDecode(await f.readAsString()) as Map<String, dynamic>;
      final db = DatabaseHelper.instance;
      await db.wipe();
      for (final l in await db.limits()) {
        await db.deleteLimit(l.id!);
      }
      for (final m in d['movements'] as List) {
        await db.addMovement(Movement.fromMap(m as Map<String, dynamic>));
      }
      for (final a in d['assets'] as List) {
        await db.addAsset(AssetItem.fromMap(a as Map<String, dynamic>));
      }
      for (final l in d['limits'] as List) {
        await db.addLimit(LimitItem.fromMap(l as Map<String, dynamic>));
      }
      await s.load();
      if (c.mounted) toast(c, 'Datos restaurados');
    } catch (_) {
      if (c.mounted) toast(c, 'El archivo de copia no es válido');
    }
  }

  @override
  Widget build(BuildContext context) {
    final p = Pal.of(context);
    final s = context.watch<AppState>();
    Widget nav(IconData i, String t, String trail, VoidCallback f) => Padding(
          padding: const EdgeInsets.only(bottom: 12),
          child: Neo(
            r: 13,
            off: 3,
            onTap: f,
            padding: const EdgeInsets.all(14),
            child: Row(children: [
              IconDisc(i, size: 34, filled: false),
              const SizedBox(width: 12),
              Expanded(child: Text(t, style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 16))),
              Text(trail, style: TextStyle(fontSize: 12, color: p.text2)),
              const SizedBox(width: 6),
              const Icon(Icons.chevron_right),
            ]),
          ),
        );
    Widget head(String t) =>
        Padding(padding: const EdgeInsets.only(top: 12, bottom: 10), child: Text(t, style: TextStyle(fontSize: 12, color: p.text2)));
    return Scaffold(
      appBar: ftBar(context, 'Datos y respaldo'),
      body: ListView(padding: const EdgeInsets.fromLTRB(21, 4, 21, 30), children: [
        head('Modo de guardado'),
        SwitchRow(Icons.lock, 'Respaldo en la nube', 'Aún no disponible (entrega final)', false,
            (_) => toast(context, 'El respaldo en la nube llega en la entrega final')),
        const SizedBox(height: 12),
        SwitchRow(Icons.phone_android, 'Solo en este teléfono', 'Sin copia de seguridad', true, (_) {}),
        head('Copia y sincronización'),
        nav(Icons.sync, 'Sincronizar ahora', s.online ? 'Pendiente' : 'Sin conexión',
            () => s.online ? toast(context, 'La sincronización llega con el respaldo en la nube') : push(context, const OfflineScreen())),
        nav(Icons.file_download_outlined, 'Exportar datos', 'Archivo', () => export(context)),
        nav(Icons.add_circle_outline, 'Importar datos', 'Archivo', () => import(context)),
        head('Zona de riesgo'),
        nav(Icons.warning_amber_rounded, 'Borrar datos de la nube', '', () => toast(context, 'No hay copia en la nube que borrar')),
        Text('Tus datos viven en este teléfono. Tratamiento conforme a la Ley 1581 de 2012.',
            style: TextStyle(fontSize: 12, color: p.text2)),
      ]),
    );
  }
}

/// Pantalla «Sin conexión» (ilustración error-sin-conexion).
class OfflineScreen extends StatelessWidget {
  const OfflineScreen({super.key});
  @override
  Widget build(BuildContext context) => Scaffold(
        appBar: ftBar(context, 'Sin conexión'),
        body: StateView(
            'error-sin-conexion', 'Sin conexión', 'Tus gastos se guardan en el teléfono y se sincronizan cuando vuelvas a tener internet.',
            action: 'Reintentar',
            onAction: () => context.read<AppState>().online ? Navigator.pop(context) : toast(context, 'Sigues sin conexión'),
            action2: 'Volver al inicio',
            onAction2: () => Navigator.popUntil(context, (r) => r.isFirst)),
      );
}
