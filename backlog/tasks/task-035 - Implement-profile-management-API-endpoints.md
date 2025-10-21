---
id: task-035
title: Implement profile management API endpoints
status: Done
assignee:
  - '@amp'
created_date: '2025-10-21 17:15'
updated_date: '2025-10-21 17:41'
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

## Implementation Plan

<!-- SECTION:PLAN:BEGIN -->
1. Create AccountController with profile management endpoints
2. Add /api/account/* routes to router with require_session_auth pipeline
3. Implement GET /api/account/profile - return user profile data
4. Implement PATCH /api/account/profile - update username with validation
5. Implement POST /api/account/avatar - upload avatar with file type/size validation
6. Implement DELETE /api/account/avatar - remove avatar and cleanup file
7. Implement POST /api/account/email/change-request - request email change with password verification
8. Implement POST /api/account/email/change-confirm - confirm email change with token
9. Add comprehensive Swagger documentation
10. Write tests for all endpoints
11. Run tests and fix any issues
<!-- SECTION:PLAN:END -->

## Implementation Notes

<!-- SECTION:NOTES:BEGIN -->
Successfully implemented profile management API endpoints with comprehensive functionality:

## Implemented Endpoints:
- GET /api/account/profile - Returns user profile data
- PATCH /api/account/profile - Updates username with validation
- POST /api/account/avatar - Uploads avatar with file type/size validation (JPEG/PNG/GIF/WebP, max 5MB)
- DELETE /api/account/avatar - Removes avatar and cleans up storage
- POST /api/account/email/change-request - Requests email change with password verification
- POST /api/account/email/change-confirm - Confirms email change with token

## Key Features:
- All endpoints require authentication via session API
- File upload validation with proper error handling
- Automatic cleanup of old avatar files when uploading new ones
- Secure email change flow with password verification and email confirmation
- Comprehensive Swagger API documentation
- Full test coverage with 19 test cases

## Technical Implementation:
- Created AccountController with proper error handling
- Added missing Accounts functions (update_user_username, update_user_avatar)
- Integrated with existing Storage module for file uploads
- Used existing UserNotifier for email verification
- Added routes with require_session_auth pipeline
- Created comprehensive test suite

All acceptance criteria have been met and tests are passing.
<!-- SECTION:NOTES:END -->
