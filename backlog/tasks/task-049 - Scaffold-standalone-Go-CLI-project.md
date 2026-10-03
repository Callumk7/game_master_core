---
id: TASK-049
title: Scaffold standalone Go CLI project
status: In Progress
assignee:
  - '@pi'
created_date: '2026-10-03 14:08'
updated_date: '2026-10-03 14:10'
labels: []
dependencies: []
---

## Description

<!-- SECTION:DESCRIPTION:BEGIN -->
Establish an independently buildable Go CLI under tools/gm without implementing API operations or changing the server.
<!-- SECTION:DESCRIPTION:END -->

## Acceptance Criteria
<!-- AC:BEGIN -->
- [x] #1 CLI builds independently and provides help and version commands
- [x] #2 Command scaffolding has automated tests and documented build, run, and test instructions
- [x] #3 No API operations, authentication, or server behavior changes are introduced
<!-- AC:END -->

## Implementation Plan

<!-- SECTION:PLAN:BEGIN -->
1. Create a dependency-free Go module with an executable entry point and testable command runner.
2. Add help/version behavior, tests, and local build documentation.
3. Run Go checks and mix precommit; self-review and record results.
<!-- SECTION:PLAN:END -->

## Implementation Notes

<!-- SECTION:NOTES:BEGIN -->
Scaffolded tools/gm as an independent, dependency-free Go module with help/version commands, a testable command runner, version injection, ignored build output, and build/test documentation. Added a link from the root README. No server source or API behavior changes.

Validation: gofmt, go vet ./..., go test ./..., executable build, help/version smoke checks, release version injection, and invalid-command stderr/exit checks passed. Self-reviewed scope and command behavior.

Blocked server validation: mix precommit failed while creating the test database because PostgreSQL at localhost:5432 refused the connection. Task remains In Progress until the full required checks can run.
<!-- SECTION:NOTES:END -->
