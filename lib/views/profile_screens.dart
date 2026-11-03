import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../services/database_helper.dart';
import '../state/app_state.dart';
import '../theme/fintrack_theme.dart';
import 'auth_screens.dart';
import 'common.dart';
import 'more_screens.dart';
import 'shell.dart';

void recommend(BuildContext c) {
  Clipboard.setData(const ClipboardData(text: 'Prueba FinTrack: la app para controlar tus gastos hormiga.'));
  toast(c, 'Enlace copiado');
}

Future<void> logout(BuildContext c) async {
  if (!await confirm(c, '¿Cerrar sesión?', 'Tus datos seguirán guardados en este teléfono.', 'Cerrar sesión') || !c.mounted) return;
  await c.read<AppState>().setFlag('loggedIn', false);
  if (c.mounted) Navigator.pushAndRemoveUntil(c, MaterialPageRoute(builder: (_) => const WelcomeScreen()), (_) => false);
}

class PersonalDataScreen extends StatefulWidget {
  const PersonalDataScreen({super.key});
  @override
  State<PersonalDataScreen> createState() => _PersonalDataScreenState();
}

class _PersonalDataScreenState extends State<PersonalDataScreen> {
  late final name = TextEditingController(text: context.read<AppState>().prefs.name);
  late final email = TextEditingController(text: context.read<AppState>().prefs.email);

  @override
  Widget build(BuildContext context) {
    final s = context.read<AppState>();
    return Scaffold(
      appBar: ftBar(context, 'Datos personales'),
      body: ListView(padding: const EdgeInsets.fromLTRB(24, 8, 24, 30), children: [
        label(context, 'Nombre'),
        ftField(context, name, 'Nombre', icon: Icons.person_outline),
        label(context, 'Correo electrónico'),
        ftField(context, email, 'Correo', icon: Icons.mail_outline, type: TextInputType.emailAddress),
        const SizedBox(height: 28),
        FtButton('Guardar cambios', onTap: () async {
          if (name.text.trim().isEmpty || !email.text.contains('@')) {
            toast(context, 'Revisa tu nombre y correo');
            return;
          }
          await s.prefs.updateProfile(name.text.trim(), email.text);
          await s.refresh();
          if (context.mounted) {
            toast(context, 'Cambios guardados');
            Navigator.pop(context);
          }
        }),
        const SizedBox(height: 12),
        FtButton('Eliminar cuenta', primary: false, onTap: () async {
          if (!await confirm(context, '¿Eliminar cuenta?', 'Se borrarán tu cuenta y todos tus movimientos de este teléfono. No se puede deshacer.', 'Eliminar') || !context.mounted) return;
          await DatabaseHelper.instance.wipe();
          await s.prefs.deleteAccount();
          await s.load();
          if (context.mounted) Navigator.pushAndRemoveUntil(context, MaterialPageRoute(builder: (_) => const WelcomeScreen()), (_) => false);
        }),
      ]),
    );
  }
}

class AboutScreen extends StatelessWidget {
  const AboutScreen({super.key});
  @override
  Widget build(BuildContext context) {
    final p = Pal.of(context);
    Widget row(IconData i, String t, VoidCallback f) => Padding(
          padding: const EdgeInsets.only(bottom: 12),
          child: Neo(
              r: 13,
              off: 3,
              onTap: f,
              padding: const EdgeInsets.all(14),
              child: Row(children: [IconDisc(i, size: 34, filled: false), const SizedBox(width: 12), Expanded(child: Text(t, style: const TextStyle(fontWeight: FontWeight.w700))), const Icon(Icons.chevron_right)])),
        );
    return Scaffold(
      appBar: ftBar(context, 'Acerca de nosotros'),
      body: ListView(padding: const EdgeInsets.fromLTRB(24, 8, 24, 30), children: [
        const Center(child: Logo(size: 30)),
        const SizedBox(height: 8),
        Center(child: Text('Versión 1.0.0', style: TextStyle(color: p.text2))),
        const SizedBox(height: 14),
        Text('FinTrack ayuda a universitarios a ver en qué se va el dinero pequeño: cafés, snacks y domicilios. '
            'Proyecto de Gestión de Proyectos, Universidad Lasallista. Equipo: Juan Sebastián Martínez y Samuel Usma.',
            style: TextStyle(height: 1.5, color: p.text2)),
        const SizedBox(height: 22),
        row(Icons.privacy_tip_outlined, 'Política de privacidad', () => push(context, const PrivacyScreen())),
        row(Icons.star_outline, 'Calificar la app', () => toast(context, '¡Gracias por tu apoyo!')),
        row(Icons.share, 'Recomendar', () => recommend(context)),
      ]),
    );
  }
}

class PrivacyScreen extends StatelessWidget {
  const PrivacyScreen({super.key});
  @override
  Widget build(BuildContext context) {
    final p = Pal.of(context);
    Widget h(String t) => Padding(padding: const EdgeInsets.only(top: 16, bottom: 4), child: Text(t, style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 16)));
    Widget b(String t) => Text(t, style: TextStyle(height: 1.5, color: p.text2));
    return Scaffold(
      appBar: ftBar(context, 'Política de privacidad'),
      body: ListView(padding: const EdgeInsets.fromLTRB(24, 0, 24, 30), children: [
        h('Qué datos guardamos'),
        b('Tu nombre, correo, movimientos, límites y las fotos de tiquetes que adjuntes. Todo se guarda en este teléfono.'),
        h('Para qué los usamos'),
        b('Solo para mostrarte tus estadísticas, avisos e informes. No vendemos ni compartimos tus datos.'),
        h('Tus derechos'),
        b('Puedes exportar o eliminar tus datos en cualquier momento desde Ajustes. Tratamiento conforme a la Ley 1581 de 2012 (Colombia).'),
        h('Aviso de no responsabilidad'),
        b('Si eliges guardar solo en el teléfono y lo pierdes o desinstalas la app, los datos no se pueden recuperar.'),
      ]),
    );
  }
}

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  Future<void> choose(BuildContext c, String title, List<String> opts, String current) => showModalBottomSheet(
        context: c,
        backgroundColor: Pal.of(c).bg,
        builder: (_) => SafeArea(
          child: Column(mainAxisSize: MainAxisSize.min, children: [
            Padding(padding: const EdgeInsets.all(16), child: Text(title, style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 18))),
            for (final o in opts)
              ListTile(
                title: Text(o),
                trailing: o == current ? const Icon(Icons.check) : null,
                onTap: () {
                  Navigator.pop(c);
                  if (o != current) toast(c, 'Por ahora solo está disponible $current');
                },
              ),
          ]),
        ),
      );

  @override
  Widget build(BuildContext context) {
    final p = Pal.of(context);
    final s = context.watch<AppState>();
    Widget head(String t) => Padding(padding: const EdgeInsets.only(top: 14, bottom: 10), child: Text(t, style: TextStyle(fontSize: 12, color: p.text2)));
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
    return Scaffold(
      appBar: ftBar(context, 'Ajustes'),
      body: ListView(padding: const EdgeInsets.fromLTRB(21, 0, 21, 30), children: [
        head('Avisos'),
        SwitchRow(Icons.notifications, 'Avisos de gasto hormiga', 'Cuando se repite un gasto pequeño', s.prefs.antAlerts, (v) => s.setFlag('antAlerts', v)),
        const SizedBox(height: 12),
        SwitchRow(Icons.alarm, 'Recordatorio diario', '8:00 p. m. (requiere notificaciones del sistema)', s.prefs.remind, (v) {
          s.setFlag('remind', v);
          if (v) toast(context, 'Preferencia guardada; el aviso del sistema llega en la entrega final');
        }),
        head('General'),
        nav(Icons.payments_outlined, 'Moneda', 'COP', () => choose(context, 'Moneda', ['COP', 'USD', 'EUR'], 'COP')),
        nav(Icons.language, 'Idioma', 'Español', () => choose(context, 'Idioma', ['Español', 'English'], 'Español')),
        nav(Icons.speed, 'Límites de gasto', '', () => push(context, const LimitsScreen())),
        nav(Icons.cloud_outlined, 'Datos y respaldo', '', () => push(context, const DataScreen())),
        SwitchRow(Icons.dark_mode_outlined, 'Modo oscuro', 'Cuida tus ojos de noche', s.dark, (v) => s.setFlag('dark', v)),
      ]),
    );
  }
}
