package api

import (
	"context"
	"encoding/json"
	"errors"
	"net/http"
	"regexp"
)

var gameIDPattern = regexp.MustCompile(`^[[:xdigit:]]{8}-[[:xdigit:]]{4}-[[:xdigit:]]{4}-[[:xdigit:]]{4}-[[:xdigit:]]{12}$`)

// ValidGameID accepts UUIDs only, so a game ID cannot inject URL path segments.
func ValidGameID(id string) bool { return gameIDPattern.MatchString(id) }

// Game matches the server's GameJSON output. Optional values preserve JSON null.
// OwnerID is documented in the spec but absent from the current JSON renderer.
type Game struct {
	ID               string  `json:"id"`
	Name             string  `json:"name"`
	Setting          *string `json:"setting"`
	Content          *string `json:"content"`
	ContentPlainText *string `json:"content_plain_text"`
	OwnerID          *string `json:"owner_id,omitempty"`
	CreatedAt        *string `json:"created_at"`
	UpdatedAt        *string `json:"updated_at"`
}

type GamesResult struct {
	Data            []Game `json:"data"`
	NewSessionToken string `json:"-"`
}

type GameResult struct {
	Data            *Game  `json:"data"`
	NewSessionToken string `json:"-"`
}

func validGame(game *Game) bool {
	return game != nil && ValidGameID(game.ID) && game.Name != ""
}

// ListGames fetches every game accessible to the current user. The API currently
// returns the full list without pagination.
func (c *Client) ListGames(ctx context.Context) (GamesResult, error) {
	if c.token == "" {
		return GamesResult{}, errors.New("a session token is required")
	}
	body, renewed, err := c.request(ctx, http.MethodGet, "/api/games", nil)
	if err != nil {
		return GamesResult{}, err
	}
	var result GamesResult
	if err := json.Unmarshal(body, &result); err != nil || result.Data == nil {
		return GamesResult{}, errors.New("API returned an invalid games response")
	}
	for i := range result.Data {
		if !validGame(&result.Data[i]) {
			return GamesResult{}, errors.New("API returned an invalid game in the games list")
		}
	}
	if renewed != "" && !validToken(renewed) {
		return GamesResult{}, errors.New("API returned an invalid renewed token")
	}
	result.NewSessionToken = renewed
	return result, nil
}

func (c *Client) GetGame(ctx context.Context, id string) (GameResult, error) {
	if !ValidGameID(id) {
		return GameResult{}, errors.New("game ID must be a UUID")
	}
	if c.token == "" {
		return GameResult{}, errors.New("a session token is required")
	}
	body, renewed, err := c.request(ctx, http.MethodGet, "/api/games/"+id, nil)
	if err != nil {
		return GameResult{}, err
	}
	var result GameResult
	if err := json.Unmarshal(body, &result); err != nil || !validGame(result.Data) {
		return GameResult{}, errors.New("API returned an invalid game response")
	}
	if renewed != "" && !validToken(renewed) {
		return GameResult{}, errors.New("API returned an invalid renewed token")
	}
	result.NewSessionToken = renewed
	return result, nil
}
