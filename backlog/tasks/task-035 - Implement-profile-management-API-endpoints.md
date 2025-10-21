---
id: task-035
title: Implement profile management API endpoints
status: To Do
assignee: []
created_date: '2025-10-21 17:15'
labels:
  - backend
  - api
  - security
dependencies: []
priority: high
---

## Description

<!-- SECTION:DESCRIPTION:BEGIN -->
Create API endpoints for users to manage their profile including username updates, avatar upload/deletion, and secure email changes with password confirmation and email verification.
<!-- SECTION:DESCRIPTION:END -->

## Acceptance Criteria
<!-- AC:BEGIN -->
- [ ] #1 GET /api/account/profile endpoint returns user profile
- [ ] #2 PATCH /api/account/profile endpoint updates username
- [ ] #3 POST /api/account/avatar endpoint uploads avatar image
- [ ] #4 DELETE /api/account/avatar endpoint removes avatar
- [ ] #5 POST /api/account/email/change-request endpoint requests email change with password
- [ ] #6 POST /api/account/email/change-confirm endpoint confirms email change with token
- [ ] #7 Avatar upload validates file type and size (max 5MB)
- [ ] #8 Avatar upload cleans up old avatar file
- [ ] #9 Email change sends verification to new email
- [ ] #10 Email change notifies old email
- [ ] #11 All endpoints require authentication
- [ ] #12 Comprehensive tests written
- [ ] #13 Swagger documentation updated
<!-- AC:END -->
