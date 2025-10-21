---
id: task-034
title: Add username and avatar_url fields to User schema
status: Done
assignee:
  - '@claude'
created_date: '2025-10-21 16:14'
updated_date: '2025-10-21 16:30'
labels:
  - backend
  - database
dependencies: []
priority: high
---

## Description

<!-- SECTION:DESCRIPTION:BEGIN -->
Add username (string, unique, nullable) and avatar_url (string, nullable) fields to the users table. Update User schema with proper validation for username (3-30 chars, alphanumeric + underscores/hyphens, unique). Add changeset for username updates.
<!-- SECTION:DESCRIPTION:END -->

## Acceptance Criteria
<!-- AC:BEGIN -->
- [x] #1 Migration created for username and avatar_url fields
- [x] #2 User schema updated with new fields
- [x] #3 Username validation implemented (3-30 chars, alphanumeric + underscores/hyphens)
- [x] #4 Username uniqueness constraint added
- [x] #5 Username changeset function created
- [x] #6 Tests pass
<!-- AC:END -->

## Implementation Plan

<!-- SECTION:PLAN:BEGIN -->
1. Create migration for username and avatar_url fields
2. Update User schema with new fields
3. Add validation functions for username format
4. Create username_changeset function
5. Run migration and verify
6. Run tests
<!-- SECTION:PLAN:END -->

## Implementation Notes

<!-- SECTION:NOTES:BEGIN -->
Added username and avatar_url fields to User schema with proper validation.

Changes made:
- Created migration adding username (string, unique) and avatar_url (string) fields
- Updated User schema with the new fields
- Implemented username_changeset/3 with validation:
  - Length: 3-30 characters
  - Format: alphanumeric + underscores/hyphens only (regex: ^[a-zA-Z0-9_-]+$)
  - Uniqueness constraint
- Implemented avatar_changeset/2 with URL length validation (max 500 chars)
- Both fields are nullable to support existing users
- All 1042 tests pass

Files modified:
- priv/repo/migrations/20251021161425_add_username_and_avatar_to_users.exs
- lib/game_master_core/accounts/user.ex

## Tests Added

Comprehensive test coverage for username and avatar_url:

### Unit Tests (test/game_master_core/accounts_test.exs)
- Username validation: length (3-30 chars), format (alphanumeric + underscores/hyphens), uniqueness
- Username allows nil (for existing users)
- Username validate_unique option
- Avatar URL validation: max length (500 chars), allows nil
- Total: 8 new unit tests

### Integration Tests (test/game_master_core_web/controllers/api_auth_controller_test.exs)
- Signup endpoint returns username and avatar_url fields
- Login endpoint returns username and avatar_url fields
- Status endpoint returns username and avatar_url fields
- Total: 6 new integration tests

### Swagger Documentation
- Updated User schema to include username and avatar_url fields
- Updated all example responses (LoginResponse, AuthStatusResponse)

**All 1056 tests pass** ✅
<!-- SECTION:NOTES:END -->
