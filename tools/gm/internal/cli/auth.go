package cli

import (
	"encoding/json"
	"errors"
	"fmt"
	"os"
	"strings"
	"time"

	"game-master/gm/internal/api"
	"game-master/gm/internal/credentials"

	"github.com/spf13/cobra"
	"golang.org/x/term"
)

const defaultBaseURL = "https://gamemastercore-production.up.railway.app"

type authDependencies struct {
	store        credentials.Store
	readPassword func() (string, error)
}

func defaultAuthDependencies() authDependencies {
	return authDependencies{
		store: credentials.Keyring{},
		readPassword: func() (string, error) {
			fd := int(os.Stdin.Fd())
			if !term.IsTerminal(fd) {
				return "", errors.New("login requires an interactive terminal for the hidden password prompt")
			}
			password, err := term.ReadPassword(fd)
			if err != nil {
				return "", errors.New("could not read password from terminal")
			}
			defer clear(password)
			return string(password), nil
		},
	}
}

func newAuthCommand(deps authDependencies) *cobra.Command {
	var baseURL string
	var timeout time.Duration
	origin := func(cmd *cobra.Command) (string, error) {
		value := baseURL
		if !cmd.Flags().Changed("base-url") {
			if env := os.Getenv("GM_BASE_URL"); env != "" {
				value = env
			}
		}
		return api.NormalizeOrigin(value)
	}
	auth := &cobra.Command{
		Use: "auth", Short: "Manage API authentication", Args: cobra.NoArgs,
		RunE: func(cmd *cobra.Command, args []string) error { return cmd.Help() },
	}
	auth.PersistentFlags().StringVar(&baseURL, "base-url", defaultBaseURL, "API origin (overrides GM_BASE_URL)")
	auth.PersistentFlags().DurationVar(&timeout, "timeout", 15*time.Second, "Request timeout")

	var jsonOutput bool
	status := &cobra.Command{
		Use: "status", Short: "Check the saved session or GM_TOKEN",
		Long: "Check authentication using GM_TOKEN if set, otherwise the session saved in the OS keychain for this API origin.",
		Args: cobra.NoArgs,
		RunE: func(cmd *cobra.Command, args []string) error {
			base, err := origin(cmd)
			if err != nil {
				return err
			}
			client, fromEnvironment, err := authenticatedClient(base, timeout, deps)
			if err != nil {
				return err
			}
			result, err := client.Status(cmd.Context())
			if err != nil {
				return err
			}
			if err := saveRenewal(cmd, deps, base, result.NewSessionToken, fromEnvironment); err != nil {
				return err
			}
			if jsonOutput {
				return json.NewEncoder(cmd.OutOrStdout()).Encode(result)
			}
			_, err = fmt.Fprintf(cmd.OutOrStdout(), "Authenticated as %s (user %s)\n", result.User.Email, result.User.ID)
			return err
		},
	}
	status.Flags().BoolVar(&jsonOutput, "json", false, "Output authentication status as JSON")

	var email string
	login := &cobra.Command{
		Use: "login", Short: "Log in and save a session to the OS keychain",
		Long: "Log in with --email and a hidden password prompt. Saves only the session token to the OS keychain for this API origin.",
		Args: cobra.NoArgs,
		RunE: func(cmd *cobra.Command, args []string) error {
			email = strings.TrimSpace(email)
			if email == "" {
				return errors.New("email is required")
			}
			base, err := origin(cmd)
			if err != nil {
				return err
			}
			client, err := api.NewClient(base, "", timeout)
			if err != nil {
				return err
			}
			if _, err := fmt.Fprint(cmd.ErrOrStderr(), "Password: "); err != nil {
				return err
			}
			password, readErr := deps.readPassword()
			if _, err := fmt.Fprintln(cmd.ErrOrStderr()); err != nil {
				return err
			}
			if readErr != nil {
				return errors.New("could not read password; login requires an interactive terminal")
			}
			result, err := client.Login(cmd.Context(), email, password)
			password = ""
			if err != nil {
				return err
			}
			if err := deps.store.Set(base, result.Token); err != nil {
				return errors.New("login succeeded but could not save session to OS keychain; ensure it is available and unlocked, then retry")
			}
			if _, set := os.LookupEnv("GM_TOKEN"); set {
				if _, err := fmt.Fprintln(cmd.ErrOrStderr(), "Warning: GM_TOKEN overrides the saved session. Unset GM_TOKEN to use this login."); err != nil {
					return err
				}
			}
			_, err = fmt.Fprintf(cmd.OutOrStdout(), "Logged in as %s (user %s). Session saved to OS keychain.\n", result.User.Email, result.User.ID)
			return err
		},
	}
	login.Flags().StringVar(&email, "email", "", "Account email address (required)")
	// Flag existence is guaranteed by registration above.
	if err := login.MarkFlagRequired("email"); err != nil {
		panic(err)
	}
	logout := &cobra.Command{
		Use: "logout", Short: "Revoke the session and remove saved credentials",
		Long: "Revoke GM_TOKEN if set, otherwise revoke and remove the saved session for this API origin. Environment overrides never modify the keychain.",
		Args: cobra.NoArgs,
		RunE: func(cmd *cobra.Command, args []string) error {
			base, err := origin(cmd)
			if err != nil {
				return err
			}
			// Validate configuration even when there is no saved session.
			if _, err := api.NewClient(base, "", timeout); err != nil {
				return err
			}
			token, fromEnvironment := os.LookupEnv("GM_TOKEN")
			if !fromEnvironment {
				token, err = deps.store.Get(base)
				if errors.Is(err, credentials.ErrNotFound) {
					_, err = fmt.Fprintln(cmd.OutOrStdout(), "Already logged out; no saved session for this API origin.")
					return err
				}
				if err != nil {
					return errors.New("could not read OS keychain; unlock it or provide GM_TOKEN")
				}
			}
			if strings.TrimSpace(token) == "" {
				return errors.New("GM_TOKEN or saved session is empty; provide a valid token or unset GM_TOKEN")
			}
			client, err := api.NewClient(base, token, timeout)
			if err != nil {
				return err
			}
			if err := client.Logout(cmd.Context()); err != nil {
				// Preserve saved credentials on failure so revocation can be retried.
				return err
			}
			if fromEnvironment {
				if _, err := fmt.Fprintln(cmd.ErrOrStderr(), "GM_TOKEN has been revoked or was already expired. Run 'unset GM_TOKEN' in your shell; saved credentials were left untouched."); err != nil {
					return err
				}
			} else if err := deps.store.Delete(base); err != nil {
				return errors.New("session revoked or already expired, but could not remove it from OS keychain; unlock the keychain and retry logout")
			}
			_, err = fmt.Fprintln(cmd.OutOrStdout(), "Logged out.")
			return err
		},
	}
	auth.AddCommand(status, login, logout)
	return auth
}
