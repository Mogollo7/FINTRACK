import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../state/app_state.dart';
import '../theme/fintrack_theme.dart';
import 'common.dart';
import 'shell.dart';

/// Splash → guía → bienvenida / inicio, según el estado guardado.
class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});
  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  @override
  void initState() {
    super.initState();
    Future.delayed(const Duration(milliseconds: 1500), () {
      if (!mounted) return;
      final s = context.read<AppState>();
      final next = s.prefs.loggedIn ? const Shell() : (s.prefs.onboarded ? const WelcomeScreen() : const OnboardingScreen());
      Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => next));
    });
  }

  @override
  Widget build(BuildContext context) {
    final p = Pal.of(context);
    return Scaffold(
      backgroundColor: p.accent,
      body: Center(
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          Cat(170, color: p.ink),
          const SizedBox(height: 16),
          const Logo(size: 30),
          const SizedBox(height: 6),
          Text('Tus gastos hormiga, bajo control', style: TextStyle(color: p.ink, fontSize: 12)),
        ]),
      ),
    );
  }
}

class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key});
  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  int i = 0;
  static const pages = <(String, String, String)>[
    ('Registra cada gasto', 'Anota en segundos lo que gastas, incluso los cafés y los antojos pequeños.', 'onboarding-1'),
    ('Descubre tus hormigas', 'Mira qué pequeños gastos se repiten y cuánto pesan en tu mes.', 'onboarding-2'),
    ('Ahorra con metas claras', 'Recibe avisos amables y mira cómo crece tu ahorro semana a semana.', 'onboarding-3'),
  ];

  void done() async {
    await context.read<AppState>().setFlag('onboarded', true);
    if (mounted) Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => const WelcomeScreen()));
  }

  @override
  Widget build(BuildContext context) {
    final p = Pal.of(context);
    final pg = pages[i];
    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(children: [
            Align(alignment: Alignment.centerRight, child: TextButton(onPressed: done, child: Text('Omitir', style: TextStyle(color: p.text2)))),
            const Spacer(),
            Ilus(pg.$3, 300),
            const Spacer(),
            Row(children: [
              for (var k = 0; k < 3; k++)
                Container(
                  margin: const EdgeInsets.only(right: 6),
                  width: k == i ? 24 : 10,
                  height: 10,
                  decoration: BoxDecoration(color: k == i ? p.accent : p.card, borderRadius: BorderRadius.circular(99), border: Border.all(color: p.border)),
                ),
            ]),
            const SizedBox(height: 14),
            Align(alignment: Alignment.centerLeft, child: Text(pg.$1, style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w700))),
            const SizedBox(height: 6),
            Align(alignment: Alignment.centerLeft, child: Text(pg.$2, style: TextStyle(color: p.text2, height: 1.5))),
            const SizedBox(height: 28),
            FtButton(i == 2 ? 'Empezar' : 'Siguiente', onTap: () => i == 2 ? done() : setState(() => i++)),
          ]),
        ),
      ),
    );
  }
}

class WelcomeScreen extends StatelessWidget {
  const WelcomeScreen({super.key});
  @override
  Widget build(BuildContext context) {
    final p = Pal.of(context);
    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            const SizedBox(height: 30),
            Neo(color: p.accent, padding: const EdgeInsets.all(24), child: Center(child: Cat(190, color: p.ink))),
            const SizedBox(height: 20),
            const Logo(),
            const Text('Bienvenido', style: TextStyle(fontSize: 34, fontWeight: FontWeight.w300)),
            const SizedBox(height: 8),
            Text('Descubre cómo los pequeños gastos de cada día se vuelven grandes ahorros.', style: TextStyle(color: p.text2, height: 1.5)),
            const Spacer(),
            FtButton('Crear cuenta', onTap: () => push(context, const AuthScreen(register: true))),
            const SizedBox(height: 12),
            FtButton('Iniciar sesión', primary: false, onTap: () => push(context, const AuthScreen())),
          ]),
        ),
      ),
    );
  }
}

class AuthScreen extends StatefulWidget {
  final bool register;
  const AuthScreen({super.key, this.register = false});
  @override
  State<AuthScreen> createState() => _AuthScreenState();
}

class _AuthScreenState extends State<AuthScreen> {
  final name = TextEditingController(), email = TextEditingController(), pass = TextEditingController();
  bool hide = true;

  Future<void> submit() async {
    final s = context.read<AppState>();
    if (widget.register) {
      if (name.text.trim().isEmpty || !email.text.contains('@') || pass.text.length < 6) {
        toast(context, 'Completa los datos (contraseña de 6+ caracteres)');
        return;
      }
      await s.prefs.register(name.text.trim(), email.text, pass.text);
      await s.load();
      if (mounted) Navigator.pushAndRemoveUntil(context, MaterialPageRoute(builder: (_) => const StorageChoiceScreen()), (_) => false);
    } else {
      if (!s.prefs.check(email.text, pass.text)) {
        toast(context, 'Correo o contraseña incorrectos');
        return;
      }
      await s.setFlag('loggedIn', true);
      await s.load();
      if (mounted) Navigator.pushAndRemoveUntil(context, MaterialPageRoute(builder: (_) => const Shell()), (_) => false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final p = Pal.of(context);
    return Scaffold(
      appBar: ftBar(context, widget.register ? 'Crear cuenta' : 'Iniciar sesión'),
      body: ListView(padding: const EdgeInsets.fromLTRB(24, 0, 24, 30), children: [
        const Center(child: Logo()),
        Center(child: Text(widget.register ? 'Empecemos' : 'Hola de nuevo', style: const TextStyle(fontSize: 32, fontWeight: FontWeight.w300))),
        if (widget.register) ...[label(context, 'Nombre'), ftField(context, name, 'Tu nombre', icon: Icons.person_outline)],
        label(context, 'Correo electrónico'),
        ftField(context, email, 'tu@correo.com', icon: Icons.mail_outline, type: TextInputType.emailAddress),
        label(context, 'Contraseña'),
        ftField(context, pass, '••••••••', icon: Icons.lock_outline, obscure: hide,
            suffix: IconButton(icon: Icon(hide ? Icons.visibility : Icons.visibility_off), onPressed: () => setState(() => hide = !hide))),
        if (!widget.register)
          Align(
            alignment: Alignment.centerRight,
            child: TextButton(
                onPressed: () => toast(context, 'La recuperación por código (OTP) llega con el servidor de correo'),
                child: Text('¿Olvidaste tu contraseña?', style: TextStyle(color: p.text2, fontSize: 12))),
          ),
        const SizedBox(height: 16),
        FtButton(widget.register ? 'Crear cuenta' : 'Iniciar sesión', onTap: submit),
        const SizedBox(height: 14),
        Center(
          child: GestureDetector(
            onTap: () => Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => AuthScreen(register: !widget.register))),
            child: Text(widget.register ? '¿Ya tienes cuenta? Inicia sesión' : '¿No tienes cuenta? Regístrate', style: const TextStyle(fontWeight: FontWeight.w600)),
          ),
        ),
      ]),
    );
  }
}

class StorageChoiceScreen extends StatelessWidget {
  const StorageChoiceScreen({super.key});
  @override
  Widget build(BuildContext context) {
    final p = Pal.of(context);
    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(children: [
            const SizedBox(height: 20),
            const Logo(),
            const Text('Tú decides', style: TextStyle(fontSize: 34, fontWeight: FontWeight.w300)),
            Text('¿Dónde guardamos tus gastos? Puedes cambiarlo luego en Ajustes.', textAlign: TextAlign.center, style: TextStyle(color: p.text2)),
            const SizedBox(height: 20),
            Neo(
                color: p.alt,
                padding: const EdgeInsets.all(16),
                onTap: () => toast(context, 'El respaldo en la nube llega en la entrega final'),
                child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Row(children: [const Text('Con respaldo en la nube', style: TextStyle(fontWeight: FontWeight.w700)), const SizedBox(width: 8), const AntBadge(text: 'Próximamente')]),
                  const SizedBox(height: 6),
                  Text('Una copia cifrada en la nube para recuperar tus datos.', style: TextStyle(fontSize: 12, color: p.text2)),
                ])),
            const SizedBox(height: 16),
            Neo(
                padding: const EdgeInsets.all(16),
                child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  const Text('Solo en este teléfono', style: TextStyle(fontWeight: FontWeight.w700)),
                  const SizedBox(height: 6),
                  Text('Nada sale de tu teléfono. Si lo pierdes o desinstalas la app, pierdes tus datos.', style: TextStyle(fontSize: 12, color: p.text2)),
                ])),
            const Spacer(),
            FtButton('Continuar', onTap: () => Navigator.pushAndRemoveUntil(context, MaterialPageRoute(builder: (_) => const Shell()), (_) => false)),
          ]),
        ),
      ),
    );
  }
}
