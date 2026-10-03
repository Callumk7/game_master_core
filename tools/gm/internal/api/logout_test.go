package api

import (
	"context"
	"net/http"
	"net/http/httptest"
	"strings"
	"testing"
	"time"
)

func TestLogout(t *testing.T) {
	for _, code := range []int{200, 204, 401, 403, 500, 302} {
		t.Run(http.StatusText(code), func(t *testing.T) {
			calls := 0
			server := httptest.NewServer(http.HandlerFunc(func(w http.ResponseWriter, r *http.Request) {
				calls++
				if r.Method != http.MethodDelete || r.URL.Path != "/api/auth/logout" || r.Header.Get("Authorization") != "Bearer session-secret" || r.Header.Get("Accept") != "application/json" {
					t.Error("incorrect logout request")
				}
				w.Header().Set("Location", "/unexpected")
				w.WriteHeader(code)
				if code != 204 {
					_, _ = w.Write([]byte("session-secret"))
				}
			}))
			defer server.Close()
			client, err := NewClient(server.URL, "session-secret", time.Second)
			if err != nil {
				t.Fatal(err)
			}
			err = client.Logout(context.Background())
			if code == 200 || code == 204 || code == 401 {
				if err != nil {
					t.Fatal(err)
				}
			} else if err == nil || strings.Contains(err.Error(), "session-secret") {
				t.Fatalf("expected safe logout error: %v", err)
			}
			if calls != 1 {
				t.Errorf("expected one request, got %d", calls)
			}
		})
	}
}

func TestLogoutRevokesRenewedSession(t *testing.T) {
	for _, secondCode := range []int{200, 401, 500} {
		t.Run(http.StatusText(secondCode), func(t *testing.T) {
			calls := 0
			server := httptest.NewServer(http.HandlerFunc(func(w http.ResponseWriter, r *http.Request) {
				calls++
				if calls == 1 {
					if r.Header.Get("Authorization") != "Bearer old-secret" {
						t.Error("incorrect original token")
					}
					w.Header().Set("X-New-Session-Token", "renewed-secret")
					w.WriteHeader(200)
				} else {
					if r.Header.Get("Authorization") != "Bearer renewed-secret" {
						t.Error("renewed token was not revoked")
					}
					w.WriteHeader(secondCode)
				}
			}))
			defer server.Close()
			client, err := NewClient(server.URL, "old-secret", time.Second)
			if err != nil {
				t.Fatal(err)
			}
			err = client.Logout(context.Background())
			if secondCode == 500 {
				if err == nil || !strings.Contains(err.Error(), "could not revoke") {
					t.Fatalf("expected revocation failure: %v", err)
				}
			} else if err != nil {
				t.Fatal(err)
			}
			if calls != 2 {
				t.Errorf("expected two revocations, got %d", calls)
			}
		})
	}
}

func TestLogoutMissingTokenAndConnectionFailure(t *testing.T) {
	client, err := NewClient("http://localhost:4000", "", time.Second)
	if err != nil {
		t.Fatal(err)
	}
	if err := client.Logout(context.Background()); err == nil {
		t.Error("logout should require a token")
	}
	server := httptest.NewServer(http.HandlerFunc(func(http.ResponseWriter, *http.Request) {}))
	server.Close()
	client, err = NewClient(server.URL, "secret", time.Second)
	if err != nil {
		t.Fatal(err)
	}
	if err := client.Logout(context.Background()); err == nil || !strings.Contains(err.Error(), "could not connect") {
		t.Fatalf("expected connection failure: %v", err)
	}
}

func TestLogoutCancellationAndTimeout(t *testing.T) {
	server := httptest.NewServer(http.HandlerFunc(func(w http.ResponseWriter, r *http.Request) { <-r.Context().Done() }))
	defer server.Close()
	client, err := NewClient(server.URL, "secret", 20*time.Millisecond)
	if err != nil {
		t.Fatal(err)
	}
	if err := client.Logout(context.Background()); err == nil || !strings.Contains(err.Error(), "timed out") {
		t.Fatalf("expected timeout: %v", err)
	}
	ctx, cancel := context.WithCancel(context.Background())
	cancel()
	if err := client.Logout(ctx); err == nil || !strings.Contains(err.Error(), "canceled") {
		t.Fatalf("expected cancellation: %v", err)
	}
}
