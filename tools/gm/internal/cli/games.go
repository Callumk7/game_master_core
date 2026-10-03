package cli

import (
	"encoding/json"
	"fmt"
	"io"
	"os"
	"strings"
	"text/tabwriter"
	"time"
	"unicode"

	"game-master/gm/internal/api"

	"github.com/spf13/cobra"
)

func newGamesCommand(deps authDependencies) *cobra.Command {
	var baseURL string
	var timeout time.Duration
	var jsonOutput bool
	games := &cobra.Command{
		Use: "games", Short: "Browse games accessible to your account", Args: cobra.NoArgs,
		RunE: func(cmd *cobra.Command, args []string) error { return cmd.Help() },
	}
	games.PersistentFlags().StringVar(&baseURL, "base-url", defaultBaseURL, "API origin (overrides GM_BASE_URL)")
	games.PersistentFlags().DurationVar(&timeout, "timeout", 15*time.Second, "Request timeout")
	games.PersistentFlags().BoolVar(&jsonOutput, "json", false, "Output the API data wrapper as JSON")
	connect := func(cmd *cobra.Command) (*api.Client, string, bool, error) {
		value := baseURL
		if !cmd.Flags().Changed("base-url") {
			if env := os.Getenv("GM_BASE_URL"); env != "" {
				value = env
			}
		}
		base, err := api.NormalizeOrigin(value)
		if err != nil {
			return nil, "", false, err
		}
		client, fromEnvironment, err := authenticatedClient(base, timeout, deps)
		return client, base, fromEnvironment, err
	}
	games.AddCommand(&cobra.Command{
		Use: "list", Short: "List all accessible games", Args: cobra.NoArgs,
		RunE: func(cmd *cobra.Command, args []string) error {
			client, base, fromEnvironment, err := connect(cmd)
			if err != nil {
				return err
			}
			result, err := client.ListGames(cmd.Context())
			if err != nil {
				return err
			}
			if err := saveRenewal(cmd, deps, base, result.NewSessionToken, fromEnvironment); err != nil {
				return err
			}
			if jsonOutput {
				return json.NewEncoder(cmd.OutOrStdout()).Encode(result)
			}
			return printGames(cmd.OutOrStdout(), result.Data)
		},
	})
	games.AddCommand(&cobra.Command{
		Use: "show <game-id>", Short: "Show a game by UUID",
		Args: func(cmd *cobra.Command, args []string) error {
			if err := cobra.ExactArgs(1)(cmd, args); err != nil {
				return err
			}
			if !api.ValidGameID(args[0]) {
				return fmt.Errorf("game ID must be a UUID")
			}
			return nil
		},
		RunE: func(cmd *cobra.Command, args []string) error {
			client, base, fromEnvironment, err := connect(cmd)
			if err != nil {
				return err
			}
			result, err := client.GetGame(cmd.Context(), args[0])
			if err != nil {
				return err
			}
			if err := saveRenewal(cmd, deps, base, result.NewSessionToken, fromEnvironment); err != nil {
				return err
			}
			if jsonOutput {
				return json.NewEncoder(cmd.OutOrStdout()).Encode(result)
			}
			return printGame(cmd.OutOrStdout(), result.Data)
		},
	})
	return games
}

// Prevent user-controlled names/content from injecting terminal control sequences.
func terminalText(value string) string {
	return strings.Map(func(r rune) rune {
		if unicode.IsControl(r) && r != '\n' {
			return ' '
		}
		return r
	}, value)
}

func singleLine(value string) string { return strings.Join(strings.Fields(terminalText(value)), " ") }
func optionalText(value *string) string {
	if value == nil || *value == "" {
		return "-"
	}
	return singleLine(*value)
}

func printGames(out io.Writer, games []api.Game) error {
	if len(games) == 0 {
		_, err := fmt.Fprintln(out, "No games found.")
		return err
	}
	table := tabwriter.NewWriter(out, 0, 4, 2, ' ', 0)
	if _, err := fmt.Fprintln(table, "ID\tNAME\tSETTING"); err != nil {
		return err
	}
	for _, game := range games {
		if _, err := fmt.Fprintf(table, "%s\t%s\t%s\n", game.ID, singleLine(game.Name), optionalText(game.Setting)); err != nil {
			return err
		}
	}
	return table.Flush()
}

func printGame(out io.Writer, game *api.Game) error {
	var text strings.Builder
	fmt.Fprintf(&text, "Name: %s\nID: %s\nSetting: %s\n", singleLine(game.Name), game.ID, optionalText(game.Setting))
	if game.OwnerID != nil {
		fmt.Fprintf(&text, "Owner: %s\n", optionalText(game.OwnerID))
	}
	fmt.Fprintf(&text, "Created: %s\nUpdated: %s\n", optionalText(game.CreatedAt), optionalText(game.UpdatedAt))
	content := game.ContentPlainText
	if content == nil || *content == "" {
		content = game.Content
	}
	if content != nil && *content != "" {
		fmt.Fprintf(&text, "\nContent:\n%s\n", terminalText(*content))
	}
	_, err := io.WriteString(out, text.String())
	return err
}
