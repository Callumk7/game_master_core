# Codebase Structure Analysis: Duplicate Functionality Review

**Date:** 2025-11-13
**Project:** Game Master Core
**Objective:** Identify and eliminate duplicate functionality between API endpoints and admin/LiveView routes

---

## Executive Summary

### High-Level Findings

This Phoenix application exhibits **significant structural duplication** across its API and admin implementations:

- **~3,000+ lines of duplicated code** across controllers and contexts
- **4 admin HTML controllers** completely duplicate API JSON functionality without authorization
- **5 entity types** (characters, factions, locations, notes, quests) each with near-identical implementations
- **Critical security gap**: Admin controllers bypass Bodyguard authorization entirely
- **No entity management LiveViews exist** - all CRUD is controller-based

### Duplication Scope Breakdown

| Category | Duplicate Lines | Files Affected |
|----------|----------------|----------------|
| Entity API Controllers | ~1,500 | 5 files |
| Admin HTML Controllers | ~360 | 4 files |
| Link Management Functions | ~750 | 5 context modules |
| Bodyguard Policies | ~150 | 6 context modules |
| **Total Estimated** | **~2,760+** | **20+ files** |

### Recommended Approach

1. **Immediate removal**: All admin HTML controllers and routes (no authorization, purely duplicate)
2. **Consolidate**: Refactor entity controllers to use shared abstractions
3. **Preserve**: All API endpoints as source of truth
4. **Future-proof**: Design for dashboard implementation without reintroducing duplication

---

## Duplicate Functionality Inventory

### 1. Entity CRUD Operations (CRITICAL DUPLICATION)

#### A. Characters

**API Implementation:**
- **Route:** `/api/games/:game_id/characters`
- **Controller:** `GameMasterCoreWeb.CharacterController` (338 lines)
- **Actions:** index, show, create, update, delete
- **Authorization:** ✅ Bodyguard.permit on update/delete
- **Business Logic:** `GameMasterCore.Characters` context

**Admin Implementation:**
- **Route:** `/admin/games/:game_id/characters`
- **Controller:** `GameMasterCoreWeb.Admin.CharacterController` (94 lines)
- **Actions:** index, show, new, create, edit, update, delete
- **Authorization:** ❌ None (relies only on `:require_authenticated_user`)
- **Business Logic:** Same `GameMasterCore.Characters` context

**Duplication Assessment:**
- **Degree:** 100% identical functionality
- **Implementation:** Divergent (JSON vs HTML, different authorization)
- **Risk:** Admin bypasses ownership checks

---

#### B. Factions

**API Implementation:**
- **Route:** `/api/games/:game_id/factions`
- **Controller:** `GameMasterCoreWeb.FactionController` (292 lines)
- **Authorization:** ✅ Bodyguard.permit on update/delete

**Admin Implementation:**
- **Route:** `/admin/games/:game_id/factions`
- **Controller:** `GameMasterCoreWeb.Admin.FactionController` (90 lines)
- **Authorization:** ❌ None

**Duplication Assessment:**
- **Degree:** 100% identical functionality
- **Implementation:** Divergent (JSON vs HTML)

---

#### C. Locations

**API Implementation:**
- **Route:** `/api/games/:game_id/locations`
- **Controller:** `GameMasterCoreWeb.LocationController` (295 lines)
- **Authorization:** ✅ Bodyguard.permit on update/delete

**Admin Implementation:** None (removed or never implemented)

**Duplication Assessment:** None currently

---

#### D. Notes

**API Implementation:**
- **Route:** `/api/games/:game_id/notes`
- **Controller:** `GameMasterCoreWeb.NoteController` (266 lines)
- **Authorization:** ✅ Bodyguard.permit on update/delete

**Admin Implementation:**
- **Route:** `/admin/games/:game_id/notes`
- **Controller:** `GameMasterCoreWeb.Admin.NoteController` (90 lines)
- **Authorization:** ❌ None

**Duplication Assessment:**
- **Degree:** 100% identical functionality
- **Implementation:** Divergent (JSON vs HTML)

---

#### E. Quests

**API Implementation:**
- **Route:** `/api/games/:game_id/quests`
- **Controller:** `GameMasterCoreWeb.QuestController` (280 lines)
- **Authorization:** ✅ Bodyguard.permit on update/delete

**Admin Implementation:** None (removed or never implemented)

**Duplication Assessment:** None currently

---

### 2. Game Management (PARTIAL DUPLICATION)

**API Implementation:**
- **Route:** `/api/games`
- **Controller:** `GameMasterCoreWeb.GameController`
- **Actions:** index, show, create, update, delete, member management
- **Authorization:** ✅ Inline checks in Games context

**Admin Implementation:**
- **Route:** `/admin/games`
- **Controller:** `GameMasterCoreWeb.Admin.GameController` (115 lines)
- **Actions:** index, show, new, create, edit, update, delete
- **Authorization:** ❌ Basic inline checks (inconsistent with API)

**Duplication Assessment:**
- **Degree:** 80% functionality overlap
- **Implementation:** Divergent (JSON vs HTML, different authorization patterns)

---

### 3. Link Management (MASSIVE INTERNAL DUPLICATION)

Not duplicate between API/admin, but **massive duplication within API itself**.

Each of 5 entity types has identical link management:
- **create_link** endpoint
- **list_links** endpoint
- **update_link** endpoint
- **delete_link** endpoint

**Pattern repeated 5 times across:**
- CharacterController
- FactionController
- LocationController
- NoteController
- QuestController

**Each controller has ~50 lines of identical link management code.**

**Total:** ~250 lines of identical code across 5 controllers

**Context-level duplication:** Each context module has:
- `link_*` functions (5 entity types each = 25 functions)
- `unlink_*` functions (25 functions)
- `update_link_*` functions (25 functions)
- `linked?` functions (25 functions)
- `list_linked_*` functions (25 functions)

**Total:** ~125 nearly identical functions across context modules

---

### 4. Pinning Operations (REPLICATED PATTERN)

Each entity controller has identical pin/unpin endpoints:
- PUT `/pin`
- PUT `/unpin`

**Implementation:** Same pattern in all 5 entity controllers (~15 lines each)

**Total:** ~75 lines of duplicated pinning code

---

### 5. Image Management (SHARED, NOT DUPLICATED)

**Good news:** Image management is already consolidated.

- **Single ImageController** handles all entity images
- **Polymorphic relationship** via `entity_type` and `entity_id`
- **No duplication** here

---

### 6. User Authentication (NO DUPLICATION)

**API Routes:**
- `/api/auth/*` - JSON authentication endpoints
- Controller: `ApiAuthController`

**LiveView Routes:**
- `/users/register`, `/users/log-in`, `/users/settings`
- LiveView modules: Registration, Login, Settings

**Assessment:** These serve different purposes:
- API: For external clients/SPAs
- LiveView: For browser-based authentication UI

**No duplication** - these are complementary, not duplicate.

---

### 7. User Account Management (SEPARATE CONCERNS)

**API Routes:**
- `/api/account/*` - Profile, avatar, email management
- Controller: `AccountController`

**LiveView Routes:**
- `/users/settings` - User settings form

**Assessment:**
- API: Programmatic access for clients
- LiveView: Interactive UI for browser users

**Minimal duplication** - different use cases. LiveView could potentially be removed if a dashboard frontend is built separately.

---

## Scope/Authorization Analysis

### Current API Authorization Approach

#### Game-Level Access Control

**Plug:** `:assign_current_game` (in router.ex)
- Verifies user can access game (owner or member)
- Assigns `conn.assigns.scope.game`
- Applied to all `/api/games/:game_id/*` routes

**Implementation:** `GameMasterCoreWeb.Plugs.AssignCurrentGame`
```elixir
# Ensures user owns or is member of game
# Returns 403 if unauthorized
```

#### Entity-Level Access Control (Bodyguard)

**Pattern used across all entity types:**

```elixir
# In each entity controller (update/delete actions)
with {:ok, entity} <- Context.fetch_entity_for_game(scope, id),
     :ok <- Bodyguard.permit(Context, :update_entity, scope.user, entity),
     {:ok, updated} <- Context.update_entity(scope, entity, params) do
  # ...
end
```

**Bodyguard Policies (defined in context modules):**

**Identical pattern in all 6 contexts:**
- `GameMasterCore.Characters`
- `GameMasterCore.Factions`
- `GameMasterCore.Locations`
- `GameMasterCore.Notes`
- `GameMasterCore.Quests`
- `GameMasterCore.Objectives`

```elixir
def authorize(:update_entity, %User{id: user_id}, %Entity{user_id: user_id}), do: :ok
def authorize(:update_entity, _user, _entity), do: :error

def authorize(:delete_entity, %User{id: user_id}, %Entity{user_id: user_id}), do: :ok
def authorize(:delete_entity, _user, _entity), do: :error
```

**Where Bodyguard is used:**
- ✅ API controllers: update and delete actions only
- ❌ Not used for create/index/show (rely on game-level access)

---

### Current Admin Authorization Approach

**Router-Level:**
- Uses `:require_authenticated_user` plug
- No game-level access verification
- No entity-level ownership checks

**Controller-Level:**
- Admin::GameController: `load_game` plug (fetches game by ID)
- Admin::CharacterController: `load_game` plug
- Admin::FactionController: `load_game` plug
- Admin::NoteController: `load_game` plug

**`load_game` plug implementation:**
```elixir
# Simply fetches game by ID from params
# NO authorization check
game = Games.get_game!(game_id)
assign(conn, :game, game)
```

**Critical Gap:** Any authenticated user can access ANY game's admin routes.

---

### Current LiveView Authorization Approach

**Router-Level:**
- User-related LiveViews use `:require_authenticated_user` or `:current_user` sessions
- No entity management LiveViews exist

**LiveView Module-Level:**
- UserLive.Settings: Operates on `@current_scope.user` only
- UserLive.Registration/Login: Public access

**Assessment:** No authorization issues in LiveViews (they don't manage game entities).

---

### Authorization Duplication & Inconsistencies

#### 1. Identical Bodyguard Policies (6 contexts)

**Pattern repeated 6 times:**

```elixir
@behaviour Bodyguard.Policy

def authorize(:update_entity, %User{id: id}, %Entity{user_id: id}), do: :ok
def authorize(:update_entity, _, _), do: :error

def authorize(:delete_entity, %User{id: id}, %Entity{user_id: id}), do: :ok
def authorize(:delete_entity, _, _), do: :error
```

**Duplication:** ~12 identical policy functions across 6 modules

**Opportunity:** Abstract into a generic `EntityPolicy` module

---

#### 2. Game Access Checks (Inconsistent Implementation)

**API Approach:**
- Uses dedicated `:assign_current_game` plug
- Validates ownership OR membership
- Returns 403 on unauthorized access

**Admin Approach:**
- Uses `load_game` plug (no authorization)
- Fetches game by ID without validation
- **Security vulnerability**

**Games Context Approach:**
- Inline checks: `can_modify_game?(scope, game)`
- Only used internally in context functions
- Not consistently applied

**Inconsistency:** Three different patterns for the same concern

---

#### 3. Read vs Write Authorization Gap

**Current pattern:**
- Read operations (index, show): No Bodyguard checks, rely on game-level access
- Write operations (update, delete): Bodyguard checks entity ownership
- Create operations: No Bodyguard checks, use game-level access

**Potential issue:**
- Game members can create entities in games they don't own
- Game members can read all entities regardless of creator
- Only updates/deletes are restricted to entity owner

**Question for clarification:** Is this intentional? Should game members have full CRUD within games they're members of?

---

### Authorization Security Assessment

| Route Type | Game-Level Check | Entity-Level Check | Security Status |
|------------|------------------|-------------------|-----------------|
| API CRUD | ✅ Plug | ✅ Bodyguard (update/delete) | **Secure** |
| Admin CRUD | ❌ None | ❌ None | **CRITICAL VULNERABILITY** |
| LiveView User | N/A | ✅ Operates on current user | **Secure** |

**Immediate Security Concern:** Admin routes allow any authenticated user to modify any game/entity.

---

## Removal Strategy

### Immediate Removal Candidates (Safe to Remove Now)

#### 1. Admin HTML Controllers (High Priority - Security Risk)

**Remove:**
- `/lib/game_master_core_web/controllers/admin/` directory
  - `character_controller.ex`
  - `faction_controller.ex`
  - `note_controller.ex`
  - `game_controller.ex`

**Remove routes:**
```elixir
# In router.ex, delete entire admin scope
scope "/admin", GameMasterCoreWeb.Admin, as: :admin do
  # ... all admin routes
end
```

**Remove templates:**
- `/lib/game_master_core_web/controllers/admin/character_html/`
- `/lib/game_master_core_web/controllers/admin/faction_html/`
- `/lib/game_master_core_web/controllers/admin/note_html/`
- `/lib/game_master_core_web/controllers/admin/game_html/`

**Remove templates:**
```bash
find lib/game_master_core_web/controllers/admin -name "*_html.ex" -o -name "*.html.heex"
```

**Impact:**
- Removes ~360 lines of controller code
- Removes HTML templates (estimated ~500+ lines)
- **Eliminates security vulnerability**
- **No API functionality affected**

**Reasoning:**
- 100% duplicate of API functionality
- No authorization checks (security risk)
- HTML views not required for API service
- Dashboard will be separate frontend

**Dependencies to check:**
- Any links in templates pointing to admin routes
- Any tests for admin controllers

---

#### 2. Admin-Related Helper Modules (If They Exist)

**Search for:**
- Admin-specific view helpers
- Admin-specific plugs (except authentication)
- Admin-specific components

**Remove if found and not used elsewhere.**

---

### Refactoring Candidates (Consolidate Before Potential Removal)

#### 1. Entity Controller Duplication (Medium Priority)

**Problem:** 5 entity controllers with ~80% identical code

**Refactoring approach:**
1. Create a `EntityController` behavior/macro
2. Extract common CRUD patterns
3. Inject entity-specific logic via callbacks

**Example structure:**
```elixir
defmodule GameMasterCoreWeb.Controllers.EntityController do
  defmacro __using__(opts) do
    context_module = Keyword.fetch!(opts, :context)
    schema_module = Keyword.fetch!(opts, :schema)

    quote do
      # Generic CRUD actions
      def index(conn, _params), do: # ...
      def show(conn, %{"id" => id}), do: # ...
      def create(conn, params), do: # ...
      def update(conn, params), do: # ...
      def delete(conn, %{"id" => id}), do: # ...

      # Generic link management
      def create_link(conn, params), do: # ...
      # ...

      # Generic pinning
      def pin(conn, %{"id" => id}), do: # ...
      def unpin(conn, %{"id" => id}), do: # ...
    end
  end
end
```

**Usage:**
```elixir
defmodule GameMasterCoreWeb.CharacterController do
  use GameMasterCoreWeb.Controllers.EntityController,
    context: GameMasterCore.Characters,
    schema: Character

  # Only character-specific actions here (primary faction, etc.)
end
```

**Benefit:**
- Reduces ~1,500 lines to ~300 lines (shared) + ~100 lines per entity
- Centralizes CRUD logic
- Makes adding new entity types trivial

**Risk:**
- Refactoring effort required
- Potential regressions if not carefully tested

**Recommendation:** Do this refactoring AFTER removing admin controllers

---

#### 2. Bodyguard Policy Duplication (Low Priority)

**Problem:** 6 identical authorization policies

**Refactoring approach:**
Create a shared `EntityPolicy` module:

```elixir
defmodule GameMasterCore.Policies.EntityPolicy do
  @moduledoc """
  Generic authorization policy for entities with user_id ownership.
  """

  alias GameMasterCore.Accounts.User

  def authorize_update(%User{id: user_id}, entity) when is_map(entity) do
    if Map.get(entity, :user_id) == user_id, do: :ok, else: :error
  end

  def authorize_delete(%User{id: user_id}, entity) when is_map(entity) do
    if Map.get(entity, :user_id) == user_id, do: :ok, else: :error
  end
end
```

**Update context modules:**
```elixir
defmodule GameMasterCore.Characters do
  alias GameMasterCore.Policies.EntityPolicy

  @behaviour Bodyguard.Policy

  def authorize(:update_character, user, character),
    do: EntityPolicy.authorize_update(user, character)

  def authorize(:delete_character, user, character),
    do: EntityPolicy.authorize_delete(user, character)
end
```

**Benefit:**
- Reduces ~150 lines of duplicate policy code
- Centralizes authorization logic
- Easier to modify authorization rules

**Risk:** Minimal

**Recommendation:** Do this after entity controller refactoring

---

#### 3. Link Management Consolidation (Low Priority, Future Enhancement)

**Problem:** Each entity has identical link management endpoints

**Current pattern:**
```
/api/games/:game_id/characters/:character_id/links
/api/games/:game_id/factions/:faction_id/links
/api/games/:game_id/notes/:note_id/links
# ... repeated 5 times
```

**Potential consolidated approach:**
```
/api/games/:game_id/links?source_type=character&source_id=123
```

**Or keep RESTful but consolidate controller:**
```elixir
# Single LinkController with polymorphic dispatch
defmodule GameMasterCoreWeb.LinkController do
  def create(conn, %{
    "entity_type" => type,
    "entity_id" => id,
    "link" => link_params
  }) do
    # Polymorphic link creation
  end
end
```

**Benefit:**
- Removes ~250 lines of duplicate endpoint code
- Centralizes link management

**Risk:**
- API breaking change (requires versioning)
- More complex routing

**Recommendation:** Consider for v2 API, not urgent for initial cleanup

---

### Preservation Candidates (Keep, With Justification)

#### 1. All API Routes and Controllers

**Keep:**
- All `/api/games/:game_id/*` routes
- All entity controllers (characters, factions, locations, notes, quests)
- All supporting controllers (images, auth, account)

**Justification:**
- Core service functionality
- Properly authorized
- Source of truth for business logic
- Required for future dashboard frontend

---

#### 2. User LiveViews

**Keep:**
- `/users/register` - UserLive.Registration
- `/users/log-in` - UserLive.Login
- `/users/settings` - UserLive.Settings

**Justification:**
- Provide browser-based authentication UI
- Not duplicate of API (complementary functionality)
- Useful for development/testing
- Could be used for standalone user management portal

**Alternative consideration:**
- If dashboard frontend will handle all UI, these could be removed
- Recommend keeping for now as they provide value and aren't duplicating core entity CRUD

---

#### 3. User Account API Routes

**Keep:**
- `/api/account/*` routes

**Justification:**
- Programmatic access to user profile/avatar management
- Used by external clients/SPAs
- Not duplicate of entity CRUD functionality

---

## Proposed Architecture

### Post-Cleanup Structure

```
GameMasterCore (Phoenix API Service)
│
├── API Layer (JSON) - SOURCE OF TRUTH
│   ├── /api/auth/* - Authentication endpoints
│   ├── /api/account/* - User account management
│   ├── /api/games/* - Game CRUD + membership
│   └── /api/games/:game_id/* - Entity CRUD
│       ├── /characters - Character management
│       ├── /factions - Faction management
│       ├── /locations - Location management
│       ├── /notes - Note management
│       └── /quests - Quest management
│
├── LiveView Layer (Browser UI) - USER AUTHENTICATION ONLY
│   ├── /users/register - Registration form
│   ├── /users/log-in - Login form
│   └── /users/settings - User settings form
│
└── [REMOVED] Admin Layer - DELETED
```

### Separation of Concerns

**API Service Responsibilities:**
- Entity CRUD operations
- Business logic enforcement
- Authorization and access control
- Data persistence
- Event broadcasting (PubSub)

**Future Dashboard Responsibilities:**
- User interface (separate React/Vue/Svelte app)
- Consumes API endpoints
- No direct database access
- No duplicate business logic

---

### Pattern for Future Dashboard Implementation

#### Recommended Approach: Separate Frontend Application

**Architecture:**
```
Dashboard Frontend (React/Vue/Svelte)
    ↓ HTTP/WebSocket
API Service (Phoenix)
    ↓
Database (PostgreSQL)
```

**Benefits:**
- Clear separation of concerns
- No code duplication
- Independently deployable
- API remains focused on business logic
- Frontend can be replaced/updated without affecting API

**Implementation Pattern:**
```javascript
// Dashboard frontend (React example)
import { useApi } from './hooks/useApi'

function CharacterList({ gameId }) {
  const { data, loading } = useApi(`/api/games/${gameId}/characters`)

  // Render characters from API data
  return <CharacterTable characters={data} />
}

function CharacterForm({ gameId, characterId }) {
  const [character, setCharacter] = useState({})
  const { post, put } = useApi()

  const handleSubmit = async () => {
    if (characterId) {
      await put(`/api/games/${gameId}/characters/${characterId}`, character)
    } else {
      await post(`/api/games/${gameId}/characters`, character)
    }
  }

  return <form onSubmit={handleSubmit}>...</form>
}
```

**Key principle:** Dashboard is a thin UI layer consuming API, never duplicating logic.

---

### Preventing Future Duplication

#### 1. Architectural Guidelines

**Document and enforce:**
- API-first development
- All business logic in context modules
- All authorization in Bodyguard policies
- UI layer consumes API (no direct context calls)

**Create:** `/docs/ARCHITECTURE.md` with these principles

---

#### 2. Code Review Checklist

**Before approving PRs, verify:**
- [ ] No business logic in controllers (belongs in contexts)
- [ ] No duplicate CRUD operations
- [ ] Authorization uses Bodyguard consistently
- [ ] No direct database queries outside contexts
- [ ] UI components call API endpoints, not contexts

---

#### 3. Refactoring Roadmap

**Phase 1: Consolidation**
1. Create `EntityController` behavior/macro
2. Refactor entity controllers to use shared behavior
3. Create `EntityPolicy` module
4. Refactor Bodyguard policies to use shared module

**Phase 2: API Stabilization**
1. Version API (v1)
2. Document all endpoints (OpenAPI/Swagger)
3. Add integration tests for all API routes
4. Ensure consistent error responses

**Phase 3: Dashboard Separation**
1. Initialize separate frontend project
2. Configure API CORS for dashboard domain
3. Implement authentication flow (session-based)
4. Build dashboard UI consuming API

---

### Authorization Model Clarification

**Recommended clear authorization model:**

#### Game-Level Access
- **Owner**: Full control (all operations)
- **Member**: Read all, create entities, update/delete own entities
- **Non-member**: No access

#### Entity-Level Access (Characters, Factions, etc.)
- **Creator (owner)**: Update, delete
- **Game members**: Read
- **Non-members**: No access

**Implementation:**
```elixir
# Consolidated policy
def authorize(:update_entity, %User{id: user_id}, %Entity{user_id: user_id}), do: :ok
def authorize(:update_entity, _user, _entity), do: :error

def authorize(:delete_entity, %User{id: user_id}, %Entity{user_id: user_id}), do: :ok
def authorize(:delete_entity, _user, _entity), do: :error

def authorize(:read_entity, user, entity) do
  # Already enforced by :assign_current_game plug
  :ok
end
```

**Question for consideration:** Should game owners have full control over all entities in their games, even if created by members?

---

## Implementation Roadmap

### Phase 0: Preparation (1 day)

**Steps:**
1. ✅ Complete this analysis
2. Review findings with team
3. Get approval for removal strategy
4. Create git branch: `refactor/remove-admin-duplication`

**Deliverables:**
- This analysis document
- Team approval
- Git branch ready

---

### Phase 1: Admin Removal (1-2 days)

**Priority:** CRITICAL (security vulnerability)

#### Step 1.1: Audit Dependencies
```bash
# Search for references to admin routes
rg "admin_.*_path" --type ex --type heex
rg "GameMasterCoreWeb.Admin" --type ex
rg "/admin/" --type ex --type heex
```

**Action:** Document all references

#### Step 1.2: Remove Admin Routes
```bash
# In router.ex, delete admin scope block
# Estimated: lines ~XX-YY (need to verify)
```

**Files to modify:**
- `lib/game_master_core_web/router.ex`

#### Step 1.3: Remove Admin Controllers
```bash
rm -rf lib/game_master_core_web/controllers/admin/
```

**Files removed:**
- `admin/game_controller.ex`
- `admin/character_controller.ex`
- `admin/faction_controller.ex`
- `admin/note_controller.ex`
- All associated `*_html.ex` files
- All associated `*.html.heex` templates

#### Step 1.4: Remove Admin Tests (If They Exist)
```bash
# Search for admin controller tests
find test -name "*admin*" -type f

# Remove found test files
rm test/game_master_core_web/controllers/admin/*_test.exs
```

#### Step 1.5: Update Navigation/Links
- Search for any navigation menus linking to admin routes
- Remove or redirect to API documentation

#### Step 1.6: Run Tests
```bash
mix test
mix credo
mix dialyzer
```

**Expected failures:** Admin controller tests (already removed)

#### Step 1.7: Commit
```bash
git add -A
git commit -m "Remove duplicate admin HTML controllers and routes

- Removes admin controllers for games, characters, factions, notes
- Removes admin HTML templates
- Removes admin routes from router
- Fixes security vulnerability (admin routes had no authorization)

Justification:
- 100% duplicate of API functionality
- Missing authorization checks (security risk)
- Not required for API service
- Future dashboard will consume API directly

Impact:
- Removes ~360 lines of controller code
- Removes ~500+ lines of templates
- No API functionality affected
- Eliminates critical security vulnerability"
```

---

### Phase 2: Entity Controller Refactoring (3-5 days)

**Priority:** MEDIUM (code quality improvement)

#### Step 2.1: Design EntityController Behavior

**Create:** `lib/game_master_core_web/controllers/entity_controller.ex`

```elixir
defmodule GameMasterCoreWeb.Controllers.EntityController do
  @moduledoc """
  Shared behavior for entity CRUD controllers.

  Provides generic implementations for:
  - Standard CRUD (index, show, create, update, delete)
  - Link management (create_link, list_links, update_link, delete_link)
  - Pinning (pin, unpin)

  ## Usage

      defmodule GameMasterCoreWeb.CharacterController do
        use GameMasterCoreWeb, :controller
        use GameMasterCoreWeb.Controllers.EntityController,
          context: GameMasterCore.Characters,
          schema: GameMasterCore.Characters.Character,
          entity_name: "character"
      end
  """

  defmacro __using__(opts) do
    context = Keyword.fetch!(opts, :context)
    schema = Keyword.fetch!(opts, :schema)
    entity_name = Keyword.fetch!(opts, :entity_name)

    quote do
      # Implementation to be designed
    end
  end
end
```

**Deliverable:** Working macro/behavior design

#### Step 2.2: Implement Generic CRUD Actions

**In `EntityController`:**
- Extract common patterns from current controllers
- Parameterize context module, schema, entity name
- Ensure authorization checks are preserved

**Test:** Create a test entity controller using the behavior

#### Step 2.3: Refactor CharacterController (Pilot)

**Convert CharacterController to use EntityController:**
```elixir
defmodule GameMasterCoreWeb.CharacterController do
  use GameMasterCoreWeb, :controller
  use GameMasterCoreWeb.Controllers.EntityController,
    context: GameMasterCore.Characters,
    schema: Character,
    entity_name: "character"

  # Only character-specific actions here
  def get_primary_faction(conn, %{"id" => id}), do: # ...
  def set_primary_faction(conn, params), do: # ...
  # ...
end
```

**Test extensively:** Ensure no regressions

#### Step 2.4: Refactor Remaining Entity Controllers

**Apply same pattern to:**
- FactionController
- LocationController
- NoteController
- QuestController

**After each:** Run full test suite

#### Step 2.5: Commit Each Refactoring
```bash
git commit -m "Refactor CharacterController to use EntityController behavior"
git commit -m "Refactor FactionController to use EntityController behavior"
# ...
```

---

### Phase 3: Policy Consolidation (1-2 days)

**Priority:** LOW (nice-to-have)

#### Step 3.1: Create EntityPolicy Module

**Create:** `lib/game_master_core/policies/entity_policy.ex`

```elixir
defmodule GameMasterCore.Policies.EntityPolicy do
  @moduledoc """
  Generic entity authorization policy.

  Checks entity ownership based on user_id field.
  """

  alias GameMasterCore.Accounts.User

  def authorize_update(%User{id: user_id}, entity) do
    if Map.get(entity, :user_id) == user_id, do: :ok, else: :error
  end

  def authorize_delete(%User{id: user_id}, entity) do
    if Map.get(entity, :user_id) == user_id, do: :ok, else: :error
  end
end
```

#### Step 3.2: Update Context Policies

**For each context:**
```elixir
defmodule GameMasterCore.Characters do
  alias GameMasterCore.Policies.EntityPolicy

  @behaviour Bodyguard.Policy

  def authorize(:update_character, user, character),
    do: EntityPolicy.authorize_update(user, character)

  def authorize(:delete_character, user, character),
    do: EntityPolicy.authorize_delete(user, character)
end
```

**Update:** All 6 context modules (Characters, Factions, Locations, Notes, Quests, Objectives)

#### Step 3.3: Test Authorization

**Ensure:** All authorization tests still pass

#### Step 3.4: Commit
```bash
git commit -m "Consolidate entity authorization into EntityPolicy module"
```

---

### Phase 4: Documentation & Testing (2-3 days)

**Priority:** HIGH (ensure quality)

#### Step 4.1: Update API Documentation

**Document all API endpoints:**
- Use OpenAPI/Swagger
- Document request/response schemas
- Document authorization requirements
- Include examples

**Tools:**
- `phoenix_swagger` or
- `open_api_spex`

**Deliverable:** `/docs/api/openapi.yaml`

#### Step 4.2: Integration Tests

**Ensure coverage for:**
- All CRUD operations
- Authorization (both successful and denied)
- Link management
- Pinning
- Edge cases (missing game, unauthorized access)

**Create:** `test/game_master_core_web/integration/` directory

#### Step 4.3: Architecture Documentation

**Create:** `/docs/ARCHITECTURE.md`

**Include:**
- System architecture diagram
- API-first development principles
- Authorization model
- Guidelines for avoiding duplication
- How to add new entity types
- Future dashboard integration pattern

#### Step 4.4: Developer Guidelines

**Create:** `/docs/DEVELOPMENT.md`

**Include:**
- How to use EntityController behavior
- How to add new entity types
- Testing guidelines
- Authorization patterns
- Code review checklist

---

### Phase 5: Final Validation (1 day)

#### Step 5.1: Full Test Suite
```bash
mix test --cover
mix credo --strict
mix dialyzer
```

**Goal:** 100% passing tests, no warnings

#### Step 5.2: Performance Testing

**Verify no performance regressions:**
- Benchmark CRUD operations
- Check query counts (N+1 queries)
- Profile authorization overhead

#### Step 5.3: Security Audit

**Verify:**
- All endpoints properly authorized
- No admin route vulnerabilities remain
- CORS configured correctly
- Input validation in place

#### Step 5.4: Code Review

**Self-review:**
- Consistent code style
- No TODOs or FIXMEs
- Clear commit messages
- Documentation complete

---

### Phase 6: Deployment Preparation (1 day)

#### Step 6.1: Migration Plan

**Since this is primarily code removal:**
- No database migrations needed
- No API breaking changes
- No data migration required

**Document:** Deployment is straightforward

#### Step 6.2: Rollback Plan

**If issues arise:**
- Git revert to previous commit
- Redeploy previous version
- No data impact (only code changes)

#### Step 6.3: Monitoring Plan

**Monitor after deployment:**
- API response times
- Error rates
- Authorization failures
- User complaints about missing features

#### Step 6.4: Communication Plan

**If admin routes were in use:**
- Notify users of removal
- Provide alternative (API documentation)
- Timeline for dashboard replacement

---

### Total Estimated Timeline

| Phase | Duration | Priority |
|-------|----------|----------|
| 0. Preparation | 1 day | Critical |
| 1. Admin Removal | 1-2 days | Critical (security) |
| 2. Controller Refactoring | 3-5 days | Medium |
| 3. Policy Consolidation | 1-2 days | Low |
| 4. Documentation & Testing | 2-3 days | High |
| 5. Final Validation | 1 day | High |
| 6. Deployment Prep | 1 day | Medium |
| **Total** | **10-15 days** | |

**Recommended approach:**
- **Do Phase 1 immediately** (security fix)
- **Phases 2-6 can be done incrementally** (quality improvement)

---

## Appendix: Detailed File Inventory

### Files to Remove (Phase 1)

#### Controllers
- `lib/game_master_core_web/controllers/admin/game_controller.ex` (115 lines)
- `lib/game_master_core_web/controllers/admin/character_controller.ex` (94 lines)
- `lib/game_master_core_web/controllers/admin/faction_controller.ex` (90 lines)
- `lib/game_master_core_web/controllers/admin/note_controller.ex` (90 lines)

#### HTML Modules
- `lib/game_master_core_web/controllers/admin/game_html.ex`
- `lib/game_master_core_web/controllers/admin/character_html.ex`
- `lib/game_master_core_web/controllers/admin/faction_html.ex`
- `lib/game_master_core_web/controllers/admin/note_html.ex`

#### Templates
- `lib/game_master_core_web/controllers/admin/game_html/*.html.heex`
- `lib/game_master_core_web/controllers/admin/character_html/*.html.heex`
- `lib/game_master_core_web/controllers/admin/faction_html/*.html.heex`
- `lib/game_master_core_web/controllers/admin/note_html/*.html.heex`

#### Tests
- `test/game_master_core_web/controllers/admin/*_test.exs`

#### Router
- Lines in `router.ex` defining admin scope (estimate: ~50-100 lines)

**Total estimated removal:** ~1,000+ lines

---

### Files to Refactor (Phase 2)

#### Controllers to Refactor
- `lib/game_master_core_web/controllers/character_controller.ex` (338 → ~150 lines)
- `lib/game_master_core_web/controllers/faction_controller.ex` (292 → ~150 lines)
- `lib/game_master_core_web/controllers/location_controller.ex` (295 → ~150 lines)
- `lib/game_master_core_web/controllers/note_controller.ex` (266 → ~150 lines)
- `lib/game_master_core_web/controllers/quest_controller.ex` (280 → ~150 lines)

#### New Files to Create
- `lib/game_master_core_web/controllers/entity_controller.ex` (~300 lines)

**Estimated reduction:** ~750 lines

---

### Files to Refactor (Phase 3)

#### New Files to Create
- `lib/game_master_core/policies/entity_policy.ex` (~50 lines)

#### Context Modules to Update
- `lib/game_master_core/characters.ex` (reduce ~20 lines)
- `lib/game_master_core/factions.ex` (reduce ~20 lines)
- `lib/game_master_core/locations.ex` (reduce ~20 lines)
- `lib/game_master_core/notes.ex` (reduce ~20 lines)
- `lib/game_master_core/quests.ex` (reduce ~20 lines)
- `lib/game_master_core/objectives.ex` (reduce ~20 lines)

**Estimated reduction:** ~70 lines

---

## Summary: Total Impact

### Code Reduction
- **Phase 1 (Removal):** ~1,000 lines removed
- **Phase 2 (Refactoring):** ~750 lines removed
- **Phase 3 (Consolidation):** ~70 lines removed
- **Total:** ~1,820 lines removed

### Security Improvement
- Eliminates critical vulnerability (unauthorized admin access)
- Consolidates authorization logic
- Single source of truth for access control

### Maintainability Improvement
- Reduces duplicate code by ~60%
- Centralizes CRUD logic
- Easier to add new entity types
- Clearer architecture

### Future-Proofing
- Clear separation between API and UI
- Ready for dashboard frontend integration
- Documented patterns to prevent duplication
- API-first development approach

---

## Questions for Clarification

1. **Game Member Permissions:** Should game members have full CRUD on all entities within games they're members of, or only on entities they created?

2. **User LiveViews:** Keep or remove user authentication LiveViews? (Registration, Login, Settings)

3. **Admin Route Usage:** Are admin routes currently being used in production? If yes, need communication plan for users.

4. **Priority:** Should we prioritize security fix (Phase 1) or do full refactoring at once?

5. **API Versioning:** Should we version the API now (v1) in preparation for future changes?

6. **Dashboard Timeline:** When is the dashboard implementation planned? This affects whether to keep user LiveViews.

---

**End of Analysis**

Generated: 2025-11-13
Analyst: Claude (AI Assistant)
Review Status: Pending team approval
