# gm CLI

Standalone Go client for the Game Master API. Supports help, version, shell
completion, interactive login with OS keychain storage, authentication status,
logout, and read-only game browsing.

## Requirements

- Go 1.24 or newer for development.
- No Phoenix server, database, or Erlang installation is needed to build or run it.

This directory is an independent Go module using [Cobra](https://github.com/spf13/cobra)
for commands, flags, generated help, and shell completion. Dependencies are pinned
in `go.mod` and verified by `go.sum`. Hidden password input uses `golang.org/x/term`;
credential storage uses [go-keyring](https://github.com/zalando/go-keyring).
Viper is not included.
The module path `game-master/gm` is local; it can be changed to a repository import
path if the CLI is published separately.

## Run and build

From the repository root:

```sh
cd tools/gm
go run ./cmd/gm --help
go run ./cmd/gm version

go build -o bin/gm ./cmd/gm
./bin/gm help
```

Optionally embed a release version:

```sh
go build -ldflags "-X main.version=0.1.0" -o bin/gm ./cmd/gm
./bin/gm version
```

Compiled binaries do not require Go or Erlang installed on the target machine.
Build for the target operating system and architecture when distributing them.

## Checks

Run from this directory:

```sh
gofmt -w cmd internal
go vet ./...
go test ./...
go build -o bin/gm ./cmd/gm
```

The server's `mix precommit` does not run these Go checks; run them separately.

## Structure

- `cmd/gm/main.go`: executable entry point, version, stderr errors, exit status.
- `internal/cli/`: Cobra command tree with injectable stdout/stderr for tests.
- `internal/api/`: HTTP client, login, bearer authentication, and response validation.
- `internal/credentials/`: OS keychain adapter behind a testable store interface.
- `bin/`: ignored build output.

Successful output goes to stdout. Errors go to stderr and exit with status 1.
No arguments prints help. Unknown commands, flags, and unexpected version arguments
are rejected. Both `gm version` and `gm --version` print the embedded version.
Cobra's `gm help <command>` provides command-specific help.

## Shell completion

Cobra generates completion scripts for bash, zsh, fish, and PowerShell:

```sh
./bin/gm completion --help
./bin/gm completion bash > /tmp/gm-completion.bash
source /tmp/gm-completion.bash
```

New commands should be registered in `internal/cli/` using `cobra.Command`. Keep
API behavior separate from command wiring and return errors to the entry point
rather than exiting inside command handlers.

## API contract

The server generates Swagger 2.0 at `../../priv/static/swagger.json`, from the
Phoenix Swagger definitions under `../../lib/game_master_core_web/swagger/`.
The scaffold does not load or generate code from that file yet.

## Login

With the API server running, build the CLI and log in:

```sh
./bin/gm auth login --email you@example.com
./bin/gm auth status
./bin/gm auth status --json
```

Login prompts for a password without echoing it. It requires an interactive
terminal: there is no `--password` flag, password environment variable, or piped
password input. Only the returned session token is stored; your password is not
saved and tokens are never printed.

Tokens are stored under service `game-master-cli`, keyed by the normalized API
origin. One session is saved per origin; logging in as a different user to the
same origin replaces the previous token. Local and production sessions are separate.
Origins normalize hostname casing, a trailing slash, and default HTTP/HTTPS ports.

Credential storage uses:

- macOS: Keychain via the built-in `/usr/bin/security` tool.
- Windows: Credential Manager.
- Linux/BSD: a running D-Bus Secret Service (e.g. GNOME Keyring), with an unlocked
  `login` collection. Headless environments may not have this available.

There is no plaintext-file fallback. If saving fails after the API accepted login,
the command exits with an error instead of claiming success or printing the token.
Unlock/configure your keychain and retry. The server-created session may still
exist until it expires; client-side storage failure cannot undo the login.

## Authentication status

`auth status` uses `GM_TOKEN` when the variable is set, otherwise the saved token
for the selected origin. Even an empty `GM_TOKEN` overrides the keychain and is
rejected; `unset GM_TOKEN` to use a saved login. Login still saves to the keychain
when `GM_TOKEN` is set, but warns that the environment token will take precedence.

For automation, provide the session token returned in the API login response through `GM_TOKEN`.
Use the token string as returned, without decoding it or adding a `Bearer` prefix.
Do not commit credentials or put them directly in shell command history. For
example, in bash, prompt for an existing token without echoing it:

```bash
read -r -s -p 'Session token: ' GM_TOKEN; printf '\n'
export GM_TOKEN
./bin/gm auth status
./bin/gm auth status --json
unset GM_TOKEN
```

The default API origin for all API commands is
`https://gamemastercore-production.up.railway.app`. Override it with `GM_BASE_URL`
or `--base-url` (the flag takes precedence). For local development:

```sh
export GM_BASE_URL=http://localhost:4000
./bin/gm auth status --timeout 10s
./bin/gm auth status --base-url http://localhost:4000 --json
```

The base URL must be an origin only, without `/api`, credentials, query, or fragment.
HTTPS is required except for loopback hosts (`localhost`, `127.0.0.1`, `::1`).
Requests time out after 15 seconds by default and redirects are not followed.
Tokens are never printed. An invalid/expired session exits with status 1
and an error on stderr, including when `--json` is requested.

Successful `--json` output contains `authenticated` and a `user` object with `id`,
`email`, and `username`. Human output identifies the account email and user ID.
For keychain-backed sessions, `x-new-session-token` is saved automatically.
Failure to save a renewed token exits with an error. Environment-provided sessions
are never persisted or overwritten; renewal triggers a warning on stderr instead.
Environment tokens remain valid according to the server's session expiry policy;
update them when needed.

Tests use Go's `httptest` servers, injected password readers, and in-memory
credential stores. They do not access your real OS keychain or need Phoenix.

## Logout

```sh
./bin/gm auth logout
```

Logout revokes the active session with `DELETE /api/auth/logout`, then removes its
keychain entry for the selected origin. A missing saved session is already logged
out; an expired/invalid token (HTTP 401) is removed locally without error.
Network failures or other API errors preserve saved credentials and exit with an
error instead of claiming that logout succeeded. If revocation succeeds but
keychain deletion fails, unlock the keychain and retry logout.

When `GM_TOKEN` is set, logout revokes only that environment token and never reads,
updates, or deletes keychain entries, even if a saved session uses the same token.
The CLI cannot change its parent shell's environment; run `unset GM_TOKEN` after
logout. To log out a saved session instead, unset `GM_TOKEN` first.

If server middleware renews a session while processing logout, the CLI also revokes
that newly issued token. Neither replacement tokens nor server response bodies are
printed. This logs out only the selected session, not every device/account session.

## Games

After logging in, browse the games accessible to your account:

```sh
./bin/gm games list
./bin/gm games list --json
./bin/gm games show c2d438d2-5f54-4d14-aef4-8194a1bc831f
./bin/gm games show c2d438d2-5f54-4d14-aef4-8194a1bc831f --json
```

Use an actual game UUID from `games list` for `show`. The list displays ID, name,
and setting; an empty result prints `No games found.`. Details include timestamps
and content, preferring `content_plain_text` over raw content. Optional owner IDs
are displayed only when returned by the API. Terminal control characters are
sanitized in human output.

Both commands support `--base-url`, `--timeout`, and `GM_BASE_URL`, and use the
same credential precedence and token renewal as `auth status`. The server currently
returns all accessible games without pagination. No write operations are performed.

JSON output retains the API's `data` wrapper: `{"data":[]}` for an empty list,
`{"data":[...]}` for a list, and `{"data":{...}}` for a single game. Game IDs are
UUID strings, and optional content/setting/timestamp fields can be null. The model
includes the current API fields plus optional `owner_id` from the spec; unknown
fields are ignored. The current server renderer does not return `owner_id`.

Missing/inaccessible games, denied access, invalid UUIDs, and malformed responses
exit with status 1 and an error on stderr, without printing a JSON result. API error
bodies and tokens are never printed. Renewal warnings go to stderr so stdout remains
valid JSON.

## Next increment

Add game creation and updates, then deletion with an explicit confirmation.

