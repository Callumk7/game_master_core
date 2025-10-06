---
id: task-029
title: Remove temporary error handling from location controller list_links endpoint
status: To Do
assignee: []
created_date: '2025-10-06 15:49'
labels:
  - cleanup
  - controller
  - refactor
dependencies: []
priority: medium
---

## Description

<!-- SECTION:DESCRIPTION:BEGIN -->
Remove temporary error handling code that was added to the location controller's list_links endpoint to catch KeyError exceptions and log diagnostic information about orphaned link records. This was a quick fix to prevent 500 errors in production while identifying the root cause. Since the orphaned link records have been cleaned up and the root cause resolved, this temporary code should be reverted to the original simple implementation.
<!-- SECTION:DESCRIPTION:END -->

## Acceptance Criteria
<!-- AC:BEGIN -->
- [ ] #1 Try/rescue block is removed from list_links method (lines ~102-140)
- [ ] #2 log_orphaned_link_details/2 private function is removed (lines ~293-356)
- [ ] #3 Original simple implementation is restored that calls Locations.links() directly
- [ ] #4 Endpoint functionality remains unchanged - still returns location links data
- [ ] #5 No error handling regressions - endpoint handles normal error cases properly
<!-- AC:END -->
