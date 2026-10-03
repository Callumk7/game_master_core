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

func TestLogin(t *testing.T) {
	server := httptest.NewServer(http.HandlerFunc(func(w http.ResponseWriter, r *http.Request) {
		if r.Method != http.MethodPost || r.URL.Path != "/api/auth/login" || r.Header.Get("Content-Type") != "application/json" || r.Header.Get("Accept") != "application/json" {
			t.Error("incorrect login request")
		}
		if r.Header.Get("Authorization") != "" {
			t.Error("login must not send an existing session")
		}
		var payload map[string]string
		if err := json.NewDecoder(r.Body).Decode(&payload); err != nil || payload["email"] != "gm@example.com" || payload["password"] != " secret password " {
			t.Error("incorrect credentials payload")
		}
		_, _ = w.Write([]byte(`{"token":"new-session","user":{"id":"c2d438d2-5f54-4d14-aef4-8194a1bc831f","email":"gm@example.com","username":"gm"}}`))
	}))
	defer server.Close()
	client, err := NewClient(server.URL, "old-session", time.Second)
	if err != nil {
		t.Fatal(err)
	}
	result, err := client.Login(context.Background(), "gm@example.com", " secret password ")
	if err != nil {
		t.Fatal(err)
	}
	if result.Token != "new-session" || result.User.ID != "c2d438d2-5f54-4d14-aef4-8194a1bc831f" {
		t.Error("incorrect login result")
	}
	output, err := json.Marshal(result)
	if err != nil || strings.Contains(string(output), "new-session") {
		t.Error("login result leaked token in JSON")
	}
}

func TestLoginFailures(t *testing.T) {
	tests := []struct {
		name       string
		code       int
		body, want string
	}{
		{"invalid credentials", 401, `{"error":"password-secret"}`, "invalid email or password"},
		{"unconfirmed email", 403, `{"error":"password-secret"}`, "confirm your email"},
		{"server error", 500, "password-secret", "HTTP 500"},
		{"redirect", 302, "password-secret", "HTTP 302"},
		{"malformed", 200, "password-secret", "invalid login response"},
		{"missing token", 200, `{"user":{"id":"c2d438d2-5f54-4d14-aef4-8194a1bc831f","email":"gm@example.com"}}`, "invalid login response"},
		{"missing user", 200, `{"token":"session"}`, "invalid login response"},
		{"empty user ID", 200, `{"token":"session","user":{"id":"","email":"gm@example.com"}}`, "invalid login response"},
		{"numeric user ID", 200, `{"token":"session","user":{"id":1,"email":"gm@example.com"}}`, "invalid login response"},
		{"invalid token", 200, `{"token":"Bearer session","user":{"id":"c2d438d2-5f54-4d14-aef4-8194a1bc831f","email":"gm@example.com"}}`, "invalid login response"},
		{"oversized", 200, strings.Repeat("x", maxResponseBytes+1), "size limit"},
	}
	for _, tt := range tests {
		t.Run(tt.name, func(t *testing.T) {
			server := httptest.NewServer(http.HandlerFunc(func(w http.ResponseWriter, r *http.Request) {
				w.WriteHeader(tt.code)
				_, _ = w.Write([]byte(tt.body))
			}))
			defer server.Close()
			client, err := NewClient(server.URL, "", time.Second)
			if err != nil {
				t.Fatal(err)
			}
			_, err = client.Login(context.Background(), "gm@example.com", "password-secret")
			if err == nil || !strings.Contains(err.Error(), tt.want) || strings.Contains(err.Error(), "password-secret") {
				t.Fatalf("unexpected error: %v", err)
			}
		})
	}
}

func TestLoginDoesNotFollowRedirect(t *testing.T) {
	server := httptest.NewServer(http.HandlerFunc(func(w http.ResponseWriter, r *http.Request) {
		if r.URL.Path != "/api/auth/login" {
			t.Error("login redirect was followed")
		}
		http.Redirect(w, r, "/unexpected", http.StatusTemporaryRedirect)
	}))
	defer server.Close()
	client, err := NewClient(server.URL, "", time.Second)
	if err != nil {
		t.Fatal(err)
	}
	if _, err := client.Login(context.Background(), "gm@example.com", "secret"); err == nil || !strings.Contains(err.Error(), "HTTP 307") {
		t.Fatalf("unexpected result: %v", err)
	}
}

func TestOriginNormalization(t *testing.T) {
	for input, want := range map[string]string{
		"https://API.example.com:443/": "https://api.example.com",
		"http://LOCALHOST:80/":         "http://localhost",
		"http://[::1]:4000/":           "http://[::1]:4000",
	} {
		got, err := NormalizeOrigin(input)
		if err != nil || got != want {
			t.Errorf("NormalizeOrigin(%q) = %q, %v; want %q", input, got, err, want)
		}
	}
}

func TestMissingCredentials(t *testing.T) {
	client, err := NewClient("http://localhost:4000", "", time.Second)
	if err != nil {
		t.Fatal(err)
	}
	if _, err := client.Status(context.Background()); err == nil {
		t.Error("status should require token")
	}
	if _, err := client.Login(context.Background(), "gm@example.com", ""); err == nil {
		t.Error("login should require password")
	}
	if _, err := client.Login(context.Background(), "", "secret"); err == nil {
		t.Error("login should require email")
	}
}
