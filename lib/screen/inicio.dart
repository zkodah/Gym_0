import 'package:flutter/material.dart';
import 'package:percent_indicator/percent_indicator.dart';
import '../services/api_service.dart';
import '../widget/navbar.dart';
import 'ejercicios.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'login.dart';

class InicioScreen extends StatefulWidget {
  const InicioScreen({super.key});

  @override
  State<InicioScreen> createState() => _InicioScreenState();
}

class _InicioScreenState extends State<InicioScreen> {
  List<dynamic> ejercicios = [];
  bool loading = true;

  // Guarda el progreso de un día en Firestore (merge sobre el mapa "progreso")
  Future<void> _guardarProgresoDia(String dia, double progreso) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;
    try {
      await FirebaseFirestore.instance
          .collection("usuarios")
          .doc(user.uid)
          .set({"progreso": {dia: progreso}}, SetOptions(merge: true));
    } catch (e) {
      print("Error guardando progreso de $dia: $e");
    }
  }

  List<dynamic> _filtrarRutinas(
  Map<String, dynamic> data,
  String objetivo,
  int edad,
  double peso,
  String nivel,
) {
  if (!data.containsKey(objetivo)) return [];

  final objetivoData = data[objetivo];

  // Buscar rango de edad
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

  // Buscar rango de peso
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

  if (periodos.containsKey(nivel)) {
    return periodos[nivel];
  }

  // fallback
  return [];
}

  @override
  void initState() {
    super.initState();
    verificarPerfilUsuario();
    cargarEjercicios();
  }
void cargarEjercicios() async {
  try {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    final doc = await FirebaseFirestore.instance
        .collection("usuarios")
        .doc(user.uid)
        .get();

    if (!doc.exists) {
      if (!mounted) return;
      setState(() => loading = false);
      return;
    }

    final dataUsuario = doc.data()!;
    print("Datos del usuario: $dataUsuario");

    // Determinar nivel según tiempo desde registro
    final nivel = _determinarNivel(dataUsuario);

    // Obtener rutinas desde API/local
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

    // Cargar progreso guardado (mapa dia -> porcentaje 0..1)
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

    // Si el nivel cambió, actualiza en Firestore
    if (dataUsuario["nivel"] != nivel) {
      await FirebaseFirestore.instance
          .collection("usuarios")
          .doc(user.uid)
          .update({"nivel": nivel});
      print("Nivel actualizado automáticamente a $nivel");
    }
  } catch (e) {
    if (!mounted) return;
    setState(() => loading = false);
    print("Error al cargar rutinas: $e");
  }
}

/// 🔹 Determina nivel según la fecha de registro
String _determinarNivel(Map<String, dynamic> data) {
  try {
    if (data["fechaRegistro"] == null) return "base";
    final fecha = DateTime.parse(data["fechaRegistro"]);
    final meses = DateTime.now().difference(fecha).inDays ~/ 30;

    if (meses < 4) return "base";
    if (meses < 7) return "intermedio";
    return "avanzado";
  } catch (e) {
    print("Error calculando nivel: $e");
    return "base";
  }
}

Future<void> verificarPerfilUsuario() async {
  try {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    final docRef = FirebaseFirestore.instance.collection("usuarios").doc(user.uid);
    final snap = await docRef.get();
    Map<String, dynamic> data = {};

    if (snap.exists) {
      data = snap.data() as Map<String, dynamic>;
    }

    // Asegurar fechaRegistro para cálculo de nivel
    if (data["fechaRegistro"] == null) {
      await docRef.set(
        {"fechaRegistro": DateTime.now().toIso8601String()},
        SetOptions(merge: true),
      );
    }

    final bool incompleto =
        !snap.exists ||
        data["alias"] == null ||
        data["edad"] == null ||
        data["altura"] == null ||
        data["peso"] == null ||
        data["objetivo"] == null ||
        (data["objetivo"].toString().isEmpty);

    if (incompleto) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _showQuestionnaire(context);
      });
    }
  } catch (e) {
    print("Error verificando perfil: $e");
  }
}

  
  
  Future<void> _showQuestionnaire(BuildContext context) async {
    final TextEditingController aliasCtrl = TextEditingController();
    final TextEditingController edadCtrl = TextEditingController();
    final TextEditingController alturaCtrl = TextEditingController();
    final TextEditingController pesoCtrl = TextEditingController();

    String objetivo = ""; // aquí guardamos la selección

    await showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) {
        return StatefulBuilder( // necesario para que se refresque la selección
          builder: (context, setState) {
            return AlertDialog(
              title: const Text("Completa tu perfil"),
              content: SingleChildScrollView(
                child: Column(
                  children: [
                    TextField(
                      controller: aliasCtrl,
                      keyboardType: TextInputType.text,
                      decoration: const InputDecoration(labelText: "Alias"),
                    ),
                    TextField(
                      controller: edadCtrl,
                      keyboardType: TextInputType.number,
                      decoration: const InputDecoration(labelText: "Edad"),
                    ),
                    TextField(
                      controller: alturaCtrl,
                      keyboardType: TextInputType.number,
                      decoration: const InputDecoration(labelText: "Altura (m)"),
                    ),
                    TextField(
                      controller: pesoCtrl,
                      keyboardType: TextInputType.number,
                      decoration: const InputDecoration(labelText: "Peso (kg)"),
                    ),
                    const SizedBox(height: 20),
                    const Text("Selecciona tu objetivo:"),
                    const SizedBox(height: 10),
                    Wrap(
                      spacing: 5,
                      runSpacing: 5,
                      children: [
                        _buildOptionCard("Fuerza", Icons.fitness_center, objetivo, (val) {
                          setState(() => objetivo = val);
                        }),
                        _buildOptionCard("Resistencia", Icons.monitor_heart, objetivo, (val) {
                          setState(() => objetivo = val);
                        }),
                        _buildOptionCard("Hipertrofia", Icons.fitness_center_rounded, objetivo, (val) {
                          setState(() => objetivo = val);
                        }),
                      ],
                    ),
                  ],
                ),
              ),
              actions: [
                ElevatedButton(
                  onPressed: () async {
                    final user = FirebaseAuth.instance.currentUser;
                    if (user != null) {
                      final data = {
                        "alias": aliasCtrl.text,
                        "edad": int.tryParse(edadCtrl.text) ?? 0,
                        "altura": double.tryParse(alturaCtrl.text) ?? 0.0,
                        "peso": double.tryParse(pesoCtrl.text) ?? 0.0,
                        "objetivo": objetivo == "Bienestar/Salud"
                            ? "Salud"
                            : objetivo == "Fuerza"
                                ? "Resistencia"
                                : "Hipertrofia",
                      };

                      print("Datos a guardar en Firestore: $data"); // Depuración

                      await FirebaseFirestore.instance
                          .collection("usuarios")
                          .doc(user.uid)
                          .set(data, SetOptions(merge: true)); // Sobrescribir datos existentes

                      Navigator.pop(context);
                    }
                  },
                  child: const Text("Guardar"),
                )
              ],
            );
          },
        );
      },
    );
  }

  /// Widget para crear tarjetas seleccionables
  Widget _buildOptionCard(String text, IconData icon, String selected, Function(String) onSelect) {
    final bool isSelected = selected == text;
    return GestureDetector(
      onTap: () => onSelect(text),
      child: Container(
        width: 100,
        height: 100,
        decoration: BoxDecoration(
          color: isSelected ? Colors.blueAccent : Colors.grey[200],
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isSelected ? Colors.blue : Colors.grey,
            width: 2,
          ),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 40, color: isSelected ? Colors.white : Colors.black),
            const SizedBox(height: 5),
            Text(
              text,
              textAlign: TextAlign.center,
              style: TextStyle(
                color: isSelected ? Colors.white : Colors.black,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    // Calcular promedio de progreso
    double total = ejercicios.isEmpty
        ? 0
        : ejercicios
            .map((d) => (d["progreso"] ?? 0).toDouble())
            .reduce((a, b) => a + b);
    double promedio = ejercicios.isEmpty ? 0 : total / ejercicios.length;

    return Scaffold(
      appBar: AppBar(
        title: const Text("Gymkoda"),
        flexibleSpace: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              colors: [
                Color(0xFFFF6D00),
                Color(0xFF9D4EDD),
              ],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
        ),
        elevation: 4,
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () async {
              await FirebaseAuth.instance.signOut();
              Navigator.pushReplacement(
                context,
                MaterialPageRoute(builder: (context) => const LoginScreen()),
              );
            },
          )
        ],
      ),
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [
              Color.fromRGBO(245, 247, 250, 1),
              Color(0xFFE4ECF7),
            ],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
        ),
        child: loading
            ? const Center(child: CircularProgressIndicator())
            : Column(
                children: [
                  Expanded(
                    child: ListView.builder(
                      itemCount: ejercicios.length,
                      itemBuilder: (context, index) {
                        final e = ejercicios[index];
                        final progreso = (e["progreso"] ?? 0).toDouble();

                        return Card(
                          margin: const EdgeInsets.symmetric(
                              vertical: 8, horizontal: 12),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(14),
                          ),
                          elevation: 5,
                          color: Colors.transparent,
                          child: Container(
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                colors: [
                                  const Color(0xFFFFFFFF).withOpacity(0.95),
                                  const Color(0xFFF3F6FF).withOpacity(0.95),
                                ],
                                begin: Alignment.topLeft,
                                end: Alignment.bottomRight,
                              ),
                              borderRadius: BorderRadius.circular(14),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withOpacity(0.05),
                                  blurRadius: 8,
                                  offset: const Offset(0, 4),
                                ),
                              ],
                            ),
                            child: ListTile(
                              title: Text(
                                e['dia'],
                                style: const TextStyle(
                                    fontSize: 18, fontWeight: FontWeight.bold),
                              ),
                              subtitle: Text(
                                e['titulo'] ?? '',
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                              trailing: CircularPercentIndicator(
                                radius: 26.0,
                                lineWidth: 6.0,
                                percent: progreso.clamp(0.0, 1.0),
                                center: Text(
                                  "${(progreso * 100).toInt()}%",
                                  style: const TextStyle(
                                    fontSize: 12,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                                // Gradiente en progreso
                                linearGradient: const LinearGradient(
                                  colors: [
                                    Color(0xFFFFA726), // orange
                                    Color(0xFFEF5350), // red
                                  ],
                                  begin: Alignment.topLeft,
                                  end: Alignment.bottomRight,
                                ),
                                backgroundColor:
                                    const Color(0xFFE0E0E0), // gris claro
                                circularStrokeCap: CircularStrokeCap.round,
                              ),
                              onTap: () async {
                                final nuevoProgreso = await Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (_) => RutinaScreen(rutina: e),
                                  ),
                                );
                                if (nuevoProgreso != null) {
                                  final dia = (e['dia'] ?? '').toString();
                                  if (!mounted) return;
                                  setState(() {
                                    ejercicios[index]['progreso'] =
                                        (nuevoProgreso as num).toDouble();
                                  });
                                  await _guardarProgresoDia(
                                      dia, (nuevoProgreso as num).toDouble());
                                }
                              },
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                  // Promedio total con círculo estilizado
                  Container(
                    height: 200,
                    margin: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [
                          Color(0xFFFF9100),
                          Color(0xFF9D4EDD),
                        ],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      borderRadius: BorderRadius.circular(16),
                      boxShadow: [
                        BoxShadow(
                          color: const Color(0xFF0083B0).withOpacity(0.3),
                          spreadRadius: 3,
                          blurRadius: 10,
                          offset: const Offset(0, 6),
                        ),
                      ],
                    ),
                    child: Center(
                      child: CircularPercentIndicator(
                        radius: 82.0,
                        lineWidth: 16.0,
                        percent: promedio.clamp(0.0, 1.0),
                        center: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text(
                              "${(promedio * 100).toInt()}%",
                              style: const TextStyle(
                                  fontSize: 26,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.white),
                            ),
                            const SizedBox(height: 4),
                            const Text(
                              "Promedio Total",
                              style: TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w600,
                                  color: Colors.white70),
                            ),
                          ],
                        ),
                        // Gradiente en progreso
                        linearGradient: const LinearGradient(
                          colors: [
                            Color.fromARGB(255, 255, 255, 255),
                            Color.fromARGB(255, 255, 255, 255),
                          ],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),  
                        backgroundColor: Colors.white.withOpacity(0.25),
                        circularStrokeCap: CircularStrokeCap.round,
                      ),
                    ),
                  ),
                ],
              ),
      ),
      bottomNavigationBar: const GymNavbar(currentIndex: 1),
    );
  }
}
