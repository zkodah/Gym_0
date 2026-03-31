package main

import (
	"encoding/json"
	"fmt"
	"log"
	"net/http"
	"strings"
	"time"

	"cloud.google.com/go/firestore"
	"firebase.google.com/go/v4/auth"
)

type app struct {
	authClient      *auth.Client
	firestoreClient *firestore.Client
	rutinas         Rutinas
}

var objetivosValidos = map[string]string{
	"hipertrofia": "Hipertrofia",
	"resistencia": "Resistencia",
	"fuerza":      "Fuerza",
}

func validarUsuarioInput(input UsuarioInput) error {
	if strings.TrimSpace(input.Alias) == "" || len(input.Alias) > 50 {
		return fmt.Errorf("alias debe tener entre 1 y 50 caracteres")
	}
	if input.Edad < 14 || input.Edad > 100 {
		return fmt.Errorf("edad debe estar entre 14 y 100")
	}
	if input.Altura < 0.9 || input.Altura > 2.5 {
		return fmt.Errorf("altura debe estar entre 0.9 y 2.5 metros")
	}
	if input.Peso < 20.0 || input.Peso > 300.0 {
		return fmt.Errorf("peso debe estar entre 20 y 300 kg")
	}
	return nil
}

// POST /usuario — upsert en Firestore usando UID del context
func (a *app) guardarUsuario(w http.ResponseWriter, r *http.Request) {
	var input UsuarioInput
	if err := json.NewDecoder(r.Body).Decode(&input); err != nil {
		http.Error(w, "Error en el formato del JSON", http.StatusBadRequest)
		return
	}
	defer r.Body.Close()

	if err := validarUsuarioInput(input); err != nil {
		http.Error(w, err.Error(), http.StatusBadRequest)
		return
	}

	// Normalizar objetivo a Title Case
	normalizado, ok := objetivosValidos[strings.ToLower(input.Objetivo)]
	if !ok {
		http.Error(w, "Objetivo inválido. Válidos: Hipertrofia, Resistencia, Fuerza", http.StatusBadRequest)
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

	// Calcular meses desde fechaRegistro
	meses := calcularMeses(u.FechaRegistro)

	// Navegar el mapa de rutinas usando la caché cargada al inicio
	porObjetivo, ok := a.rutinas[u.Objetivo]
	if !ok {
		http.Error(w, "Perfil de rutina no encontrado", http.StatusNotFound)
		return
	}
	rangoEdad := seleccionarRangoEdad(u.Edad)
	porEdad, ok := porObjetivo[rangoEdad]
	if !ok {
		http.Error(w, "Perfil de rutina no encontrado", http.StatusNotFound)
		return
	}
	rangoPeso := seleccionarRangoPeso(u.Peso)
	porPeso, ok := porEdad[rangoPeso]
	if !ok {
		http.Error(w, "Perfil de rutina no encontrado", http.StatusNotFound)
		return
	}
	periodo := seleccionarPeriodo(meses)
	dias, ok := porPeso[periodo]
	if !ok {
		http.Error(w, "Perfil de rutina no encontrado", http.StatusNotFound)
		return
	}

	w.Header().Set("Content-Type", "application/json")
	json.NewEncoder(w).Encode(dias)
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
