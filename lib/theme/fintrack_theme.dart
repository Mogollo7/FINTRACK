import 'package:flutter/material.dart';

/// Paleta del mockup de Figma (variables color/*), claro y oscuro.
class Pal {
  final Color bg, card, alt, accent, ink, border, shadow, text, text2, onAccent, income, expense, fijo;
  final bool dark;
  const Pal._(this.dark, this.bg, this.card, this.alt, this.accent, this.ink, this.border, this.shadow, this.text,
      this.text2, this.onAccent, this.income, this.expense, this.fijo);

  static const light = Pal._(false, Color(0xFFFFFDF3), Color(0xFFFFFFFF), Color(0xFFF4F6C4), Color(0xFFFFA914),
      Color(0xFF17140F), Color(0xFF17140F), Color(0xFF17140F), Color(0xFF17140F), Color(0xFF6B6454),
      Color(0xFF17140F), Color(0xFF1B7F37), Color(0xFFC62828), Color(0xFF2F3E50));
  static const darkP = Pal._(true, Color(0xFF0F0D09), Color(0xFF211D15), Color(0xFF2E291F), Color(0xFFFFB938),
      Color(0xFF17140F), Color(0xFF8A8070), Color(0xFF4A4234), Color(0xFFF2ECDD), Color(0xFFBDB59E),
      Color(0xFF17140F), Color(0xFF5BD27A), Color(0xFFFF5252), Color(0xFF7C93AD));

  static Pal of(BuildContext c) => Theme.of(c).brightness == Brightness.dark ? darkP : light;

  ThemeData theme() => ThemeData(
        useMaterial3: true,
        brightness: dark ? Brightness.dark : Brightness.light,
        scaffoldBackgroundColor: bg,
        colorScheme: ColorScheme.fromSeed(seedColor: accent, brightness: dark ? Brightness.dark : Brightness.light)
            .copyWith(primary: accent, surface: card, onSurface: text),
        textTheme: ThemeData(brightness: dark ? Brightness.dark : Brightness.light)
            .textTheme
            .apply(bodyColor: text, displayColor: text),
        dividerColor: border,
      );

  /// Tarjeta con borde y sombra dura (4,4).
  BoxDecoration box({Color? color, double r = 21, double off = 4}) => BoxDecoration(
        color: color ?? card,
        borderRadius: BorderRadius.circular(r),
        border: Border.all(color: border, width: 1.5),
        boxShadow: [BoxShadow(color: shadow, offset: Offset(off, off))],
      );
}

/// Contenedor neo-brutalista reutilizable.
class Neo extends StatelessWidget {
  final Widget child;
  final Color? color;
  final double r, off;
  final EdgeInsets padding;
  final VoidCallback? onTap;
  const Neo({super.key, required this.child, this.color, this.r = 21, this.off = 4, this.padding = const EdgeInsets.all(16), this.onTap});

  @override
  Widget build(BuildContext context) {
    final p = Pal.of(context);
    final w = Container(width: double.infinity, padding: padding, decoration: p.box(color: color, r: r, off: off), child: child);
    return onTap == null ? w : GestureDetector(onTap: onTap, behavior: HitTestBehavior.opaque, child: w);
  }
}

/// Botón principal (ámbar) o secundario (tarjeta).
class FtButton extends StatelessWidget {
  final String label;
  final VoidCallback? onTap;
  final bool primary;
  const FtButton(this.label, {super.key, this.onTap, this.primary = true});

  @override
  Widget build(BuildContext context) {
    final p = Pal.of(context);
    return Opacity(
      opacity: onTap == null ? .5 : 1,
      child: Neo(
        onTap: onTap,
        r: 13,
        off: 3,
        color: primary ? p.accent : p.card,
        padding: const EdgeInsets.symmetric(vertical: 14),
        child: Center(
          child: Text(label,
              style: TextStyle(fontWeight: FontWeight.w700, fontSize: 15, color: primary ? p.onAccent : p.text)),
        ),
      ),
    );
  }
}

/// Círculo con icono (categorías, filas).
class IconDisc extends StatelessWidget {
  final IconData icon;
  final double size;
  final bool filled;
  const IconDisc(this.icon, {super.key, this.size = 40, this.filled = true});

  @override
  Widget build(BuildContext context) {
    final p = Pal.of(context);
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: filled ? p.accent : p.alt,
        border: Border.all(color: p.border, width: 1.5),
      ),
      child: Icon(icon, size: size * .5, color: filled ? p.onAccent : p.text),
    );
  }
}

/// Barra superior simple: flecha atrás + título centrado.
PreferredSizeWidget ftBar(BuildContext context, String title, {List<Widget>? actions, bool close = false}) {
  final p = Pal.of(context);
  return AppBar(
    backgroundColor: p.bg,
    elevation: 0,
    scrolledUnderElevation: 0,
    centerTitle: true,
    leading: IconButton(icon: Icon(close ? Icons.close : Icons.arrow_back, color: p.text), onPressed: () => Navigator.maybePop(context)),
    title: Text(title, style: TextStyle(color: p.text, fontWeight: FontWeight.w700, fontSize: 16)),
    actions: actions,
  );
}

void toast(BuildContext c, String msg) {
  final p = Pal.of(c);
  ScaffoldMessenger.of(c)
    ..hideCurrentSnackBar()
    ..showSnackBar(SnackBar(
      content: Text(msg, style: TextStyle(color: p.dark ? p.onAccent : Colors.white, fontWeight: FontWeight.w600)),
      backgroundColor: p.dark ? p.accent : p.ink,
      behavior: SnackBarBehavior.floating,
      duration: const Duration(milliseconds: 2200),
    ));
}
