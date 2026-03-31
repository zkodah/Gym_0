import 'package:flutter/material.dart';
import 'dart:async';
import 'package:percent_indicator/percent_indicator.dart';
import 'package:google_fonts/google_fonts.dart';
import 'youtube_busqueda.dart';
import 'ejercicio_detalle.dart';
import '../widget/navbar.dart';

const _kAccent = Color(0xFFFF6D00);
const _kSecondary = Color(0xFF9D4EDD);
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

  List<Map<String, dynamic>> get _ejercicios {
    final raw = widget.rutina['ejercicios'];
    if (raw is List) {
      return raw.map((e) => Map<String, dynamic>.from(e as Map)).toList();
    }
    return [];
  }

  List<String> get _calentamiento {
    final raw = widget.rutina['calentamiento'];
    if (raw is List) return raw.map((e) => e.toString()).toList();
    return [];
  }

  List<String> get _vueltaCalma {
    final raw = widget.rutina['vuelta_a_la_calma'];
    if (raw is List) return raw.map((e) => e.toString()).toList();
    return [];
  }

  String get _duracion =>
      widget.rutina['duracion_estimada']?.toString() ?? '';

  String get _objetivoDia =>
      widget.rutina['objetivo_dia']?.toString() ?? '';

  @override
  void initState() {
    super.initState();
    completados = List<bool>.filled(_ejercicios.length, false);
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
          actions: [
            if (_duracion.isNotEmpty)
              Padding(
                padding: const EdgeInsets.only(right: 14),
                child: Row(
                  children: [
                    const Icon(Icons.schedule_outlined,
                        color: Colors.white54, size: 14),
                    const SizedBox(width: 4),
                    Text(
                      _duracion,
                      style: GoogleFonts.outfit(
                        fontSize: 12,
                        color: Colors.white54,
                      ),
                    ),
                  ],
                ),
              ),
          ],
        ),
        body: Column(
          children: [
            // ── Objetivo del día ──────────────────────────────────────────
            if (_objetivoDia.isNotEmpty)
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
                child: Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(
                      horizontal: 14, vertical: 10),
                  decoration: BoxDecoration(
                    color: _kAccent.withOpacity(0.08),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: _kAccent.withOpacity(0.2),
                      width: 1,
                    ),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.flag_outlined,
                          color: _kAccent, size: 15),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          _objetivoDia,
                          style: GoogleFonts.outfit(
                            fontSize: 12,
                            color: _kInk,
                            height: 1.3,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),

            // ── Cronómetro ────────────────────────────────────────────────
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
              child: _CronometroButton(
                running: running,
                tiempo: formatTime(seconds),
                onTap: toggleTimer,
              ),
            ),

            // ── Lista de secciones ────────────────────────────────────────
            Expanded(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
                child: ListView(
                  children: [
                    // Calentamiento
                    if (_calentamiento.isNotEmpty)
                      _SeccionCard(
                        icon: Icons.local_fire_department_outlined,
                        iconColor: const Color(0xFFFF9E00),
                        titulo: 'Calentamiento',
                        items: _calentamiento,
                      ),

                    if (_calentamiento.isNotEmpty) const SizedBox(height: 10),

                    // Ejercicios
                    _EjerciciosCard(
                      ejercicios: _ejercicios,
                      completados: completados,
                      onChanged: (i, val) =>
                          setState(() => completados[i] = val ?? false),
                    ),

                    if (_vueltaCalma.isNotEmpty) const SizedBox(height: 10),

                    // Vuelta a la calma
                    if (_vueltaCalma.isNotEmpty)
                      _SeccionCard(
                        icon: Icons.self_improvement_outlined,
                        iconColor: _kSecondary,
                        titulo: 'Vuelta a la calma',
                        items: _vueltaCalma,
                      ),

                    const SizedBox(height: 8),
                  ],
                ),
              ),
            ),

            // ── Barra de progreso ─────────────────────────────────────────
            _ProgresoBar(
              progreso: progreso,
              completados: completados.where((c) => c).length,
              total: completados.length,
            ),
          ],
        ),
        bottomNavigationBar: const GymNavbar(currentIndex: 1),
      ),
    );
  }
}

// ── Sección genérica (calentamiento / vuelta a la calma) ──────────────────────

class _SeccionCard extends StatelessWidget {
  final IconData icon;
  final Color iconColor;
  final String titulo;
  final List<String> items;

  const _SeccionCard({
    required this.icon,
    required this.iconColor,
    required this.titulo,
    required this.items,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(14, 12, 14, 6),
            child: Row(
              children: [
                Icon(icon, color: iconColor, size: 16),
                const SizedBox(width: 6),
                Text(
                  titulo,
                  style: GoogleFonts.outfit(
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    color: _kInk,
                  ),
                ),
              ],
            ),
          ),
          const Divider(height: 1, color: Color(0xFFF0F0F0)),
          ...items.map(
            (item) => Padding(
              padding:
                  const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    margin: const EdgeInsets.only(top: 6),
                    width: 5,
                    height: 5,
                    decoration: BoxDecoration(
                      color: iconColor,
                      shape: BoxShape.circle,
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      item,
                      style: GoogleFonts.outfit(
                        fontSize: 13,
                        color: _kInk,
                        height: 1.35,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 6),
        ],
      ),
    );
  }
}

// ── Card de ejercicios ─────────────────────────────────────────────────────────

class _EjerciciosCard extends StatelessWidget {
  final List<Map<String, dynamic>> ejercicios;
  final List<bool> completados;
  final void Function(int, bool?) onChanged;

  const _EjerciciosCard({
    required this.ejercicios,
    required this.completados,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
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
                const Icon(Icons.fitness_center_rounded,
                    color: _kAccent, size: 16),
                const SizedBox(width: 6),
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
                  '${completados.where((c) => c).length}/${ejercicios.length}',
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
          ListView.separated(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            padding: const EdgeInsets.symmetric(vertical: 4),
            itemCount: ejercicios.length,
            separatorBuilder: (_, __) => const Divider(
              height: 1,
              indent: 16,
              color: Color(0xFFF0F0F0),
            ),
            itemBuilder: (context, i) {
              final ej = ejercicios[i];
              final nombre = ej['nombre']?.toString() ?? '';
              final series = ej['series']?.toString() ?? '';
              final reps = ej['reps']?.toString() ?? '';
              final descanso = ej['descanso']?.toString() ?? '';
              final tip = ej['tip']?.toString() ?? '';

              final mpRaw = ej['musculos_principales'];
              final msRaw = ej['musculos_secundarios'];
              final mp = mpRaw is List
                  ? mpRaw.map((e) => e.toString()).toList()
                  : <String>[];
              final ms = msRaw is List
                  ? msRaw.map((e) => e.toString()).toList()
                  : <String>[];

              return _EjercicioItem(
                nombre: nombre,
                series: series,
                reps: reps,
                descanso: descanso,
                tip: tip,
                musculosPrincipales: mp,
                musculosSecundarios: ms,
                completado: completados[i],
                onChanged: (val) => onChanged(i, val),
                onYoutube: () => Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) =>
                        YoutubeSearchScreen(initialQuery: nombre),
                  ),
                ),
                onAnatomia: () => Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => EjercicioDetalleScreen(ejercicio: ej),
                  ),
                ),
                onTap: () => Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => EjercicioDetalleScreen(ejercicio: ej),
                  ),
                ),
              );
            },
          ),
        ],
      ),
    );
  }
}

// ── Ejercicio Item ─────────────────────────────────────────────────────────────

class _EjercicioItem extends StatelessWidget {
  final String nombre;
  final String series;
  final String reps;
  final String descanso;
  final String tip;
  final List<String> musculosPrincipales;
  final List<String> musculosSecundarios;
  final bool completado;
  final ValueChanged<bool?> onChanged;
  final VoidCallback onYoutube;
  final VoidCallback onAnatomia;
  final VoidCallback? onTap;

  const _EjercicioItem({
    required this.nombre,
    required this.series,
    required this.reps,
    required this.descanso,
    required this.tip,
    required this.musculosPrincipales,
    required this.musculosSecundarios,
    required this.completado,
    required this.onChanged,
    required this.onYoutube,
    required this.onAnatomia,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final allMuscles = [
      ...musculosPrincipales,
      ...musculosSecundarios,
    ];

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Checkbox
          Padding(
            padding: const EdgeInsets.only(top: 2),
            child: SizedBox(
              width: 28,
              height: 28,
              child: Checkbox(
                value: completado,
                onChanged: onChanged,
                activeColor: _kAccent,
                checkColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(6),
                ),
                materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
              ),
            ),
          ),
          const SizedBox(width: 8),

          // Exercise info (tappable → detail)
          Expanded(
            child: GestureDetector(
              onTap: onTap ?? onAnatomia,
              behavior: HitTestBehavior.opaque,
              child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Nombre
                Text(
                  nombre,
                  style: GoogleFonts.outfit(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: completado ? const Color(0xFFBBBBBB) : _kInk,
                    decoration:
                        completado ? TextDecoration.lineThrough : null,
                    decorationColor: const Color(0xFFBBBBBB),
                  ),
                ),

                // Series × reps • descanso
                if (series.isNotEmpty || reps.isNotEmpty)
                  Padding(
                    padding: const EdgeInsets.only(top: 3),
                    child: Row(
                      children: [
                        if (series.isNotEmpty && reps.isNotEmpty)
                          _MetaChip(
                            label: '$series × $reps',
                            icon: Icons.repeat_rounded,
                            color: _kAccent,
                          ),
                        if (descanso.isNotEmpty) ...[
                          const SizedBox(width: 6),
                          _MetaChip(
                            label: descanso,
                            icon: Icons.timer_outlined,
                            color: const Color(0xFF6B7280),
                          ),
                        ],
                      ],
                    ),
                  ),

                // Muscle chips (principales only to keep it compact)
                if (allMuscles.isNotEmpty)
                  Padding(
                    padding: const EdgeInsets.only(top: 5),
                    child: Wrap(
                      spacing: 4,
                      runSpacing: 4,
                      children: [
                        ...musculosPrincipales.take(2).map(
                              (m) => _SmallMuscleChip(
                                label: _shortMusculo(m),
                                color: _kAccent,
                              ),
                            ),
                        ...musculosSecundarios.take(2).map(
                              (m) => _SmallMuscleChip(
                                label: _shortMusculo(m),
                                color: _kSecondary,
                              ),
                            ),
                      ],
                    ),
                  ),
              ],
            ),
            ),
          ),

          // Action buttons
          Column(
            children: [
              Tooltip(
                message: 'Ver músculos',
                child: IconButton(
                  onPressed: onAnatomia,
                  icon: const Icon(
                    Icons.accessibility_new_rounded,
                    color: _kSecondary,
                    size: 22,
                  ),
                  padding: const EdgeInsets.all(4),
                  constraints: const BoxConstraints(),
                  splashRadius: 18,
                ),
              ),
              const SizedBox(height: 2),
              Tooltip(
                message: 'Tutorial en YouTube',
                child: IconButton(
                  onPressed: onYoutube,
                  icon: const Icon(
                    Icons.play_circle_outline_rounded,
                    color: _kAccent,
                    size: 22,
                  ),
                  padding: const EdgeInsets.all(4),
                  constraints: const BoxConstraints(),
                  splashRadius: 18,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

// ── Meta chip (series×reps, descanso) ─────────────────────────────────────────

class _MetaChip extends StatelessWidget {
  final String label;
  final IconData icon;
  final Color color;

  const _MetaChip({
    required this.label,
    required this.icon,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 11, color: color.withOpacity(0.8)),
        const SizedBox(width: 3),
        Text(
          label,
          style: GoogleFonts.outfit(
            fontSize: 12,
            fontWeight: FontWeight.w500,
            color: color.withOpacity(0.9),
          ),
        ),
      ],
    );
  }
}

// ── Small muscle chip ──────────────────────────────────────────────────────────

class _SmallMuscleChip extends StatelessWidget {
  final String label;
  final Color color;

  const _SmallMuscleChip({required this.label, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withOpacity(0.3), width: 0.8),
      ),
      child: Text(
        label,
        style: GoogleFonts.outfit(
          fontSize: 10,
          fontWeight: FontWeight.w600,
          color: color,
        ),
      ),
    );
  }
}

String _shortMusculo(String m) {
  const shorts = {
    'cuadriceps': 'Cuádriceps',
    'isquiotibiales': 'Isquios',
    'gluteos': 'Glúteos',
    'pantorrillas': 'Gemelos',
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
    'abdominales': 'Abdomen',
    'oblicuos': 'Oblicuos',
    'antebrazos': 'Antebrazos',
    'core': 'Core',
    'psoas': 'Psoas',
    'aductores': 'Aductores',
    'abductores': 'Abductores',
  };
  return shorts[m.toLowerCase()] ?? m;
}

// ── Cronómetro button ──────────────────────────────────────────────────────────

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
                color:
                    (widget.running ? _kAccent : _kInk).withOpacity(0.15),
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

// ── Barra de progreso inferior ─────────────────────────────────────────────────

class _ProgresoBar extends StatelessWidget {
  final double progreso;
  final int completados;
  final int total;

  const _ProgresoBar({
    required this.progreso,
    required this.completados,
    required this.total,
  });

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
                          ? '¡Rutina completada! Excelente trabajo'
                          : '$completados de $total ejercicios completados',
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
