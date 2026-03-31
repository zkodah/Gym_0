import 'package:flutter/material.dart';
import 'dart:async';
import 'dart:math' as math;
import 'package:google_fonts/google_fonts.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'youtube_busqueda.dart';

const _kAccent = Color(0xFFFF6D00);
const _kSecondary = Color(0xFF9D4EDD);
const _kInk = Color(0xFF1A1A2E);
const _kBg = Color(0xFFF5F5F7);
const _kInactive = Color(0xFF3A3A5A);

// ─── Data model ───────────────────────────────────────────────────────────────

class _Registro {
  final DateTime fecha;
  final double valor;
  final String tipo;

  const _Registro({required this.fecha, required this.valor, required this.tipo});

  factory _Registro.fromMap(Map<String, dynamic> m) => _Registro(
        fecha: (m['fecha'] as Timestamp).toDate(),
        valor: (m['valor'] as num).toDouble(),
        tipo: m['tipo']?.toString() ?? 'peso',
      );
}

// ─── Main screen ──────────────────────────────────────────────────────────────

class EjercicioDetalleScreen extends StatefulWidget {
  final Map<String, dynamic> ejercicio;

  const EjercicioDetalleScreen({super.key, required this.ejercicio});

  @override
  State<EjercicioDetalleScreen> createState() => _EjercicioDetalleScreenState();
}

class _EjercicioDetalleScreenState extends State<EjercicioDetalleScreen>
    with TickerProviderStateMixin {
  late final TabController _tab;

  String get _nombre => widget.ejercicio['nombre']?.toString() ?? '';
  String get _series => widget.ejercicio['series']?.toString() ?? '';
  String get _reps => widget.ejercicio['reps']?.toString() ?? '';
  String get _descanso => widget.ejercicio['descanso']?.toString() ?? '';
  String get _tip => widget.ejercicio['tip']?.toString() ?? '';

  List<String> get _mp {
    final r = widget.ejercicio['musculos_principales'];
    return r is List ? r.map((e) => e.toString()).toList() : [];
  }

  List<String> get _ms {
    final r = widget.ejercicio['musculos_secundarios'];
    return r is List ? r.map((e) => e.toString()).toList() : [];
  }

  bool get _esTiempo {
    final r = _reps.toLowerCase();
    return r.contains('s') || r.contains('min') || r.contains('seg') ||
        (_series.isEmpty && _reps.isEmpty);
  }

  List<_Registro> _registros = [];
  bool _cargando = true;
  String _periodo = '3m';
  bool _verMejor = true;

  String? get _uid => FirebaseAuth.instance.currentUser?.uid;
  String get _key => _nombre.toLowerCase().replaceAll(RegExp(r'[^a-z0-9]'), '_');

  CollectionReference? get _col {
    final uid = _uid;
    if (uid == null) return null;
    return FirebaseFirestore.instance
        .collection('usuarios')
        .doc(uid)
        .collection('ejercicios')
        .doc(_key)
        .collection('registros');
  }

  @override
  void initState() {
    super.initState();
    _tab = TabController(length: 3, vsync: this);
    _cargarHistorial();
  }

  @override
  void dispose() {
    _tab.dispose();
    super.dispose();
  }

  Future<void> _cargarHistorial() async {
    setState(() => _cargando = true);
    try {
      final col = _col;
      if (col == null) {
        setState(() => _cargando = false);
        return;
      }
      DateTime? cutoff;
      final now = DateTime.now();
      if (_periodo == '1m') cutoff = now.subtract(const Duration(days: 30));
      if (_periodo == '3m') cutoff = now.subtract(const Duration(days: 90));
      if (_periodo == '6m') cutoff = now.subtract(const Duration(days: 180));

      Query q = col.orderBy('fecha');
      if (cutoff != null) {
        q = q.where('fecha', isGreaterThanOrEqualTo: Timestamp.fromDate(cutoff));
      }
      final snap = await q.get();
      setState(() {
        _registros = snap.docs
            .map((d) => _Registro.fromMap(d.data() as Map<String, dynamic>))
            .toList();
        _cargando = false;
      });
    } catch (_) {
      setState(() => _cargando = false);
    }
  }

  Future<void> _registrar(double valor) async {
    final col = _col;
    if (col == null) return;
    await col.add({
      'fecha': Timestamp.now(),
      'valor': valor,
      'tipo': _esTiempo ? 'tiempo' : 'peso',
    });
    await _cargarHistorial();
  }

  List<FlSpot> _spots() {
    if (_registros.isEmpty) return [];
    final Map<int, List<double>> byDay = {};
    for (final r in _registros) {
      final day =
          DateTime(r.fecha.year, r.fecha.month, r.fecha.day).millisecondsSinceEpoch ~/
              86400000;
      byDay.putIfAbsent(day, () => []).add(r.valor);
    }
    final days = byDay.keys.toList()..sort();
    final minDay = days.first.toDouble();
    return days.map((d) {
      final vals = byDay[d]!;
      final val = _verMejor
          ? vals.reduce(math.max)
          : vals.reduce((a, b) => a + b);
      return FlSpot((d - minDay).toDouble(), val);
    }).toList();
  }

  double? get _mejor =>
      _registros.isEmpty ? null : _registros.map((r) => r.valor).reduce(math.max);

  void _abrirLog() => showModalBottomSheet(
        context: context,
        isScrollControlled: true,
        backgroundColor: Colors.transparent,
        builder: (_) => _LogSheet(
          esTiempo: _esTiempo,
          nombre: _nombre,
          onGuardar: (val) {
            Navigator.pop(context);
            _registrar(val);
          },
        ),
      );

  @override
  Widget build(BuildContext context) {
    final spots = _spots();
    return Scaffold(
      backgroundColor: _kBg,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        surfaceTintColor: Colors.transparent,
        iconTheme: const IconThemeData(color: _kInk),
        title: Text(
          _nombre,
          style: GoogleFonts.outfit(
            fontSize: 18,
            fontWeight: FontWeight.w700,
            color: _kInk,
          ),
        ),
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.play_circle_outline_rounded, color: _kAccent),
            tooltip: 'Tutorial YouTube',
            onPressed: () => Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => YoutubeSearchScreen(initialQuery: _nombre),
              ),
            ),
          ),
        ],
        bottom: TabBar(
          controller: _tab,
          labelColor: _kAccent,
          unselectedLabelColor: const Color(0xFF9E9E9E),
          indicatorColor: _kAccent,
          indicatorWeight: 2.5,
          labelStyle:
              GoogleFonts.outfit(fontSize: 13, fontWeight: FontWeight.w600),
          unselectedLabelStyle: GoogleFonts.outfit(fontSize: 13),
          tabs: const [
            Tab(text: 'Resumen'),
            Tab(text: 'Historial'),
            Tab(text: 'Cómo hacerlo'),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _abrirLog,
        backgroundColor: _kAccent,
        elevation: 2,
        icon: const Icon(Icons.add_rounded, color: Colors.white),
        label: Text(
          'Registrar sesión',
          style: GoogleFonts.outfit(fontWeight: FontWeight.w600, color: Colors.white),
        ),
      ),
      body: TabBarView(
        controller: _tab,
        children: [
          _ResumenTab(
            series: _series,
            reps: _reps,
            descanso: _descanso,
            mp: _mp,
            ms: _ms,
          ),
          _HistorialTab(
            registros: _registros,
            cargando: _cargando,
            periodo: _periodo,
            verMejor: _verMejor,
            esTiempo: _esTiempo,
            spots: spots,
            mejor: _mejor,
            onPeriodo: (p) {
              setState(() => _periodo = p);
              _cargarHistorial();
            },
            onVerMejor: (v) => setState(() => _verMejor = v),
          ),
          _ComoHacerloTab(tip: _tip, nombre: _nombre),
        ],
      ),
    );
  }
}

// ─── Tab 1: Resumen ───────────────────────────────────────────────────────────

class _ResumenTab extends StatelessWidget {
  final String series;
  final String reps;
  final String descanso;
  final List<String> mp;
  final List<String> ms;

  const _ResumenTab({
    required this.series,
    required this.reps,
    required this.descanso,
    required this.mp,
    required this.ms,
  });

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 120),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Body diagram card (dark)
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: _kInk,
              borderRadius: BorderRadius.circular(22),
              boxShadow: [
                BoxShadow(
                  color: _kInk.withOpacity(0.22),
                  blurRadius: 22,
                  offset: const Offset(0, 8),
                ),
              ],
            ),
            child: _BodyDiagram(mp: mp, ms: ms),
          ),

          const SizedBox(height: 18),

          // Primary muscles label
          if (mp.isNotEmpty)
            Text(
              'Principal: ${mp.map(_labelMus).join(', ')}',
              style: GoogleFonts.outfit(
                fontSize: 13,
                color: _kAccent,
                fontWeight: FontWeight.w600,
              ),
            ),
          if (ms.isNotEmpty) ...[
            const SizedBox(height: 2),
            Text(
              'Secundario: ${ms.map(_labelMus).join(', ')}',
              style: GoogleFonts.outfit(
                  fontSize: 12, color: const Color(0xFFAAAAAA)),
            ),
          ],

          const SizedBox(height: 18),

          // Stats card
          if (series.isNotEmpty || reps.isNotEmpty || descanso.isNotEmpty)
            Container(
              padding:
                  const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: const Color(0xFFEEEEEE)),
              ),
              child: Row(
                children: [
                  if (series.isNotEmpty && reps.isNotEmpty) ...[
                    _StatCell(label: 'Series × Reps', value: '$series × $reps'),
                    Container(
                        width: 1,
                        height: 36,
                        color: const Color(0xFFEEEEEE),
                        margin: const EdgeInsets.symmetric(horizontal: 16)),
                  ],
                  if (descanso.isNotEmpty)
                    _StatCell(label: 'Descanso', value: descanso),
                ],
              ),
            ),

          const SizedBox(height: 14),

          // Muscle chips
          if (mp.isNotEmpty || ms.isNotEmpty) ...[
            Row(children: [
              _Dot(color: _kAccent),
              const SizedBox(width: 5),
              Text('Principal',
                  style: GoogleFonts.outfit(
                      fontSize: 11, color: const Color(0xFFAAAAAA))),
              const SizedBox(width: 12),
              _Dot(color: _kSecondary),
              const SizedBox(width: 5),
              Text('Secundario',
                  style: GoogleFonts.outfit(
                      fontSize: 11, color: const Color(0xFFAAAAAA))),
            ]),
            const SizedBox(height: 8),
            Wrap(
              spacing: 6,
              runSpacing: 6,
              children: [
                ...mp.map((m) => _Chip(label: _labelMus(m), color: _kAccent)),
                ...ms.map((m) => _Chip(label: _labelMus(m), color: _kSecondary)),
              ],
            ),
          ],
        ],
      ),
    );
  }
}

// ─── Body diagram widget (front/back toggle + painter) ────────────────────────

class _BodyDiagram extends StatefulWidget {
  final List<String> mp;
  final List<String> ms;
  const _BodyDiagram({required this.mp, required this.ms});

  @override
  State<_BodyDiagram> createState() => _BodyDiagramState();
}

class _BodyDiagramState extends State<_BodyDiagram> {
  bool _frente = true;

  Color _color(String m) {
    final lower = m.toLowerCase();
    if (widget.mp.map((e) => e.toLowerCase()).contains(lower)) return _kAccent;
    if (widget.ms.map((e) => e.toLowerCase()).contains(lower)) return _kSecondary;
    return _kInactive;
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // Toggle
        Container(
          height: 36,
          decoration: BoxDecoration(
            color: const Color(0xFF1E1E3A),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Row(
            children: [
              Expanded(
                  child: _TogBtn(
                      label: 'Frontal',
                      active: _frente,
                      onTap: () => setState(() => _frente = true))),
              Expanded(
                  child: _TogBtn(
                      label: 'Posterior',
                      active: !_frente,
                      onTap: () => setState(() => _frente = false))),
            ],
          ),
        ),
        const SizedBox(height: 12),
        AnimatedSwitcher(
          duration: const Duration(milliseconds: 250),
          transitionBuilder: (child, anim) => FadeTransition(
            opacity: anim,
            child: ScaleTransition(
                scale: Tween(begin: 0.97, end: 1.0).animate(anim),
                child: child),
          ),
          child: CustomPaint(
            key: ValueKey(_frente),
            size: const Size(160, 300),
            painter: _BodyPainter(frente: _frente, colorMusculo: _color),
          ),
        ),
      ],
    );
  }
}

class _TogBtn extends StatelessWidget {
  final String label;
  final bool active;
  final VoidCallback onTap;
  const _TogBtn({required this.label, required this.active, required this.onTap});

  @override
  Widget build(BuildContext context) => GestureDetector(
        onTap: onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          margin: const EdgeInsets.all(3),
          decoration: BoxDecoration(
            color: active ? _kAccent : Colors.transparent,
            borderRadius: BorderRadius.circular(8),
          ),
          child: Center(
            child: Text(label,
                style: GoogleFonts.outfit(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: active ? Colors.white : Colors.white38,
                )),
          ),
        ),
      );
}

// ─── Tab 2: Historial ─────────────────────────────────────────────────────────

class _HistorialTab extends StatelessWidget {
  final List<_Registro> registros;
  final bool cargando;
  final String periodo;
  final bool verMejor;
  final bool esTiempo;
  final List<FlSpot> spots;
  final double? mejor;
  final ValueChanged<String> onPeriodo;
  final ValueChanged<bool> onVerMejor;

  const _HistorialTab({
    required this.registros,
    required this.cargando,
    required this.periodo,
    required this.verMejor,
    required this.esTiempo,
    required this.spots,
    required this.mejor,
    required this.onPeriodo,
    required this.onVerMejor,
  });

  String _fmt(double v) {
    if (esTiempo) {
      final s = v.toInt();
      if (s >= 60) {
        final m = s ~/ 60;
        final sec = s % 60;
        return sec == 0 ? '${m}min' : '${m}min ${sec}s';
      }
      return '${s}s';
    }
    return '${v.toStringAsFixed(1)}kg';
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 120),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header row
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                mejor != null
                    ? (verMejor
                        ? 'Mejor: ${_fmt(mejor!)}'
                        : 'Sesiones: ${registros.length}')
                    : 'Sin registros',
                style: GoogleFonts.outfit(
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                    color: _kInk),
              ),
              _PeriodoPicker(valor: periodo, onChanged: onPeriodo),
            ],
          ),

          const SizedBox(height: 12),

          // Chart or states
          if (cargando)
            const SizedBox(
              height: 200,
              child: Center(
                  child: CircularProgressIndicator(
                      color: _kAccent, strokeWidth: 2)),
            )
          else if (spots.isEmpty)
            _EmptyChart()
          else
            _LineChartCard(
                spots: spots, esTiempo: esTiempo, registros: registros),

          const SizedBox(height: 12),

          // Toggle best / total
          Container(
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: const Color(0xFFEEEEEE)),
            ),
            child: Row(
              children: [
                Expanded(
                    child: _ToggleChip(
                        label:
                            esTiempo ? 'Mejor tiempo' : 'Mayor peso',
                        active: verMejor,
                        onTap: () => onVerMejor(true))),
                Expanded(
                    child: _ToggleChip(
                        label:
                            esTiempo ? 'Tiempo total' : 'Volumen total',
                        active: !verMejor,
                        onTap: () => onVerMejor(false))),
              ],
            ),
          ),

          const SizedBox(height: 20),

          // Personal records
          if (mejor != null) ...[
            Row(children: [
              Container(
                width: 32,
                height: 32,
                decoration: const BoxDecoration(
                  color: Color(0xFFFFF3E0),
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.emoji_events_rounded,
                    color: Color(0xFFFF9E00), size: 18),
              ),
              const SizedBox(width: 10),
              Text('Récords personales',
                  style: GoogleFonts.outfit(
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                      color: _kInk)),
            ]),
            const SizedBox(height: 10),
            Container(
              padding:
                  const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: const Color(0xFFEEEEEE)),
              ),
              child: Column(
                children: [
                  _RecordRow(
                    label:
                        esTiempo ? 'Mejor tiempo' : 'Mayor peso registrado',
                    value: _fmt(mejor!),
                    color: _kAccent,
                  ),
                  const Divider(height: 16, color: Color(0xFFF0F0F0)),
                  _RecordRow(
                    label: 'Total de sesiones',
                    value: '${registros.length}',
                    color: const Color(0xFF9E9E9E),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _EmptyChart extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      height: 200,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFEEEEEE)),
      ),
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.bar_chart_rounded,
                size: 44, color: Color(0xFFDDDDDD)),
            const SizedBox(height: 8),
            Text('Sin registros todavía',
                style: GoogleFonts.outfit(
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                    color: const Color(0xFF9E9E9E))),
            Text('Toca "Registrar sesión" para empezar',
                style: GoogleFonts.outfit(
                    fontSize: 12, color: const Color(0xFFBBBBBB))),
          ],
        ),
      ),
    );
  }
}

class _LineChartCard extends StatelessWidget {
  final List<FlSpot> spots;
  final bool esTiempo;
  final List<_Registro> registros;

  const _LineChartCard(
      {required this.spots,
      required this.esTiempo,
      required this.registros});

  String _yLabel(double v) =>
      esTiempo ? '${v.toInt()}s' : '${v.toInt()}kg';

  String _xLabel(double x) {
    if (registros.isEmpty) return '';
    final sorted = [...registros]..sort((a, b) => a.fecha.compareTo(b.fecha));
    final first = sorted.first.fecha;
    final minDay =
        DateTime(first.year, first.month, first.day).millisecondsSinceEpoch ~/
            86400000;
    final date = DateTime.fromMillisecondsSinceEpoch(
        (minDay + x.toInt()) * 86400000);
    const m = [
      'Ene','Feb','Mar','Abr','May','Jun',
      'Jul','Ago','Sep','Oct','Nov','Dic'
    ];
    return '${m[date.month - 1]} ${date.day}';
  }

  @override
  Widget build(BuildContext context) {
    final minY = spots.map((s) => s.y).reduce(math.min);
    final maxY = spots.map((s) => s.y).reduce(math.max);
    final pad = (maxY - minY) < 1 ? 10.0 : (maxY - minY) * 0.25;

    return Container(
      height: 230,
      padding: const EdgeInsets.fromLTRB(4, 16, 16, 8),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFEEEEEE)),
      ),
      child: LineChart(
        LineChartData(
          lineBarsData: [
            LineChartBarData(
              spots: spots,
              isCurved: true,
              curveSmoothness: 0.35,
              color: _kAccent,
              barWidth: 2.5,
              isStrokeCapRound: true,
              dotData: FlDotData(
                show: true,
                getDotPainter: (spot, pct, bar, idx) => FlDotCirclePainter(
                  radius: 4,
                  color: Colors.white,
                  strokeWidth: 2,
                  strokeColor: _kAccent,
                ),
              ),
              belowBarData: BarAreaData(
                show: true,
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    _kAccent.withOpacity(0.15),
                    _kAccent.withOpacity(0.0)
                  ],
                ),
              ),
            ),
          ],
          titlesData: FlTitlesData(
            leftTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                reservedSize: 44,
                getTitlesWidget: (val, meta) => Text(
                  _yLabel(val),
                  style: GoogleFonts.outfit(
                      fontSize: 10, color: const Color(0xFFAAAAAA)),
                ),
              ),
            ),
            bottomTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                reservedSize: 28,
                getTitlesWidget: (val, meta) {
                  final isFirst = (val - spots.first.x).abs() < 0.5;
                  final isLast = (val - spots.last.x).abs() < 0.5;
                  final mid = spots[spots.length ~/ 2];
                  final isMid = (val - mid.x).abs() < 0.5;
                  if (!isFirst && !isLast && !isMid) {
                    return const SizedBox.shrink();
                  }
                  return Padding(
                    padding: const EdgeInsets.only(top: 6),
                    child: Text(
                      _xLabel(val),
                      style: GoogleFonts.outfit(
                          fontSize: 9, color: const Color(0xFFAAAAAA)),
                    ),
                  );
                },
              ),
            ),
            topTitles: const AxisTitles(
                sideTitles: SideTitles(showTitles: false)),
            rightTitles: const AxisTitles(
                sideTitles: SideTitles(showTitles: false)),
          ),
          gridData: FlGridData(
            show: true,
            drawVerticalLine: false,
            getDrawingHorizontalLine: (_) => FlLine(
              color: Colors.black.withOpacity(0.05),
              strokeWidth: 1,
              dashArray: [4, 4],
            ),
          ),
          borderData: FlBorderData(show: false),
          minY: (minY - pad).clamp(0, double.infinity),
          maxY: maxY + pad,
        ),
      ),
    );
  }
}

// ─── Tab 3: Cómo hacerlo ─────────────────────────────────────────────────────

class _ComoHacerloTab extends StatelessWidget {
  final String tip;
  final String nombre;
  const _ComoHacerloTab({required this.tip, required this.nombre});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (tip.isNotEmpty)
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: _kAccent.withOpacity(0.06),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: _kAccent.withOpacity(0.2)),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Icon(Icons.tips_and_updates_outlined,
                      color: _kAccent, size: 20),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      tip,
                      style: GoogleFonts.outfit(
                          fontSize: 14, color: _kInk, height: 1.5),
                    ),
                  ),
                ],
              ),
            )
          else
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: const Color(0xFFEEEEEE)),
              ),
              child: Text(
                'No hay instrucciones específicas para este ejercicio.',
                style: GoogleFonts.outfit(
                    fontSize: 14, color: const Color(0xFF9E9E9E)),
              ),
            ),

          const SizedBox(height: 16),

          // YouTube button
          GestureDetector(
            onTap: () => Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => YoutubeSearchScreen(initialQuery: nombre),
              ),
            ),
            child: Container(
              padding:
                  const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: const Color(0xFFEEEEEE)),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.04),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Row(
                children: [
                  Container(
                    width: 44,
                    height: 44,
                    decoration: const BoxDecoration(
                      color: Color(0x1AFF0000),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(Icons.play_circle_filled_rounded,
                        color: Color(0xFFFF0000), size: 26),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Ver tutorial en YouTube',
                            style: GoogleFonts.outfit(
                                fontSize: 15,
                                fontWeight: FontWeight.w700,
                                color: _kInk)),
                        Text('Buscar videos de "$nombre"',
                            style: GoogleFonts.outfit(
                                fontSize: 12,
                                color: const Color(0xFF9E9E9E))),
                      ],
                    ),
                  ),
                  const Icon(Icons.arrow_forward_ios_rounded,
                      size: 14, color: Color(0xFFCCCCCC)),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Log bottom sheet ─────────────────────────────────────────────────────────

class _LogSheet extends StatefulWidget {
  final bool esTiempo;
  final String nombre;
  final ValueChanged<double> onGuardar;

  const _LogSheet(
      {required this.esTiempo,
      required this.nombre,
      required this.onGuardar});

  @override
  State<_LogSheet> createState() => _LogSheetState();
}

class _LogSheetState extends State<_LogSheet> {
  bool _running = false;
  int _seg = 0;
  Timer? _timer;
  final _ctrl = TextEditingController();

  @override
  void dispose() {
    _timer?.cancel();
    _ctrl.dispose();
    super.dispose();
  }

  void _toggle() {
    if (_running) {
      _timer?.cancel();
    } else {
      _timer =
          Timer.periodic(const Duration(seconds: 1), (_) => setState(() => _seg++));
    }
    setState(() => _running = !_running);
  }

  String _fmt(int s) {
    final m = s ~/ 60;
    final sec = s % 60;
    return m == 0 ? '${sec}s' : '${m}min ${sec.toString().padLeft(2, '0')}s';
  }

  void _save() {
    if (widget.esTiempo) {
      if (_seg == 0) return;
      widget.onGuardar(_seg.toDouble());
    } else {
      final v = double.tryParse(_ctrl.text.replaceAll(',', '.'));
      if (v == null || v <= 0) return;
      widget.onGuardar(v);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(
          bottom: MediaQuery.of(context).viewInsets.bottom),
      child: Container(
        margin: const EdgeInsets.fromLTRB(12, 0, 12, 16),
        padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(24),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.12),
              blurRadius: 30,
              offset: const Offset(0, -2),
            )
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 36,
                height: 4,
                decoration: BoxDecoration(
                  color: const Color(0xFFDDDDDD),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: 16),
            Text('Registrar sesión',
                style: GoogleFonts.outfit(
                    fontSize: 18,
                    fontWeight: FontWeight.w800,
                    color: _kInk)),
            Text(widget.nombre,
                style: GoogleFonts.outfit(
                    fontSize: 13, color: const Color(0xFF9E9E9E))),
            const SizedBox(height: 24),

            if (widget.esTiempo) ...[
              Center(
                child: Text(
                  _fmt(_seg),
                  style: GoogleFonts.outfit(
                    fontSize: 52,
                    fontWeight: FontWeight.w800,
                    color: _running ? _kAccent : _kInk,
                    letterSpacing: -1,
                  ),
                ),
              ),
              const SizedBox(height: 16),
              Center(
                child: GestureDetector(
                  onTap: _toggle,
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    padding: const EdgeInsets.symmetric(
                        horizontal: 36, vertical: 14),
                    decoration: BoxDecoration(
                      color: _running ? Colors.white : _kInk,
                      borderRadius: BorderRadius.circular(50),
                      border: _running
                          ? Border.all(color: _kAccent, width: 2)
                          : null,
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          _running
                              ? Icons.stop_rounded
                              : Icons.play_arrow_rounded,
                          color: _running ? _kAccent : Colors.white,
                          size: 22,
                        ),
                        const SizedBox(width: 8),
                        Text(
                          _running
                              ? 'Detener'
                              : (_seg > 0 ? 'Reanudar' : 'Iniciar'),
                          style: GoogleFonts.outfit(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                            color: _running ? _kAccent : Colors.white,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ] else ...[
              Text('Peso utilizado',
                  style: GoogleFonts.outfit(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: const Color(0xFF6B7280))),
              const SizedBox(height: 8),
              TextField(
                controller: _ctrl,
                keyboardType:
                    const TextInputType.numberWithOptions(decimal: true),
                autofocus: true,
                style: GoogleFonts.outfit(
                    fontSize: 22,
                    fontWeight: FontWeight.w700,
                    color: _kInk),
                decoration: InputDecoration(
                  hintText: '80.0',
                  hintStyle: GoogleFonts.outfit(
                      color: const Color(0xFFDDDDDD),
                      fontWeight: FontWeight.w400),
                  suffixText: 'kg',
                  suffixStyle: GoogleFonts.outfit(
                      fontSize: 16, color: const Color(0xFF9E9E9E)),
                  filled: true,
                  fillColor: _kBg,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide.none,
                  ),
                  contentPadding: const EdgeInsets.symmetric(
                      horizontal: 16, vertical: 14),
                ),
              ),
            ],

            const SizedBox(height: 20),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _save,
                style: ElevatedButton.styleFrom(
                  backgroundColor: _kAccent,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14)),
                  elevation: 0,
                ),
                child: Text('Guardar registro',
                    style: GoogleFonts.outfit(
                        fontSize: 16, fontWeight: FontWeight.w700)),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─── Small helpers ────────────────────────────────────────────────────────────

class _StatCell extends StatelessWidget {
  final String label;
  final String value;
  const _StatCell({required this.label, required this.value});

  @override
  Widget build(BuildContext context) => Expanded(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(label,
                style: GoogleFonts.outfit(
                    fontSize: 11, color: const Color(0xFF9E9E9E))),
            Text(value,
                style: GoogleFonts.outfit(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    color: _kInk)),
          ],
        ),
      );
}

class _Dot extends StatelessWidget {
  final Color color;
  const _Dot({required this.color});
  @override
  Widget build(BuildContext context) => Container(
      width: 10,
      height: 10,
      decoration: BoxDecoration(color: color, shape: BoxShape.circle));
}

class _Chip extends StatelessWidget {
  final String label;
  final Color color;
  const _Chip({required this.label, required this.color});

  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
        decoration: BoxDecoration(
          color: color.withOpacity(0.1),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: color.withOpacity(0.35), width: 0.8),
        ),
        child: Text(label,
            style: GoogleFonts.outfit(
                fontSize: 11,
                fontWeight: FontWeight.w600,
                color: color)),
      );
}

class _PeriodoPicker extends StatelessWidget {
  final String valor;
  final ValueChanged<String> onChanged;
  const _PeriodoPicker({required this.valor, required this.onChanged});

  String _label(String v) => switch (v) {
        '1m' => 'Último mes',
        '3m' => 'Últimos 3 meses',
        '6m' => 'Últimos 6 meses',
        _ => 'Todo el tiempo',
      };

  @override
  Widget build(BuildContext context) => PopupMenuButton<String>(
        onSelected: onChanged,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        itemBuilder: (_) => [
          PopupMenuItem(
              value: '1m',
              child: Text('Último mes', style: GoogleFonts.outfit())),
          PopupMenuItem(
              value: '3m',
              child: Text('Últimos 3 meses', style: GoogleFonts.outfit())),
          PopupMenuItem(
              value: '6m',
              child: Text('Últimos 6 meses', style: GoogleFonts.outfit())),
          PopupMenuItem(
              value: 'all',
              child: Text('Todo el tiempo', style: GoogleFonts.outfit())),
        ],
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: const Color(0xFFEEEEEE)),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(_label(valor),
                  style: GoogleFonts.outfit(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: _kAccent)),
              const SizedBox(width: 4),
              const Icon(Icons.keyboard_arrow_down_rounded,
                  size: 16, color: _kAccent),
            ],
          ),
        ),
      );
}

class _ToggleChip extends StatelessWidget {
  final String label;
  final bool active;
  final VoidCallback onTap;
  const _ToggleChip(
      {required this.label, required this.active, required this.onTap});

  @override
  Widget build(BuildContext context) => GestureDetector(
        onTap: onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          margin: const EdgeInsets.all(4),
          padding: const EdgeInsets.symmetric(vertical: 10),
          decoration: BoxDecoration(
            color: active ? _kInk : Colors.transparent,
            borderRadius: BorderRadius.circular(10),
          ),
          child: Center(
            child: Text(label,
                style: GoogleFonts.outfit(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color:
                      active ? Colors.white : const Color(0xFF9E9E9E),
                )),
          ),
        ),
      );
}

class _RecordRow extends StatelessWidget {
  final String label;
  final String value;
  final Color color;
  const _RecordRow(
      {required this.label, required this.value, required this.color});

  @override
  Widget build(BuildContext context) => Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label,
              style: GoogleFonts.outfit(fontSize: 14, color: _kInk)),
          Text(value,
              style: GoogleFonts.outfit(
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                  color: color)),
        ],
      );
}

String _labelMus(String m) {
  const map = {
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
  return map[m.toLowerCase()] ?? m;
}

// ─── Body CustomPainter (inline, matches anatomia.dart logic) ─────────────────

class _BodyPainter extends CustomPainter {
  final bool frente;
  final Color Function(String) colorMusculo;

  const _BodyPainter({required this.frente, required this.colorMusculo});

  @override
  void paint(Canvas canvas, Size size) {
    canvas.scale(size.width / 190, size.height / 400);
    _silhouette(canvas);
    if (frente) {
      _drawFrente(canvas);
    } else {
      _drawEspalda(canvas);
    }
  }

  void _silhouette(Canvas canvas) {
    final p = Paint()
      ..color = const Color(0xFF1E1E3A)
      ..style = PaintingStyle.fill;
    canvas.drawCircle(const Offset(95, 24), 21, p);
    canvas.drawRRect(
        RRect.fromRectAndRadius(
            const Rect.fromLTWH(84, 44, 22, 18), const Radius.circular(4)),
        p);
    canvas.drawRRect(
        RRect.fromRectAndRadius(
            const Rect.fromLTWH(58, 62, 74, 126), const Radius.circular(14)),
        p);
    canvas.drawRRect(
        RRect.fromRectAndRadius(
            const Rect.fromLTWH(30, 64, 27, 98), const Radius.circular(12)),
        p);
    canvas.drawRRect(
        RRect.fromRectAndRadius(
            const Rect.fromLTWH(133, 64, 27, 98), const Radius.circular(12)),
        p);
    canvas.drawRRect(
        RRect.fromRectAndRadius(
            const Rect.fromLTWH(58, 188, 74, 26), const Radius.circular(10)),
        p);
    canvas.drawRRect(
        RRect.fromRectAndRadius(
            const Rect.fromLTWH(60, 212, 32, 166), const Radius.circular(14)),
        p);
    canvas.drawRRect(
        RRect.fromRectAndRadius(
            const Rect.fromLTWH(98, 212, 32, 166), const Radius.circular(14)),
        p);
    final outline = Paint()
      ..color = const Color(0xFF34345C)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.2;
    canvas.drawCircle(const Offset(95, 24), 21, outline);
    final eye = Paint()
      ..color = const Color(0xFF34345C)
      ..style = PaintingStyle.fill;
    canvas.drawCircle(const Offset(89, 20), 2.2, eye);
    canvas.drawCircle(const Offset(101, 20), 2.2, eye);
  }

  void _drawFrente(Canvas canvas) {
    _paint(canvas, 'deltoides_anterior', _oval(43, 74, 19, 15));
    _paint(canvas, 'deltoides_lateral', _oval(43, 74, 19, 15));
    _paint(canvas, 'deltoides', _oval(43, 74, 19, 15));
    _paint(canvas, 'deltoides_anterior', _oval(147, 74, 19, 15));
    _paint(canvas, 'deltoides_lateral', _oval(147, 74, 19, 15));
    _paint(canvas, 'deltoides', _oval(147, 74, 19, 15));
    _paint(canvas, 'pecho', _rrect(62, 70, 30, 46, 8));
    _paint(canvas, 'pecho', _rrect(98, 70, 30, 46, 8));
    _paint(canvas, 'biceps', _rrect(33, 96, 22, 46, 9));
    _paint(canvas, 'biceps', _rrect(135, 96, 22, 46, 9));
    _paint(canvas, 'antebrazos', _rrect(31, 146, 18, 40, 7));
    _paint(canvas, 'antebrazos', _rrect(141, 146, 18, 40, 7));
    for (int row = 0; row < 3; row++) {
      final y = 120.0 + row * 18;
      _paint(canvas, 'abdominales', _rrect(79, y, 13, 14, 4));
      _paint(canvas, 'abdominales', _rrect(98, y, 13, 14, 4));
      _paint(canvas, 'core', _rrect(79, y, 13, 14, 4));
      _paint(canvas, 'core', _rrect(98, y, 13, 14, 4));
    }
    _paint(canvas, 'oblicuos', _rrect(63, 124, 14, 46, 6));
    _paint(canvas, 'oblicuos', _rrect(113, 124, 14, 46, 6));
    _paint(canvas, 'cuadriceps', _rrect(61, 216, 30, 68, 12));
    _paint(canvas, 'cuadriceps', _rrect(99, 216, 30, 68, 12));
    _paint(canvas, 'aductores', _rrect(78, 216, 14, 54, 7));
    _paint(canvas, 'aductores', _rrect(98, 216, 14, 54, 7));
    _paint(canvas, 'pantorrillas', _rrect(63, 290, 24, 60, 10));
    _paint(canvas, 'pantorrillas', _rrect(103, 290, 24, 60, 10));
    _paint(canvas, 'gemelos', _rrect(63, 290, 24, 60, 10));
    _paint(canvas, 'gemelos', _rrect(103, 290, 24, 60, 10));
  }

  void _drawEspalda(Canvas canvas) {
    _paint(canvas, 'trapecio', _trapecio());
    _paint(canvas, 'deltoides_posterior', _oval(43, 78, 19, 15));
    _paint(canvas, 'deltoides', _oval(43, 78, 19, 15));
    _paint(canvas, 'deltoides_posterior', _oval(147, 78, 19, 15));
    _paint(canvas, 'deltoides', _oval(147, 78, 19, 15));
    _paint(canvas, 'romboides', _rrect(74, 106, 42, 40, 6));
    _paint(canvas, 'dorsales', _dorsales(left: true));
    _paint(canvas, 'dorsales', _dorsales(left: false));
    _paint(canvas, 'triceps', _rrect(33, 96, 22, 52, 9));
    _paint(canvas, 'triceps', _rrect(135, 96, 22, 52, 9));
    _paint(canvas, 'antebrazos', _rrect(31, 152, 18, 40, 7));
    _paint(canvas, 'antebrazos', _rrect(141, 152, 18, 40, 7));
    _paint(canvas, 'lumbares', _rrect(77, 162, 36, 32, 7));
    _paint(canvas, 'gluteos', _oval(79, 202, 25, 28));
    _paint(canvas, 'gluteos', _oval(111, 202, 25, 28));
    _paint(canvas, 'isquiotibiales', _rrect(61, 228, 30, 62, 12));
    _paint(canvas, 'isquiotibiales', _rrect(99, 228, 30, 62, 12));
    _paint(canvas, 'pantorrillas', _rrect(64, 296, 24, 56, 10));
    _paint(canvas, 'pantorrillas', _rrect(102, 296, 24, 56, 10));
    _paint(canvas, 'gemelos', _rrect(64, 296, 24, 56, 10));
    _paint(canvas, 'gemelos', _rrect(102, 296, 24, 56, 10));
  }

  Path _oval(double cx, double cy, double rx, double ry) => Path()
    ..addOval(Rect.fromCenter(
        center: Offset(cx, cy), width: rx * 2, height: ry * 2));

  Path _rrect(double x, double y, double w, double h, double r) => Path()
    ..addRRect(RRect.fromRectAndRadius(
        Rect.fromLTWH(x, y, w, h), Radius.circular(r)));

  Path _trapecio() => Path()
    ..moveTo(95, 63)
    ..lineTo(136, 70)
    ..lineTo(130, 106)
    ..lineTo(95, 114)
    ..lineTo(60, 106)
    ..lineTo(54, 70)
    ..close();

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

  void _paint(Canvas canvas, String musculo, Path path) {
    final color = colorMusculo(musculo);
    canvas.drawPath(path,
        Paint()
          ..color = color
          ..style = PaintingStyle.fill);
    if (color != _kInactive) {
      canvas.drawPath(
          path,
          Paint()
            ..color = color.withOpacity(0.35)
            ..style = PaintingStyle.stroke
            ..strokeWidth = 4
            ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 6));
    }
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
