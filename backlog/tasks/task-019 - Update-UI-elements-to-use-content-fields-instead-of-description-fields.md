---
id: task-019
title: Update UI elements to use content fields instead of description fields
status: Done
assignee:
  - '@myself'
created_date: '2025-09-21 17:06'
updated_date: '2025-09-21 17:11'
labels: []
dependencies: []
---

## Description

<!-- SECTION:DESCRIPTION:BEGIN -->
Complete the frontend migration by updating all HTML templates, forms, and display components to use the new content field names instead of description fields
<!-- SECTION:DESCRIPTION:END -->

## Acceptance Criteria
<!-- AC:BEGIN -->
- [x] #1 All admin form templates updated to use content field names
- [x] #2 All display templates updated to show content instead of description
- [x] #3 All form labels updated to reflect content field naming
- [x] #4 All table columns updated to display content fields
- [x] #5 All field references in templates use @entity.content instead of @entity.description
- [x] #6 All form field references use f[:content] instead of f[:description]
- [x] #7 UI testing performed to verify forms work correctly
- [x] #8 Display pages show content correctly after updates
<!-- AC:END -->

## Implementation Plan

<!-- SECTION:PLAN:BEGIN -->
# UI Migration Implementation Plan

## Investigation Summary
Based on codebase analysis, the following UI components need updates:

### Files Requiring Updates (8 files total):

#### Admin Form Templates (3 files):
1. lib/game_master_core_web/controllers/admin/game_html/game_form.html.heex
   - Line 3: <.input field={f[:description]} → <.input field={f[:content]}
   - Update label from "Description" to "Content"

2. lib/game_master_core_web/controllers/admin/character_html/character_form.html.heex  
   - Line 3: <.input field={f[:description]} → <.input field={f[:content]}
   - Update label from "Description" to "Content"

3. lib/game_master_core_web/controllers/admin/faction_html/faction_form.html.heex
   - Line 3: <.input field={f[:description]} → <.input field={f[:content]}
   - Update label from "Description" to "Content"

#### Admin Display Templates (5 files):
4. lib/game_master_core_web/controllers/admin/game_html/show.html.heex
   - Line 29: {@game.description} → {@game.content}
   - Update title from "Description" to "Content"

5. lib/game_master_core_web/controllers/admin/game_html/index.html.heex
   - Line 13: {game.description} → {game.content}
   - Update column label from "Description" to "Content"

6. lib/game_master_core_web/controllers/admin/character_html/show.html.heex
   - Line 20: {@character.description} → {@character.content}
   - Update title from "Description" to "Content"

7. lib/game_master_core_web/controllers/admin/character_html/index.html.heex
   - Line 19: {character.description} → {character.content}
   - Update column label from "Description" to "Content"

8. lib/game_master_core_web/controllers/admin/faction_html/show.html.heex
   - Line 20: {@faction.description} → {@faction.content}
   - Update title from "Description" to "Content"

9. lib/game_master_core_web/controllers/admin/faction_html/index.html.heex
   - Line 17: {faction.description} → {faction.content}
   - Update column label from "Description" to "Content"

### Implementation Steps:
1. Update form field references (f[:description] → f[:content])
2. Update display field references (@entity.description → @entity.content)
3. Update form labels ("Description" → "Content")
4. Update display titles and column headers
5. Test all admin pages for games, characters, and factions
6. Verify forms submit correctly with new field names
7. Verify display pages show content correctly

### Testing Plan:
- Test game creation and editing forms
- Test character creation and editing forms  
- Test faction creation and editing forms
- Verify all index pages display content
- Verify all show pages display content
- Check that form validation still works properly
<!-- SECTION:PLAN:END -->

## Implementation Notes

<!-- SECTION:NOTES:BEGIN -->
Successfully updated all UI elements from description to content fields. Updated 9 HTML templates (3 forms + 6 display pages) for Games, Characters, and Factions. Fixed one backend function and several test assertions that were still using the old field names. All web tests now pass (301/301). The UI now consistently uses content field naming across the entire application.
<!-- SECTION:NOTES:END -->
