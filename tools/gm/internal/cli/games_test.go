package cli

import (
	"bytes"
	"encoding/json"
	"errors"
	"io"
	"net/http"
	"net/http/httptest"
	"strings"
	"testing"

	"game-master/gm/internal/api"
)

const gameID = "c2d438d2-5f54-4d14-aef4-8194a1bc831f"
const gameJSON = `{"id":"c2d438d2-5f54-4d14-aef4-8194a1bc831f","name":"Winter Campaign","setting":"Fantasy","content":"<p>Adventure</p>","content_plain_text":"Adventure","created_at":"2026-01-01T12:00:00Z","updated_at":"2026-01-02T12:00:00Z"}`

func TestGamesCommands(t *testing.T) {
	unsetToken(t)
	server := httptest.NewServer(http.HandlerFunc(func(w http.ResponseWriter, r *http.Request) {
		if r.Header.Get("Authorization") != "Bearer saved-secret" {
			t.Error("saved session not used")
		}
		w.Header().Set("X-New-Session-Token", "renewed-secret")
		if r.URL.Path == "/api/games" {
			_, _ = w.Write([]byte(`{"data":[` + gameJSON + `]}`))
		} else if r.URL.Path == "/api/games/"+gameID {
			_, _ = w.Write([]byte(`{"data":` + gameJSON + `}`))
		} else {
			t.Error("unexpected path")
		}
	}))
	defer server.Close()
	t.Setenv("GM_BASE_URL", server.URL)
	for _, command := range []string{"list", "show"} {
		for _, jsonOutput := range []bool{false, true} {
			store := &memoryStore{tokens: map[string]string{server.URL: "saved-secret"}}
			args := []string{"games", command}
			if command == "show" {
				args = append(args, gameID)
			}
			if jsonOutput {
				args = append(args, "--json")
			}
			var stdout, stderr bytes.Buffer
			if err := run(args, &stdout, &stderr, "dev", authDependencies{store: store}); err != nil {
				t.Fatal(err)
			}
			if store.tokens[server.URL] != "renewed-secret" || stderr.Len() != 0 {
				t.Error("saved session renewal failed")
			}
			if jsonOutput {
				var envelope map[string]json.RawMessage
				if err := json.Unmarshal(stdout.Bytes(), &envelope); err != nil || envelope["data"] == nil || len(envelope) != 1 {
					t.Fatalf("invalid JSON envelope: %s", stdout.String())
				}
				if command == "list" {
					var games []api.Game
					if err := json.Unmarshal(envelope["data"], &games); err != nil || len(games) != 1 || games[0].ID != gameID {
						t.Fatal("invalid games list output")
					}
				} else {
					var game api.Game
					if err := json.Unmarshal(envelope["data"], &game); err != nil || game.ID != gameID {
						t.Fatal("invalid game output")
					}
				}
			} else {
				for _, want := range []string{gameID, "Winter Campaign", "Fantasy"} {
					if !strings.Contains(stdout.String(), want) {
						t.Errorf("missing %q in human output", want)
					}
				}
				if command == "show" && (!strings.Contains(stdout.String(), "Content:\nAdventure") || strings.Contains(stdout.String(), "<p>")) {
					t.Error("show should prefer plain-text content")
				}
			}
			if strings.Contains(stdout.String(), "secret") {
				t.Error("session token leaked")
			}
		}
	}
}

func TestGamesEnvironmentOverrideAndEmptyList(t *testing.T) {
	t.Setenv("GM_TOKEN", "env-secret")
	t.Setenv("GM_BASE_URL", "invalid")
	server := httptest.NewServer(http.HandlerFunc(func(w http.ResponseWriter, r *http.Request) {
		if r.Header.Get("Authorization") != "Bearer env-secret" {
			t.Error("environment token not used")
		}
		w.Header().Set("X-New-Session-Token", "renewed-secret")
		_, _ = w.Write([]byte(`{"data":[]}`))
	}))
	defer server.Close()
	for _, jsonOutput := range []bool{false, true} {
		store := &memoryStore{}
		var stdout, stderr bytes.Buffer
		args := []string{"games", "list", "--base-url", server.URL}
		if jsonOutput {
			args = append(args, "--json")
		}
		if err := run(args, &stdout, &stderr, "dev", authDependencies{store: store}); err != nil {
			t.Fatal(err)
		}
		want := "No games found.\n"
		if jsonOutput {
			want = "{\"data\":[]}\n"
		}
		if stdout.String() != want || !strings.Contains(stderr.String(), "server renewed") {
			t.Error("incorrect empty list or renewal output")
		}
		if store.gets != 0 || store.sets != 0 {
			t.Error("environment token must not touch keychain")
		}
	}
}

func TestGamesErrorsProduceNoResults(t *testing.T) {
	unsetToken(t)
	for _, body := range []string{`{}`, `{"data":[]}`} {
		server := httptest.NewServer(http.HandlerFunc(func(w http.ResponseWriter, r *http.Request) {
			w.Header().Set("X-New-Session-Token", "renewed-secret")
			_, _ = w.Write([]byte(body))
		}))
		store := &memoryStore{tokens: map[string]string{server.URL: "saved-secret"}, setErr: errors.New("storage-secret")}
		var stdout, stderr bytes.Buffer
		err := run([]string{"games", "list", "--base-url", server.URL, "--json"}, &stdout, &stderr, "dev", authDependencies{store: store})
		server.Close()
		if err == nil || strings.Contains(err.Error(), "storage-secret") || stdout.Len() != 0 {
			t.Fatalf("expected safe error without JSON results: %v", err)
		}
	}
	store := &memoryStore{}
	var stdout, stderr bytes.Buffer
	if err := run([]string{"games", "list"}, &stdout, &stderr, "dev", authDependencies{store: store}); err == nil || !strings.Contains(err.Error(), "no saved session") {
		t.Fatalf("missing credential error: %v", err)
	}
}

func TestGamesHelpAndArgumentValidation(t *testing.T) {
	t.Setenv("GM_TOKEN", "")
	t.Setenv("GM_BASE_URL", "invalid")
	store := &memoryStore{}
	for _, args := range [][]string{{"games"}, {"games", "list", "--help"}, {"games", "show", "--help"}} {
		var stdout bytes.Buffer
		if err := run(args, &stdout, io.Discard, "dev", authDependencies{store: store}); err != nil {
			t.Fatal(err)
		}
		if !strings.Contains(stdout.String(), "Usage:") {
			t.Error("missing help")
		}
	}
	for _, args := range [][]string{{"games", "list", "extra"}, {"games", "show"}, {"games", "show", "../auth/logout"}, {"games", "show", gameID, "extra"}} {
		if err := run(args, io.Discard, io.Discard, "dev", authDependencies{store: store}); err == nil {
			t.Errorf("expected argument error for %v", args)
		}
	}
	if store.gets != 0 {
		t.Error("help or invalid arguments accessed keychain")
	}
}

func TestGameOutputSafetyAndWriterErrors(t *testing.T) {
	content := "Line one\nLine two\x1b[31m"
	game := api.Game{ID: gameID, Name: "Game\tName\x1b[31m", Content: &content}
	var stdout bytes.Buffer
	if err := printGames(&stdout, []api.Game{game}); err != nil {
		t.Fatal(err)
	}
	if err := printGame(&stdout, &game); err != nil {
		t.Fatal(err)
	}
	if strings.ContainsRune(stdout.String(), '\x1b') || !strings.Contains(stdout.String(), "Line one\nLine two") {
		t.Error("unsafe terminal output or missing content fallback")
	}
	want := errors.New("writer unavailable")
	for _, err := range []error{printGames(failingWriter{err: want}, nil), printGames(failingWriter{err: want}, []api.Game{game}), printGame(failingWriter{err: want}, &game)} {
		if !errors.Is(err, want) {
			t.Errorf("output error = %v, want %v", err, want)
		}
	}
}
