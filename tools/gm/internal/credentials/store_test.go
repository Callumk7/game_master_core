package credentials

import (
	"errors"
	"testing"

	"github.com/zalando/go-keyring"
)

func TestKeyringStore(t *testing.T) {
	// This replaces the OS backend for this test process: never touch real credentials.
	keyring.MockInit()
	store := Keyring{}
	if _, err := store.Get("https://api.example.com"); !errors.Is(err, ErrNotFound) {
		t.Fatalf("expected missing session: %v", err)
	}
	if err := store.Set("https://api.example.com", "first-session"); err != nil {
		t.Fatal(err)
	}
	if err := store.Set("http://localhost:4000", "local-session"); err != nil {
		t.Fatal(err)
	}
	if err := store.Set("https://api.example.com", "renewed-session"); err != nil {
		t.Fatal(err)
	}
	for origin, want := range map[string]string{"https://api.example.com": "renewed-session", "http://localhost:4000": "local-session"} {
		got, err := store.Get(origin)
		if err != nil || got != want {
			t.Errorf("unexpected stored session for %s: %v", origin, err)
		}
	}
	for range 2 {
		if err := store.Delete("https://api.example.com"); err != nil {
			t.Fatalf("delete must be idempotent: %v", err)
		}
	}
	if _, err := store.Get("https://api.example.com"); !errors.Is(err, ErrNotFound) {
		t.Fatalf("deleted session still exists: %v", err)
	}
	if token, err := store.Get("http://localhost:4000"); err != nil || token != "local-session" {
		t.Fatal("delete affected another origin")
	}
}
