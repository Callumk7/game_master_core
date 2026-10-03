// Package api contains the Game Master HTTP client, independent of CLI wiring.
package api

import (
	"bytes"
	"context"
	"encoding/json"
	"errors"
	"fmt"
	"io"
	"net"
	"net/http"
	"net/url"
	"strings"
	"time"
)

const maxResponseBytes = 1 << 20

// Client sends requests to a single API origin.
type Client struct {
	baseURL string
	token   string
	http    *http.Client
}

// AuthStatus is the response from GET /api/auth/status.
type AuthStatus struct {
	Authenticated   bool   `json:"authenticated"`
	User            *User  `json:"user,omitempty"`
	NewSessionToken string `json:"-"`
}

// LoginResult includes a secret token that must not be printed or JSON encoded.
type LoginResult struct {
	Token string `json:"-"`
	User  *User  `json:"user"`
}

// User contains the account fields needed for authentication output.
type User struct {
	ID       string `json:"id"`
	Email    string `json:"email"`
	Username string `json:"username"`
}

// NormalizeOrigin validates the API origin and provides a stable credential key.
// HTTPS is required except for loopback development servers.
func NormalizeOrigin(baseURL string) (string, error) {
	u, err := url.Parse(baseURL)
	if err != nil || u.Hostname() == "" || (u.Scheme != "http" && u.Scheme != "https") {
		return "", errors.New("base URL must be an absolute http or https URL")
	}
	if u.User != nil || u.RawQuery != "" || u.ForceQuery || u.Fragment != "" || (u.Path != "" && u.Path != "/") {
		return "", errors.New("base URL must contain only an origin, without credentials, path, query, or fragment")
	}
	ip := net.ParseIP(u.Hostname())
	if u.Scheme == "http" && !strings.EqualFold(u.Hostname(), "localhost") && (ip == nil || !ip.IsLoopback()) {
		return "", errors.New("base URL must use HTTPS unless the host is loopback")
	}
	u.Host = strings.ToLower(u.Host)
	if (u.Scheme == "https" && u.Port() == "443") || (u.Scheme == "http" && u.Port() == "80") {
		u.Host = strings.TrimSuffix(u.Host, ":"+u.Port())
	}
	u.Path, u.RawPath = "", ""
	return u.String(), nil
}

// NewClient allows an empty token for login. Status and Logout require a bearer token.
// Redirects are never followed, preventing credentials from being forwarded.
func NewClient(baseURL, token string, timeout time.Duration) (*Client, error) {
	origin, err := NormalizeOrigin(baseURL)
	if err != nil {
		return nil, err
	}
	token = strings.TrimSpace(token)
	if token != "" && !validToken(token) {
		return nil, errors.New("session token must be a single bearer token without whitespace")
	}
	if timeout <= 0 {
		return nil, errors.New("timeout must be greater than zero")
	}
	return &Client{
		baseURL: origin,
		token:   token,
		http: &http.Client{
			Timeout:       timeout,
			CheckRedirect: func(*http.Request, []*http.Request) error { return http.ErrUseLastResponse },
		},
	}, nil
}

func validToken(token string) bool {
	if token == "" {
		return false
	}
	for _, char := range token {
		if char <= ' ' || char >= 127 {
			return false
		}
	}
	return true
}

func validUser(user *User) bool { return user != nil && user.ID != "" && user.Email != "" }

// Login exchanges email/password for a session. It never sends an old bearer
// token, retries requests, or returns server response bodies in errors.
func (c *Client) Login(ctx context.Context, email, password string) (LoginResult, error) {
	if strings.TrimSpace(email) == "" || password == "" {
		return LoginResult{}, errors.New("email and password are required")
	}
	payload, err := json.Marshal(struct {
		Email    string `json:"email"`
		Password string `json:"password"`
	}{email, password})
	if err != nil {
		return LoginResult{}, errors.New("could not encode login request")
	}
	body, _, err := c.request(ctx, http.MethodPost, "/api/auth/login", payload)
	if err != nil {
		return LoginResult{}, err
	}
	// Decode into a separate type: LoginResult deliberately hides Token from JSON.
	var response struct {
		Token string `json:"token"`
		User  *User  `json:"user"`
	}
	if err := json.Unmarshal(body, &response); err != nil || !validToken(response.Token) || !validUser(response.User) {
		return LoginResult{}, errors.New("API returned an invalid login response")
	}
	return LoginResult{Token: response.Token, User: response.User}, nil
}

// Status validates the bearer session against the server.
func (c *Client) Status(ctx context.Context) (AuthStatus, error) {
	if c.token == "" {
		return AuthStatus{}, errors.New("a session token is required")
	}
	body, renewed, err := c.request(ctx, http.MethodGet, "/api/auth/status", nil)
	if err != nil {
		return AuthStatus{}, err
	}
	var payload struct {
		Authenticated *bool `json:"authenticated"`
		User          *User `json:"user"`
	}
	if err := json.Unmarshal(body, &payload); err != nil || payload.Authenticated == nil {
		return AuthStatus{}, errors.New("API returned an invalid authentication response")
	}
	if !*payload.Authenticated {
		return AuthStatus{}, errors.New("session is not authenticated; run 'gm auth login' or update GM_TOKEN")
	}
	if !validUser(payload.User) {
		return AuthStatus{}, errors.New("API returned an invalid authenticated user")
	}
	if renewed != "" && !validToken(renewed) {
		return AuthStatus{}, errors.New("API returned an invalid renewed token")
	}
	return AuthStatus{Authenticated: true, User: payload.User, NewSessionToken: renewed}, nil
}

// Logout revokes the session. A 401 means it is already invalid or expired.
// Older server middleware can issue a fresh token before handling logout; revoke
// that token too rather than leaving a newly created session active.
func (c *Client) Logout(ctx context.Context) error {
	if c.token == "" {
		return errors.New("a session token is required")
	}
	_, renewed, err := c.request(ctx, http.MethodDelete, "/api/auth/logout", nil)
	if err != nil || renewed == "" {
		return err
	}
	if !validToken(renewed) {
		return errors.New("session revoked but API returned an invalid renewed token")
	}
	renewedClient := *c
	renewedClient.token = renewed
	_, next, err := renewedClient.request(ctx, http.MethodDelete, "/api/auth/logout", nil)
	if err != nil {
		return errors.New("original session revoked but could not revoke the server-renewed session")
	}
	if next != "" {
		return errors.New("API unexpectedly renewed a fresh session during logout")
	}
	return nil
}

func (c *Client) request(ctx context.Context, method, path string, payload []byte) ([]byte, string, error) {
	req, err := http.NewRequestWithContext(ctx, method, c.baseURL+path, bytes.NewReader(payload))
	if err != nil {
		return nil, "", errors.New("could not create API request")
	}
	req.Header.Set("Accept", "application/json")
	if payload != nil {
		req.Header.Set("Content-Type", "application/json")
	}
	if method != http.MethodPost && c.token != "" {
		req.Header.Set("Authorization", "Bearer "+c.token)
	}
	resp, err := c.http.Do(req)
	if err != nil {
		if errors.Is(err, context.DeadlineExceeded) {
			return nil, "", errors.New("API request timed out")
		}
		if errors.Is(err, context.Canceled) {
			return nil, "", errors.New("API request canceled")
		}
		return nil, "", errors.New("could not connect to API; check the base URL and server availability")
	}
	defer resp.Body.Close()
	if method == http.MethodDelete && path == "/api/auth/logout" {
		switch resp.StatusCode {
		case http.StatusOK, http.StatusNoContent:
			return nil, resp.Header.Get("X-New-Session-Token"), nil
		case http.StatusUnauthorized:
			return nil, "", nil
		}
	}
	switch resp.StatusCode {
	case http.StatusOK:
	case http.StatusUnauthorized:
		if method == http.MethodPost {
			return nil, "", errors.New("invalid email or password")
		}
		return nil, "", errors.New("session is invalid or expired; run 'gm auth login' or update GM_TOKEN")
	case http.StatusNotFound:
		if strings.HasPrefix(path, "/api/games/") {
			return nil, "", errors.New("game not found or not accessible (HTTP 404)")
		}
		return nil, "", errors.New("API endpoint not found (HTTP 404)")
	case http.StatusForbidden:
		if method == http.MethodPost {
			return nil, "", errors.New("login denied (HTTP 403); confirm your email before logging in")
		}
		return nil, "", errors.New("API denied access (HTTP 403)")
	default:
		return nil, "", fmt.Errorf("API returned HTTP %d", resp.StatusCode)
	}
	body, err := io.ReadAll(io.LimitReader(resp.Body, maxResponseBytes+1))
	if err != nil {
		return nil, "", errors.New("could not read API response")
	}
	if len(body) > maxResponseBytes {
		return nil, "", errors.New("API response exceeds size limit")
	}
	return body, resp.Header.Get("X-New-Session-Token"), nil
}
