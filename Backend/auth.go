package main

import (
	"context"
	"net/http"
	"os"
	"strings"

	firebase "firebase.google.com/go/v4"
	"firebase.google.com/go/v4/auth"
	"google.golang.org/api/option"
)

type contextKey string

const contextKeyUID contextKey = "uid"

func initFirebase(ctx context.Context) (*firebase.App, error) {
	// Opción 1: JSON como string en variable de entorno (para cloud deploy)
	if creds := os.Getenv("FIREBASE_CREDENTIALS"); creds != "" {
		opt := option.WithCredentialsJSON([]byte(creds))
		return firebase.NewApp(ctx, nil, opt)
	}
	// Opción 2: ruta a archivo JSON (para desarrollo local)
	if path := os.Getenv("GOOGLE_APPLICATION_CREDENTIALS"); path != "" {
		opt := option.WithCredentialsFile(path)
		return firebase.NewApp(ctx, nil, opt)
	}
	// Fallback: Application Default Credentials
	return firebase.NewApp(ctx, nil)
}

func middlewareAuth(authClient *auth.Client, next http.HandlerFunc) http.HandlerFunc {
	return func(w http.ResponseWriter, r *http.Request) {
		header := r.Header.Get("Authorization")
		if !strings.HasPrefix(header, "Bearer ") {
			http.Error(w, "Token requerido", http.StatusUnauthorized)
			return
		}
		token := strings.TrimPrefix(header, "Bearer ")
		t, err := authClient.VerifyIDToken(r.Context(), token)
		if err != nil {
			http.Error(w, "Token inválido", http.StatusUnauthorized)
			return
		}
		ctx := context.WithValue(r.Context(), contextKeyUID, t.UID)
		next(w, r.WithContext(ctx))
	}
}

func uidFromContext(ctx context.Context) string {
	uid, _ := ctx.Value(contextKeyUID).(string)
	return uid
}
