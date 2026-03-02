import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_application_1/widget/navbar.dart';

const _kAccent = Color(0xFFFF6D00);
const _kInk = Color(0xFF1A1A2E);
const _kBg = Color(0xFFF5F5F7);
const _kMuted = Color(0xFF6B7280);

class PerfilScreen extends StatefulWidget {
  const PerfilScreen({super.key});

  @override
  State<PerfilScreen> createState() => _PerfilScreenState();
}

class _PerfilScreenState extends State<PerfilScreen> {
  Map<String, dynamic>? userData;
  bool loading = true;

  @override
  void initState() {
    super.initState();
    _cargarPerfil();
  }

  Future<void> _cargarPerfil() async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) return;
      final doc = await FirebaseFirestore.instance
          .collection("usuarios")
          .doc(user.uid)
          .get();
      if (mounted) {
        setState(() {
          userData = doc.exists ? doc.data() : {};
          loading = false;
        });
      }
    } catch (e) {
      if (mounted) setState(() => loading = false);
    }
  }

  String _nivelLabel(String? nivel) {
    switch (nivel) {
      case 'intermedio':
        return 'Intermedio';
      case 'avanzado':
        return 'Avanzado';
      default:
        return 'Base';
    }
  }

  Color _nivelColor(String? nivel) {
    switch (nivel) {
      case 'intermedio':
        return const Color(0xFF3B82F6);
      case 'avanzado':
        return const Color(0xFF10B981);
      default:
        return _kAccent;
    }
  }

  IconData _objetivoIcon(String? objetivo) {
    switch (objetivo) {
      case 'Resistencia':
        return Icons.monitor_heart_outlined;
      case 'Hipertrofia':
        return Icons.trending_up_rounded;
      case 'Fuerza':
        return Icons.fitness_center_rounded;
      default:
        return Icons.flag_outlined;
    }
  }

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;

    return Scaffold(
      backgroundColor: _kBg,
      appBar: AppBar(
        backgroundColor: _kBg,
        elevation: 0,
        scrolledUnderElevation: 0,
        title: Text(
          'Perfil',
          style: GoogleFonts.outfit(
            fontSize: 22,
            fontWeight: FontWeight.w700,
            color: _kInk,
          ),
        ),
      ),
      body: loading
          ? _buildSkeleton()
          : userData == null
              ? _buildError()
              : _buildContent(user),
      bottomNavigationBar: const GymNavbar(currentIndex: 2),
    );
  }

  // ── Skeleton ──────────────────────────────────────────────────────────────

  Widget _buildSkeleton() {
    return _PerfilSkeleton();
  }

  // ── Error ─────────────────────────────────────────────────────────────────

  Widget _buildError() {
    return Center(
      child: Text(
        'No se pudo cargar el perfil',
        style: GoogleFonts.outfit(color: _kMuted),
      ),
    );
  }

  // ── Content ───────────────────────────────────────────────────────────────

  Widget _buildContent(User? user) {
    final data = userData!;
    final nivel = data['nivel']?.toString();
    final objetivo = data['objetivo']?.toString();
    final alias = data['alias']?.toString() ??
        user?.displayName ??
        'Atleta';
    final photoUrl = user?.photoURL;

    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── Header: foto + nombre + nivel ──────────────────────────────
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(20),
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
                // Avatar
                _Avatar(photoUrl: photoUrl, alias: alias),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        alias,
                        style: GoogleFonts.outfit(
                          fontSize: 20,
                          fontWeight: FontWeight.w700,
                          color: _kInk,
                        ),
                      ),
                      if (user?.email != null) ...[
                        const SizedBox(height: 2),
                        Text(
                          user!.email!,
                          style: GoogleFonts.outfit(
                            fontSize: 12,
                            color: _kMuted,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                      const SizedBox(height: 8),
                      // Nivel badge
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(
                          color: _nivelColor(nivel).withOpacity(0.10),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Text(
                          _nivelLabel(nivel),
                          style: GoogleFonts.outfit(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: _nivelColor(nivel),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 16),

          // ── Stats: edad, altura, peso ──────────────────────────────────
          Row(
            children: [
              Expanded(
                child: _StatCard(
                  icon: Icons.cake_outlined,
                  label: 'Edad',
                  value: '${data['edad'] ?? '—'}',
                  unit: 'años',
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _StatCard(
                  icon: Icons.straighten_rounded,
                  label: 'Altura',
                  value: '${data['altura'] ?? '—'}',
                  unit: 'm',
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _StatCard(
                  icon: Icons.monitor_weight_outlined,
                  label: 'Peso',
                  value: '${data['peso'] ?? '—'}',
                  unit: 'kg',
                ),
              ),
            ],
          ),

          const SizedBox(height: 16),

          // ── Objetivo ──────────────────────────────────────────────────
          Container(
            padding: const EdgeInsets.all(18),
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
                Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    color: _kAccent.withOpacity(0.10),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(
                    _objetivoIcon(objetivo),
                    color: _kAccent,
                    size: 24,
                  ),
                ),
                const SizedBox(width: 14),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Objetivo',
                      style: GoogleFonts.outfit(
                        fontSize: 12,
                        color: _kMuted,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      objetivo ?? '—',
                      style: GoogleFonts.outfit(
                        fontSize: 17,
                        fontWeight: FontWeight.w700,
                        color: _kInk,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ── Avatar ────────────────────────────────────────────────────────────────────
class _Avatar extends StatelessWidget {
  final String? photoUrl;
  final String alias;

  const _Avatar({required this.photoUrl, required this.alias});

  @override
  Widget build(BuildContext context) {
    if (photoUrl != null && photoUrl!.isNotEmpty) {
      return CircleAvatar(
        radius: 34,
        backgroundImage: NetworkImage(photoUrl!),
        backgroundColor: const Color(0xFFEEEEEE),
      );
    }
    return CircleAvatar(
      radius: 34,
      backgroundColor: _kAccent.withOpacity(0.12),
      child: Text(
        alias.isNotEmpty ? alias[0].toUpperCase() : 'A',
        style: GoogleFonts.outfit(
          fontSize: 26,
          fontWeight: FontWeight.w700,
          color: _kAccent,
        ),
      ),
    );
  }
}

// ── Stat Card ─────────────────────────────────────────────────────────────────
class _StatCard extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final String unit;

  const _StatCard({
    required this.icon,
    required this.label,
    required this.value,
    required this.unit,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 18, color: _kAccent),
          const SizedBox(height: 8),
          Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                value,
                style: GoogleFonts.outfit(
                  fontSize: 20,
                  fontWeight: FontWeight.w800,
                  color: _kInk,
                  height: 1.0,
                ),
              ),
              const SizedBox(width: 2),
              Padding(
                padding: const EdgeInsets.only(bottom: 2),
                child: Text(
                  unit,
                  style: GoogleFonts.outfit(
                    fontSize: 11,
                    color: _kMuted,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 2),
          Text(
            label,
            style: GoogleFonts.outfit(
              fontSize: 11,
              color: _kMuted,
            ),
          ),
        ],
      ),
    );
  }
}

// ── Skeleton ──────────────────────────────────────────────────────────────────
class _PerfilSkeleton extends StatefulWidget {
  @override
  State<_PerfilSkeleton> createState() => _PerfilSkeletonState();
}

class _PerfilSkeletonState extends State<_PerfilSkeleton>
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
        final v = _ctrl.value;
        final g = LinearGradient(
          colors: const [Color(0xFFE8E8E8), Color(0xFFF5F5F5), Color(0xFFE8E8E8)],
          stops: const [0.0, 0.5, 1.0],
          begin: Alignment(-1.5 + v * 3, 0),
          end: Alignment(1.5 + v * 3, 0),
        );

        Widget block(double h, double? w) => Container(
              height: h,
              width: w,
              decoration: BoxDecoration(
                gradient: g,
                borderRadius: BorderRadius.circular(6),
              ),
            );

        return Padding(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header skeleton
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Row(
                  children: [
                    Container(
                      width: 68,
                      height: 68,
                      decoration: BoxDecoration(gradient: g, shape: BoxShape.circle),
                    ),
                    const SizedBox(width: 16),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        block(16, 130),
                        const SizedBox(height: 8),
                        block(11, 180),
                        const SizedBox(height: 10),
                        block(24, 80),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: Container(
                      height: 90,
                      decoration: BoxDecoration(
                        gradient: g,
                        borderRadius: BorderRadius.circular(14),
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Container(
                      height: 90,
                      decoration: BoxDecoration(
                        gradient: g,
                        borderRadius: BorderRadius.circular(14),
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Container(
                      height: 90,
                      decoration: BoxDecoration(
                        gradient: g,
                        borderRadius: BorderRadius.circular(14),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }
}
