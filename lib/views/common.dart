import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import '../models/models.dart';
import '../state/app_state.dart';
import '../theme/fintrack_theme.dart';

const days = ['Lun', 'Mar', 'Mié', 'Jue', 'Vie', 'Sáb', 'Dom'];
const months = [
  'enero',
  'febrero',
  'marzo',
  'abril',
  'mayo',
  'junio',
  'julio',
  'agosto',
  'septiembre',
  'octubre',
  'noviembre',
  'diciembre'
];

String hhmm(DateTime d) {
  final h = d.hour % 12 == 0 ? 12 : d.hour % 12;
  return '$h:${d.minute.toString().padLeft(2, '0')} ${d.hour < 12 ? 'a. m.' : 'p. m.'}';
}

String relDay(DateTime d) {
  final n = DateTime.now();
  final diff = DateTime(n.year, n.month, n.day).difference(DateTime(d.year, d.month, d.day)).inDays;
  if (diff == 0) return 'Hoy';
  if (diff == 1) return 'Ayer';
  if (diff < 7) return 'Hace $diff días';
  return '${d.day} de ${months[d.month - 1]}';
}

class Logo extends StatelessWidget {
  final double size;
  const Logo({super.key, this.size = 26});
  @override
  Widget build(BuildContext context) {
    final p = Pal.of(context);
    return Row(mainAxisSize: MainAxisSize.min, children: [
      SvgPicture.asset('assets/icon/cat_mascot.svg', height: size * 1.1, colorFilter: ColorFilter.mode(p.text, BlendMode.srcIn)),
      const SizedBox(width: 6),
      Text.rich(TextSpan(style: TextStyle(fontSize: size, color: p.text), children: const [
        TextSpan(text: 'Fin', style: TextStyle(fontWeight: FontWeight.w300)),
        TextSpan(text: 'Track', style: TextStyle(fontWeight: FontWeight.w800)),
      ])),
    ]);
  }
}

class Ilus extends StatelessWidget {
  final String name;
  final double size;
  const Ilus(this.name, this.size, {super.key});
  @override
  Widget build(BuildContext context) => Image.asset('assets/ilus/ILUSTRACION_$name.png', width: size, height: size, fit: BoxFit.contain);
}

class Cat extends StatelessWidget {
  final double height;
  final Color? color;
  const Cat(this.height, {super.key, this.color});
  @override
  Widget build(BuildContext context) => SvgPicture.asset('assets/icon/cat_mascot.svg',
      height: height, colorFilter: ColorFilter.mode(color ?? Pal.of(context).text, BlendMode.srcIn));
}

class SectionTitle extends StatelessWidget {
  final String text;
  final Widget? trailing;
  const SectionTitle(this.text, {super.key, this.trailing});
  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.only(top: 22, bottom: 12),
        child: Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
          Text(text, style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w700)),
          if (trailing != null) trailing!,
        ]),
      );
}

class Segmented extends StatelessWidget {
  final List<String> labels;
  final int index;
  final ValueChanged<int> onChanged;
  const Segmented(this.labels, this.index, this.onChanged, {super.key});
  @override
  Widget build(BuildContext context) {
    final p = Pal.of(context);
    return Container(
      decoration: p.box(r: 13, off: 3),
      clipBehavior: Clip.antiAlias,
      child: Row(children: [
        for (var i = 0; i < labels.length; i++)
          Expanded(
            child: GestureDetector(
              onTap: () => onChanged(i),
              behavior: HitTestBehavior.opaque,
              child: Container(
                height: 44,
                alignment: Alignment.center,
                color: i == index ? p.accent : Colors.transparent,
                child: Text(labels[i],
                    style: TextStyle(fontWeight: i == index ? FontWeight.w700 : FontWeight.w500, color: i == index ? p.onAccent : p.text)),
              ),
            ),
          ),
      ]),
    );
  }
}

/// Campo de texto del mockup (borde oscuro, radio 13).
Widget ftField(BuildContext c, TextEditingController ctl, String hint,
    {IconData? icon, bool obscure = false, TextInputType? type, Widget? suffix, ValueChanged<String>? onChanged}) {
  final p = Pal.of(c);
  return Container(
    decoration: BoxDecoration(color: p.card, borderRadius: BorderRadius.circular(13), border: Border.all(color: p.border, width: 1.5)),
    child: TextField(
      controller: ctl,
      obscureText: obscure,
      keyboardType: type,
      onChanged: onChanged,
      style: TextStyle(color: p.text, fontSize: 15),
      decoration: InputDecoration(
        hintText: hint,
        hintStyle: TextStyle(color: p.text2),
        border: InputBorder.none,
        prefixIcon: icon == null ? null : Icon(icon, size: 20, color: p.text),
        suffixIcon: suffix,
        contentPadding: const EdgeInsets.symmetric(vertical: 14, horizontal: 12),
      ),
    ),
  );
}

Widget label(BuildContext c, String t) =>
    Padding(padding: const EdgeInsets.only(bottom: 6, top: 14), child: Text(t, style: TextStyle(fontSize: 12, color: Pal.of(c).text2)));

/// Barra de progreso en forma de píldora.
class PillBar extends StatelessWidget {
  final double value;
  final Color? color;
  final Color? track;
  final double height;
  const PillBar(this.value, {super.key, this.color, this.track, this.height = 10});
  @override
  Widget build(BuildContext context) {
    final p = Pal.of(context);
    return Container(
      height: height,
      decoration:
          BoxDecoration(color: track ?? p.alt, borderRadius: BorderRadius.circular(99), border: Border.all(color: p.border, width: 1.2)),
      clipBehavior: Clip.antiAlias,
      alignment: Alignment.centerLeft,
      child: FractionallySizedBox(widthFactor: value.clamp(0, 1).toDouble(), child: Container(color: color ?? p.accent)),
    );
  }
}

class MovementTile extends StatelessWidget {
  final Movement m;
  final VoidCallback? onTap;
  const MovementTile(this.m, {super.key, this.onTap});
  @override
  Widget build(BuildContext context) {
    final p = Pal.of(context);
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Neo(
        r: 13,
        off: 3,
        onTap: onTap,
        padding: const EdgeInsets.all(12),
        child: Row(children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(shape: BoxShape.circle, color: p.accent, border: Border.all(color: p.border, width: 1.5)),
            child: Icon(m.isIncome ? Icons.north_east : Icons.south_west, color: p.onAccent, size: 20),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Row(children: [
                Flexible(
                    child: Text(m.note.isEmpty ? m.category : m.note,
                        overflow: TextOverflow.ellipsis, style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 16))),
                if (m.isAnt) ...[
                  const SizedBox(width: 8),
                  const AntBadge(),
                ],
              ]),
              const SizedBox(height: 2),
              Text('${m.category} · ${relDay(m.date).toLowerCase()}, ${hhmm(m.date)}', style: TextStyle(fontSize: 12, color: p.text2)),
            ]),
          ),
          Text(money(m.isIncome ? m.amount : -m.amount, sign: true),
              style: TextStyle(fontWeight: FontWeight.w700, fontSize: 15, color: m.isIncome ? p.income : p.expense)),
        ]),
      ),
    );
  }
}

class AntBadge extends StatelessWidget {
  final String text;
  const AntBadge({super.key, this.text = 'HORMIGA'});
  @override
  Widget build(BuildContext context) {
    final p = Pal.of(context);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(color: p.accent, borderRadius: BorderRadius.circular(99), border: Border.all(color: p.border, width: 1)),
      child: Text(text, style: TextStyle(fontSize: 9, fontWeight: FontWeight.w800, letterSpacing: .6, color: p.onAccent)),
    );
  }
}

/// Estado vacío / error con mascota (pantallas «Vacío», «Error», «Sin conexión»).
class StateView extends StatelessWidget {
  final String img;
  final String title, body;
  final String? action;
  final VoidCallback? onAction;
  final String? action2;
  final VoidCallback? onAction2;
  const StateView(this.img, this.title, this.body, {super.key, this.action, this.onAction, this.action2, this.onAction2});
  @override
  Widget build(BuildContext context) {
    final p = Pal.of(context);
    // Centrado y desplazable: nunca se desborda aunque el alto disponible sea poco.
    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 21, vertical: 24),
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          Ilus(img, 200),
          const SizedBox(height: 24),
          Text(title, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w700)),
          const SizedBox(height: 8),
          Text(body, textAlign: TextAlign.center, style: TextStyle(color: p.text2, height: 1.5)),
          const SizedBox(height: 28),
          if (action != null) FtButton(action!, onTap: onAction),
          if (action2 != null) ...[const SizedBox(height: 12), FtButton(action2!, primary: false, onTap: onAction2)],
        ]),
      ),
    );
  }
}

/// Esqueleto de carga (pantallas «Cargando»).
class Skeleton extends StatefulWidget {
  const Skeleton({super.key});
  @override
  State<Skeleton> createState() => _SkeletonState();
}

class _SkeletonState extends State<Skeleton> with SingleTickerProviderStateMixin {
  late final c = AnimationController(vsync: this, duration: const Duration(milliseconds: 900))..repeat(reverse: true);
  @override
  void dispose() {
    c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final p = Pal.of(context);
    Widget b(double h, {double? w}) => AnimatedBuilder(
          animation: c,
          builder: (_, __) => Container(
            height: h,
            width: w,
            decoration: BoxDecoration(
                color: Color.lerp(p.alt, p.card, c.value * .6),
                borderRadius: BorderRadius.circular(21),
                border: Border.all(color: p.border.withOpacity(.5), width: 1.5)),
          ),
        );
    return Padding(
      padding: const EdgeInsets.all(21),
      child: Column(children: [
        b(140),
        const SizedBox(height: 14),
        Row(children: [Expanded(child: b(56)), const SizedBox(width: 12), Expanded(child: b(56))]),
        const SizedBox(height: 22),
        b(190),
        const SizedBox(height: 22),
        b(64),
        const SizedBox(height: 12),
        b(64),
      ]),
    );
  }
}

// ----------------------- Gráficos -----------------------

class WeekAreaChart extends StatelessWidget {
  final List<double> values;
  const WeekAreaChart(this.values, {super.key});
  @override
  Widget build(BuildContext context) {
    final p = Pal.of(context);
    return Column(children: [
      SizedBox(
          height: 110,
          width: double.infinity,
          child: CustomPaint(painter: _AreaPainter(values, p.accent, p.dark ? p.text : p.fijo, p.border))),
      const SizedBox(height: 8),
      Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
        for (final d in days) Text(d, style: TextStyle(fontSize: 10, fontWeight: FontWeight.w700, color: p.text2)),
      ]),
    ]);
  }
}

class _AreaPainter extends CustomPainter {
  final List<double> v;
  final Color fill, line, dot;
  _AreaPainter(this.v, this.fill, this.line, this.dot);
  @override
  void paint(Canvas c, Size s) {
    final mx = v.reduce(math.max);
    final top = mx <= 0 ? 1.0 : mx;
    Offset pt(int i) => Offset(s.width * i / (v.length - 1), s.height - 10 - (s.height - 24) * (v[i] / top));
    final path = Path()..moveTo(0, s.height);
    for (var i = 0; i < v.length; i++) {
      path.lineTo(pt(i).dx, pt(i).dy);
    }
    path.lineTo(s.width, s.height);
    path.close();
    c.drawPath(path, Paint()..color = fill);
    final l = Path()..moveTo(pt(0).dx, pt(0).dy);
    for (var i = 1; i < v.length; i++) {
      l.lineTo(pt(i).dx, pt(i).dy);
    }
    c.drawPath(
        l,
        Paint()
          ..color = line
          ..style = PaintingStyle.stroke
          ..strokeWidth = 2.5
          ..strokeJoin = StrokeJoin.round);
    final last = pt(v.length - 1);
    c.drawCircle(last, 6, Paint()..color = fill);
    c.drawCircle(
        last,
        6,
        Paint()
          ..color = dot
          ..style = PaintingStyle.stroke
          ..strokeWidth = 2);
  }

  @override
  bool shouldRepaint(covariant _AreaPainter o) => o.v != v || o.fill != fill;
}

class Donut extends StatelessWidget {
  final List<double> values;
  final List<Color> colors;
  final Widget center;
  final Color border;
  const Donut(this.values, this.colors, this.center, this.border, {super.key});
  @override
  Widget build(BuildContext context) => SizedBox(
        width: 124,
        height: 124,
        child: Stack(alignment: Alignment.center, children: [
          CustomPaint(size: const Size(124, 124), painter: _DonutPainter(values, colors, border)),
          center,
        ]),
      );
}

class _DonutPainter extends CustomPainter {
  final List<double> v;
  final List<Color> colors;
  final Color border;
  _DonutPainter(this.v, this.colors, this.border);
  @override
  void paint(Canvas c, Size s) {
    final rect = Rect.fromLTWH(14, 14, s.width - 28, s.height - 28);
    final total = v.fold(0.0, (a, b) => a + b);
    const w = 26.0;
    if (total <= 0) {
      c.drawArc(
          rect,
          0,
          math.pi * 2,
          false,
          Paint()
            ..color = border.withOpacity(.25)
            ..style = PaintingStyle.stroke
            ..strokeWidth = w);
      return;
    }
    var a = -math.pi / 2;
    for (var i = 0; i < v.length; i++) {
      final sweep = v[i] / total * math.pi * 2;
      c.drawArc(
          rect,
          a,
          sweep,
          false,
          Paint()
            ..color = colors[i]
            ..style = PaintingStyle.stroke
            ..strokeWidth = w);
      a += sweep;
    }
    final stroke = Paint()
      ..color = border
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.5;
    c.drawCircle(s.center(Offset.zero), rect.width / 2 + w / 2, stroke);
    c.drawCircle(s.center(Offset.zero), rect.width / 2 - w / 2, stroke);
  }

  @override
  bool shouldRepaint(covariant _DonutPainter o) => o.v != v;
}

/// Pregunta de confirmación (diálogos «Eliminar», «Cerrar sesión»…).
Future<bool> confirm(BuildContext c, String title, String body, String ok) async {
  final p = Pal.of(c);
  final r = await showDialog<bool>(
    context: c,
    builder: (_) => Dialog(
      backgroundColor: Colors.transparent,
      child: Neo(
        padding: const EdgeInsets.all(20),
        child: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(title, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w800)),
          const SizedBox(height: 8),
          Text(body, style: TextStyle(color: p.text2, height: 1.4)),
          const SizedBox(height: 20),
          Row(children: [
            Expanded(child: FtButton('Cancelar', primary: false, onTap: () => Navigator.pop(c, false))),
            const SizedBox(width: 12),
            Expanded(child: FtButton(ok, onTap: () => Navigator.pop(c, true))),
          ]),
        ]),
      ),
    ),
  );
  return r ?? false;
}

/// Pide un texto o número con un diálogo simple.
Future<String?> ask(BuildContext c, String title, {String initial = '', String hint = '', bool number = false}) {
  final ctl = TextEditingController(text: initial);
  return showDialog<String>(
    context: c,
    builder: (_) => Dialog(
      backgroundColor: Colors.transparent,
      child: Neo(
        padding: const EdgeInsets.all(20),
        child: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(title, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w800)),
          const SizedBox(height: 14),
          ftField(c, ctl, hint, type: number ? TextInputType.number : TextInputType.text),
          const SizedBox(height: 18),
          Row(children: [
            Expanded(child: FtButton('Cancelar', primary: false, onTap: () => Navigator.pop(c))),
            const SizedBox(width: 12),
            Expanded(child: FtButton('Guardar', onTap: () => Navigator.pop(c, ctl.text.trim()))),
          ]),
        ]),
      ),
    ),
  );
}

double? parseMoney(String? s) => s == null ? null : double.tryParse(s.replaceAll('.', '').replaceAll(',', '.').replaceAll(r'$', '').trim());
