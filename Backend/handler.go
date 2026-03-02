package main

import (
	"encoding/json"
	"fmt"
	"log"
	"net/http"
	"os"
	"strings"
	"time"

	"cloud.google.com/go/firestore"
	"firebase.google.com/go/v4/auth"
)

type app struct {
	authClient      *auth.Client
	firestoreClient *firestore.Client
}

var objetivosValidos = map[string]string{
	"hipertrofia": "Hipertrofia",
	"resistencia": "Resistencia",
	"fuerza":      "Fuerza",
}

// POST /usuario — upsert en Firestore usando UID del context
func (a *app) guardarUsuario(w http.ResponseWriter, r *http.Request) {
	var input UsuarioInput
	if err := json.NewDecoder(r.Body).Decode(&input); err != nil {
		http.Error(w, "Error en el formato del JSON", http.StatusBadRequest)
		return
	}
	defer r.Body.Close()

	// Normalizar objetivo a Title Case
	normalizado, ok := objetivosValidos[strings.ToLower(input.Objetivo)]
	if !ok {
		http.Error(w, fmt.Sprintf("Objetivo inválido: %q. Válidos: Hipertrofia, Resistencia, Fuerza", input.Objetivo), http.StatusBadRequest)
		return
	}
	input.Objetivo = normalizado

	uid := uidFromContext(r.Context())
	if err := upsertUsuarioFS(r.Context(), a.firestoreClient, uid, input); err != nil {
		log.Printf("Error guardando usuario %s: %v", uid, err)
		http.Error(w, "Error al guardar el usuario", http.StatusInternalServerError)
		return
	}
	w.Header().Set("Content-Type", "application/json")
	json.NewEncoder(w).Encode(map[string]string{"mensaje": "Usuario guardado correctamente"})
}

// GET /usuario — lee de Firestore por UID del context
func (a *app) obtenerUsuario(w http.ResponseWriter, r *http.Request) {
	uid := uidFromContext(r.Context())
	u, err := getUsuarioFS(r.Context(), a.firestoreClient, uid)
	if err != nil {
		http.Error(w, "Usuario no encontrado", http.StatusNotFound)
		return
	}
	w.Header().Set("Content-Type", "application/json")
	json.NewEncoder(w).Encode(u)
}

// GET /rutina — selecciona la rutina personalizada del usuario
func (a *app) obtenerRutina(w http.ResponseWriter, r *http.Request) {
	uid := uidFromContext(r.Context())
	u, err := getUsuarioFS(r.Context(), a.firestoreClient, uid)
	if err != nil {
		http.Error(w, "Perfil no encontrado. Completa tu perfil primero.", http.StatusNotFound)
		return
	}

	rutinas, err := cargarRutinas()
	if err != nil {
		log.Printf("Error cargando rutinas: %v", err)
		http.Error(w, "Error cargando rutinas", http.StatusInternalServerError)
		return
	}

	// Calcular meses desde fechaRegistro (igual que el frontend)
	meses := calcularMeses(u.FechaRegistro)

	// Override con ?meses=N si se proporciona (útil para testing)
	if qm := r.URL.Query().Get("meses"); qm != "" {
		var m int
		if _, err := fmt.Sscanf(qm, "%d", &m); err == nil {
			meses = m
		}
	}

	// Navegar el mapa de rutinas
	porObjetivo, ok := rutinas[u.Objetivo]
	if !ok {
		http.Error(w, fmt.Sprintf("Objetivo %q no encontrado en rutinas", u.Objetivo), http.StatusNotFound)
		return
	}
	rangoEdad := seleccionarRangoEdad(u.Edad)
	porEdad, ok := porObjetivo[rangoEdad]
	if !ok {
		http.Error(w, fmt.Sprintf("Rango de edad %q no encontrado", rangoEdad), http.StatusNotFound)
		return
	}
	rangoPeso := seleccionarRangoPeso(u.Peso)
	porPeso, ok := porEdad[rangoPeso]
	if !ok {
		http.Error(w, fmt.Sprintf("Rango de peso %q no encontrado", rangoPeso), http.StatusNotFound)
		return
	}
	periodo := seleccionarPeriodo(meses)
	dias, ok := porPeso[periodo]
	if !ok {
		http.Error(w, fmt.Sprintf("Período %q no encontrado", periodo), http.StatusNotFound)
		return
	}

	w.Header().Set("Content-Type", "application/json")
	json.NewEncoder(w).Encode(dias)
}

// GET /rutinas — devuelve el JSON completo (debug, sin auth)
func listarRutinas(w http.ResponseWriter, r *http.Request) {
	rutinas, err := cargarRutinas()
	if err != nil {
		log.Printf("Error al cargar rutinas: %v", err)
		http.Error(w, "No se pudo cargar rutinas.json", http.StatusInternalServerError)
		return
	}
	w.Header().Set("Content-Type", "application/json")
	json.NewEncoder(w).Encode(rutinas)
}

func cargarRutinas() (Rutinas, error) {
	file, err := os.Open("data/rutinas.json")
	if err != nil {
		return nil, err
	}
	defer file.Close()
	var rutinas Rutinas
	if err := json.NewDecoder(file).Decode(&rutinas); err != nil {
		return nil, err
	}
	return rutinas, nil
}

// calcularMeses calcula cuántos meses pasaron desde fechaRegistro (formato ISO8601)
func calcularMeses(fechaRegistro string) int {
	if fechaRegistro == "" {
		return 0
	}
	t, err := time.Parse(time.RFC3339, fechaRegistro)
	if err != nil {
		// intentar formato sin zona horaria
		t, err = time.Parse("2006-01-02T15:04:05.999999999", fechaRegistro)
		if err != nil {
			return 0
		}
	}
	return int(time.Since(t).Hours() / 24 / 30)
}

func seleccionarRangoEdad(edad int) string {
	if edad < 31 {
		return "18-30"
	}
	if edad < 46 {
		return "31-45"
	}
	return "46-60"
}

func seleccionarRangoPeso(peso float64) string {
	if peso < 76 {
		return "60-75"
	}
	if peso < 91 {
		return "76-90"
	}
	return "91+"
}

func seleccionarPeriodo(meses int) string {
	if meses < 4 {
		return "base"
	}
	if meses < 7 {
		return "intermedio"
	}
	return "avanzado"
}
