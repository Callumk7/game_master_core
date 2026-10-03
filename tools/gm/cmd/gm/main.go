package main

import (
	"fmt"
	"os"

	"game-master/gm/internal/cli"
)

// Override at build time with -ldflags "-X main.version=<version>".
var version = "dev"

func main() {
	if err := cli.Run(os.Args[1:], os.Stdout, os.Stderr, version); err != nil {
		fmt.Fprintln(os.Stderr, "gm:", err)
		os.Exit(1)
	}
}
