# Tiled Project: Action Plan & Notes (March 2026)

## Current State

- **Homepage:** Exists, but layout and fonts need work.
- **Settings Page:** Layout unfinished; clear and buttons work but not styled as desired.
- **Confirmation Modal:** Needs improvement (see below).
- **Single Player:** Loads into game; UI/UX needs polish (button placement, badge labels, overlay automation, accessibility).
- **Game Screens:** Fonts, slider numbers, and positioning need standardization and improvement.
- **Multiplayer/Lobby:** Needs title, background/color update, QR code fix, and badge resizing.
- **Testing:** Can test with 2 players, but need easier way to test with 4. Max players may need to be reduced for this version.
- **Documentation/Tracking:** Need better changelog, TODOs, and regular review.

---

## Confirmation Modal Discussion

- **Current Issue:** The modal sometimes blocks or confuses the "Go" button below it. The modal itself doesn’t look great and may not be necessary.
- **Options:**
  - Increase modal size and improve its appearance.
  - Make the "Go" button less visible or inactive when the modal is up, to avoid confusion.
  - Change the "Go" button to require a double-click for confirmation.
  - Remove the confirmation modal entirely if it’s not adding value.
- **Considerations:**  
  - If the action is simple and low-risk, confirmation may not be needed.
  - If accidental clicks are a concern, improving the modal or requiring a double-click could help.
  - Whichever approach, ensure the UI clearly communicates what’s happening.

---

## Action Plan

### 1. UI/UX Improvements
- [ ] Homepage: Finalize layout and fonts.
- [ ] Settings page: Finish layout, style buttons.
- [ ] Confirmation modal: Decide on approach (see above) and implement.
- [ ] Game screens: Standardize fonts, centre numbers on sliders, improve positioning.
- [ ] Accessibility: Review colour contrast, add options for slider numbers, etc.

### 2. Single Player Flow
- [ ] Move guess button to bottom.
- [ ] Clarify player badge labels.
- [ ] Fix guess button focus/click issues.
- [ ] Automate overlay between questions (timer).
- [ ] Review and improve overlay messaging (e.g., winner/next round).

### 3. Multiplayer/Lobby
- [ ] Add/standardize lobby title.
- [ ] Update lobby background/color.
- [ ] Fix QR code functionality.
- [ ] Resize/fix player badges for multiple players.

### 4. Testing & Limits
- [ ] Make it easier to test with 4 players (consider mock/test mode).
- [ ] Decide on max player count for this version (recommend 4–6).
- [ ] Document future ideas for potential fork (not for current release).

### 5. Documentation & Tracking
- [ ] Keep a running changelog or dev diary (even brief bullet points).
- [ ] Consider a simple Kanban board or TODO list for tasks.
- [ ] Regularly review and update documentation as you go.

---

**Next Steps:**  
- Decide on the confirmation modal approach and implement it.
- Work through the action plan, updating this document as you go.
