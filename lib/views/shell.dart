import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/models.dart';
import '../state/app_state.dart';
import '../theme/fintrack_theme.dart';
import 'add_flow.dart';
import 'common.dart';
import 'more_screens.dart';
import 'profile_screens.dart';
import 'report_screens.dart';

void push(BuildContext c, Widget w) => Navigator.push(c, MaterialPageRoute(builder: (_) => w));

/// Barra inferior ámbar con muesca para el botón «+».
class Shell extends StatefulWidget {
  const Shell({super.key});
  @override
  State<Shell> createState() => _ShellState();
}

class _ShellState extends State<Shell> {
  int tab = 0;

  @override
  Widget build(BuildContext context) {
    final p = Pal.of(context);
    final s = context.watch<AppState>();
    final tabs = [const HomeTab(), const StatsTab(), const ReportTab(), const ProfileTab()];
    Widget item(IconData i, int idx) => IconButton(
          onPressed: () => setState(() => tab = idx),
          icon: Icon(i, size: 28, color: p.onAccent),
          style: IconButton.styleFrom(backgroundColor: tab == idx ? p.onAccent.withOpacity(.12) : null),
        );
    return Scaffold(
      body: SafeArea(
        bottom: false,
        child: s.failed
            ? StateView('error-generico', 'Algo salió mal', 'No pudimos cargar tus datos. Inténtalo de nuevo en un momento.',
                action: 'Reintentar', onAction: s.load)
            : tabs[tab],
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerDocked,
      floatingActionButton: GestureDetector(
        onTap: () => push(context, const AddScreen()),
        child: Container(
          width: 58,
          height: 58,
          decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: p.accent,
              border: Border.all(color: p.ink, width: 3),
              boxShadow: [BoxShadow(color: p.ink, offset: const Offset(2, 3))]),
          child: Icon(Icons.add, size: 30, color: p.ink),
        ),
      ),
      bottomNavigationBar: BottomAppBar(
        color: p.accent,
        height: 70,
        padding: EdgeInsets.zero,
        shape: const CircularNotchedRectangle(),
        notchMargin: 8,
        child: Row(mainAxisAlignment: MainAxisAlignment.spaceAround, children: [
          item(Icons.home_rounded, 0),
          item(Icons.pie_chart_rounded, 1),
          const SizedBox(width: 56),
          item(Icons.receipt_long_rounded, 2),
          item(Icons.person_rounded, 3),
        ]),
      ),
    );
  }
}

/// Cabecera de las pestañas: logo + campana con punto rojo.
class TopHeader extends StatelessWidget {
  const TopHeader({super.key});
  @override
  Widget build(BuildContext context) {
    final p = Pal.of(context);
    final s = context.watch<AppState>();
    return Container(
      padding: const EdgeInsets.fromLTRB(21, 8, 21, 12),
      decoration: BoxDecoration(border: Border(bottom: BorderSide(color: p.border, width: 1.5))),
      child: Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
        const Logo(),
        Row(children: [
          if (!s.online)
            GestureDetector(
              onTap: () => push(context, const OfflineScreen()),
              child: Container(
              margin: const EdgeInsets.only(right: 10),
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
              decoration: BoxDecoration(color: p.alt, borderRadius: BorderRadius.circular(99), border: Border.all(color: p.border)),
              child: Text('Sin conexión', style: TextStyle(fontSize: 10, fontWeight: FontWeight.w700, color: p.text)),
            )),
          // Área táctil de 48 px (pauta de accesibilidad) alrededor de la campana.
          GestureDetector(
            onTap: () => push(context, const NoticesScreen()),
            behavior: HitTestBehavior.opaque,
            child: Padding(
              padding: const EdgeInsets.all(10),
              child: Stack(clipBehavior: Clip.none, children: [
                Icon(Icons.notifications, size: 28, color: p.text),
                if (s.unread > 0)
                  Positioned(right: 2, top: 0, child: Container(width: 9, height: 9, decoration: BoxDecoration(color: p.expense, shape: BoxShape.circle))),
              ]),
            ),
          ),
        ]),
      ]),
    );
  }
}

// ----------------------------- Inicio -----------------------------
class HomeTab extends StatelessWidget {
  const HomeTab({super.key});
  @override
  Widget build(BuildContext context) {
    final p = Pal.of(context);
    final s = context.watch<AppState>();
    final first = s.prefs.name.split(' ').first;
    final d = s.weekDelta;
    return Column(children: [
      const TopHeader(),
      Expanded(
        child: s.loading
            ? const Skeleton()
            : ListView(padding: const EdgeInsets.fromLTRB(21, 22, 21, 100), children: [
                Neo(
                  color: p.accent,
                  padding: const EdgeInsets.all(20),
                  child: Row(children: [
                    Expanded(
                      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                        Text('Hola, $first', style: TextStyle(fontSize: 16, color: p.onAccent)),
                        Text('Saldo disponible', style: TextStyle(fontSize: 13, color: p.onAccent)),
                        const SizedBox(height: 6),
                        FittedBox(
                            fit: BoxFit.scaleDown,
                            child: Text(money(s.balance), style: TextStyle(fontSize: 42, fontWeight: FontWeight.w600, color: p.onAccent))),
                      ]),
                    ),
                    GestureDetector(
                      onTap: () => push(context, const AssetsScreen()),
                      child: Container(
                        width: 48,
                        height: 48,
                        decoration: BoxDecoration(shape: BoxShape.circle, color: Colors.white, border: Border.all(color: p.ink, width: 1.5)),
                        child: const Icon(Icons.north_east, color: Color(0xFF17140F)),
                      ),
                    ),
                  ]),
                ),
                const SizedBox(height: 16),
                Row(children: [
                  Expanded(child: _QuickBtn(Icons.add, 'Añadir dinero', () => push(context, const AddScreen(income: true)))),
                  const SizedBox(width: 12),
                  Expanded(child: _QuickBtn(Icons.remove, 'Añadir gasto', () => push(context, const AddScreen()))),
                ]),
                const SectionTitle('Resumen de la semana'),
                Neo(
                  padding: const EdgeInsets.all(16),
                  child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
                      Text('Gastado esta semana', style: TextStyle(fontSize: 12, color: p.text2)),
                      if (d != null)
                        Row(children: [
                          Icon(d <= 0 ? Icons.trending_down : Icons.trending_up, size: 16, color: d <= 0 ? p.income : p.expense),
                          const SizedBox(width: 4),
                          Text('${d.abs().round()} % ${d <= 0 ? 'menos' : 'más'}',
                              style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: d <= 0 ? p.income : p.expense)),
                        ]),
                    ]),
                    Text(money(s.weekSpent), style: const TextStyle(fontSize: 24, fontWeight: FontWeight.w700)),
                    const SizedBox(height: 14),
                    WeekAreaChart(s.weekSeries),
                    if (s.antEquivalence != null) ...[
                      const SizedBox(height: 12),
                      Row(children: [
                        const AntBadge(),
                        const SizedBox(width: 8),
                        Expanded(child: Text(s.antEquivalence!, style: TextStyle(fontSize: 12, color: p.text2))),
                      ]),
                    ],
                  ]),
                ),
                SectionTitle('Actividad reciente',
                    trailing: GestureDetector(onTap: () => push(context, const MovementsScreen()), child: const Text('Ver más'))),
                if (s.movements.isEmpty)
                  Neo(
                      onTap: () => push(context, const AddScreen()),
                      child: Text('Aún no hay movimientos. Toca aquí para registrar tu primer gasto.', style: TextStyle(color: p.text2)))
                else
                  for (final m in s.movements.take(5)) MovementTile(m, onTap: () => push(context, DetailScreen(m.id!))),
              ]),
      ),
    ]);
  }
}

class _QuickBtn extends StatelessWidget {
  final IconData i;
  final String t;
  final VoidCallback onTap;
  const _QuickBtn(this.i, this.t, this.onTap);
  @override
  Widget build(BuildContext context) {
    final p = Pal.of(context);
    return Neo(
      r: 13,
      off: 3,
      onTap: onTap,
      padding: const EdgeInsets.all(10),
      child: Row(children: [
        Container(
          width: 30,
          height: 30,
          decoration: BoxDecoration(color: p.alt, borderRadius: BorderRadius.circular(8), border: Border.all(color: p.border, width: 1.2)),
          child: Icon(i, size: 18, color: p.text),
        ),
        const SizedBox(width: 8),
        Flexible(child: Text(t, style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 14))),
      ]),
    );
  }
}

// --------------------------- Estadísticas ---------------------------
class StatsTab extends StatefulWidget {
  const StatsTab({super.key});
  @override
  State<StatsTab> createState() => _StatsTabState();
}

class _StatsTabState extends State<StatsTab> {
  int per = 1;
  bool income = false;
  @override
  Widget build(BuildContext context) {
    final p = Pal.of(context);
    final s = context.watch<AppState>();
    final period = Period.values[per];
    final inc = AppState.sum(s.inPeriod(period, income: true));
    final exp = AppState.sum(s.inPeriod(period, income: false));
    final kinds = s.byKind(period);
    final cats = s.byCategory(period, income: income);
    final catMax = cats.isEmpty ? 1.0 : cats.first.value;
    final colors = [p.fijo, p.accent, p.expense];
    Widget box(String k, String v, Color c) => Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 9),
          margin: const EdgeInsets.only(bottom: 8),
          decoration: BoxDecoration(color: p.alt, borderRadius: BorderRadius.circular(13), border: Border.all(color: p.border, width: 1.5)),
          child: Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
            Text(k, style: TextStyle(fontSize: 13, color: p.text2)),
            Text(v, style: TextStyle(fontWeight: FontWeight.w800, fontSize: 15, color: c)),
          ]),
        );
    return Column(children: [
      const TopHeader(),
      Expanded(
        child: ListView(padding: const EdgeInsets.fromLTRB(21, 14, 21, 100), children: [
          Center(
            child: PopupMenuButton<bool>(
              onSelected: (v) => setState(() => income = v),
              itemBuilder: (_) => const [PopupMenuItem(value: false, child: Text('Gastos')), PopupMenuItem(value: true, child: Text('Ingresos'))],
              child: Row(mainAxisSize: MainAxisSize.min, children: [
                Text(income ? 'Ingresos' : 'Gastos', style: const TextStyle(fontSize: 26, fontWeight: FontWeight.w700)),
                const Icon(Icons.keyboard_arrow_down),
              ]),
            ),
          ),
          const SizedBox(height: 14),
          Segmented(const ['Semana', 'Mes', 'Año'], per, (i) => setState(() => per = i)),
          const SizedBox(height: 18),
          Neo(
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Row(children: [
                Donut(income ? [inc] : [kinds[kFijo]!, kinds[kNecesario]!, kinds[kHormiga]!], income ? [p.income] : colors,
                    Column(mainAxisSize: MainAxisSize.min, children: [
                      Text(money(income ? inc : exp), style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 14)),
                      Text(income ? 'ingresado' : 'gastado', style: TextStyle(fontSize: 10, color: p.text2)),
                    ]), p.border),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(children: [
                    box('Ingresos', money(inc), p.income),
                    box('Gastos', money(exp), p.expense),
                    box('Balance', money(inc - exp), (inc - exp) < 0 ? p.expense : p.income),
                  ]),
                ),
              ]),
              if (!income) ...[
                const SizedBox(height: 14),
                const Text('Distribución de gastos', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 16)),
                const SizedBox(height: 10),
                Container(
                  height: 10,
                  decoration: BoxDecoration(borderRadius: BorderRadius.circular(99), border: Border.all(color: p.border, width: 1.2), color: p.alt),
                  clipBehavior: Clip.antiAlias,
                  child: exp == 0
                      ? null
                      : Row(children: [
                          for (var i = 0; i < 3; i++)
                            if (kinds.values.elementAt(i) > 0) Expanded(flex: (kinds.values.elementAt(i) / exp * 1000).round().clamp(1, 1000), child: Container(color: colors[i])),
                        ]),
                ),
                const SizedBox(height: 12),
                for (final e in [(0, 'Fijos', kFijo), (1, 'Necesarios', kNecesario), (2, 'Hormiga', kHormiga)])
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 4),
                    child: Row(children: [
                      Container(width: 10, height: 10, decoration: BoxDecoration(shape: BoxShape.circle, color: colors[e.$1])),
                      const SizedBox(width: 10),
                      Expanded(child: Text(e.$2)),
                      Text(money(kinds[e.$3]!)),
                    ]),
                  ),
              ],
            ]),
          ),
          const SizedBox(height: 18),
          Neo(
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              const Text('Principales categorías', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 16)),
              const SizedBox(height: 10),
              if (cats.isEmpty) Text('Sin movimientos en este periodo.', style: TextStyle(color: p.text2)),
              for (final e in cats.take(5))
                Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: Column(children: [
                    Row(children: [
                      Icon(catIcon(e.key), size: 18),
                      const SizedBox(width: 10),
                      Expanded(child: Text(e.key)),
                      Text(money(e.value)),
                    ]),
                    const SizedBox(height: 6),
                    PillBar(e.value / catMax, height: 8, color: e.key == cats.first.key ? p.accent : p.ink),
                  ]),
                ),
            ]),
          ),
        ]),
      ),
    ]);
  }
}

// ------------------------------ Informe ------------------------------
class ReportTab extends StatefulWidget {
  const ReportTab({super.key});
  @override
  State<ReportTab> createState() => _ReportTabState();
}

class _ReportTabState extends State<ReportTab> {
  int per = 1;
  bool busy = false;

  Future<void> download() async {
    setState(() => busy = true);
    final s = context.read<AppState>();
    try {
      final f = await createReport(s, Period.values[per]);
      if (mounted) push(context, ReportReadyScreen(f));
    } catch (e) {
      if (mounted) toast(context, 'No se pudo generar el informe');
    }
    if (mounted) setState(() => busy = false);
  }

  @override
  Widget build(BuildContext context) {
    final p = Pal.of(context);
    final s = context.watch<AppState>();
    Widget mini(String k, String v) => Expanded(
          child: Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(color: p.alt, borderRadius: BorderRadius.circular(13), border: Border.all(color: p.border, width: 1.5)),
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(k, style: TextStyle(fontSize: 11, color: p.text2)),
              Text(v, style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 16)),
            ]),
          ),
        );
    Widget check(String t) => Padding(
        padding: const EdgeInsets.symmetric(vertical: 4),
        child: Row(children: [Icon(Icons.check_circle, size: 18, color: p.income), const SizedBox(width: 10), Text(t)]));
    return Column(children: [
      const TopHeader(),
      Expanded(
        child: ListView(padding: const EdgeInsets.fromLTRB(21, 14, 21, 100), children: [
          const Center(child: Text('Informe', style: TextStyle(fontSize: 22, fontWeight: FontWeight.w700))),
          const SizedBox(height: 14),
          Segmented(const ['Semana', 'Mes', 'Año'], per, (i) => setState(() => per = i)),
          const SizedBox(height: 18),
          Neo(
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text('Patrimonio neto', style: TextStyle(fontSize: 12, color: p.text2)),
              Text(money(s.netWorth), style: const TextStyle(fontSize: 34, fontWeight: FontWeight.w700)),
              const SizedBox(height: 12),
              Row(children: [mini('Activos', money(s.assetsTotal)), const SizedBox(width: 10), mini('Pasivos', money(s.liabilitiesTotal))]),
            ]),
          ),
          const SizedBox(height: 18),
          Neo(
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              const Text('Incluye', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 16)),
              const SizedBox(height: 6),
              check('Ingresos y gastos del periodo'),
              check('Gastos hormiga por categoría'),
              check('Evolución del saldo (estilo extracto)'),
            ]),
          ),
          const SizedBox(height: 22),
          FtButton(busy ? 'Generando…' : 'Descargar informe', onTap: busy ? null : download),
        ]),
      ),
    ]);
  }
}

// ------------------------------ Perfil ------------------------------
class ProfileTab extends StatelessWidget {
  const ProfileTab({super.key});
  @override
  Widget build(BuildContext context) {
    final p = Pal.of(context);
    final s = context.watch<AppState>();
    Widget row(IconData i, String t, VoidCallback f) => Padding(
          padding: const EdgeInsets.only(bottom: 14),
          child: Neo(
            r: 13,
            off: 3,
            onTap: f,
            padding: const EdgeInsets.all(12),
            child: Row(children: [
              IconDisc(i, size: 34, filled: false),
              const SizedBox(width: 12),
              Expanded(child: Text(t, style: const TextStyle(fontWeight: FontWeight.w700))),
              const Icon(Icons.chevron_right),
            ]),
          ),
        );
    return Column(children: [
      const TopHeader(),
      Expanded(
        child: ListView(padding: EdgeInsets.zero, children: [
          Container(
            color: p.accent,
            padding: const EdgeInsets.symmetric(vertical: 26),
            child: Column(children: [
              Container(
                width: 76,
                height: 76,
                alignment: Alignment.center,
                decoration: BoxDecoration(shape: BoxShape.circle, color: p.ink, border: Border.all(color: p.ink, width: 2)),
                child: Text(s.prefs.name.isEmpty ? '?' : s.prefs.name[0].toUpperCase(),
                    style: TextStyle(fontSize: 34, fontWeight: FontWeight.w800, color: p.accent)),
              ),
              const SizedBox(height: 10),
              Text(s.prefs.name, style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700, color: p.onAccent)),
              Text(s.prefs.email, style: TextStyle(fontSize: 12, color: p.onAccent)),
            ]),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(21, 28, 21, 100),
            child: Column(children: [
              row(Icons.person, 'Datos personales', () => push(context, const PersonalDataScreen())),
              row(Icons.share, 'Recomiéndanos', () => recommend(context)),
              row(Icons.info, 'Acerca de nosotros', () => push(context, const AboutScreen())),
              row(Icons.settings, 'Ajustes', () => push(context, const SettingsScreen())),
              const SizedBox(height: 4),
              FtButton('Cerrar sesión', primary: false, onTap: () => logout(context)),
            ]),
          ),
        ]),
      ),
    ]);
  }
}
