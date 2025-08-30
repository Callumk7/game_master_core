# Misc TODO

- [x] Add `game_id` to `Character` and `Note` schemas
- [ ] Add location reference to factions, once we have locations
- [ ] When creating a character with a JSON body, the level can't be a number?

- [x] Setup Manual API tests in Yaak
- [ ] Check error codes in production build

- [x] There is double fetching going on when getting a scoped character, and the character data having already been fetched. This is the same for each entity type so far:
    - Character
    - Faction
    - Note
    - ***NOTE*** This could be ok actually as the purpose may be to just check permissions of the user.

- [ ] Add tests for deleting entities when they have attached links

- [ ] Currently, we show 404 not found when a user tries to access a game they don't have access to. It should be a 403.

- [ ] Missing functionality for some note links:
    - Location
    - Quest

- [x] Permission issues for finding stuff about characters etc that current user doesn't 'own'. Should remove all concept of user_id when it comes to auth for games. That can come much later if needed.


## Features
- Self connections
    - at this point, might be worth doing the whole refactor in order to simplify the Links module

- Deeply nested connections
    - Describe an interface that allows us to easily accomodate each entity type. We should largely have all the functionality written.
    - thinking about it, we can have an `includes` interface, followed by a `depth` interface. 
    - This can translate well across the application

- Client side authentication
- More experimentation with LiveView
- Then see how LiveVue looks
