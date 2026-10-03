package api

import (
	"context"
	"net/http"
	"net/http/httptest"
	"strings"
	"testing"
	"time"
)

func TestLogoutRenewalIsValidatedAndBounded(t *testing.T) {
	for _, tt := range []struct {
		name, token, want string
		calls             int
	}{
		{"invalid token", "bad token", "invalid renewed token", 1},
		{"repeated renewal", "renewed-secret", "unexpectedly renewed", 2},
	} {
		t.Run(tt.name, func(t *testing.T) {
			calls := 0
			server := httptest.NewServer(http.HandlerFunc(func(w http.ResponseWriter, r *http.Request) {
				calls++
				w.Header().Set("X-New-Session-Token", tt.token)
				w.WriteHeader(200)
			}))
			defer server.Close()
			client, err := NewClient(server.URL, "old-secret", time.Second)
			if err != nil {
				t.Fatal(err)
			}
			err = client.Logout(context.Background())
			if err == nil || !strings.Contains(err.Error(), tt.want) || strings.Contains(err.Error(), tt.token) {
				t.Fatalf("unexpected error: %v", err)
			}
			if calls != tt.calls {
				t.Errorf("got %d requests, want %d", calls, tt.calls)
			}
		})
	}
}
