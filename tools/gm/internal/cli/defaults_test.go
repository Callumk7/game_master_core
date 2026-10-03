package cli

import (
	"bytes"
	"strings"
	"testing"
)

func TestProductionOriginIsDefault(t *testing.T) {
	unsetToken(t)
	t.Setenv("GM_BASE_URL", "")
	const want = "https://gamemastercore-production.up.railway.app"
	store := &memoryStore{}
	deps := authDependencies{store: store}
	var stdout, stderr bytes.Buffer
	// A missing saved session stops execution before any network request.
	for _, args := range [][]string{{"auth", "status"}, {"games", "list"}, {"games", "show", gameID}} {
		if err := run(args, &stdout, &stderr, "dev", deps); err == nil {
			t.Fatal("expected missing session error")
		}
		if store.lastOrigin != want {
			t.Errorf("default origin for %v = %q, want %q", args, store.lastOrigin, want)
		}
	}
	for _, command := range []string{"login", "status"} {
		stdout.Reset()
		if err := run([]string{"auth", command, "--help"}, &stdout, &stderr, "dev", deps); err != nil {
			t.Fatal(err)
		}
		if !strings.Contains(stdout.String(), want) {
			t.Errorf("%s help missing production default", command)
		}
	}
}
