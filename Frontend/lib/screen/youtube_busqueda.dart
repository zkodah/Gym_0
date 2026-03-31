import 'dart:async';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_application_1/services/api_youtube.dart';
import 'package:flutter_application_1/screen/videos.dart';
import 'package:flutter_application_1/widget/navbar.dart';

// ── Paleta centralizada ───────────────────────────────────────────────────────
const _kAccent = Color(0xFFFF6D00);
const _kBg = Color(0xFFF5F5F7);
const _kInk = Color(0xFF1A1A2E);

// ── Screen ────────────────────────────────────────────────────────────────────
class YoutubeSearchScreen extends StatefulWidget {
  /// Query pre-cargado desde la pantalla de rutinas.
  final String? initialQuery;

  const YoutubeSearchScreen({super.key, this.initialQuery});

  @override
  State<YoutubeSearchScreen> createState() => _YoutubeSearchScreenState();
}

class _YoutubeSearchScreenState extends State<YoutubeSearchScreen>
    with SingleTickerProviderStateMixin {
  final List<Map<String, String>> _resultados = [];
  bool _cargando = false;
  String? _error;
  Timer? _debounce;

  late final TextEditingController _searchCtrl;
  late final AnimationController _staggerCtrl;

  @override
  void initState() {
    super.initState();
    _searchCtrl = TextEditingController(text: widget.initialQuery ?? '');
    _staggerCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 700),
    );

    if (widget.initialQuery != null && widget.initialQuery!.isNotEmpty) {
      WidgetsBinding.instance.addPostFrameCallback(
        (_) => _buscar(widget.initialQuery!),
      );
    }
  }

  @override
  void dispose() {
    _debounce?.cancel();
    _searchCtrl.dispose();
    _staggerCtrl.dispose();
    super.dispose();
  }

  void _buscar(String raw) {
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 400), () async {
      final q = raw.trim();
      if (q.isEmpty) {
        setState(() {
          _resultados.clear();
          _error = null;
        });
        return;
      }

      setState(() {
        _cargando = true;
        _error = null;
        _resultados.clear();
      });

      try {
        final data = await YoutubeApiService.buscarVideos(q);
        if (!mounted) return;
        setState(() {
          _resultados.addAll(data);
          _cargando = false;
          if (data.isEmpty) _error = 'Sin resultados para "$q"';
        });
        if (data.isNotEmpty) _staggerCtrl.forward(from: 0);
      } catch (e) {
        if (!mounted) return;
        setState(() {
          _cargando = false;
          _error = 'Error al buscar. Verifica tu conexión.';
        });
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _kBg,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: Navigator.canPop(context)
            ? IconButton(
                icon: const Icon(Icons.arrow_back_ios_new_rounded, color: _kInk),
                onPressed: () => Navigator.pop(context),
              )
            : null,
        title: Text(
          'Buscar ejercicios',
          style: GoogleFonts.outfit(
            fontSize: 22,
            fontWeight: FontWeight.w700,
            color: _kInk,
          ),
        ),
        iconTheme: const IconThemeData(color: _kInk),
      ),
      body: Column(
        children: [
          _SearchBar(
            controller: _searchCtrl,
            onChanged: (v) {
              setState(() {});
              _buscar(v);
            },
            onClear: () {
              _searchCtrl.clear();
              setState(() {
                _resultados.clear();
                _error = null;
              });
            },
          ),
          Expanded(child: _buildBody()),
        ],
      ),
      bottomNavigationBar: const GymNavbar(currentIndex: 0),
    );
  }

  Widget _buildBody() {
    if (_cargando) {
      return ListView.builder(
        padding: const EdgeInsets.symmetric(horizontal: 16),
        itemCount: 5,
        itemBuilder: (_, __) => const _SkeletonCard(),
      );
    }

    if (_error != null && _resultados.isEmpty) {
      return _ErrorState(message: _error!);
    }

    if (_resultados.isEmpty) {
      return const _EmptyState();
    }

    return ListView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      itemCount: _resultados.length,
      itemBuilder: (context, i) {
        final startAt = (i * 0.08).clamp(0.0, 0.7);
        final endAt = (startAt + 0.4).clamp(0.0, 1.0);
        return AnimatedBuilder(
          animation: _staggerCtrl,
          builder: (_, child) {
            final anim = CurvedAnimation(
              parent: _staggerCtrl,
              curve: Interval(startAt, endAt, curve: Curves.easeOutCubic),
            );
            return FadeTransition(
              opacity: anim,
              child: SlideTransition(
                position: Tween<Offset>(
                  begin: const Offset(0, 0.18),
                  end: Offset.zero,
                ).animate(anim),
                child: child,
              ),
            );
          },
          child: _VideoCard(video: _resultados[i]),
        );
      },
    );
  }
}

// ── Search Bar ────────────────────────────────────────────────────────────────
class _SearchBar extends StatelessWidget {
  final TextEditingController controller;
  final ValueChanged<String> onChanged;
  final VoidCallback onClear;

  const _SearchBar({
    required this.controller,
    required this.onChanged,
    required this.onClear,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 4, 16, 16),
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: _kAccent.withOpacity(0.10),
              blurRadius: 20,
              offset: const Offset(0, 6),
            ),
          ],
        ),
        child: TextField(
          controller: controller,
          style: GoogleFonts.outfit(fontSize: 16, color: _kInk),
          decoration: InputDecoration(
            hintText: 'Ej: press de banca, sentadillas...',
            hintStyle: GoogleFonts.outfit(
              color: const Color(0xFF9E9E9E),
              fontSize: 15,
            ),
            prefixIcon: const Icon(Icons.search_rounded, color: _kAccent),
            suffixIcon: controller.text.isNotEmpty
                ? IconButton(
                    icon: const Icon(Icons.clear_rounded,
                        color: Color(0xFF9E9E9E)),
                    onPressed: onClear,
                  )
                : null,
            border: InputBorder.none,
            contentPadding:
                const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
          ),
          onChanged: onChanged,
        ),
      ),
    );
  }
}

// ── Video Card con feedback táctil ────────────────────────────────────────────
class _VideoCard extends StatefulWidget {
  final Map<String, String> video;

  const _VideoCard({required this.video});

  @override
  State<_VideoCard> createState() => _VideoCardState();
}

class _VideoCardState extends State<_VideoCard>
    with SingleTickerProviderStateMixin {
  late final AnimationController _pressCtrl;
  late final Animation<double> _scaleAnim;

  @override
  void initState() {
    super.initState();
    _pressCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 100),
      reverseDuration: const Duration(milliseconds: 200),
    );
    _scaleAnim = Tween<double>(begin: 1.0, end: 0.97).animate(
      CurvedAnimation(parent: _pressCtrl, curve: Curves.easeOut),
    );
  }

  @override
  void dispose() {
    _pressCtrl.dispose();
    super.dispose();
  }

  void _onTap() {
    _pressCtrl.reverse();
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => VideoPlayerScreen(videoId: widget.video['id']!),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final v = widget.video;

    return GestureDetector(
      onTapDown: (_) => _pressCtrl.forward(),
      onTapUp: (_) => _onTap(),
      onTapCancel: () => _pressCtrl.reverse(),
      child: AnimatedBuilder(
        animation: _scaleAnim,
        builder: (_, child) =>
            Transform.scale(scale: _scaleAnim.value, child: child),
        child: Container(
          margin: const EdgeInsets.only(bottom: 16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.06),
                blurRadius: 16,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // ── Thumbnail 16:9 ──────────────────────────────────────────
              ClipRRect(
                borderRadius: const BorderRadius.vertical(
                  top: Radius.circular(16),
                ),
                child: AspectRatio(
                  aspectRatio: 16 / 9,
                  child: Stack(
                    fit: StackFit.expand,
                    children: [
                      if (v['thumbnail']!.isNotEmpty)
                        Image.network(
                          v['thumbnail']!,
                          fit: BoxFit.cover,
                          loadingBuilder: (_, child, progress) =>
                              progress == null
                                  ? child
                                  : Container(
                                      color: const Color(0xFFEEEEEE)),
                          errorBuilder: (_, __, ___) =>
                              Container(color: const Color(0xFFEEEEEE)),
                        )
                      else
                        Container(color: const Color(0xFFEEEEEE)),
                      // Play overlay
                      Center(
                        child: Container(
                          width: 48,
                          height: 48,
                          decoration: BoxDecoration(
                            color: Colors.black.withOpacity(0.45),
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(
                            Icons.play_arrow_rounded,
                            color: Colors.white,
                            size: 30,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              // ── Info ────────────────────────────────────────────────────
              Padding(
                padding: const EdgeInsets.fromLTRB(14, 12, 14, 14),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      v['title'] ?? '',
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: GoogleFonts.outfit(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: _kInk,
                        height: 1.4,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Row(
                      children: [
                        const Icon(
                          Icons.play_circle_outline_rounded,
                          size: 14,
                          color: _kAccent,
                        ),
                        const SizedBox(width: 4),
                        Expanded(
                          child: Text(
                            v['channel'] ?? '',
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: GoogleFonts.outfit(
                              fontSize: 12,
                              color: const Color(0xFF9E9E9E),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ── Skeleton shimmer ──────────────────────────────────────────────────────────
class _SkeletonCard extends StatefulWidget {
  const _SkeletonCard();

  @override
  State<_SkeletonCard> createState() => _SkeletonCardState();
}

class _SkeletonCardState extends State<_SkeletonCard>
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
        final gradient = LinearGradient(
          colors: const [
            Color(0xFFE8E8E8),
            Color(0xFFF5F5F5),
            Color(0xFFE8E8E8),
          ],
          stops: const [0.0, 0.5, 1.0],
          begin: Alignment(-1.5 + v * 3, 0),
          end: Alignment(1.5 + v * 3, 0),
        );

        Widget block(double h, double? w) => Container(
              height: h,
              width: w,
              decoration: BoxDecoration(
                gradient: gradient,
                borderRadius: BorderRadius.circular(6),
              ),
            );

        return Container(
          margin: const EdgeInsets.only(bottom: 16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.04),
                blurRadius: 12,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Column(
            children: [
              AspectRatio(
                aspectRatio: 16 / 9,
                child: Container(
                  decoration: BoxDecoration(
                    gradient: gradient,
                    borderRadius: const BorderRadius.vertical(
                      top: Radius.circular(16),
                    ),
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(14),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    block(13, double.infinity),
                    const SizedBox(height: 8),
                    block(13, 220),
                    const SizedBox(height: 10),
                    block(11, 130),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

// ── Empty state ───────────────────────────────────────────────────────────────
class _EmptyState extends StatelessWidget {
  const _EmptyState();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 88,
            height: 88,
            decoration: BoxDecoration(
              color: _kAccent.withOpacity(0.08),
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.play_circle_outline_rounded,
              size: 44,
              color: _kAccent,
            ),
          ),
          const SizedBox(height: 20),
          Text(
            'Busca un ejercicio para\nver cómo se realiza',
            style: GoogleFonts.outfit(
              color: _kInk,
              fontSize: 17,
              fontWeight: FontWeight.w600,
              height: 1.45,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 8),
          Text(
            'Aprende la técnica correcta con videos',
            style: GoogleFonts.outfit(
              color: const Color(0xFF9E9E9E),
              fontSize: 13,
            ),
          ),
        ],
      ),
    );
  }
}

// ── Error state ───────────────────────────────────────────────────────────────
class _ErrorState extends StatelessWidget {
  final String message;

  const _ErrorState({required this.message});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.search_off_rounded, size: 56, color: Colors.grey[300]),
          const SizedBox(height: 16),
          Text(
            message,
            style: GoogleFonts.outfit(
              color: Colors.grey[500],
              fontSize: 15,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}
