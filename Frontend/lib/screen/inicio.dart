import 'dart:async';
import 'package:flutter/material.dart';
import 'package:percent_indicator/percent_indicator.dart';
import 'package:google_fonts/google_fonts.dart';
import '../services/api_service.dart';
import '../widget/navbar.dart';
import 'ejercicios.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'login.dart';

// ── Paleta ────────────────────────────────────────────────────────────────────
const _kAccent = Color(0xFFFF6D00);
const _kInk = Color(0xFF1A1A2E);
const _kBg = Color(0xFFF5F5F7);
const _kMuted = Color(0xFF6B7280);

// ── Screen ────────────────────────────────────────────────────────────────────
class InicioScreen extends StatefulWidget {
  const InicioScreen({super.key});

  @override
  State<InicioScreen> createState() => _InicioScreenState();
}

class _InicioScreenState extends State<InicioScreen>
    with SingleTickerProviderStateMixin {
  List<dynamic> ejercicios = [];
  bool loading = true;
  late final AnimationController _staggerCtrl;

  @override
  void initState() {
    super.initState();
    _staggerCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    );
    verificarPerfilUsuario();
    cargarEjercicios();
  }

  @override
  void dispose() {
    _staggerCtrl.dispose();
    super.dispose();
  }

  // ── Firestore helpers ──────────────────────────────────────────────────────

  Future<void> _guardarProgresoDia(String dia, double progreso) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;
    try {
      await FirebaseFirestore.instance
          .collection("usuarios")
          .doc(user.uid)
          .set({"progreso": {dia: progreso}}, SetOptions(merge: true));
    } catch (e) {
      debugPrint("Error guardando progreso de $dia: $e");
    }
  }

  // ── Lógica de filtrado (sin cambios) ──────────────────────────────────────

  List<dynamic> _filtrarRutinas(
    Map<String, dynamic> data,
    String objetivo,
    int edad,
    double peso,
    String nivel,
  ) {
    if (!data.containsKey(objetivo)) return [];
    final objetivoData = data[objetivo];

    String? rangoEdad;
    for (var key in objetivoData.keys) {
      final partes = key.replaceAll("+", "-200").split("-");
      final min = int.parse(partes[0]);
      final max = int.parse(partes[1]);
      if (edad >= min && edad <= max) {
        rangoEdad = key;
        break;
      }
    }
    if (rangoEdad == null) return [];

    final pesoData = objetivoData[rangoEdad];
    String? rangoPeso;
    for (var key in pesoData.keys) {
      final partes = key.replaceAll("+", "-999").split("-");
      final min = int.parse(partes[0]);
      final max = int.parse(partes[1]);
      if (peso >= min && peso <= max) {
        rangoPeso = key;
        break;
      }
    }
    if (rangoPeso == null) return [];

    final periodos = pesoData[rangoPeso];
    if (periodos.containsKey(nivel)) return periodos[nivel];
    return [];
  }

  String _determinarNivel(Map<String, dynamic> data) {
    try {
      if (data["fechaRegistro"] == null) return "base";
      final fecha = DateTime.parse(data["fechaRegistro"]);
      final meses = DateTime.now().difference(fecha).inDays ~/ 30;
      if (meses < 4) return "base";
      if (meses < 7) return "intermedio";
      return "avanzado";
    } catch (_) {
      return "base";
    }
  }

  // ── Carga de datos ────────────────────────────────────────────────────────

  Future<void> cargarEjercicios() async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) return;

      final doc = await FirebaseFirestore.instance
          .collection("usuarios")
          .doc(user.uid)
          .get();

      if (!doc.exists) {
        if (mounted) setState(() => loading = false);
        return;
      }

      final dataUsuario = doc.data()!;
      final nivel = _determinarNivel(dataUsuario);
      final rutinasData = await ApiService.getRutinas();

      final rutinas = _filtrarRutinas(
        rutinasData,
        (dataUsuario["objetivo"] ?? "").toString(),
        (dataUsuario["edad"] ?? 0) as int,
        (dataUsuario["peso"] is num)
            ? (dataUsuario["peso"] as num).toDouble()
            : double.tryParse("${dataUsuario["peso"]}") ?? 0.0,
        nivel,
      );

      final progresoMapRaw = dataUsuario["progreso"] ?? {};
      final Map<String, dynamic> progresoMap =
          (progresoMapRaw is Map<String, dynamic>) ? progresoMapRaw : {};

      final enriquecidas = rutinas.map<Map<String, dynamic>>((r) {
        final m = Map<String, dynamic>.from(r as Map);
        final dia = (m["dia"] ?? "").toString();
        final p = progresoMap[dia];
        m["progreso"] = (p is num) ? p.toDouble() : 0.0;
        return m;
      }).toList();

      if (!mounted) return;
      setState(() {
        ejercicios = enriquecidas;
        loading = false;
      });
      _staggerCtrl.forward(from: 0);

      if (dataUsuario["nivel"] != nivel) {
        await FirebaseFirestore.instance
            .collection("usuarios")
            .doc(user.uid)
            .update({"nivel": nivel});
      }
    } catch (e) {
      if (mounted) setState(() => loading = false);
      debugPrint("Error al cargar rutinas: $e");
    }
  }

  Future<void> verificarPerfilUsuario() async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) return;

      final docRef =
          FirebaseFirestore.instance.collection("usuarios").doc(user.uid);
      final snap = await docRef.get();
      Map<String, dynamic> data = {};

      if (snap.exists) data = snap.data() as Map<String, dynamic>;

      if (data["fechaRegistro"] == null) {
        await docRef.set(
          {"fechaRegistro": DateTime.now().toIso8601String()},
          SetOptions(merge: true),
        );
      }

      final bool incompleto = !snap.exists ||
          data["alias"] == null ||
          data["edad"] == null ||
          data["altura"] == null ||
          data["peso"] == null ||
          data["objetivo"] == null ||
          (data["objetivo"].toString().isEmpty);

      if (incompleto) {
        WidgetsBinding.instance
            .addPostFrameCallback((_) => _showQuestionnaire(context));
      }
    } catch (e) {
      debugPrint("Error verificando perfil: $e");
    }
  }

  // ── Questionnaire ─────────────────────────────────────────────────────────

  Future<void> _showQuestionnaire(BuildContext context) async {
    final aliasCtrl = TextEditingController();
    final edadCtrl = TextEditingController();
    final alturaCtrl = TextEditingController();
    final pesoCtrl = TextEditingController();
    String objetivo = "";

    await showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDialogState) => Dialog(
          backgroundColor: Colors.white,
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  'Completa tu perfil',
                  style: GoogleFonts.outfit(
                    fontSize: 22,
                    fontWeight: FontWeight.w700,
                    color: _kInk,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Lo usamos para crear tu rutina personalizada.',
                  style: GoogleFonts.outfit(
                      fontSize: 13, color: _kMuted),
                ),
                const SizedBox(height: 20),
                _QField(ctrl: aliasCtrl, label: 'Alias'),
                _QField(
                    ctrl: edadCtrl,
                    label: 'Edad',
                    type: TextInputType.number),
                _QField(
                    ctrl: alturaCtrl,
                    label: 'Altura (m)',
                    hint: '1.75',
                    type: TextInputType.number),
                _QField(
                    ctrl: pesoCtrl,
                    label: 'Peso (kg)',
                    type: TextInputType.number),
                const SizedBox(height: 20),
                Text(
                  'Objetivo',
                  style: GoogleFonts.outfit(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: _kInk,
                  ),
                ),
                const SizedBox(height: 10),
                Column(
                  children: [
                    _ObjetivoChip(
                      label: 'Fuerza',
                      icon: Icons.fitness_center_rounded,
                      selected: objetivo == 'Fuerza',
                      onTap: () =>
                          setDialogState(() => objetivo = 'Fuerza'),
                    ),
                    const SizedBox(height: 8),
                    _ObjetivoChip(
                      label: 'Resistencia',
                      icon: Icons.directions_run_rounded,
                      selected: objetivo == 'Resistencia',
                      onTap: () =>
                          setDialogState(() => objetivo = 'Resistencia'),
                    ),
                    const SizedBox(height: 8),
                    _ObjetivoChip(
                      label: 'Hipertrofia',
                      icon: Icons.show_chart_rounded,
                      selected: objetivo == 'Hipertrofia',
                      onTap: () =>
                          setDialogState(() => objetivo = 'Hipertrofia'),
                    ),
                  ],
                ),
                const SizedBox(height: 24),
                SizedBox(
                  width: double.infinity,
                  height: 52,
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: _kAccent,
                      foregroundColor: Colors.white,
                      elevation: 0,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                    ),
                    onPressed: () async {
                      final user = FirebaseAuth.instance.currentUser;
                      if (user == null) return;
                      final data = {
                        "alias": aliasCtrl.text,
                        "edad": int.tryParse(edadCtrl.text) ?? 0,
                        "altura":
                            double.tryParse(alturaCtrl.text) ?? 0.0,
                        "peso": double.tryParse(pesoCtrl.text) ?? 0.0,
                        "objetivo": objetivo.isEmpty ? 'Hipertrofia' : objetivo,
                      };
                      await FirebaseFirestore.instance
                          .collection("usuarios")
                          .doc(user.uid)
                          .set(data, SetOptions(merge: true));
                      if (ctx.mounted) Navigator.pop(ctx);
                      cargarEjercicios();
                    },
                    child: Text(
                      'Guardar perfil',
                      style: GoogleFonts.outfit(
                        fontWeight: FontWeight.w600,
                        fontSize: 15,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // ── Build ─────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;
    final alias = user?.displayName?.split(' ').first ?? 'Atleta';

    double promedio = 0;
    if (ejercicios.isNotEmpty) {
      final total = ejercicios
          .map((d) => (d["progreso"] ?? 0).toDouble())
          .reduce((a, b) => a + b);
      promedio = total / ejercicios.length;
    }

    return Scaffold(
      backgroundColor: _kBg,
      appBar: AppBar(
        backgroundColor: _kBg,
        elevation: 0,
        scrolledUnderElevation: 0,
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Hola, $alias',
              style: GoogleFonts.outfit(
                fontSize: 20,
                fontWeight: FontWeight.w700,
                color: _kInk,
              ),
            ),
            Text(
              'Tu rutina de hoy',
              style: GoogleFonts.outfit(
                fontSize: 12,
                color: _kMuted,
              ),
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout_rounded, color: _kMuted),
            onPressed: () async {
              await FirebaseAuth.instance.signOut();
              if (!mounted) return;
              Navigator.pushReplacement(
                context,
                MaterialPageRoute(builder: (_) => const LoginScreen()),
              );
            },
          ),
        ],
      ),
      body: loading
          ? _buildSkeleton()
          : ejercicios.isEmpty
              ? _buildEmpty()
              : _buildContent(promedio),
      bottomNavigationBar: const GymNavbar(currentIndex: 1),
    );
  }

  // ── Skeleton ──────────────────────────────────────────────────────────────

  Widget _buildSkeleton() {
    return ListView.builder(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
      itemCount: 5,
      itemBuilder: (_, __) => const _RutinaSkeletonCard(),
    );
  }

  // ── Empty ─────────────────────────────────────────────────────────────────

  Widget _buildEmpty() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 80,
            height: 80,
            decoration: BoxDecoration(
              color: _kAccent.withOpacity(0.08),
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.fitness_center_rounded,
                size: 38, color: _kAccent),
          ),
          const SizedBox(height: 20),
          Text(
            'Sin rutinas disponibles',
            style: GoogleFonts.outfit(
              fontSize: 17,
              fontWeight: FontWeight.w600,
              color: _kInk,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Completa tu perfil para ver tu plan',
            style: GoogleFonts.outfit(fontSize: 13, color: _kMuted),
          ),
        ],
      ),
    );
  }

  // ── Content ───────────────────────────────────────────────────────────────

  Widget _buildContent(double promedio) {
    return Column(
      children: [
        Expanded(
          child: ListView.builder(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
            itemCount: ejercicios.length,
            itemBuilder: (context, i) {
              final e = ejercicios[i];
              final progreso = (e["progreso"] ?? 0).toDouble();
              final startAt = (i * 0.08).clamp(0.0, 0.7);
              final endAt = (startAt + 0.4).clamp(0.0, 1.0);

              return AnimatedBuilder(
                animation: _staggerCtrl,
                builder: (_, child) {
                  final anim = CurvedAnimation(
                    parent: _staggerCtrl,
                    curve:
                        Interval(startAt, endAt, curve: Curves.easeOutCubic),
                  );
                  return FadeTransition(
                    opacity: anim,
                    child: SlideTransition(
                      position: Tween<Offset>(
                        begin: const Offset(0, 0.15),
                        end: Offset.zero,
                      ).animate(anim),
                      child: child,
                    ),
                  );
                },
                child: _RutinaCard(
                  rutina: e,
                  progreso: progreso,
                  onTap: () async {
                    final nuevoProgreso = await Navigator.push(
                      context,
                      MaterialPageRoute(
                          builder: (_) => RutinaScreen(rutina: e)),
                    );
                    if (nuevoProgreso != null && mounted) {
                      final dia = (e['dia'] ?? '').toString();
                      setState(() {
                        ejercicios[i]['progreso'] =
                            (nuevoProgreso as num).toDouble();
                      });
                      await _guardarProgresoDia(
                          dia, (nuevoProgreso as num).toDouble());
                    }
                  },
                ),
              );
            },
          ),
        ),
        // ── Progreso global ──────────────────────────────────────────────
        _ProgresoGlobal(promedio: promedio),
      ],
    );
  }
}

// ── Rutina Card ───────────────────────────────────────────────────────────────
class _RutinaCard extends StatefulWidget {
  final Map<String, dynamic> rutina;
  final double progreso;
  final VoidCallback onTap;

  const _RutinaCard({
    required this.rutina,
    required this.progreso,
    required this.onTap,
  });

  @override
  State<_RutinaCard> createState() => _RutinaCardState();
}

class _RutinaCardState extends State<_RutinaCard>
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
    _scale = Tween<double>(begin: 1.0, end: 0.97).animate(
      CurvedAnimation(parent: _ctrl, curve: Curves.easeOut),
    );
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final e = widget.rutina;
    final progreso = widget.progreso;

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
        child: Container(
          margin: const EdgeInsets.only(bottom: 12),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
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
              // Info
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      e['dia'] ?? '',
                      style: GoogleFonts.outfit(
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                        color: _kAccent,
                        letterSpacing: 0.5,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      e['titulo'] ?? '',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: GoogleFonts.outfit(
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                        color: _kInk,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '${(e['ejercicios'] as List?)?.length ?? 0} ejercicios',
                      style: GoogleFonts.outfit(
                        fontSize: 12,
                        color: _kMuted,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 12),
              // Progress circle
              CircularPercentIndicator(
                radius: 28.0,
                lineWidth: 5.0,
                percent: progreso.clamp(0.0, 1.0),
                center: Text(
                  '${(progreso * 100).toInt()}%',
                  style: GoogleFonts.outfit(
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    color: _kInk,
                  ),
                ),
                linearGradient: const LinearGradient(
                  colors: [_kAccent, Color(0xFFFF9E00)],
                ),
                backgroundColor: const Color(0xFFEEEEEE),
                circularStrokeCap: CircularStrokeCap.round,
              ),
              const SizedBox(width: 8),
              const Icon(Icons.chevron_right_rounded,
                  color: Color(0xFFCCCCCC), size: 20),
            ],
          ),
        ),
      ),
    );
  }
}

// ── Progreso global ───────────────────────────────────────────────────────────
class _ProgresoGlobal extends StatelessWidget {
  final double promedio;
  const _ProgresoGlobal({required this.promedio});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 0, 16, 16),
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 18),
      decoration: BoxDecoration(
        color: _kInk,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: _kInk.withOpacity(0.20),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Row(
        children: [
          CircularPercentIndicator(
            radius: 36.0,
            lineWidth: 7.0,
            percent: promedio.clamp(0.0, 1.0),
            center: Text(
              '${(promedio * 100).toInt()}%',
              style: GoogleFonts.outfit(
                fontSize: 13,
                fontWeight: FontWeight.w800,
                color: Colors.white,
              ),
            ),
            linearGradient: const LinearGradient(
              colors: [_kAccent, Color(0xFFFF9E00)],
            ),
            backgroundColor: Colors.white.withOpacity(0.15),
            circularStrokeCap: CircularStrokeCap.round,
          ),
          const SizedBox(width: 18),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Progreso semanal',
                style: GoogleFonts.outfit(
                  fontSize: 15,
                  fontWeight: FontWeight.w700,
                  color: Colors.white,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                promedio == 0
                    ? 'Empieza tu primera rutina'
                    : 'Sigue así, vas bien',
                style: GoogleFonts.outfit(
                  fontSize: 12,
                  color: Colors.white60,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

// ── Skeleton Card ─────────────────────────────────────────────────────────────
class _RutinaSkeletonCard extends StatefulWidget {
  const _RutinaSkeletonCard();

  @override
  State<_RutinaSkeletonCard> createState() => _RutinaSkeletonCardState();
}

class _RutinaSkeletonCardState extends State<_RutinaSkeletonCard>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    )..repeat();
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _ctrl,
      builder: (_, __) {
        final g = LinearGradient(
          colors: const [Color(0xFFE8E8E8), Color(0xFFF5F5F5), Color(0xFFE8E8E8)],
          stops: const [0.0, 0.5, 1.0],
          begin: Alignment(-1.5 + _ctrl.value * 3, 0),
          end: Alignment(1.5 + _ctrl.value * 3, 0),
        );
        Widget block(double h, double? w) => Container(
              height: h,
              width: w,
              decoration: BoxDecoration(
                  gradient: g, borderRadius: BorderRadius.circular(6)),
            );

        return Container(
          margin: const EdgeInsets.only(bottom: 12),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
          ),
          child: Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    block(10, 60),
                    const SizedBox(height: 8),
                    block(14, 180),
                    const SizedBox(height: 6),
                    block(10, 90),
                  ],
                ),
              ),
              const SizedBox(width: 16),
              Container(
                width: 56,
                height: 56,
                decoration: BoxDecoration(
                    gradient: g, shape: BoxShape.circle),
              ),
            ],
          ),
        );
      },
    );
  }
}

// ── Questionnaire helpers ─────────────────────────────────────────────────────

class _QField extends StatelessWidget {
  final TextEditingController ctrl;
  final String label;
  final String? hint;
  final TextInputType type;

  const _QField({
    required this.ctrl,
    required this.label,
    this.hint,
    this.type = TextInputType.text,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Column(
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
          const SizedBox(height: 6),
          TextField(
            controller: ctrl,
            keyboardType: type,
            style: GoogleFonts.outfit(fontSize: 15, color: _kInk),
            decoration: InputDecoration(
              hintText: hint,
              hintStyle: GoogleFonts.outfit(color: const Color(0xFFBBBBBB)),
              filled: true,
              fillColor: _kBg,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10),
                borderSide: BorderSide.none,
              ),
              contentPadding:
                  const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            ),
          ),
        ],
      ),
    );
  }
}

class _ObjetivoChip extends StatelessWidget {
  final String label;
  final IconData icon;
  final bool selected;
  final VoidCallback onTap;

  const _ObjetivoChip({
    required this.label,
    required this.icon,
    required this.selected,
    required this.onTap,
  });

  String get _desc => switch (label) {
        'Fuerza' => 'Potencia, carga máxima y fuerza funcional',
        'Resistencia' => 'Capacidad cardiovascular y aguante',
        _ => 'Volumen muscular y definición corporal',
      };

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        curve: Curves.easeOutCubic,
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 13),
        decoration: BoxDecoration(
          color: selected ? _kAccent : Colors.white,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: selected ? _kAccent : const Color(0xFFE5E7EB),
            width: selected ? 1.5 : 1,
          ),
          boxShadow: selected
              ? [
                  BoxShadow(
                    color: _kAccent.withOpacity(0.22),
                    blurRadius: 14,
                    offset: const Offset(0, 5),
                  ),
                ]
              : [],
        ),
        child: Row(
          children: [
            // Icon container
            AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              width: 42,
              height: 42,
              decoration: BoxDecoration(
                color: selected
                    ? Colors.white.withOpacity(0.18)
                    : _kAccent.withOpacity(0.08),
                borderRadius: BorderRadius.circular(11),
              ),
              child: Icon(
                icon,
                size: 21,
                color: selected ? Colors.white : _kAccent,
              ),
            ),

            const SizedBox(width: 13),

            // Text
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    label,
                    style: GoogleFonts.outfit(
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                      color: selected ? Colors.white : _kInk,
                    ),
                  ),
                  const SizedBox(height: 1),
                  Text(
                    _desc,
                    style: GoogleFonts.outfit(
                      fontSize: 11,
                      color: selected
                          ? Colors.white.withOpacity(0.75)
                          : _kMuted,
                      height: 1.3,
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(width: 8),

            // Check indicator
            AnimatedSwitcher(
              duration: const Duration(milliseconds: 180),
              child: selected
                  ? const Icon(
                      Icons.check_circle_rounded,
                      key: ValueKey(true),
                      color: Colors.white,
                      size: 20,
                    )
                  : Container(
                      key: const ValueKey(false),
                      width: 20,
                      height: 20,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: const Color(0xFFDDDDDD),
                          width: 1.5,
                        ),
                      ),
                    ),
            ),
          ],
        ),
      ),
    );
  }
}
