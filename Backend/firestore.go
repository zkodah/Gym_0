package main

import (
	"context"

	"cloud.google.com/go/firestore"
)

func getUsuarioFS(ctx context.Context, client *firestore.Client, uid string) (UsuarioDB, error) {
	doc, err := client.Collection("usuarios").Doc(uid).Get(ctx)
	if err != nil {
		return UsuarioDB{}, err
	}
	var u UsuarioDB
	if err := doc.DataTo(&u); err != nil {
		return UsuarioDB{}, err
	}
	u.UID = uid
	return u, nil
}

func upsertUsuarioFS(ctx context.Context, client *firestore.Client, uid string, input UsuarioInput) error {
	_, err := client.Collection("usuarios").Doc(uid).Set(ctx, input, firestore.MergeAll)
	return err
}
