// Package credentials stores session tokens in the operating system keyring.
package credentials

import (
	"errors"

	"github.com/zalando/go-keyring"
)

const service = "game-master-cli"

var ErrNotFound = errors.New("no saved session")

// Store keeps one session token per normalized API origin, not passwords.
type Store interface {
	Get(origin string) (string, error)
	Set(origin, token string) error
	Delete(origin string) error
}

// Keyring uses macOS Keychain, Windows Credential Manager, or Secret Service.
// There is deliberately no plaintext fallback.
type Keyring struct{}

func (Keyring) Get(origin string) (string, error) {
	token, err := keyring.Get(service, origin)
	if errors.Is(err, keyring.ErrNotFound) {
		return "", ErrNotFound
	}
	if err != nil {
		return "", errors.New("could not read OS keychain; unlock it or provide GM_TOKEN")
	}
	return token, nil
}

// Delete is idempotent: a missing credential is already removed.
func (Keyring) Delete(origin string) error {
	err := keyring.Delete(service, origin)
	if err != nil && !errors.Is(err, keyring.ErrNotFound) {
		return errors.New("could not remove session from OS keychain; ensure it is available and unlocked")
	}
	return nil
}

func (Keyring) Set(origin, token string) error {
	if err := keyring.Set(service, origin, token); err != nil {
		// OS backend diagnostics may contain secrets; never surface them.
		return errors.New("could not save session to OS keychain; ensure it is available and unlocked")
	}
	return nil
}
