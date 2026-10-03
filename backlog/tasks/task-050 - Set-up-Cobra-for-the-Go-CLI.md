---
id: TASK-050
title: Set up Cobra for the Go CLI
status: In Progress
assignee:
  - '@pi'
created_date: '2026-10-03 14:21'
updated_date: '2026-10-03 14:23'
labels: []
dependencies: []
---

## Description

<!-- SECTION:DESCRIPTION:BEGIN -->
Replace manual CLI argument dispatch with Cobra while retaining the scaffold's scope and testability.
<!-- SECTION:DESCRIPTION:END -->

## Acceptance Criteria
<!-- AC:BEGIN -->
- [x] #1 Help and version commands are implemented through Cobra with no API commands added
- [x] #2 Command errors, output routing, and version injection remain tested and documented
- [x] #3 Cobra dependency is pinned and Go formatting, vet, tests, and build pass
<!-- AC:END -->

## Implementation Plan

<!-- SECTION:PLAN:BEGIN -->
1. Add Cobra and replace manual dispatch with a fresh command tree per invocation.
2. Update tests and documentation for Cobra help, flags, and error behavior.
3. Run Go checks, executable smoke tests, and mix precommit; record any blockers.
<!-- SECTION:PLAN:END -->

## Implementation Notes

<!-- SECTION:NOTES:BEGIN -->
Installed Cobra v1.10.2 with pinned module dependencies and go.sum. Replaced manual dispatch with a fresh Cobra command tree per Run, injected stdout/stderr, generated help, version command/flag, argument and flag validation, and built-in shell completion. Updated tests and README; no API commands or Viper added. Self-reviewed command wiring and output ownership.

Validation passed: gofmt, go mod tidy, go vet ./..., go test -race ./..., build, release version injection for command and flag, bash completion syntax, and unknown-command exit status with a single stderr error and empty stdout.

Required server validation remains blocked: mix precommit compiled and generated Swagger but failed when connecting to PostgreSQL at localhost:5432 (connection refused). Keeping task In Progress until full validation is available.
<!-- SECTION:NOTES:END -->
