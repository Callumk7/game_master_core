package cli

import (
	"bytes"
	"errors"
	"net/http"
	"net/http/httptest"
	"os"
	"strings"
	"testing"

	"game-master/gm/internal/credentials"
)

type memoryStore struct {
	tokens                    map[string]string
	getErr, setErr, deleteErr error
	gets, sets, deletes       int
	lastOrigin                string
}

func (s *memoryStore) Get(origin string) (string, error) {
	s.gets++
	s.lastOrigin = origin
	if s.getErr != nil {
		return "", s.getErr
	}
	if token, ok := s.tokens[origin]; ok {
		return token, nil
	}
	return "", credentials.ErrNotFound
}
func (s *memoryStore) Set(origin, token string) error {
	s.sets++
	if s.setErr != nil {
		return s.setErr
	}
	if s.tokens == nil {
		s.tokens = make(map[string]string)
	}
	s.tokens[origin] = token
	return nil
}

func (s *memoryStore) Delete(origin string) error {
	s.deletes++
	if s.deleteErr != nil {
		return s.deleteErr
	}
	delete(s.tokens, origin)
	return nil
}

func unsetToken(t *testing.T) {
	t.Helper()
	t.Setenv("GM_TOKEN", "")
	if err := os.Unsetenv("GM_TOKEN"); err != nil {
		t.Fatal(err)
	}
}

func TestLoginAndSavedStatus(t *testing.T) {
	unsetToken(t)
	store := &memoryStore{}
	deps := authDependencies{store: store, readPassword: func() (string, error) { return "password-secret", nil }}
	server := httptest.NewServer(http.HandlerFunc(func(w http.ResponseWriter, r *http.Request) {
		switch r.URL.Path {
		case "/api/auth/login":
			_, _ = w.Write([]byte(`{"token":"session-secret","user":{"id":"c2d438d2-5f54-4d14-aef4-8194a1bc831f","email":"gm@example.com"}}`))
		case "/api/auth/status":
			if r.Header.Get("Authorization") != "Bearer session-secret" {
				t.Error("saved token not used")
			}
			w.Header().Set("X-New-Session-Token", "renewed-secret")
			_, _ = w.Write([]byte(`{"authenticated":true,"user":{"id":"c2d438d2-5f54-4d14-aef4-8194a1bc831f","email":"gm@example.com"}}`))
		default:
			t.Error("unexpected endpoint")
		}
	}))
	defer server.Close()
	t.Setenv("GM_BASE_URL", server.URL)
	var stdout, stderr bytes.Buffer
	if err := run([]string{"auth", "login", "--email", "gm@example.com"}, &stdout, &stderr, "dev", deps); err != nil {
		t.Fatal(err)
	}
	if store.tokens[server.URL] != "session-secret" || !strings.Contains(stdout.String(), "Logged in as gm@example.com") || stderr.String() != "Password: \n" {
		t.Error("login did not save and report session correctly")
	}
	if err := run([]string{"auth", "status", "--json"}, &stdout, &stderr, "dev", deps); err != nil {
		t.Fatal(err)
	}
	if store.tokens[server.URL] != "renewed-secret" || store.sets != 2 {
		t.Error("renewed saved session was not persisted")
	}
	for _, secret := range []string{"password-secret", "session-secret", "renewed-secret"} {
		if strings.Contains(stdout.String()+stderr.String(), secret) {
			t.Error("secret leaked to output")
		}
	}
}

func TestLoginFailuresDoNotSave(t *testing.T) {
	unsetToken(t)
	for _, code := range []int{401, 403, 500} {
		server := httptest.NewServer(http.HandlerFunc(func(w http.ResponseWriter, r *http.Request) {
			w.WriteHeader(code)
			_, _ = w.Write([]byte("password-secret"))
		}))
		store := &memoryStore{tokens: map[string]string{server.URL: "previous-session"}}
		var stdout, stderr bytes.Buffer
		deps := authDependencies{store: store, readPassword: func() (string, error) { return "password-secret", nil }}
		err := run([]string{"auth", "login", "--email", "gm@example.com", "--base-url", server.URL}, &stdout, &stderr, "dev", deps)
		server.Close()
		if err == nil || store.sets != 0 || store.tokens[server.URL] != "previous-session" || stdout.Len() != 0 {
			t.Error("failed login must preserve existing session and return error")
		}
		if strings.Contains(err.Error()+stderr.String(), "password-secret") {
			t.Error("password leaked")
		}
	}
}

func TestLoginStorageFailure(t *testing.T) {
	unsetToken(t)
	server := httptest.NewServer(http.HandlerFunc(func(w http.ResponseWriter, r *http.Request) {
		_, _ = w.Write([]byte(`{"token":"session-secret","user":{"id":"c2d438d2-5f54-4d14-aef4-8194a1bc831f","email":"gm@example.com"}}`))
	}))
	defer server.Close()
	store := &memoryStore{setErr: errors.New("session-secret")}
	deps := authDependencies{store: store, readPassword: func() (string, error) { return "password-secret", nil }}
	var stdout, stderr bytes.Buffer
	err := run([]string{"auth", "login", "--email", "gm@example.com", "--base-url", server.URL}, &stdout, &stderr, "dev", deps)
	if err == nil || !strings.Contains(err.Error(), "login succeeded but could not save") || strings.Contains(err.Error(), "session-secret") || stdout.Len() != 0 {
		t.Fatalf("unexpected storage failure: %v", err)
	}
}

func TestLoginValidationDoesNotPrompt(t *testing.T) {
	deps := authDependencies{store: &memoryStore{}, readPassword: func() (string, error) { t.Error("unexpected password prompt"); return "", nil }}
	for _, args := range [][]string{
		{"auth", "login"},
		{"auth", "login", "--email", " "},
		{"auth", "login", "--email", "gm@example.com", "--base-url", "http://remote.example.com"},
		{"auth", "login", "--email", "gm@example.com", "--timeout", "0s"},
		{"auth", "login", "--email", "gm@example.com", "--password", "secret"},
	} {
		var stdout, stderr bytes.Buffer
		if err := run(args, &stdout, &stderr, "dev", deps); err == nil {
			t.Errorf("expected error for %v", args)
		}
	}
	var stdout, stderr bytes.Buffer
	if err := run([]string{"auth", "login", "--help"}, &stdout, &stderr, "dev", deps); err != nil {
		t.Fatal(err)
	}
}

func TestPasswordReadFailure(t *testing.T) {
	store := &memoryStore{}
	deps := authDependencies{store: store, readPassword: func() (string, error) { return "", errors.New("password-secret") }}
	var stdout, stderr bytes.Buffer
	err := run([]string{"auth", "login", "--email", "gm@example.com", "--base-url", "http://localhost:4000"}, &stdout, &stderr, "dev", deps)
	if err == nil || !strings.Contains(err.Error(), "interactive terminal") || strings.Contains(err.Error(), "password-secret") || store.sets != 0 {
		t.Fatalf("unexpected read failure: %v", err)
	}
}

func TestEnvironmentTokenDoesNotTouchStorage(t *testing.T) {
	t.Setenv("GM_TOKEN", "env-secret")
	store := &memoryStore{}
	server := httptest.NewServer(http.HandlerFunc(func(w http.ResponseWriter, r *http.Request) {
		if r.Header.Get("Authorization") != "Bearer env-secret" {
			t.Error("environment token did not take precedence")
		}
		w.Header().Set("X-New-Session-Token", "renewed-secret")
		_, _ = w.Write([]byte(`{"authenticated":true,"user":{"id":"c2d438d2-5f54-4d14-aef4-8194a1bc831f","email":"gm@example.com"}}`))
	}))
	defer server.Close()
	var stdout, stderr bytes.Buffer
	if err := run([]string{"auth", "status", "--base-url", server.URL}, &stdout, &stderr, "dev", authDependencies{store: store}); err != nil {
		t.Fatal(err)
	}
	if store.gets != 0 || store.sets != 0 {
		t.Error("environment credentials must not touch keychain")
	}
}

func TestSavedStatusFailures(t *testing.T) {
	unsetToken(t)
	for _, getErr := range []error{credentials.ErrNotFound, errors.New("storage-secret")} {
		var stdout, stderr bytes.Buffer
		err := run([]string{"auth", "status", "--base-url", "http://localhost:4000"}, &stdout, &stderr, "dev", authDependencies{store: &memoryStore{getErr: getErr}})
		if err == nil || strings.Contains(err.Error(), "storage-secret") || stdout.Len() != 0 {
			t.Fatalf("unexpected result: %v", err)
		}
	}
	server := httptest.NewServer(http.HandlerFunc(func(w http.ResponseWriter, r *http.Request) {
		w.Header().Set("X-New-Session-Token", "renewed-secret")
		_, _ = w.Write([]byte(`{"authenticated":true,"user":{"id":"c2d438d2-5f54-4d14-aef4-8194a1bc831f","email":"gm@example.com"}}`))
	}))
	defer server.Close()
	store := &memoryStore{tokens: map[string]string{server.URL: "old-secret"}, setErr: errors.New("storage-secret")}
	var stdout, stderr bytes.Buffer
	err := run([]string{"auth", "status", "--base-url", server.URL}, &stdout, &stderr, "dev", authDependencies{store: store})
	if err == nil || !strings.Contains(err.Error(), "renewed token") || strings.Contains(err.Error(), "storage-secret") || stdout.Len() != 0 || store.tokens[server.URL] != "old-secret" {
		t.Fatalf("unexpected renewal failure: %v", err)
	}
}

func TestLoginWarnsAboutEnvironmentOverride(t *testing.T) {
	t.Setenv("GM_TOKEN", "env-secret")
	server := httptest.NewServer(http.HandlerFunc(func(w http.ResponseWriter, r *http.Request) {
		_, _ = w.Write([]byte(`{"token":"session-secret","user":{"id":"c2d438d2-5f54-4d14-aef4-8194a1bc831f","email":"gm@example.com"}}`))
	}))
	defer server.Close()
	var stdout, stderr bytes.Buffer
	store := &memoryStore{}
	err := run([]string{"auth", "login", "--email", "gm@example.com", "--base-url", server.URL}, &stdout, &stderr, "dev", authDependencies{store: store, readPassword: func() (string, error) { return "password-secret", nil }})
	if err != nil || !strings.Contains(stderr.String(), "GM_TOKEN overrides") || store.tokens[server.URL] != "session-secret" {
		t.Fatalf("unexpected login: %v", err)
	}
}
