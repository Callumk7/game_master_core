// Package cli implements the gm command interface independently of process exit.
package cli

import (
	"fmt"
	"io"

	"github.com/spf13/cobra"
)

// Run executes a fresh command tree, so flags and output do not leak between runs.
// The caller is responsible for reporting returned errors and selecting an exit code.
func Run(args []string, stdout, stderr io.Writer, version string) error {
	return run(args, stdout, stderr, version, defaultAuthDependencies())
}

func run(args []string, stdout, stderr io.Writer, version string, deps authDependencies) error {
	root := newRootCommand(version, deps)
	root.SetArgs(append([]string{}, args...))
	root.SetOut(stdout)
	root.SetErr(stderr)
	return root.Execute()
}

func newRootCommand(version string, deps authDependencies) *cobra.Command {
	root := &cobra.Command{
		Use:           "gm",
		Short:         "Game Master API CLI",
		Long:          "Game Master API CLI. Use 'gm auth status' to check your API session.",
		Version:       version,
		Args:          cobra.NoArgs,
		SilenceErrors: true,
		SilenceUsage:  true,
		RunE: func(cmd *cobra.Command, args []string) error {
			return cmd.Help()
		},
	}
	root.SetVersionTemplate("gm {{.Version}}\n")
	root.AddCommand(newAuthCommand(deps), newGamesCommand(deps))
	root.AddCommand(&cobra.Command{
		Use:   "version",
		Short: "Show the CLI version",
		Args:  cobra.NoArgs,
		RunE: func(cmd *cobra.Command, args []string) error {
			_, err := fmt.Fprintf(cmd.OutOrStdout(), "gm %s\n", version)
			return err
		},
	})
	return root
}
