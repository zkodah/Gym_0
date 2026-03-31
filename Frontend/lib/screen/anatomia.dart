import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

const _kAccent = Color(0xFFFF6D00);
const _kSecondary = Color(0xFF9D4EDD);
const _kInk = Color(0xFF1A1A2E);
const _kCard = Color(0xFF252540);
const _kInactive = Color(0xFF3A3A5A);

class AnatomiaScreen extends StatefulWidget {
  final String nombreEjercicio;
  final List<String> musculosPrincipales;
  final List<String> musculosSecundarios;
  final String? tip;

  const AnatomiaScreen({
    super.key,
    required this.nombreEjercicio,
    required this.musculosPrincipales,
    required this.musculosSecundarios,
    this.tip,
  });

  @override
  State<AnatomiaScreen> createState() => _AnatomiaScreenState();
}

class _AnatomiaScreenState extends State<AnatomiaScreen>
    with SingleTickerProviderStateMixin {
  bool _verFrente = true;

  Color _colorMusculo(String musculo) {
    final m = musculo.toLowerCase();
    if (widget.musculosPrincipales.map((e) => e.toLowerCase()).contains(m)) {
      return _kAccent;
    }
    if (widget.musculosSecundarios.map((e) => e.toLowerCase()).contains(m)) {
      return _kSecondary;
    }
    return _kInactive;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _kInk,
      appBar: AppBar(
        backgroundColor: _kInk,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.white),
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Músculos trabajados',
              style: GoogleFonts.outfit(
                fontSize: 11,
                fontWeight: FontWeight.w600,
                color: _kAccent,
                letterSpacing: 0.5,
              ),
            ),
            Text(
              widget.nombreEjercicio,
              style: GoogleFonts.outfit(
                fontSize: 16,
                fontWeight: FontWeight.w700,
                color: Colors.white,
              ),
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
      body: Column(
        children: [
          // ── Toggle frente / espalda ─────────────────────────────────────
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 8, 20, 0),
            child: Container(
              height: 42,
              decoration: BoxDecoration(
                color: _kCard,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: _ToggleBtn(
                      label: 'Vista frontal',
                      active: _verFrente,
                      onTap: () => setState(() => _verFrente = true),
                    ),
                  ),
                  Expanded(
                    child: _ToggleBtn(
                      label: 'Vista posterior',
                      active: !_verFrente,
                      onTap: () => setState(() => _verFrente = false),
                    ),
                  ),
                ],
              ),
            ),
          ),

          // ── Diagrama corporal ───────────────────────────────────────────
          Expanded(
            flex: 6,
            child: Center(
              child: AnimatedSwitcher(
                duration: const Duration(milliseconds: 280),
                transitionBuilder: (child, anim) => FadeTransition(
                  opacity: anim,
                  child: SlideTransition(
                    position: Tween<Offset>(
                      begin: const Offset(0.06, 0),
                      end: Offset.zero,
                    ).animate(anim),
                    child: child,
                  ),
                ),
                child: CustomPaint(
                  key: ValueKey(_verFrente),
                  size: const Size(190, 400),
                  painter: _BodyPainter(
                    frente: _verFrente,
                    colorMusculo: _colorMusculo,
                  ),
                ),
              ),
            ),
          ),

          // ── Panel inferior: leyenda + chips + tip ───────────────────────
          Container(
            padding: const EdgeInsets.fromLTRB(20, 18, 20, 28),
            decoration: const BoxDecoration(
              color: _kCard,
              borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Leyenda
                Row(
                  children: [
                    _LegendDot(color: _kAccent),
                    const SizedBox(width: 6),
                    Text(
                      'Principal',
                      style: GoogleFonts.outfit(
                        fontSize: 13,
                        color: Colors.white70,
                      ),
                    ),
                    const SizedBox(width: 20),
                    _LegendDot(color: _kSecondary),
                    const SizedBox(width: 6),
                    Text(
                      'Secundario',
                      style: GoogleFonts.outfit(
                        fontSize: 13,
                        color: Colors.white70,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),

                // Muscle chips
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    ...widget.musculosPrincipales.map(
                      (m) => _MuscleChip(
                        label: _labelMusculo(m),
                        color: _kAccent,
                      ),
                    ),
                    ...widget.musculosSecundarios.map(
                      (m) => _MuscleChip(
                        label: _labelMusculo(m),
                        color: _kSecondary,
                      ),
                    ),
                  ],
                ),

                // Tip
                if (widget.tip != null && widget.tip!.isNotEmpty) ...[
                  const SizedBox(height: 14),
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: _kAccent.withOpacity(0.08),
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(
                        color: _kAccent.withOpacity(0.25),
                        width: 1,
                      ),
                    ),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Icon(
                          Icons.tips_and_updates_outlined,
                          color: _kAccent,
                          size: 16,
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            widget.tip!,
                            style: GoogleFonts.outfit(
                              fontSize: 13,
                              color: Colors.white70,
                              height: 1.4,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ── Helpers ────────────────────────────────────────────────────────────────────

String _labelMusculo(String m) {
  const labels = {
    'cuadriceps': 'Cuádriceps',
    'isquiotibiales': 'Isquiotibiales',
    'gluteos': 'Glúteos',
    'pantorrillas': 'Pantorrillas',
    'gemelos': 'Gemelos',
    'pecho': 'Pecho',
    'dorsales': 'Dorsales',
    'trapecio': 'Trapecio',
    'romboides': 'Romboides',
    'lumbares': 'Lumbares',
    'deltoides': 'Deltoides',
    'deltoides_anterior': 'Deltoides ant.',
    'deltoides_lateral': 'Deltoides lat.',
    'deltoides_posterior': 'Deltoides post.',
    'biceps': 'Bíceps',
    'triceps': 'Tríceps',
    'abdominales': 'Abdominales',
    'oblicuos': 'Oblicuos',
    'antebrazos': 'Antebrazos',
    'core': 'Core',
    'psoas': 'Psoas',
    'aductores': 'Aductores',
    'abductores': 'Abductores',
  };
  return labels[m.toLowerCase()] ?? m;
}

// ── Sub-widgets ────────────────────────────────────────────────────────────────

class _ToggleBtn extends StatelessWidget {
  final String label;
  final bool active;
  final VoidCallback onTap;

  const _ToggleBtn({
    required this.label,
    required this.active,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        margin: const EdgeInsets.all(3),
        decoration: BoxDecoration(
          color: active ? _kAccent : Colors.transparent,
          borderRadius: BorderRadius.circular(9),
        ),
        child: Center(
          child: Text(
            label,
            style: GoogleFonts.outfit(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: active ? Colors.white : Colors.white38,
            ),
          ),
        ),
      ),
    );
  }
}

class _LegendDot extends StatelessWidget {
  final Color color;
  const _LegendDot({required this.color});

  @override
  Widget build(BuildContext context) => Container(
        width: 12,
        height: 12,
        decoration: BoxDecoration(color: color, shape: BoxShape.circle),
      );
}

class _MuscleChip extends StatelessWidget {
  final String label;
  final Color color;
  const _MuscleChip({required this.label, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
      decoration: BoxDecoration(
        color: color.withOpacity(0.14),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withOpacity(0.45), width: 1),
      ),
      child: Text(
        label,
        style: GoogleFonts.outfit(
          fontSize: 12,
          fontWeight: FontWeight.w600,
          color: color,
        ),
      ),
    );
  }
}

// ── CustomPainter del cuerpo ───────────────────────────────────────────────────

class _BodyPainter extends CustomPainter {
  final bool frente;
  final Color Function(String) colorMusculo;

  const _BodyPainter({required this.frente, required this.colorMusculo});

  @override
  void paint(Canvas canvas, Size size) {
    // Virtual canvas: 190×400, scale to actual size
    canvas.scale(size.width / 190, size.height / 400);
    _drawSilhouette(canvas);
    if (frente) {
      _drawFrente(canvas);
    } else {
      _drawEspalda(canvas);
    }
  }

  void _drawSilhouette(Canvas canvas) {
    final p = Paint()
      ..color = const Color(0xFF1E1E3A)
      ..style = PaintingStyle.fill;

    // Head
    canvas.drawCircle(const Offset(95, 24), 21, p);
    // Neck
    canvas.drawRRect(
        RRect.fromRectAndRadius(
            const Rect.fromLTWH(84, 44, 22, 18), const Radius.circular(4)),
        p);
    // Torso
    canvas.drawRRect(
        RRect.fromRectAndRadius(
            const Rect.fromLTWH(58, 62, 74, 126), const Radius.circular(14)),
        p);
    // Left upper arm
    canvas.drawRRect(
        RRect.fromRectAndRadius(
            const Rect.fromLTWH(30, 64, 27, 98), const Radius.circular(12)),
        p);
    // Right upper arm
    canvas.drawRRect(
        RRect.fromRectAndRadius(
            const Rect.fromLTWH(133, 64, 27, 98), const Radius.circular(12)),
        p);
    // Hips/pelvis
    canvas.drawRRect(
        RRect.fromRectAndRadius(
            const Rect.fromLTWH(58, 188, 74, 26), const Radius.circular(10)),
        p);
    // Left leg
    canvas.drawRRect(
        RRect.fromRectAndRadius(
            const Rect.fromLTWH(60, 212, 32, 166), const Radius.circular(14)),
        p);
    // Right leg
    canvas.drawRRect(
        RRect.fromRectAndRadius(
            const Rect.fromLTWH(98, 212, 32, 166), const Radius.circular(14)),
        p);

    // Silhouette outline
    final outline = Paint()
      ..color = const Color(0xFF34345C)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.2;
    canvas.drawCircle(const Offset(95, 24), 21, outline);

    // Eyes
    final eye = Paint()
      ..color = const Color(0xFF34345C)
      ..style = PaintingStyle.fill;
    canvas.drawCircle(const Offset(89, 20), 2.2, eye);
    canvas.drawCircle(const Offset(101, 20), 2.2, eye);
  }

  void _drawFrente(Canvas canvas) {
    // Deltoides (anterior + lateral)
    _paint(canvas, 'deltoides_anterior', _oval(43, 74, 19, 15));
    _paint(canvas, 'deltoides_lateral', _oval(43, 74, 19, 15));
    _paint(canvas, 'deltoides', _oval(43, 74, 19, 15));
    _paint(canvas, 'deltoides_anterior', _oval(147, 74, 19, 15));
    _paint(canvas, 'deltoides_lateral', _oval(147, 74, 19, 15));
    _paint(canvas, 'deltoides', _oval(147, 74, 19, 15));

    // Pecho izquierdo + derecho
    _paint(canvas, 'pecho', _rrect(62, 70, 30, 46, 8));
    _paint(canvas, 'pecho', _rrect(98, 70, 30, 46, 8));

    // Bíceps
    _paint(canvas, 'biceps', _rrect(33, 96, 22, 46, 9));
    _paint(canvas, 'biceps', _rrect(135, 96, 22, 46, 9));

    // Antebrazos
    _paint(canvas, 'antebrazos', _rrect(31, 146, 18, 40, 7));
    _paint(canvas, 'antebrazos', _rrect(141, 146, 18, 40, 7));

    // Abdominales (3×2 grid)
    for (int row = 0; row < 3; row++) {
      final y = 120.0 + row * 18;
      _paint(canvas, 'abdominales', _rrect(79, y, 13, 14, 4));
      _paint(canvas, 'abdominales', _rrect(98, y, 13, 14, 4));
      _paint(canvas, 'core', _rrect(79, y, 13, 14, 4));
      _paint(canvas, 'core', _rrect(98, y, 13, 14, 4));
    }

    // Oblicuos
    _paint(canvas, 'oblicuos', _rrect(63, 124, 14, 46, 6));
    _paint(canvas, 'oblicuos', _rrect(113, 124, 14, 46, 6));

    // Cuádriceps
    _paint(canvas, 'cuadriceps', _rrect(61, 216, 30, 68, 12));
    _paint(canvas, 'cuadriceps', _rrect(99, 216, 30, 68, 12));

    // Aductores (cara interna)
    _paint(canvas, 'aductores', _rrect(78, 216, 14, 54, 7));
    _paint(canvas, 'aductores', _rrect(98, 216, 14, 54, 7));

    // Pantorrillas / gemelos (frontal)
    _paint(canvas, 'pantorrillas', _rrect(63, 290, 24, 60, 10));
    _paint(canvas, 'pantorrillas', _rrect(103, 290, 24, 60, 10));
    _paint(canvas, 'gemelos', _rrect(63, 290, 24, 60, 10));
    _paint(canvas, 'gemelos', _rrect(103, 290, 24, 60, 10));
  }

  void _drawEspalda(Canvas canvas) {
    // Trapecio (diamante)
    _paint(canvas, 'trapecio', _trapecio());

    // Deltoides posterior
    _paint(canvas, 'deltoides_posterior', _oval(43, 78, 19, 15));
    _paint(canvas, 'deltoides', _oval(43, 78, 19, 15));
    _paint(canvas, 'deltoides_posterior', _oval(147, 78, 19, 15));
    _paint(canvas, 'deltoides', _oval(147, 78, 19, 15));

    // Romboides (centro espalda alta)
    _paint(canvas, 'romboides', _rrect(74, 106, 42, 40, 6));

    // Dorsales izquierdo + derecho
    _paint(canvas, 'dorsales', _dorsales(left: true));
    _paint(canvas, 'dorsales', _dorsales(left: false));

    // Tríceps
    _paint(canvas, 'triceps', _rrect(33, 96, 22, 52, 9));
    _paint(canvas, 'triceps', _rrect(135, 96, 22, 52, 9));

    // Antebrazos
    _paint(canvas, 'antebrazos', _rrect(31, 152, 18, 40, 7));
    _paint(canvas, 'antebrazos', _rrect(141, 152, 18, 40, 7));

    // Lumbares
    _paint(canvas, 'lumbares', _rrect(77, 162, 36, 32, 7));

    // Glúteos
    _paint(canvas, 'gluteos', _oval(79, 202, 25, 28));
    _paint(canvas, 'gluteos', _oval(111, 202, 25, 28));

    // Isquiotibiales
    _paint(canvas, 'isquiotibiales', _rrect(61, 228, 30, 62, 12));
    _paint(canvas, 'isquiotibiales', _rrect(99, 228, 30, 62, 12));

    // Pantorrillas / gemelos
    _paint(canvas, 'pantorrillas', _rrect(64, 296, 24, 56, 10));
    _paint(canvas, 'pantorrillas', _rrect(102, 296, 24, 56, 10));
    _paint(canvas, 'gemelos', _rrect(64, 296, 24, 56, 10));
    _paint(canvas, 'gemelos', _rrect(102, 296, 24, 56, 10));
  }

  // ── Path helpers ────────────────────────────────────────────────────────────

  Path _oval(double cx, double cy, double rx, double ry) => Path()
    ..addOval(Rect.fromCenter(
        center: Offset(cx, cy), width: rx * 2, height: ry * 2));

  Path _rrect(double x, double y, double w, double h, double r) =>
      Path()
        ..addRRect(RRect.fromRectAndRadius(
            Rect.fromLTWH(x, y, w, h), Radius.circular(r)));

  Path _trapecio() {
    return Path()
      ..moveTo(95, 63)
      ..lineTo(136, 70)
      ..lineTo(130, 106)
      ..lineTo(95, 114)
      ..lineTo(60, 106)
      ..lineTo(54, 70)
      ..close();
  }

  Path _dorsales({required bool left}) {
    if (left) {
      return Path()
        ..moveTo(58, 108)
        ..lineTo(78, 106)
        ..lineTo(74, 166)
        ..lineTo(58, 170)
        ..close();
    } else {
      return Path()
        ..moveTo(132, 108)
        ..lineTo(112, 106)
        ..lineTo(116, 166)
        ..lineTo(132, 170)
        ..close();
    }
  }

  // ── Draw a muscle region with fill + optional glow ──────────────────────────

  void _paint(Canvas canvas, String musculo, Path path) {
    final color = colorMusculo(musculo);

    canvas.drawPath(path, Paint()
      ..color = color
      ..style = PaintingStyle.fill);

    if (color != _kInactive) {
      // Glow
      canvas.drawPath(
          path,
          Paint()
            ..color = color.withOpacity(0.35)
            ..style = PaintingStyle.stroke
            ..strokeWidth = 4
            ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 6));
    }

    // Border
    canvas.drawPath(
        path,
        Paint()
          ..color = color == _kInactive
              ? const Color(0xFF454570)
              : color.withOpacity(0.75)
          ..style = PaintingStyle.stroke
          ..strokeWidth = 0.8);
  }

  @override
  bool shouldRepaint(_BodyPainter old) =>
      old.frente != frente || old.colorMusculo != colorMusculo;
}
