package cli

import (
	"bytes"
	"encoding/json"
	"net/http"
	"net/http/httptest"
	"strings"
	"testing"
)

func TestAuthStatus(t *testing.T) {
	t.Setenv("GM_TOKEN", "test-secret")
	server := httptest.NewServer(http.HandlerFunc(func(w http.ResponseWriter, r *http.Request) {
		if r.URL.Path != "/api/auth/status" || r.Header.Get("Authorization") != "Bearer test-secret" {
			t.Error("incorrect auth request")
		}
		w.Header().Set("X-New-Session-Token", "renewed-secret")
		_, _ = w.Write([]byte(`{"authenticated":true,"user":{"id":"c2d438d2-5f54-4d14-aef4-8194a1bc831f","email":"gm@example.com","username":"gm"}}`))
	}))
	defer server.Close()
	t.Setenv("GM_BASE_URL", server.URL)

	for _, jsonOutput := range []bool{false, true} {
		var stdout, stderr bytes.Buffer
		args := []string{"auth", "status"}
		if jsonOutput {
			args = append(args, "--json")
		}
		if err := Run(args, &stdout, &stderr, "dev"); err != nil {
			t.Fatal(err)
		}
		if jsonOutput {
			var result struct {
				Authenticated bool `json:"authenticated"`
				User          struct {
					ID string `json:"id"`
				} `json:"user"`
			}
			if err := json.Unmarshal(stdout.Bytes(), &result); err != nil || !result.Authenticated || result.User.ID != "c2d438d2-5f54-4d14-aef4-8194a1bc831f" {
				t.Fatalf("invalid JSON output: %s (%v)", stdout.String(), err)
			}
		} else if stdout.String() != "Authenticated as gm@example.com (user c2d438d2-5f54-4d14-aef4-8194a1bc831f)\n" {
			t.Errorf("unexpected output: %s", stdout.String())
		}
		if !strings.Contains(stderr.String(), "server renewed") {
			t.Error("missing session renewal warning")
		}
		for _, secret := range []string{"test-secret", "renewed-secret"} {
			if strings.Contains(stdout.String()+stderr.String(), secret) {
				t.Error("credential leaked in output")
			}
		}
	}
}

func TestAuthStatusFlagOverridesEnvironment(t *testing.T) {
	t.Setenv("GM_TOKEN", "test-secret")
	t.Setenv("GM_BASE_URL", "not-a-url")
	server := httptest.NewServer(http.HandlerFunc(func(w http.ResponseWriter, r *http.Request) {
		_, _ = w.Write([]byte(`{"authenticated":true,"user":{"id":"c2d438d2-5f54-4d14-aef4-8194a1bc831f","email":"gm@example.com"}}`))
	}))
	defer server.Close()
	var stdout, stderr bytes.Buffer
	if err := Run([]string{"auth", "status", "--base-url", server.URL}, &stdout, &stderr, "dev"); err != nil {
		t.Fatal(err)
	}
	if stderr.Len() != 0 {
		t.Errorf("unexpected stderr: %s", stderr.String())
	}
}

func TestAuthHelpDoesNotRequireCredentials(t *testing.T) {
	t.Setenv("GM_TOKEN", "")
	t.Setenv("GM_BASE_URL", "invalid")
	for _, args := range [][]string{{"auth"}, {"auth", "--help"}, {"auth", "status", "--help"}} {
		var stdout, stderr bytes.Buffer
		if err := Run(args, &stdout, &stderr, "dev"); err != nil {
			t.Fatal(err)
		}
		if !strings.Contains(stdout.String(), "Usage:") || stderr.Len() != 0 {
			t.Error("expected help on stdout only")
		}
	}
}

func TestAuthStatusErrors(t *testing.T) {
	t.Setenv("GM_BASE_URL", "http://localhost:4000")
	t.Setenv("GM_TOKEN", "")
	var stdout, stderr bytes.Buffer
	if err := Run([]string{"auth", "status"}, &stdout, &stderr, "dev"); err == nil || !strings.Contains(err.Error(), "session is empty") {
		t.Fatalf("expected missing token error: %v", err)
	}
	t.Setenv("GM_TOKEN", "test-secret")
	for _, args := range [][]string{
		{"auth", "status", "--timeout", "0s"},
		{"auth", "status", "--timeout", "invalid"},
		{"auth", "status", "extra"},
	} {
		if err := Run(args, &stdout, &stderr, "dev"); err == nil {
			t.Errorf("expected error for %v", args)
		}
	}
	server := httptest.NewServer(http.HandlerFunc(func(w http.ResponseWriter, r *http.Request) {
		w.WriteHeader(http.StatusUnauthorized)
		_, _ = w.Write([]byte(`{"error":"test-secret"}`))
	}))
	defer server.Close()
	if err := Run([]string{"auth", "status", "--base-url", server.URL, "--json"}, &stdout, &stderr, "dev"); err == nil || !strings.Contains(err.Error(), "expired") {
		t.Fatalf("expected expired session error: %v", err)
	}
	if stdout.Len() != 0 || stderr.Len() != 0 {
		t.Error("failed commands should return errors without printing results")
	}
}
