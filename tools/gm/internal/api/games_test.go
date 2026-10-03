package api

import (
	"context"
	"encoding/json"
	"net/http"
	"net/http/httptest"
	"strings"
	"testing"
	"time"
)

const testGameID = "c2d438d2-5f54-4d14-aef4-8194a1bc831f"

// Matches GameJSON/JSONHelpers, including null fields and no owner_id.
const testGameJSON = `{"id":"c2d438d2-5f54-4d14-aef4-8194a1bc831f","name":"Winter Campaign","setting":null,"content":"<p>Adventure</p>","content_plain_text":"Adventure","created_at":"2026-01-01T12:00:00Z","updated_at":"2026-01-02T12:00:00Z"}`

func TestGamesRequests(t *testing.T) {
	server := httptest.NewServer(http.HandlerFunc(func(w http.ResponseWriter, r *http.Request) {
		if r.Method != http.MethodGet || r.Header.Get("Authorization") != "Bearer session-secret" || r.Header.Get("Accept") != "application/json" {
			t.Error("incorrect authenticated request")
		}
		w.Header().Set("X-New-Session-Token", "renewed-secret")
		switch r.URL.Path {
		case "/api/games":
			_, _ = w.Write([]byte(`{"data":[` + testGameJSON + `]}`))
		case "/api/games/" + testGameID:
			_, _ = w.Write([]byte(`{"data":` + testGameJSON + `}`))
		default:
			t.Error("unexpected path")
		}
	}))
	defer server.Close()
	client, err := NewClient(server.URL, "session-secret", time.Second)
	if err != nil {
		t.Fatal(err)
	}
	list, err := client.ListGames(context.Background())
	if err != nil {
		t.Fatal(err)
	}
	if len(list.Data) != 1 || list.Data[0].ID != testGameID || list.Data[0].Setting != nil || list.NewSessionToken != "renewed-secret" {
		t.Fatal("unexpected games result")
	}
	show, err := client.GetGame(context.Background(), testGameID)
	if err != nil {
		t.Fatal(err)
	}
	if show.Data.Name != "Winter Campaign" || *show.Data.ContentPlainText != "Adventure" || show.Data.OwnerID != nil || show.NewSessionToken != "renewed-secret" {
		t.Fatal("unexpected game result")
	}
	for _, result := range []any{list, show} {
		output, err := json.Marshal(result)
		if err != nil || strings.Contains(string(output), "renewed-secret") {
			t.Fatal("renewed token must be excluded from JSON")
		}
	}
}

func TestGamesResponseValidation(t *testing.T) {
	for _, tt := range []struct {
		name, body  string
		show, valid bool
	}{
		{"empty list", `{"data":[]}`, false, true},
		{"missing list", `{}`, false, false},
		{"null list", `{"data":null}`, false, false},
		{"wrong list shape", `{"data":{}}`, false, false},
		{"numeric ID", `{"data":[{"id":1,"name":"Game"}]}`, false, false},
		{"invalid UUID", `{"data":[{"id":"not-a-uuid","name":"Game"}]}`, false, false},
		{"missing name", `{"data":[{"id":"` + testGameID + `"}]}`, false, false},
		{"invalid JSON", `<html>secret</html>`, false, false},
		{"null game", `{"data":null}`, true, false},
		{"list instead of game", `{"data":[]}`, true, false},
		{"missing game", `{}`, true, false},
		{"too large", strings.Repeat("x", maxResponseBytes+1), true, false},
	} {
		t.Run(tt.name, func(t *testing.T) {
			server := httptest.NewServer(http.HandlerFunc(func(w http.ResponseWriter, r *http.Request) { _, _ = w.Write([]byte(tt.body)) }))
			defer server.Close()
			client, err := NewClient(server.URL, "secret", time.Second)
			if err != nil {
				t.Fatal(err)
			}
			if tt.show {
				_, err = client.GetGame(context.Background(), testGameID)
			} else {
				_, err = client.ListGames(context.Background())
			}
			if (err == nil) != tt.valid {
				t.Fatalf("unexpected validation result: %v", err)
			}
		})
	}
}

func TestGamesAPIErrors(t *testing.T) {
	for _, tt := range []struct {
		code int
		want string
	}{{401, "expired"}, {403, "HTTP 403"}, {404, "game not found or not accessible"}, {500, "HTTP 500"}, {302, "HTTP 302"}} {
		server := httptest.NewServer(http.HandlerFunc(func(w http.ResponseWriter, r *http.Request) {
			w.WriteHeader(tt.code)
			_, _ = w.Write([]byte("session-secret"))
		}))
		client, err := NewClient(server.URL, "session-secret", time.Second)
		if err != nil {
			t.Fatal(err)
		}
		_, err = client.GetGame(context.Background(), testGameID)
		server.Close()
		if err == nil || !strings.Contains(err.Error(), tt.want) || strings.Contains(err.Error(), "session-secret") {
			t.Fatalf("unexpected API error: %v", err)
		}
	}
}

func TestGamesMissingTokenAndInvalidID(t *testing.T) {
	client, err := NewClient("http://localhost:4000", "", time.Second)
	if err != nil {
		t.Fatal(err)
	}
	if _, err := client.ListGames(context.Background()); err == nil {
		t.Error("list should require token")
	}
	if _, err := client.GetGame(context.Background(), testGameID); err == nil {
		t.Error("show should require token")
	}
	for _, id := range []string{"", "42", "../auth/logout", testGameID + "?x=1", testGameID + "/extra"} {
		if _, err := client.GetGame(context.Background(), id); err == nil || !strings.Contains(err.Error(), "UUID") {
			t.Errorf("accepted invalid ID %q", id)
		}
	}
}
