package main

import (
	"context"
	"log"
	"net/http"
	"os"

	"github.com/joho/godotenv"
)

func main() {
	// Carga .env si existe (para desarrollo local). En producción se ignora.
	if err := godotenv.Load(); err != nil {
		log.Println("Sin archivo .env, usando variables de entorno del sistema")
	}

	ctx := context.Background()

	fbApp, err := initFirebase(ctx)
	if err != nil {
		log.Fatalf("Error inicializando Firebase: %v", err)
	}

	authClient, err := fbApp.Auth(ctx)
	if err != nil {
		log.Fatalf("Error creando Auth client: %v", err)
	}

	firestoreClient, err := fbApp.Firestore(ctx)
	if err != nil {
		log.Fatalf("Error creando Firestore client: %v", err)
	}
	defer firestoreClient.Close()

	a := &app{
		authClient:      authClient,
		firestoreClient: firestoreClient,
	}

	registrarRutas(a, authClient)

	port := os.Getenv("PORT")
	if port == "" {
		port = "8080"
	}

	log.Printf("Servidor corriendo en http://localhost:%s", port)
	if err := http.ListenAndServe(":"+port, nil); err != nil {
		log.Fatalf("Error en el servidor: %v", err)
	}
}
