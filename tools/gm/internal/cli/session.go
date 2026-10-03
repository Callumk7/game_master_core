package cli

import (
	"errors"
	"fmt"
	"os"
	"strings"
	"time"

	"game-master/gm/internal/api"
	"game-master/gm/internal/credentials"

	"github.com/spf13/cobra"
)

// authenticatedClient centralizes credential precedence for read-only commands.
func authenticatedClient(base string, timeout time.Duration, deps authDependencies) (*api.Client, bool, error) {
	if _, err := api.NewClient(base, "", timeout); err != nil {
		return nil, false, err
	}
	token, fromEnvironment := os.LookupEnv("GM_TOKEN")
	if !fromEnvironment {
		var err error
		token, err = deps.store.Get(base)
		if errors.Is(err, credentials.ErrNotFound) {
			return nil, false, errors.New("no saved session; run 'gm auth login --email you@example.com' or set GM_TOKEN")
		}
		if err != nil {
			return nil, false, errors.New("could not read OS keychain; unlock it or provide GM_TOKEN")
		}
	}
	if strings.TrimSpace(token) == "" {
		return nil, fromEnvironment, errors.New("GM_TOKEN or saved session is empty; run 'gm auth login' or set a valid GM_TOKEN")
	}
	client, err := api.NewClient(base, token, timeout)
	return client, fromEnvironment, err
}

func saveRenewal(cmd *cobra.Command, deps authDependencies, base, token string, fromEnvironment bool) error {
	if token == "" {
		return nil
	}
	if fromEnvironment {
		_, err := fmt.Fprintln(cmd.ErrOrStderr(), "Warning: the server renewed this session. Environment tokens are not saved; update GM_TOKEN when it expires or unset it and use 'gm auth login'.")
		return err
	}
	if err := deps.store.Set(base, token); err != nil {
		return errors.New("API request succeeded but could not save its renewed token to OS keychain")
	}
	return nil
}
