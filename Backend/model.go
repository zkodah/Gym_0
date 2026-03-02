package main

// UsuarioInput es lo que envía el cliente en POST /usuario
type UsuarioInput struct {
	Alias    string  `json:"alias"    firestore:"alias"`
	Edad     int     `json:"edad"     firestore:"edad"`
	Altura   float64 `json:"altura"   firestore:"altura"`
	Peso     float64 `json:"peso"     firestore:"peso"`
	Objetivo string  `json:"objetivo" firestore:"objetivo"`
}

// UsuarioDB es lo que lee el backend de Firestore (incluye UID y fechaRegistro)
type UsuarioDB struct {
	UID           string  `json:"uid"`
	Alias         string  `json:"alias"          firestore:"alias"`
	Edad          int     `json:"edad"           firestore:"edad"`
	Altura        float64 `json:"altura"         firestore:"altura"`
	Peso          float64 `json:"peso"           firestore:"peso"`
	Objetivo      string  `json:"objetivo"       firestore:"objetivo"`
	FechaRegistro string  `json:"fechaRegistro"  firestore:"fechaRegistro"`
}

// Rutinas es un mapa dinámico: objetivo → rangoEdad → rangoPeso → periodo → []Dia
type Rutinas map[string]map[string]map[string]map[string][]Dia

type Dia struct {
	Dia    string   `json:"dia"`
	Titulo string   `json:"titulo"`
	Rutina []string `json:"rutina"`
}
