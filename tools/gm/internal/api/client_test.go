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

func TestStatus(t *testing.T) {
	server := httptest.NewServer(http.HandlerFunc(func(w http.ResponseWriter, r *http.Request) {
		if r.Method != http.MethodGet || r.URL.Path != "/api/auth/status" {
			t.Errorf("unexpected request: %s %s", r.Method, r.URL.Path)
		}
		if r.Header.Get("Authorization") != "Bearer session-token" || r.Header.Get("Accept") != "application/json" {
			t.Error("missing request headers")
		}
		w.Header().Set("Content-Type", "application/json")
		w.Header().Set("X-New-Session-Token", "renewed-secret")
		_, _ = w.Write([]byte(`{"authenticated":true,"user":{"id":"c2d438d2-5f54-4d14-aef4-8194a1bc831f","email":"gm@example.com","username":"gm","avatar_url":null}}`))
	}))
	defer server.Close()
	client, err := NewClient(server.URL+"/", "session-token", time.Second)
	if err != nil {
		t.Fatal(err)
	}
	status, err := client.Status(context.Background())
	if err != nil {
		t.Fatal(err)
	}
	if !status.Authenticated || status.User.ID != "c2d438d2-5f54-4d14-aef4-8194a1bc831f" || status.NewSessionToken != "renewed-secret" {
		t.Fatalf("unexpected status: authenticated=%v user=%v", status.Authenticated, status.User)
	}
	output, err := json.Marshal(status)
	if err != nil || strings.Contains(string(output), "renewed-secret") {
		t.Fatal("JSON output must not include renewed credentials")
	}
}

func TestStatusErrors(t *testing.T) {
	tests := []struct {
		name string
		code int
		body string
		want string
	}{
		{"unauthorized", 401, `{"error":"session-token"}`, "invalid or expired"},
		{"forbidden", 403, "session-token", "HTTP 403"},
		{"server error", 500, "session-token", "HTTP 500"},
		{"redirect", 302, "session-token", "HTTP 302"},
		{"not authenticated", 200, `{"authenticated":false}`, "not authenticated"},
		{"missing authenticated", 200, `{}`, "invalid authentication response"},
		{"invalid JSON", 200, `<html>session-token</html>`, "invalid authentication response"},
		{"trailing JSON", 200, `{"authenticated":false} {}`, "invalid authentication response"},
		{"missing user", 200, `{"authenticated":true}`, "invalid authenticated user"},
		{"invalid user", 200, `{"authenticated":true,"user":{"id":""}}`, "invalid authenticated user"},
		{"too large", 200, strings.Repeat("x", maxResponseBytes+1), "size limit"},
	}
	for _, tt := range tests {
		t.Run(tt.name, func(t *testing.T) {
			server := httptest.NewServer(http.HandlerFunc(func(w http.ResponseWriter, r *http.Request) {
				w.WriteHeader(tt.code)
				_, _ = w.Write([]byte(tt.body))
			}))
			defer server.Close()
			client, err := NewClient(server.URL, "session-token", time.Second)
			if err != nil {
				t.Fatal(err)
			}
			_, err = client.Status(context.Background())
			if err == nil || !strings.Contains(err.Error(), tt.want) || strings.Contains(err.Error(), "session-token") {
				t.Fatalf("unexpected error: %v", err)
			}
		})
	}
}

func TestClientValidation(t *testing.T) {
	for _, baseURL := range []string{"", "not-a-url", "ftp://localhost", "http://example.com", "https://user:secret@example.com", "https://example.com/api", "https://example.com?token=secret", "https://example.com#secret"} {
		if _, err := NewClient(baseURL, "secret", time.Second); err == nil {
			t.Errorf("accepted invalid URL %q", baseURL)
		}
	}
	for _, baseURL := range []string{"https://example.com", "http://localhost:4000", "http://127.0.0.1:4000", "http://[::1]:4000"} {
		if _, err := NewClient(baseURL, "secret", time.Second); err != nil {
			t.Errorf("rejected URL %q: %v", baseURL, err)
		}
	}
	for _, token := range []string{"Bearer secret", "secret\nheader", "secret\x00token"} {
		if _, err := NewClient("http://localhost:4000", token, time.Second); err == nil {
			t.Error("accepted invalid token")
		}
	}
	if _, err := NewClient("http://localhost:4000", "secret", 0); err == nil {
		t.Error("accepted nonpositive timeout")
	}
}

func TestRedirectIsNotFollowed(t *testing.T) {
	server := httptest.NewServer(http.HandlerFunc(func(w http.ResponseWriter, r *http.Request) {
		if r.URL.Path != "/api/auth/status" {
			t.Error("redirect was followed")
		}
		http.Redirect(w, r, "/unexpected", http.StatusFound)
	}))
	defer server.Close()
	client, err := NewClient(server.URL, "secret", time.Second)
	if err != nil {
		t.Fatal(err)
	}
	if _, err := client.Status(context.Background()); err == nil || !strings.Contains(err.Error(), "HTTP 302") {
		t.Fatalf("unexpected redirect result: %v", err)
	}
}

func TestTimeoutAndCancellation(t *testing.T) {
	server := httptest.NewServer(http.HandlerFunc(func(w http.ResponseWriter, r *http.Request) {
		<-r.Context().Done()
	}))
	defer server.Close()
	client, err := NewClient(server.URL, "secret", 20*time.Millisecond)
	if err != nil {
		t.Fatal(err)
	}
	if _, err := client.Status(context.Background()); err == nil || !strings.Contains(err.Error(), "timed out") {
		t.Fatalf("expected timeout: %v", err)
	}
	ctx, cancel := context.WithCancel(context.Background())
	cancel()
	if _, err := client.Status(ctx); err == nil || !strings.Contains(err.Error(), "canceled") {
		t.Fatalf("expected cancellation: %v", err)
	}
}

func TestConnectionFailure(t *testing.T) {
	server := httptest.NewServer(http.HandlerFunc(func(http.ResponseWriter, *http.Request) {}))
	server.Close()
	client, err := NewClient(server.URL, "secret", time.Second)
	if err != nil {
		t.Fatal(err)
	}
	if _, err := client.Status(context.Background()); err == nil || !strings.Contains(err.Error(), "could not connect") {
		t.Fatalf("expected connection failure: %v", err)
	}
}
