package main

import (
	"net/http"

	"firebase.google.com/go/v4/auth"
)

func habilitarCORS(next http.HandlerFunc) http.HandlerFunc {
	return func(w http.ResponseWriter, r *http.Request) {
		w.Header().Set("Access-Control-Allow-Origin", "*")
		w.Header().Set("Access-Control-Allow-Methods", "GET, POST, OPTIONS")
		w.Header().Set("Access-Control-Allow-Headers", "Content-Type, Authorization")
		if r.Method == http.MethodOptions {
			w.WriteHeader(http.StatusNoContent)
			return
		}
		next(w, r)
	}
}

func registrarRutas(a *app, authClient *auth.Client) {
	// Health check — sin auth, 20 req/min
	http.HandleFunc("/", middlewareHeaders(limitarPorIP(20, func(w http.ResponseWriter, r *http.Request) {
		w.Write([]byte("API de AppGym corriendo"))
	})))

	// /usuario — con auth, 60 req/min
	http.HandleFunc("/usuario", habilitarCORS(middlewareHeaders(limitarPorIP(60, middlewareAuth(authClient, func(w http.ResponseWriter, r *http.Request) {
		switch r.Method {
		case http.MethodGet:
			a.obtenerUsuario(w, r)
		case http.MethodPost:
			a.guardarUsuario(w, r)
		default:
			http.Error(w, "Método no permitido", http.StatusMethodNotAllowed)
		}
	})))))

	// /rutina — con auth, 60 req/min
	http.HandleFunc("/rutina", habilitarCORS(middlewareHeaders(limitarPorIP(60, middlewareAuth(authClient, a.obtenerRutina)))))
}
