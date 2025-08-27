# Misc TODO

- [ ] Add `game_id` to `Character` and `Note` schemas
- [ ] Add location reference to factions, once we have locations
- [ ] When creating a character with a JSON body, the level can't be a number?

- [ ] Update the character schema changeset to use game_scope, instead of game_id as an arg

- [ ] Setup Manual API tests in Yaak
- [ ] Check error codes in production build

- [ ] There is double fetching going on when getting a scoped character, and the character data having already been fetched. This is the same for each entity type so far:
    - Character
    - Faction
    - Note
    - ***NOTE*** This could be ok actually as the purpose may be to just check permissions of the user.

- [ ] Add tests for deleting entities when they have attached links

