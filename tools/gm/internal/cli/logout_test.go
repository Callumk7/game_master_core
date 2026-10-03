package cli

import (
	"bytes"
	"errors"
	"net/http"
	"net/http/httptest"
	"strings"
	"testing"
)

func TestLogoutSavedSession(t *testing.T) {
	unsetToken(t)
	for _, code := range []int{200, 204, 401, 403, 500} {
		t.Run(http.StatusText(code), func(t *testing.T) {
			server := httptest.NewServer(http.HandlerFunc(func(w http.ResponseWriter, r *http.Request) {
				if r.Header.Get("Authorization") != "Bearer saved-secret" {
					t.Error("wrong logout token")
				}
				w.WriteHeader(code)
			}))
			defer server.Close()
			store := &memoryStore{tokens: map[string]string{server.URL: "saved-secret", "https://other.example.com": "other-secret"}}
			var stdout, stderr bytes.Buffer
			err := run([]string{"auth", "logout", "--base-url", server.URL}, &stdout, &stderr, "dev", authDependencies{store: store})
			if code == 200 || code == 204 || code == 401 {
				if err != nil {
					t.Fatal(err)
				}
				if store.deletes != 1 || store.tokens[server.URL] != "" || stdout.String() != "Logged out.\n" {
					t.Error("logout did not remove saved session")
				}
			} else {
				if err == nil || store.deletes != 0 || store.tokens[server.URL] != "saved-secret" || stdout.Len() != 0 {
					t.Error("failed revocation must preserve saved session")
				}
			}
			if store.tokens["https://other.example.com"] != "other-secret" || stderr.Len() != 0 {
				t.Error("unrelated session modified or unexpected stderr")
			}
		})
	}
}

func TestLogoutEnvironmentSession(t *testing.T) {
	t.Setenv("GM_TOKEN", "env-secret")
	server := httptest.NewServer(http.HandlerFunc(func(w http.ResponseWriter, r *http.Request) {
		if r.Header.Get("Authorization") != "Bearer env-secret" {
			t.Error("wrong environment token")
		}
		w.WriteHeader(200)
	}))
	defer server.Close()
	store := &memoryStore{tokens: map[string]string{server.URL: "unrelated-secret"}}
	var stdout, stderr bytes.Buffer
	if err := run([]string{"auth", "logout", "--base-url", server.URL}, &stdout, &stderr, "dev", authDependencies{store: store}); err != nil {
		t.Fatal(err)
	}
	if store.gets != 0 || store.sets != 0 || store.deletes != 0 || store.tokens[server.URL] != "unrelated-secret" {
		t.Error("environment logout must not touch keychain")
	}
	if !strings.Contains(stderr.String(), "unset GM_TOKEN") || stdout.String() != "Logged out.\n" {
		t.Error("missing environment logout instructions")
	}
	if strings.Contains(stdout.String()+stderr.String(), "env-secret") {
		t.Error("credential leaked")
	}
}

func TestLogoutNoSavedSession(t *testing.T) {
	unsetToken(t)
	store := &memoryStore{}
	var stdout, stderr bytes.Buffer
	// No token means no request; this intentionally points at a server that is not running.
	if err := run([]string{"auth", "logout", "--base-url", "http://localhost:4000"}, &stdout, &stderr, "dev", authDependencies{store: store}); err != nil {
		t.Fatal(err)
	}
	if !strings.Contains(stdout.String(), "Already logged out") || store.deletes != 0 || stderr.Len() != 0 {
		t.Error("expected idempotent logout")
	}
}

func TestLogoutStorageErrors(t *testing.T) {
	unsetToken(t)
	var stdout, stderr bytes.Buffer
	store := &memoryStore{getErr: errors.New("storage-secret")}
	err := run([]string{"auth", "logout"}, &stdout, &stderr, "dev", authDependencies{store: store})
	if err == nil || !strings.Contains(err.Error(), "could not read OS keychain") || strings.Contains(err.Error(), "storage-secret") {
		t.Fatalf("unexpected lookup error: %v", err)
	}
	server := httptest.NewServer(http.HandlerFunc(func(w http.ResponseWriter, r *http.Request) { w.WriteHeader(200) }))
	defer server.Close()
	store = &memoryStore{tokens: map[string]string{server.URL: "saved-secret"}, deleteErr: errors.New("storage-secret")}
	err = run([]string{"auth", "logout", "--base-url", server.URL}, &stdout, &stderr, "dev", authDependencies{store: store})
	if err == nil || !strings.Contains(err.Error(), "could not remove") || strings.Contains(err.Error(), "storage-secret") || stdout.Len() != 0 || store.tokens[server.URL] != "saved-secret" {
		t.Fatalf("unexpected deletion error: %v", err)
	}
}

func TestLogoutConnectionFailurePreservesSession(t *testing.T) {
	unsetToken(t)
	server := httptest.NewServer(http.HandlerFunc(func(http.ResponseWriter, *http.Request) {}))
	server.Close()
	store := &memoryStore{tokens: map[string]string{server.URL: "saved-secret"}}
	var stdout, stderr bytes.Buffer
	err := run([]string{"auth", "logout", "--base-url", server.URL}, &stdout, &stderr, "dev", authDependencies{store: store})
	if err == nil || store.deletes != 0 || store.tokens[server.URL] != "saved-secret" || stdout.Len() != 0 {
		t.Fatal("failed request should preserve credentials")
	}
}

func TestLogoutValidationAndHelp(t *testing.T) {
	t.Setenv("GM_TOKEN", "")
	store := &memoryStore{}
	deps := authDependencies{store: store}
	var stdout, stderr bytes.Buffer
	for _, args := range [][]string{
		{"auth", "logout"},
		{"auth", "logout", "extra"},
		{"auth", "logout", "--timeout", "0s"},
		{"auth", "logout", "--base-url", "http://remote.example.com"},
	} {
		if err := run(args, &stdout, &stderr, "dev", deps); err == nil {
			t.Errorf("expected validation error for %v", args)
		}
	}
	if store.gets != 0 || store.deletes != 0 {
		t.Error("invalid inputs must not touch keychain")
	}
	if err := run([]string{"auth", "logout", "--help"}, &stdout, &stderr, "dev", deps); err != nil {
		t.Fatal(err)
	}
	if !strings.Contains(stdout.String(), "Revoke GM_TOKEN") {
		t.Error("missing logout help")
	}
}
