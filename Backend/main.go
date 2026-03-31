package main

import (
	"context"
	"encoding/json"
	"log"
	"net/http"
	"os"

	"github.com/joho/godotenv"
)

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

	rutinas, err := cargarRutinas()
	if err != nil {
		log.Fatalf("Error cargando rutinas.json: %v", err)
	}
	log.Printf("Rutinas cargadas: %d objetivos", len(rutinas))

	a := &app{
		authClient:      authClient,
		firestoreClient: firestoreClient,
		rutinas:         rutinas,
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
