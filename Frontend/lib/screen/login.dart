import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:google_fonts/google_fonts.dart';
import '../services/auth_service.dart';

const _kAccent = Color(0xFFFF6D00);
const _kInk = Color(0xFF1A1A2E);
const _kBg = Color(0xFFF5F5F7);
const _kMuted = Color(0xFF6B7280);

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  bool _loading = false;
  bool _isRegister = false;
  bool _obscurePass = true;
  String? _error;

  final _emailCtrl = TextEditingController();
  final _passCtrl = TextEditingController();
  final _confirmPassCtrl = TextEditingController();

  @override
  void dispose() {
    _emailCtrl.dispose();
    _passCtrl.dispose();
    _confirmPassCtrl.dispose();
    super.dispose();
  }

  // ── Email / Password ───────────────────────────────────────────────────────

  Future<void> _handleEmailAuth() async {
    final email = _emailCtrl.text.trim();
    final pass = _passCtrl.text;

    if (email.isEmpty || pass.isEmpty) {
      setState(() => _error = 'Completa todos los campos');
      return;
    }
    if (_isRegister && pass != _confirmPassCtrl.text) {
      setState(() => _error = 'Las contraseñas no coinciden');
      return;
    }

    setState(() { _loading = true; _error = null; });
    try {
      if (_isRegister) {
        // ── Registro: crear cuenta + enviar verificación ──────────────────
        final result = await FirebaseAuth.instance.createUserWithEmailAndPassword(
          email: email,
          password: pass,
        );
        await result.user!.sendEmailVerification();
        await FirebaseAuth.instance.signOut();
        if (!mounted) return;
        setState(() => _loading = false);
        _showVerificationSent(email);
      } else {
        // ── Login: verificar que el correo esté confirmado ────────────────
        final result = await FirebaseAuth.instance.signInWithEmailAndPassword(
          email: email,
          password: pass,
        );
        final user = result.user!;
        await user.reload();
        if (!user.emailVerified) {
          await FirebaseAuth.instance.signOut();
          if (!mounted) return;
          setState(() { _loading = false; _error = 'Verifica tu correo antes de continuar. Revisa tu bandeja de entrada.'; });
          return;
        }
        if (!mounted) return;
        await AuthService.handleLogin(context, user);
      }
    } on FirebaseAuthException catch (e) {
      if (mounted) setState(() { _loading = false; _error = _msg(e.code); });
    } catch (_) {
      if (mounted) setState(() { _loading = false; _error = 'Error inesperado. Intenta de nuevo'; });
    }
  }

  void _showVerificationSent(String email) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => Dialog(
        backgroundColor: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        child: Padding(
          padding: const EdgeInsets.all(28),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 64,
                height: 64,
                decoration: BoxDecoration(
                  color: _kAccent.withOpacity(0.10),
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.mark_email_unread_outlined,
                    color: _kAccent, size: 30),
              ),
              const SizedBox(height: 18),
              Text(
                'Verifica tu correo',
                style: GoogleFonts.outfit(
                  fontSize: 20,
                  fontWeight: FontWeight.w800,
                  color: _kInk,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Enviamos un enlace de verificación a:',
                textAlign: TextAlign.center,
                style: GoogleFonts.outfit(fontSize: 13, color: _kMuted),
              ),
              const SizedBox(height: 4),
              Text(
                email,
                textAlign: TextAlign.center,
                style: GoogleFonts.outfit(
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                  color: _kInk,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                'Revisa tu bandeja de entrada y haz click en el enlace para activar tu cuenta.',
                textAlign: TextAlign.center,
                style: GoogleFonts.outfit(
                  fontSize: 12,
                  color: _kMuted,
                  height: 1.5,
                ),
              ),
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () {
                    Navigator.pop(context);
                    setState(() {
                      _isRegister = false;
                      _passCtrl.clear();
                      _confirmPassCtrl.clear();
                    });
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: _kAccent,
                    foregroundColor: Colors.white,
                    elevation: 0,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12)),
                  ),
                  child: Text('Entendido, ir a iniciar sesión',
                      style: GoogleFonts.outfit(
                          fontWeight: FontWeight.w700, fontSize: 14)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  String _msg(String code) => switch (code) {
        'user-not-found'       => 'No existe una cuenta con ese correo',
        'wrong-password'       => 'Contraseña incorrecta',
        'invalid-credential'   => 'Correo o contraseña incorrectos',
        'email-already-in-use' => 'Ya existe una cuenta con ese correo',
        'weak-password'        => 'La contraseña debe tener mínimo 6 caracteres',
        'invalid-email'        => 'El formato del correo no es válido',
        _                      => 'Error al autenticar. Intenta de nuevo',
      };

  // ── Google Sign-In ─────────────────────────────────────────────────────────

  Future<void> _handleGoogle() async {
    setState(() { _loading = true; _error = null; });
    try {
      await GoogleSignIn().signOut();
      await FirebaseAuth.instance.signOut();
      final googleUser = await GoogleSignIn().signIn();
      if (googleUser == null) {
        if (mounted) setState(() => _loading = false);
        return;
      }
      final googleAuth = await googleUser.authentication;
      final credential = GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );
      final result = await FirebaseAuth.instance.signInWithCredential(credential);
      if (!mounted) return;
      await AuthService.handleLogin(context, result.user!);
    } catch (e) {
      debugPrint('Google Sign-In error: $e');
      if (!mounted) return;
      setState(() { _loading = false; _error = 'No se pudo iniciar con Google'; });
    }
  }

  // ── Build ──────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final h = MediaQuery.of(context).size.height;

    return Scaffold(
      backgroundColor: _kBg,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 28),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              SizedBox(height: h * 0.08),

              // ── Logo ──────────────────────────────────────────────────────
              Container(
                width: 56,
                height: 56,
                decoration: BoxDecoration(
                  color: _kAccent,
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(
                      color: _kAccent.withOpacity(0.30),
                      blurRadius: 20,
                      offset: const Offset(0, 8),
                    ),
                  ],
                ),
                child: const Icon(
                  Icons.fitness_center_rounded,
                  color: Colors.white,
                  size: 28,
                ),
              ),

              const SizedBox(height: 24),

              // ── Headline ──────────────────────────────────────────────────
              Text(
                'Gymkoda',
                style: GoogleFonts.outfit(
                  fontSize: 42,
                  fontWeight: FontWeight.w800,
                  color: _kInk,
                  height: 1.0,
                  letterSpacing: -1.5,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                _isRegister
                    ? 'Crea tu cuenta y empieza hoy.'
                    : 'Rutinas personalizadas\nsegún tu cuerpo y objetivo.',
                style: GoogleFonts.outfit(
                  fontSize: 16,
                  fontWeight: FontWeight.w400,
                  color: _kMuted,
                  height: 1.5,
                ),
              ),

              const SizedBox(height: 28),

              // ── Marquee ───────────────────────────────────────────────────
              const _MarqueeRow(),

              const SizedBox(height: 32),

              // ── Formulario ────────────────────────────────────────────────
              _Field(
                ctrl: _emailCtrl,
                label: 'Correo electrónico',
                hint: 'hola@gymkoda.app',
                type: TextInputType.emailAddress,
                icon: Icons.mail_outline_rounded,
              ),
              const SizedBox(height: 14),
              _Field(
                ctrl: _passCtrl,
                label: 'Contraseña',
                hint: '••••••••',
                obscure: _obscurePass,
                icon: Icons.lock_outline_rounded,
                suffix: IconButton(
                  onPressed: () => setState(() => _obscurePass = !_obscurePass),
                  icon: Icon(
                    _obscurePass
                        ? Icons.visibility_outlined
                        : Icons.visibility_off_outlined,
                    size: 18,
                    color: _kMuted,
                  ),
                ),
              ),

              // ── Confirmar contraseña (solo registro) ──────────────────────
              AnimatedSize(
                duration: const Duration(milliseconds: 220),
                curve: Curves.easeOutCubic,
                child: _isRegister
                    ? Padding(
                        padding: const EdgeInsets.only(top: 14),
                        child: _Field(
                          ctrl: _confirmPassCtrl,
                          label: 'Confirmar contraseña',
                          hint: '••••••••',
                          obscure: true,
                          icon: Icons.lock_outline_rounded,
                        ),
                      )
                    : const SizedBox.shrink(),
              ),

              // ── Error inline ──────────────────────────────────────────────
              AnimatedSize(
                duration: const Duration(milliseconds: 180),
                child: _error != null
                    ? Padding(
                        padding: const EdgeInsets.only(top: 10),
                        child: Row(
                          children: [
                            const Icon(Icons.error_outline_rounded,
                                size: 15, color: Color(0xFFE53935)),
                            const SizedBox(width: 6),
                            Expanded(
                              child: Text(
                                _error!,
                                style: GoogleFonts.outfit(
                                  fontSize: 13,
                                  color: const Color(0xFFE53935),
                                ),
                              ),
                            ),
                          ],
                        ),
                      )
                    : const SizedBox.shrink(),
              ),

              const SizedBox(height: 20),

              // ── Botón principal ───────────────────────────────────────────
              _PrimaryButton(
                loading: _loading,
                label: _isRegister ? 'Crear cuenta' : 'Iniciar sesión',
                onTap: _loading ? null : _handleEmailAuth,
              ),

              const SizedBox(height: 16),

              // ── Toggle login / registro ───────────────────────────────────
              Center(
                child: GestureDetector(
                  onTap: () => setState(() {
                    _isRegister = !_isRegister;
                    _error = null;
                    _confirmPassCtrl.clear();
                  }),
                  child: RichText(
                    text: TextSpan(
                      style: GoogleFonts.outfit(
                          fontSize: 13, color: _kMuted),
                      children: [
                        TextSpan(
                          text: _isRegister
                              ? '¿Ya tienes cuenta?  '
                              : '¿No tienes cuenta?  ',
                        ),
                        TextSpan(
                          text: _isRegister ? 'Iniciar sesión' : 'Crear cuenta',
                          style: GoogleFonts.outfit(
                            fontSize: 13,
                            fontWeight: FontWeight.w700,
                            color: _kAccent,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),

              const SizedBox(height: 24),

              // ── Divider "o" ───────────────────────────────────────────────
              Row(
                children: [
                  const Expanded(child: Divider(color: Color(0xFFE5E7EB))),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 14),
                    child: Text(
                      'o continuar con',
                      style: GoogleFonts.outfit(
                          fontSize: 12, color: const Color(0xFFAAAAAA)),
                    ),
                  ),
                  const Expanded(child: Divider(color: Color(0xFFE5E7EB))),
                ],
              ),

              const SizedBox(height: 16),

              // ── Botón Google ──────────────────────────────────────────────
              _GoogleButton(
                  loading: _loading, onTap: _loading ? null : _handleGoogle),

              const SizedBox(height: 14),

              Center(
                child: Text(
                  'Al continuar aceptas los términos de uso',
                  style: GoogleFonts.outfit(
                      fontSize: 12, color: const Color(0xFF9E9E9E)),
                ),
              ),

              const SizedBox(height: 32),
            ],
          ),
        ),
      ),
    );
  }
}

// ── Campo de texto ─────────────────────────────────────────────────────────────

class _Field extends StatelessWidget {
  final TextEditingController ctrl;
  final String label;
  final String hint;
  final TextInputType type;
  final IconData icon;
  final bool obscure;
  final Widget? suffix;

  const _Field({
    required this.ctrl,
    required this.label,
    required this.hint,
    this.type = TextInputType.text,
    required this.icon,
    this.obscure = false,
    this.suffix,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: GoogleFonts.outfit(
            fontSize: 13,
            fontWeight: FontWeight.w600,
            color: _kInk,
          ),
        ),
        const SizedBox(height: 7),
        TextField(
          controller: ctrl,
          keyboardType: type,
          obscureText: obscure,
          style: GoogleFonts.outfit(fontSize: 15, color: _kInk),
          decoration: InputDecoration(
            hintText: hint,
            hintStyle: GoogleFonts.outfit(
                fontSize: 14, color: const Color(0xFFCCCCCC)),
            filled: true,
            fillColor: Colors.white,
            prefixIcon: Icon(icon, size: 18, color: _kMuted),
            suffixIcon: suffix,
            contentPadding:
                const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: Color(0xFFE5E7EB)),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: Color(0xFFE5E7EB)),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: _kAccent, width: 1.5),
            ),
          ),
        ),
      ],
    );
  }
}

// ── Botón principal animado ────────────────────────────────────────────────────

class _PrimaryButton extends StatefulWidget {
  final bool loading;
  final String label;
  final VoidCallback? onTap;
  const _PrimaryButton(
      {required this.loading, required this.label, required this.onTap});

  @override
  State<_PrimaryButton> createState() => _PrimaryButtonState();
}

class _PrimaryButtonState extends State<_PrimaryButton>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;
  late final Animation<double> _scale;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 100),
      reverseDuration: const Duration(milliseconds: 200),
    );
    _scale = Tween<double>(begin: 1.0, end: 0.97)
        .animate(CurvedAnimation(parent: _ctrl, curve: Curves.easeOut));
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: (_) => _ctrl.forward(),
      onTapUp: (_) {
        _ctrl.reverse();
        widget.onTap?.call();
      },
      onTapCancel: () => _ctrl.reverse(),
      child: AnimatedBuilder(
        animation: _scale,
        builder: (_, child) =>
            Transform.scale(scale: _scale.value, child: child),
        child: Container(
          width: double.infinity,
          height: 56,
          decoration: BoxDecoration(
            color: _kAccent,
            borderRadius: BorderRadius.circular(14),
            boxShadow: [
              BoxShadow(
                color: _kAccent.withOpacity(0.28),
                blurRadius: 18,
                offset: const Offset(0, 7),
              ),
            ],
          ),
          child: Center(
            child: widget.loading
                ? const SizedBox(
                    width: 22,
                    height: 22,
                    child: CircularProgressIndicator(
                        color: Colors.white, strokeWidth: 2.5),
                  )
                : Text(
                    widget.label,
                    style: GoogleFonts.outfit(
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                      color: Colors.white,
                    ),
                  ),
          ),
        ),
      ),
    );
  }
}

// ── Marquee infinito ──────────────────────────────────────────────────────────

class _MarqueeRow extends StatefulWidget {
  const _MarqueeRow();

  @override
  State<_MarqueeRow> createState() => _MarqueeRowState();
}

class _MarqueeRowState extends State<_MarqueeRow>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;

  static const _chips = [
    (Icons.fitness_center_rounded, 'Fuerza', true),
    (Icons.directions_run_rounded, 'Resistencia', false),
    (Icons.show_chart_rounded, 'Hipertrofia', true),
    (Icons.bolt_rounded, 'Potencia', false),
    (Icons.local_fire_department_rounded, 'Cardio', true),
    (Icons.self_improvement_outlined, 'Movilidad', false),
  ];

  static const _chipW = 140.0;
  static const _gap = 12.0;
  static const _halfW = 912.0; // 6 × (140 + 12)

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 18),
    )..repeat();
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  Widget _chip(IconData icon, String label, bool filled) {
    return Container(
      width: _chipW,
      margin: const EdgeInsets.only(right: _gap),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 9),
      decoration: BoxDecoration(
        color: filled ? _kAccent : Colors.white,
        borderRadius: BorderRadius.circular(50),
        border: filled
            ? null
            : Border.all(color: const Color(0xFFE2E5EA), width: 1.2),
        boxShadow: [
          BoxShadow(
            color: filled
                ? _kAccent.withOpacity(0.20)
                : Colors.black.withOpacity(0.05),
            blurRadius: filled ? 10 : 6,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Row(
        children: [
          Icon(icon, size: 15, color: filled ? Colors.white : _kAccent),
          const SizedBox(width: 7),
          Expanded(
            child: Text(
              label,
              overflow: TextOverflow.ellipsis,
              maxLines: 1,
              style: GoogleFonts.outfit(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: filled ? Colors.white : _kInk,
              ),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final items =
        _chips.map((c) => _chip(c.$1, c.$2, c.$3)).toList();

    return SizedBox(
      height: 42,
      child: ClipRect(
        child: AnimatedBuilder(
          animation: _ctrl,
          builder: (_, child) => Transform.translate(
            offset: Offset(-_ctrl.value * _halfW, 0),
            child: child,
          ),
          child: UnconstrainedBox(
            alignment: Alignment.centerLeft,
            child: Row(children: [...items, ...items]),
          ),
        ),
      ),
    );
  }
}

// ── Botón Google ──────────────────────────────────────────────────────────────

class _GoogleButton extends StatefulWidget {
  final bool loading;
  final VoidCallback? onTap;
  const _GoogleButton({required this.loading, required this.onTap});

  @override
  State<_GoogleButton> createState() => _GoogleButtonState();
}

class _GoogleButtonState extends State<_GoogleButton>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;
  late final Animation<double> _scale;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 100),
      reverseDuration: const Duration(milliseconds: 200),
    );
    _scale = Tween<double>(begin: 1.0, end: 0.97)
        .animate(CurvedAnimation(parent: _ctrl, curve: Curves.easeOut));
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: (_) => _ctrl.forward(),
      onTapUp: (_) {
        _ctrl.reverse();
        widget.onTap?.call();
      },
      onTapCancel: () => _ctrl.reverse(),
      child: AnimatedBuilder(
        animation: _scale,
        builder: (_, child) =>
            Transform.scale(scale: _scale.value, child: child),
        child: Container(
          width: double.infinity,
          height: 54,
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: const Color(0xFFE5E7EB)),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.06),
                blurRadius: 12,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Center(
            child: widget.loading
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                        color: _kAccent, strokeWidth: 2),
                  )
                : Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        width: 22,
                        height: 22,
                        decoration: BoxDecoration(
                          color: const Color(0xFFF5F5F5),
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: const Center(
                          child: Text(
                            'G',
                            style: TextStyle(
                              color: Color(0xFF4285F4),
                              fontWeight: FontWeight.w700,
                              fontSize: 13,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Text(
                        'Continuar con Google',
                        style: GoogleFonts.outfit(
                          fontSize: 15,
                          fontWeight: FontWeight.w600,
                          color: _kInk,
                        ),
                      ),
                    ],
                  ),
          ),
        ),
      ),
    );
  }
}
