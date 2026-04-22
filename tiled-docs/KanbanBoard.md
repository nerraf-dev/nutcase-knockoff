# Tiled Kanban Board

One source of truth for active work. Keep cards short.

Card format:
- Type | Outcome | Link
- Type options: Bug, Feature, Polish, Test, Docs, Decision

GitHub link shorthand:
- Use `local` when no issue exists.
- Use `GH-new` when an issue should be created at next sync.
- Use `GH-<number>` for issue-backed work, for example `GH-42`.
- Keep details in the issue; keep board cards one line.

## Now (max 3)
- Test | Run controller break pass on real devices and log failures | [2026-04-21 notes](04-sprint/2026-04-21.md)
- Feature | Add clear vote ceremony flow (incoming -> cast -> result) | local
- Polish | Improve setup confirm modal consistency with game buttons | local

## Next (up to 7)
- Test | Verify QR join flow on at least 2 non-desktop devices before opening an issue | local
- Polish | Standardise fonts and centre slider numbers on game screens | local
- Polish | Clarify player badge labels and resize for multi-player layouts | local
- Feature | Improve winner and next-question overlay copy consistency | local
- Test | Add easier 4-player test setup or mock mode | local
- Decision | Confirm max player count for v1 (4-6) | GH-new
- Polish | Add or standardise lobby title and background pass | local

## Waiting (blocked or external)
- Test | Cross-device run on additional phones/tablets after current fixes | local

## Later (parking lot)
- Feature | Near-win visual progression on player badge or tile cracks | [2026-04-21 notes](04-sprint/2026-04-21.md)
- Decision | Confirmation modal long-term approach (improve vs remove path) | local
- Docs | Document future fork ideas and maintain changelog rhythm | local
- Polish | Accessibility pass on color contrast and slider-number options | local

## Done (this week)
- Feature | Transition overlay shown before question 1 with updated copy | [2026-04-21 notes](04-sprint/2026-04-21.md)
- Feature | Automate overlay between questions (timer) | local
- Polish | Homepage layout and font pass | local
- Polish | Settings page layout and button style pass | local
- Polish | Move guess button to bottom in single-player | local
- Bug | Fix guess button focus and click issues | local

## Archive (older done)
- Move completed items here weekly to keep the board readable.

## Daily 5-minute update
1. Move finished cards to Done.
2. Keep only up to 3 items in Now.
3. Move blocked items to Waiting with one-line reason.
4. Create a GitHub issue only for bugs/decisions that need history.
5. Replace `GH-new` with `GH-<number>` once created, then keep details in one place.

## Issue triage rule (quick)
- Create issue when at least one is true:
- Reproducible bug with player impact.
- Cross-session decision you will revisit.
- Work item you want to reference in commit/PR history.
- Keep board-only when it is small personal polish or same-day work.


