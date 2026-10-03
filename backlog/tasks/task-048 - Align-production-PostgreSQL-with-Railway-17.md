---
id: TASK-048
title: Align production PostgreSQL with Railway 17
status: In Progress
assignee:
  - '@assistant'
created_date: '2026-10-03 13:56'
updated_date: '2026-10-03 13:57'
labels: []
dependencies: []
---

## Description

<!-- SECTION:DESCRIPTION:BEGIN -->
Support importing the Railway PostgreSQL 17 database into the exe deployment.
<!-- SECTION:DESCRIPTION:END -->

## Acceptance Criteria
<!-- AC:BEGIN -->
- [x] #1 Production Compose and deployment examples use PostgreSQL 17.
- [x] #2 Deployment guide explains resetting an empty PostgreSQL 16 volume without deleting uploads.
<!-- AC:END -->

## Implementation Plan

<!-- SECTION:PLAN:BEGIN -->
1. Update production Compose and deployment examples to PostgreSQL 17.
2. Document the empty database volume reset for Compose and systemd without deleting uploads.
3. Validate configuration and run mix precommit.
<!-- SECTION:PLAN:END -->

## Implementation Notes

<!-- SECTION:NOTES:BEGIN -->
Updated production Compose and deployment examples to PostgreSQL 17. Added empty PostgreSQL 16 database-volume reset instructions, preserving uploads, including systemd service changes and restore-before-migrations guidance. Docker Compose configuration validation passed. mix precommit reached tests but failed because PostgreSQL is unavailable at localhost:5432 (connection refused); task remains In Progress pending test validation.
<!-- SECTION:NOTES:END -->
