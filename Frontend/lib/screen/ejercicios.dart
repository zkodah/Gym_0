import 'package:flutter/material.dart';
import 'dart:async';
import 'package:percent_indicator/percent_indicator.dart';
import 'package:google_fonts/google_fonts.dart';
import 'youtube_busqueda.dart';
import '../widget/navbar.dart';

const _kAccent = Color(0xFFFF6D00);
const _kInk = Color(0xFF1A1A2E);
const _kBg = Color(0xFFF5F5F7);

class RutinaScreen extends StatefulWidget {
  final Map<String, dynamic> rutina;
  const RutinaScreen({super.key, required this.rutina});

  @override
  State<RutinaScreen> createState() => _RutinaScreenState();
}

class _RutinaScreenState extends State<RutinaScreen> {
  bool running = false;
  int seconds = 0;
  Timer? timer;
  late List<bool> completados;

  @override
  void initState() {
    super.initState();
    completados = List<bool>.filled(widget.rutina['rutina'].length, false);
  }

  @override
  void dispose() {
    timer?.cancel();
    super.dispose();
  }

  void toggleTimer() {
    if (running) {
      timer?.cancel();
    } else {
      timer = Timer.periodic(const Duration(seconds: 1), (_) {
        setState(() => seconds++);
      });
    }
    setState(() => running = !running);
  }

  String formatTime(int s) {
    final m = (s ~/ 60).toString().padLeft(2, '0');
    final sec = (s % 60).toString().padLeft(2, '0');
    return '$m:$sec';
  }

  double calcularProgreso() {
    if (completados.isEmpty) return 0;
    return completados.where((c) => c).length / completados.length;
  }

  void _volver() => Navigator.pop(context, calcularProgreso());

  String get _titulo {
    final titulo = widget.rutina['titulo']?.toString() ?? '';
    return titulo.isNotEmpty ? titulo : (widget.rutina['dia']?.toString() ?? '');
  }

  @override
  Widget build(BuildContext context) {
    final rutina = widget.rutina;
    final progreso = calcularProgreso();

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop) _volver();
      },
      child: Scaffold(
        backgroundColor: _kBg,
        appBar: AppBar(
          backgroundColor: _kInk,
          elevation: 0,
          iconTheme: const IconThemeData(color: Colors.white),
          leading: IconButton(
            icon: const Icon(Icons.arrow_back_ios_new_rounded),
            onPressed: _volver,
          ),
          title: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                widget.rutina['dia']?.toString() ?? '',
                style: GoogleFonts.outfit(
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                  color: _kAccent,
                  letterSpacing: 0.5,
                ),
              ),
              Text(
                _titulo,
                style: GoogleFonts.outfit(
                  fontSize: 17,
                  fontWeight: FontWeight.w700,
                  color: Colors.white,
                ),
              ),
            ],
          ),
        ),
        body: Column(
          children: [
            // ── Cronómetro ──────────────────────────────────────────────────
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
              child: _CronometroButton(
                running: running,
                tiempo: formatTime(seconds),
                onTap: toggleTimer,
              ),
            ),

            // ── Lista de ejercicios ─────────────────────────────────────────
            Expanded(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
                child: Container(
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.05),
                        blurRadius: 12,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Padding(
                        padding: const EdgeInsets.fromLTRB(16, 14, 16, 6),
                        child: Row(
                          children: [
                            Text(
                              'Ejercicios',
                              style: GoogleFonts.outfit(
                                fontSize: 16,
                                fontWeight: FontWeight.w700,
                                color: _kInk,
                              ),
                            ),
                            const Spacer(),
                            Text(
                              '${completados.where((c) => c).length}/${rutina['rutina'].length}',
                              style: GoogleFonts.outfit(
                                fontSize: 13,
                                fontWeight: FontWeight.w600,
                                color: _kAccent,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const Divider(height: 1, color: Color(0xFFF0F0F0)),
                      Expanded(
                        child: ListView.separated(
                          padding: const EdgeInsets.symmetric(vertical: 4),
                          itemCount: rutina['rutina'].length,
                          separatorBuilder: (_, __) => const Divider(
                            height: 1,
                            indent: 56,
                            color: Color(0xFFF0F0F0),
                          ),
                          itemBuilder: (context, i) {
                            final nombre = rutina['rutina'][i].toString();
                            return _EjercicioItem(
                              nombre: nombre,
                              completado: completados[i],
                              onChanged: (val) =>
                                  setState(() => completados[i] = val ?? false),
                              onYoutube: () => Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (_) => YoutubeSearchScreen(
                                    initialQuery: nombre,
                                  ),
                                ),
                              ),
                            );
                          },
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),

            // ── Barra de progreso ───────────────────────────────────────────
            _ProgresoBar(progreso: progreso),
          ],
        ),
        bottomNavigationBar: const GymNavbar(currentIndex: 1),
      ),
    );
  }
}

// ── Cronómetro button ─────────────────────────────────────────────────────────
class _CronometroButton extends StatefulWidget {
  final bool running;
  final String tiempo;
  final VoidCallback onTap;

  const _CronometroButton({
    required this.running,
    required this.tiempo,
    required this.onTap,
  });

  @override
  State<_CronometroButton> createState() => _CronometroButtonState();
}

class _CronometroButtonState extends State<_CronometroButton>
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
        widget.onTap();
      },
      onTapCancel: () => _ctrl.reverse(),
      child: AnimatedBuilder(
        animation: _scale,
        builder: (_, child) =>
            Transform.scale(scale: _scale.value, child: child),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 250),
          width: double.infinity,
          padding: const EdgeInsets.symmetric(vertical: 14),
          decoration: BoxDecoration(
            color: widget.running ? Colors.white : _kInk,
            borderRadius: BorderRadius.circular(14),
            border: widget.running
                ? Border.all(color: _kAccent, width: 1.5)
                : null,
            boxShadow: [
              BoxShadow(
                color: (widget.running ? _kAccent : _kInk).withOpacity(0.15),
                blurRadius: 16,
                offset: const Offset(0, 6),
              ),
            ],
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                widget.running
                    ? Icons.stop_circle_outlined
                    : Icons.timer_outlined,
                color: widget.running ? _kAccent : Colors.white,
                size: 20,
              ),
              const SizedBox(width: 10),
              Text(
                widget.running
                    ? '${widget.tiempo}  —  Detener'
                    : 'Iniciar cronómetro',
                style: GoogleFonts.outfit(
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                  color: widget.running ? _kInk : Colors.white,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ── Barra de progreso inferior ────────────────────────────────────────────────
class _ProgresoBar extends StatelessWidget {
  final double progreso;
  const _ProgresoBar({required this.progreso});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          CircularPercentIndicator(
            radius: 28.0,
            lineWidth: 5.5,
            percent: progreso.clamp(0.0, 1.0),
            center: Text(
              '${(progreso * 100).toInt()}%',
              style: GoogleFonts.outfit(
                fontSize: 11,
                fontWeight: FontWeight.w800,
                color: _kInk,
              ),
            ),
            linearGradient: const LinearGradient(
              colors: [_kAccent, Color(0xFFFF9E00)],
            ),
            backgroundColor: const Color(0xFFEEEEEE),
            circularStrokeCap: CircularStrokeCap.round,
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Progreso de la rutina',
                  style: GoogleFonts.outfit(
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    color: _kInk,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  progreso == 0
                      ? 'Marca ejercicios al completarlos'
                      : progreso == 1.0
                          ? 'Rutina completada'
                          : 'Vas por el camino correcto',
                  style: GoogleFonts.outfit(
                    fontSize: 12,
                    color: const Color(0xFF9E9E9E),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ── Ejercicio Item ────────────────────────────────────────────────────────────
class _EjercicioItem extends StatelessWidget {
  final String nombre;
  final bool completado;
  final ValueChanged<bool?> onChanged;
  final VoidCallback onYoutube;

  const _EjercicioItem({
    required this.nombre,
    required this.completado,
    required this.onChanged,
    required this.onYoutube,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: CheckboxListTile(
            contentPadding: const EdgeInsets.only(left: 8),
            title: Text(
              nombre,
              style: GoogleFonts.outfit(
                fontSize: 14,
                fontWeight: FontWeight.w500,
                color: completado
                    ? const Color(0xFFBBBBBB)
                    : _kInk,
                decoration: completado ? TextDecoration.lineThrough : null,
                decorationColor: const Color(0xFFBBBBBB),
              ),
            ),
            value: completado,
            onChanged: onChanged,
            activeColor: _kAccent,
            checkColor: Colors.white,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(5),
            ),
          ),
        ),
        Tooltip(
          message: 'Ver tutorial en YouTube',
          child: IconButton(
            onPressed: onYoutube,
            icon: const Icon(
              Icons.play_circle_outline_rounded,
              color: _kAccent,
              size: 24,
            ),
            splashRadius: 20,
          ),
        ),
        const SizedBox(width: 4),
      ],
    );
  }
}
