package cli

import (
	"bytes"
	"errors"
	"io"
	"strings"
	"testing"
)

func TestHelp(t *testing.T) {
	for _, args := range [][]string{nil, {}, {"help"}, {"--help"}, {"-h"}} {
		t.Run(strings.Join(args, " "), func(t *testing.T) {
			var stdout, stderr bytes.Buffer
			if err := Run(args, &stdout, &stderr, "dev"); err != nil {
				t.Fatalf("unexpected error: %v", err)
			}
			for _, want := range []string{"Game Master API CLI", "Usage:", "version", "completion", "--help", "--version"} {
				if !strings.Contains(stdout.String(), want) {
					t.Errorf("help missing %q: %s", want, stdout.String())
				}
			}
			if stderr.Len() != 0 {
				t.Errorf("unexpected stderr: %s", stderr.String())
			}
		})
	}
}

func TestVersion(t *testing.T) {
	for _, args := range [][]string{{"version"}, {"--version"}} {
		var stdout, stderr bytes.Buffer
		if err := Run(args, &stdout, &stderr, "test-version"); err != nil {
			t.Fatalf("unexpected error: %v", err)
		}
		if got := stdout.String(); got != "gm test-version\n" {
			t.Errorf("stdout = %q", got)
		}
		if stderr.Len() != 0 {
			t.Errorf("unexpected stderr: %s", stderr.String())
		}
	}
}

func TestCommandErrors(t *testing.T) {
	tests := []struct {
		args []string
		want string
	}{
		{[]string{"unknown"}, "unknown command"},
		{[]string{"version", "extra"}, "unknown command"},
		{[]string{"--unknown"}, "unknown flag"},
		{[]string{"version", "--unknown"}, "unknown flag"},
	}
	for _, tt := range tests {
		t.Run(strings.Join(tt.args, " "), func(t *testing.T) {
			var stdout, stderr bytes.Buffer
			err := Run(tt.args, &stdout, &stderr, "dev")
			if err == nil || !strings.Contains(err.Error(), tt.want) {
				t.Fatalf("error = %v, want containing %q", err, tt.want)
			}
			// main owns error reporting; Cobra must not print duplicates or usage.
			if stdout.Len() != 0 || stderr.Len() != 0 {
				t.Errorf("unexpected output: stdout=%q stderr=%q", stdout.String(), stderr.String())
			}
		})
	}
}

func TestCommandTreeIsFresh(t *testing.T) {
	if err := Run([]string{"--help"}, io.Discard, io.Discard, "dev"); err != nil {
		t.Fatal(err)
	}
	var stdout bytes.Buffer
	if err := Run([]string{"version"}, &stdout, io.Discard, "next"); err != nil {
		t.Fatal(err)
	}
	if got := stdout.String(); got != "gm next\n" {
		t.Errorf("flags or version leaked between runs: %q", got)
	}
}

func TestCompletion(t *testing.T) {
	var stdout bytes.Buffer
	if err := Run([]string{"completion", "bash"}, &stdout, io.Discard, "dev"); err != nil {
		t.Fatal(err)
	}
	if !strings.Contains(stdout.String(), "__start_gm") {
		t.Error("expected generated bash completion script")
	}
}

type failingWriter struct {
	err error
}

func (w failingWriter) Write([]byte) (int, error) {
	return 0, w.err
}

func TestVersionPropagatesOutputErrors(t *testing.T) {
	want := errors.New("output unavailable")
	if err := Run([]string{"version"}, failingWriter{err: want}, io.Discard, "dev"); !errors.Is(err, want) {
		t.Errorf("error = %v, want %v", err, want)
	}
}
