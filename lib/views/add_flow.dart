import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:image_picker/image_picker.dart';
import 'package:path/path.dart' as pth;
import 'package:path_provider/path_provider.dart';
import 'package:provider/provider.dart';
import '../models/models.dart';
import '../state/app_state.dart';
import '../theme/fintrack_theme.dart';
import 'common.dart';
import 'shell.dart';

// ------------------------------ Agregar ------------------------------
class AddScreen extends StatefulWidget {
  final bool income;
  const AddScreen({super.key, this.income = false});
  @override
  State<AddScreen> createState() => _AddScreenState();
}

class _AddScreenState extends State<AddScreen> {
  late bool income = widget.income;
  String? cat;
  DateTime date = DateTime.now();

  @override
  Widget build(BuildContext context) {
    final p = Pal.of(context);
    final cats = income ? incomeCats : expenseCats;
    return Scaffold(
      appBar: ftBar(context, 'Agregar', close: true),
      body: ListView(padding: const EdgeInsets.fromLTRB(21, 6, 21, 24), children: [
        Segmented(const ['Ingreso', 'Gasto'], income ? 0 : 1, (i) => setState(() {
              income = i == 0;
              cat = null;
            })),
        label(context, 'Categoría'),
        GridView.count(
          crossAxisCount: 4,
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          mainAxisSpacing: 14,
          childAspectRatio: .85,
          children: [
            for (final e in cats.entries)
              GestureDetector(
                onTap: () => setState(() => cat = e.key),
                child: Column(children: [
                  Container(
                    width: 52,
                    height: 52,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: cat == e.key ? p.accent : p.alt,
                      border: Border.all(color: p.border, width: cat == e.key ? 2.5 : 1.5),
                    ),
                    child: Icon(e.value, color: cat == e.key ? p.onAccent : p.text),
                  ),
                  const SizedBox(height: 6),
                  Text(e.key, style: const TextStyle(fontSize: 11)),
                ]),
              ),
          ],
        ),
        label(context, 'Fecha'),
        Neo(
          r: 13,
          off: 0,
          padding: const EdgeInsets.all(14),
          onTap: () async {
            final d = await showDatePicker(context: context, initialDate: date, firstDate: DateTime(2020), lastDate: DateTime.now());
            if (d != null) setState(() => date = DateTime(d.year, d.month, d.day, DateTime.now().hour, DateTime.now().minute));
          },
          child: Row(children: [
            const Icon(Icons.alarm, size: 20),
            const SizedBox(width: 10),
            Text(relDay(date) == 'Hoy' ? 'Hoy, ${date.day} de ${months[date.month - 1]}' : '${date.day} de ${months[date.month - 1]}'),
          ]),
        ),
        const SizedBox(height: 40),
        FtButton('Continuar',
            onTap: cat == null ? null : () => push(context, AmountScreen(income: income, category: cat!, date: date))),
      ]),
    );
  }
}

// ------------------------------- Monto -------------------------------
class AmountScreen extends StatefulWidget {
  final bool income;
  final String category;
  final DateTime date;
  final Movement? editing;
  const AmountScreen({super.key, required this.income, required this.category, required this.date, this.editing});
  @override
  State<AmountScreen> createState() => _AmountScreenState();
}

class _AmountScreenState extends State<AmountScreen> {
  late String digits = widget.editing == null ? '' : widget.editing!.amount.round().toString();
  late final note = TextEditingController(text: widget.editing?.note ?? '');
  String? photo;
  bool saving = false;

  @override
  void initState() {
    super.initState();
    photo = widget.editing?.photoPath;
  }

  void key(String k) => setState(() {
        if (k == '<') {
          if (digits.isNotEmpty) digits = digits.substring(0, digits.length - 1);
        } else if ((digits + k).length <= 9) {
          digits = digits.isEmpty && k.startsWith('0') ? '' : digits + k;
        }
      });

  Future<void> pickPhoto() async {
    final src = await showModalBottomSheet<ImageSource>(
      context: context,
      backgroundColor: Pal.of(context).bg,
      builder: (_) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(21),
          child: Column(mainAxisSize: MainAxisSize.min, children: [
            FtButton('Escanear con la cámara', onTap: () => Navigator.pop(context, ImageSource.camera)),
            const SizedBox(height: 12),
            FtButton('Elegir de la galería', primary: false, onTap: () => Navigator.pop(context, ImageSource.gallery)),
          ]),
        ),
      ),
    );
    if (src == null) return;
    try {
      final x = await ImagePicker().pickImage(source: src, imageQuality: 75, maxWidth: 1600);
      if (x == null) return;
      final dir = await getApplicationDocumentsDirectory();
      final dest = pth.join(dir.path, 'tiquete_${DateTime.now().millisecondsSinceEpoch}${pth.extension(x.path)}');
      await File(x.path).copy(dest);
      setState(() => photo = dest);
    } on PlatformException catch (e) {
      // Permiso negado: el gasto se puede guardar igual, sin tiquete.
      if (mounted) {
        toast(context, e.code.contains('denied') ? 'Sin permiso de cámara: guarda el gasto sin tiquete o actívalo en Ajustes de Android' : 'No se pudo abrir la cámara');
      }
    } catch (_) {
      if (mounted) toast(context, 'No se pudo abrir la cámara');
    }
  }

  Future<void> save() async {
    final amount = double.tryParse(digits) ?? 0;
    if (amount <= 0) return;
    final s = context.read<AppState>();
    // Fricción consciente: una pausa antes de pasar un límite (no se aplica al editar).
    final over = widget.income || widget.editing != null ? null : s.limitExceededBy(widget.category, amount);
    if (over != null &&
        !await confirm(context, '¿Seguro?',
            'Con este gasto superas tu límite ${over.category ?? 'hormiga'} ${over.period == 'week' ? 'semanal' : 'mensual'} de ${money(over.amount)}.',
            'Guardar igual')) {
      return;
    }
    if (!mounted) return;
    setState(() => saving = true);
    HapticFeedback.mediumImpact();
    final old = widget.editing;
    final m = Movement(
      id: old?.id,
      amount: amount,
      isIncome: widget.income,
      category: widget.category,
      kind: widget.income ? 'ingreso' : classify(widget.category, amount),
      note: note.text.trim(),
      date: old?.date ?? widget.date,
      photoPath: photo,
    );
    if (old != null) {
      await s.update(m);
      if (mounted) {
        toast(context, 'Cambios guardados');
        Navigator.pop(context);
        Navigator.pop(context);
      }
      return;
    }
    await s.add(m);
    if (!mounted) return;
    Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => RegisteredScreen(m)));
  }

  @override
  Widget build(BuildContext context) {
    final p = Pal.of(context);
    final amount = double.tryParse(digits) ?? 0;
    Widget k(String t) => GestureDetector(
          onTap: () => key(t == '⌫' ? '<' : t),
          child: Container(
            height: 48,
            alignment: Alignment.center,
            decoration: p.box(r: 10, off: 2, color: t == '⌫' ? p.ink : p.card),
            child: t == '⌫'
                ? Icon(Icons.backspace, color: p.dark ? p.accent : Colors.white, size: 20)
                : Text(t, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w600)),
          ),
        );
    return Scaffold(
      appBar: ftBar(context, widget.editing != null ? 'Editar movimiento' : (widget.income ? 'Nuevo ingreso' : 'Nuevo gasto'), close: true),
      body: ListView(padding: EdgeInsets.fromLTRB(21, 0, 21, 24 + MediaQuery.of(context).viewPadding.bottom), children: [
        Align(
          alignment: Alignment.centerLeft,
          child: Container(
            padding: const EdgeInsets.fromLTRB(4, 4, 14, 4),
            decoration: p.box(r: 99, off: 0),
            child: Row(mainAxisSize: MainAxisSize.min, children: [
              IconDisc(catIcon(widget.category), size: 30),
              const SizedBox(width: 8),
              Text(widget.category, style: const TextStyle(fontWeight: FontWeight.w600)),
            ]),
          ),
        ),
        const SizedBox(height: 22),
        Center(child: Text('Monto', style: TextStyle(color: p.text2, fontSize: 12))),
        Center(child: Text(money(amount), style: const TextStyle(fontSize: 42, fontWeight: FontWeight.w600))),
        if (!widget.income && widget.editing == null) ...[
          const SizedBox(height: 10),
          // Montos rápidos: un toque para los gastos hormiga más comunes.
          Row(mainAxisAlignment: MainAxisAlignment.center, children: [
            for (final v in [2000, 5000, 10000])
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 5),
                child: GestureDetector(
                  onTap: () {
                    HapticFeedback.selectionClick();
                    setState(() => digits = '$v');
                  },
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 13),
                    decoration: p.box(r: 99, off: 2, color: digits == '$v' ? p.accent : p.alt),
                    child: Text(money(v), style: TextStyle(fontWeight: FontWeight.w700, color: digits == '$v' ? p.onAccent : p.text)),
                  ),
                ),
              ),
          ]),
        ],
        label(context, 'Nota'),
        ftField(context, note, 'Ej. Café con Ana', icon: Icons.sticky_note_2_outlined),
        if (!widget.income) ...[
          label(context, 'Tiquete'),
          Neo(
            r: 13,
            off: 0,
            padding: const EdgeInsets.all(12),
            onTap: pickPhoto,
            child: Row(children: [
              const Icon(Icons.photo_camera_outlined),
              const SizedBox(width: 10),
              Expanded(child: Text(photo == null ? 'Adjuntar tiquete' : pth.basename(photo!), overflow: TextOverflow.ellipsis)),
              if (photo != null) GestureDetector(onTap: () => setState(() => photo = null), child: const Icon(Icons.close, size: 18)),
            ]),
          ),
        ],
        const SizedBox(height: 18),
        GridView.count(
          crossAxisCount: 3,
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          mainAxisSpacing: 10,
          crossAxisSpacing: 10,
          childAspectRatio: 2.2,
          children: [for (final t in ['1', '2', '3', '4', '5', '6', '7', '8', '9', '000', '0', '⌫']) k(t)],
        ),
        const SizedBox(height: 22),
        FtButton(widget.editing != null ? 'Guardar cambios' : (widget.income ? 'Guardar ingreso' : 'Guardar gasto'),
            onTap: amount > 0 && !saving ? save : null),
      ]),
    );
  }
}

// ---------------------------- Gasto registrado ----------------------------
class RegisteredScreen extends StatelessWidget {
  final Movement m;
  const RegisteredScreen(this.m, {super.key});
  @override
  Widget build(BuildContext context) {
    final p = Pal.of(context);
    final s = context.watch<AppState>();
    final near = m.isIncome
        ? null
        : s.limits.where((l) => l.amount > 0 && s.spentFor(l) / l.amount >= .9 && (l.category == null ? m.isAnt : l.category == m.category)).firstOrNull;
    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(21),
          child: Column(children: [
            const Spacer(),
            const Ilus('gasto-registrado', 220),
            const SizedBox(height: 18),
            Text(m.isIncome ? '¡Ingreso guardado!' : '¡Gasto registrado!', style: const TextStyle(fontSize: 24, fontWeight: FontWeight.w800)),
            const SizedBox(height: 18),
            MovementTile(m),
            if (near != null)
              Neo(
                color: p.alt,
                r: 13,
                off: 3,
                padding: const EdgeInsets.all(12),
                child: Row(children: [
                  const Icon(Icons.warning_amber_rounded),
                  const SizedBox(width: 10),
                  Expanded(child: Text('Llevas ${(s.spentFor(near) / near.amount * 100).round()} % de tu límite ${near.category ?? 'hormiga'} ${near.period == 'week' ? 'semanal' : 'mensual'}.')),
                ]),
              ),
            const Spacer(),
            FtButton('Volver al inicio', onTap: () => Navigator.popUntil(context, (r) => r.isFirst)),
            const SizedBox(height: 12),
            FtButton('Agregar otro', primary: false, onTap: () => Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => AddScreen(income: m.isIncome)))),
          ]),
        ),
      ),
    );
  }
}

// ------------------------------- Detalle -------------------------------
class DetailScreen extends StatelessWidget {
  final int id;
  const DetailScreen(this.id, {super.key});
  @override
  Widget build(BuildContext context) {
    final p = Pal.of(context);
    final s = context.watch<AppState>();
    final m = s.movements.where((e) => e.id == id).firstOrNull;
    if (m == null) return Scaffold(appBar: ftBar(context, 'Detalle', close: true), body: const SizedBox());
    Widget field(Widget child) => Neo(r: 13, off: 0, padding: const EdgeInsets.all(14), child: child);
    return Scaffold(
      appBar: ftBar(context, 'Detalle', close: true),
      body: ListView(padding: const EdgeInsets.fromLTRB(21, 0, 21, 24), children: [
        Align(
          alignment: Alignment.centerLeft,
          child: Container(
            padding: const EdgeInsets.fromLTRB(4, 4, 16, 4),
            decoration: p.box(r: 99, off: 0),
            child: Row(mainAxisSize: MainAxisSize.min, children: [
              IconDisc(catIcon(m.category), size: 34),
              const SizedBox(width: 8),
              Text(m.category, style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 16)),
            ]),
          ),
        ),
        const SizedBox(height: 22),
        Center(child: Text('Monto', style: TextStyle(color: p.text2, fontSize: 12))),
        Center(child: Text(money(m.amount), style: const TextStyle(fontSize: 42, fontWeight: FontWeight.w600))),
        label(context, 'Nota'),
        field(Row(children: [const Icon(Icons.sticky_note_2_outlined), const SizedBox(width: 10), Expanded(child: Text(m.note.isEmpty ? '(sin nota)' : m.note))])),
        if (m.photoPath != null) ...[
          label(context, 'Tiquete'),
          field(Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Row(children: [const Icon(Icons.receipt_long), const SizedBox(width: 10), Expanded(child: Text(pth.basename(m.photoPath!), overflow: TextOverflow.ellipsis))]),
            if (File(m.photoPath!).existsSync()) ...[
              const SizedBox(height: 10),
              ClipRRect(borderRadius: BorderRadius.circular(10), child: Image.file(File(m.photoPath!), height: 180, width: double.infinity, fit: BoxFit.cover)),
            ],
          ])),
        ],
        label(context, 'Fecha'),
        field(Row(children: [const Icon(Icons.alarm), const SizedBox(width: 10), Text('${relDay(m.date)}, ${m.date.day} de ${months[m.date.month - 1]} · ${hhmm(m.date)}')])),
        if (m.isAnt) ...[const SizedBox(height: 14), const Align(alignment: Alignment.centerLeft, child: AntBadge(text: 'HORMIGA · cuenta para tu límite semanal'))],
        const SizedBox(height: 40),
        Row(children: [
          Expanded(
              child: FtButton('Eliminar', primary: false, onTap: () async {
            if (await confirm(context, '¿Eliminar movimiento?', 'Esta acción no se puede deshacer.', 'Eliminar')) {
              await s.remove(m.id!);
              if (context.mounted) {
                Navigator.pop(context);
                toast(context, 'Gasto eliminado');
              }
            }
          })),
          const SizedBox(width: 12),
          Expanded(child: FtButton('Editar', onTap: () => push(context, AmountScreen(income: m.isIncome, category: m.category, date: m.date, editing: m)))),
        ]),
      ]),
    );
  }
}

// ------------------------------ Movimientos ------------------------------
class MovementsScreen extends StatefulWidget {
  const MovementsScreen({super.key});
  @override
  State<MovementsScreen> createState() => _MovementsScreenState();
}

class _MovementsScreenState extends State<MovementsScreen> {
  int tab = 0;
  String? cat; // filtro por categoría (null = todas)
  @override
  Widget build(BuildContext context) {
    final p = Pal.of(context);
    final s = context.watch<AppState>();
    final byTab = s.movements.where((m) => tab == 0 || (tab == 1) == m.isIncome).toList();
    final cats = {for (final m in byTab) m.category}.toList()..sort();
    final list = byTab.where((m) => cat == null || m.category == cat).toList();
    final groups = <String, List<Movement>>{};
    for (final m in list) {
      groups.putIfAbsent(relDay(m.date), () => []).add(m);
    }
    return Scaffold(
      appBar: ftBar(context, 'Movimientos'),
      body: s.movements.isEmpty
          ? StateView('sin-movimientos', 'Aún no hay movimientos', 'Registra tu primer gasto y aparecerá aquí.',
              action: 'Agregar gasto', onAction: () => push(context, const AddScreen()))
          : ListView(padding: const EdgeInsets.fromLTRB(21, 4, 21, 30), children: [
              Segmented(const ['Todos', 'Ingresos', 'Gastos'], tab, (i) => setState(() {
                    tab = i;
                    cat = null;
                  })),
              const SizedBox(height: 12),
              if (cats.length > 1)
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(children: [
                    for (final c in [null, ...cats])
                      Padding(
                        padding: const EdgeInsets.only(right: 8, bottom: 4),
                        child: GestureDetector(
                          onTap: () => setState(() => cat = c),
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 13),
                            decoration: p.box(r: 99, off: 2, color: cat == c ? p.accent : p.card),
                            child: Row(mainAxisSize: MainAxisSize.min, children: [
                              if (c != null) ...[Icon(catIcon(c), size: 16, color: cat == c ? p.onAccent : p.text), const SizedBox(width: 6)],
                              Text(c ?? 'Todas', style: TextStyle(fontWeight: FontWeight.w600, color: cat == c ? p.onAccent : p.text)),
                            ]),
                          ),
                        ),
                      ),
                  ]),
                ),
              const SizedBox(height: 8),
              if (list.isEmpty) Padding(padding: const EdgeInsets.all(30), child: Center(child: Text('Nada por aquí.', style: TextStyle(color: Pal.of(context).text2)))),
              for (final g in groups.entries) ...[
                Padding(padding: const EdgeInsets.only(top: 8, bottom: 10), child: Text(g.key, style: TextStyle(fontSize: 12, color: Pal.of(context).text2))),
                for (final m in g.value) MovementTile(m, onTap: () => push(context, DetailScreen(m.id!))),
              ],
            ]),
    );
  }
}
