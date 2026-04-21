## V1 Stability and Polish Sprint: Day-by-Day Checklist (Day 1 to Day 14)

Capacity assumption: 11-15 hours/week.  
Daily rule: complete at most 3 items per session.  
Task mix each day: 1 stability item, 1 testing or documentation item, 1 polish or copy item.

## Linux Testing Quickstart (No PowerShell)

Run from project root: /home/simon/Projects/tiled/tiled

Godot headless tests:
- godot --headless -s res://scenes/tests/input_validator_test.gd
- godot --headless -s res://scenes/tests/answer_modal_headless_test.gd
- godot --headless -s res://scenes/tests/vote_multiplayer_headless_scaffold.gd

Playwright controller tests:
- npm install
- npm run test:e2e

Notes:
- Your Linux Godot path is: /home/simon/.local/bin/godot
- In fish shell, use $status instead of $? for exit status checks.

## One Thing Right Now (Focus Reset)

If attention is scattered, do only this block today:

- [ ] Run: godot --headless -s res://scenes/tests/input_validator_test.gd
- [ ] Open this file and tick Day 1 item: Create one Stability Done checklist.
- [ ] Write only 3 checklist lines for today:
	- [ ] Confirm v1 boundary (no new modes, no redesign)
	- [ ] Identify the single missing transition to fix next
	- [ ] Log one controller dead-end state to investigate tomorrow

Stop after these three lines are done.

### Day 1 - Scope Lock and Done Bar
- [ ] Confirm v1 boundaries using [tiled-docs/04-sprint/V1 Ship Plan.md](tiled-docs/04-sprint/V1%20Ship%20Plan.md).
- [ ] Freeze out-of-scope work in your active task list (new modes, redesigns, spin-off ideas).
- [ ] Create one Stability Done checklist with pass or fail criteria.
- [ ] Run current baseline tests once and save results snapshot.

Outcome:
- One source-of-truth checklist for all remaining days.

### Day 2 - Transition Audit Pass
- [ ] Walk full flow and list every screen/state transition in order.
- [ ] Mark missing or weak transitions, including unclear transition messaging.
- [ ] Prioritize transition fixes by break severity.
- [ ] Add transition matrix section to testing notes.

Outcome:
- Complete transition matrix with top fixes ranked.

### Day 3 - Transition Fix Batch 1
- [ ] Implement highest severity transition fix(es).
- [ ] Validate no skipped or dead-end state after each fix.
- [ ] Record behavior before/after in test notes.
- [ ] Re-run smoke baseline.

Outcome:
- Core flow has no critical transition blocker.

### Day 4 - Controller Flow Investigation and Cleanup 1
- [ ] Audit first-join flow (connect, join, profile, ready).
- [ ] Identify dead-end controller states and confusing hints.
- [ ] Apply small cleanup changes only (no architecture redesign).
- [ ] Add controller state progression checklist for manual QA.

Outcome:
- Reduced controller join friction with no structural risk.

### Day 5 - Controller Cleanup 2 and Reconnect Checks
- [ ] Test reconnect within grace window and after grace timeout.
- [ ] Verify state recovery does not duplicate or orphan player state.
- [ ] Fix one or two highest-impact reconnect issues.
- [ ] Run controller e2e baseline and note regressions.

Outcome:
- Controller reliability improves in real join and rejoin conditions.

### Day 6 - Copy Pass 1 (Clarity)
- [ ] Run a host-side script read-through for one full session.
- [ ] Rewrite confusing or placeholder text for transitions and resolution.
- [ ] Ensure players can understand reveal, guess, and scoring language at first read.
- [ ] Log all changed strings in a simple changelog section.

Outcome:
- Core copy is clear and no longer placeholder-heavy.

### Day 7 - Polish Pass 1 (Low Cost, High Comprehension)
- [ ] Add only quick polish that improves readability and state clarity.
- [ ] Confirm missing transition visuals/messages are now present.
- [ ] Verify round-end and next-round pacing feels intentional.
- [ ] Run short couch-style play pass (15-20 minutes).

Outcome:
- Gameplay feels cleaner without scope creep.

### Day 8 - Test Documentation Build-Out
- [ ] Create a repeatable alpha protocol document.
- [ ] Add preflight checklist (build, ports, host/controller readiness).
- [ ] Add scenario matrix (single-player, multiplayer, reconnect, fuzzy vote).
- [ ] Add pass or fail format and issue logging template.

Outcome:
- Testing process is documented and reusable.

### Day 9 - Vote and Edge Case Reliability
- [ ] Run fuzzy vote scenarios end to end with 3+ players.
- [ ] Verify no stuck vote session and correct round continuation.
- [ ] Capture unresolved vote edge cases with reproducible steps.
- [ ] Add these cases to protocol as required checks.

Outcome:
- Voting and resolution edge cases become visible and actionable.

### Day 10 - Internal Alpha Run 1
- [ ] Execute full alpha protocol from start to finish.
- [ ] Log every failure against checklist criteria.
- [ ] Fix only high severity blockers found in this run.
- [ ] Re-test fixed items immediately.

Outcome:
- First confidence read on v1 readiness with evidence.

### Day 11 - Hardening Day
- [ ] Close remaining high severity issues from Day 10.
- [ ] Re-check transition matrix and controller matrix after fixes.
- [ ] Confirm no regression in smoke and controller e2e baselines.
- [ ] Update issue log status (open, fixed, deferred).

Outcome:
- Build is more stable and regression-aware.

### Day 12 - External Alpha Run 2 Preparation
- [ ] Prepare clean test instructions for friend/family replay session.
- [ ] Verify environment preflight (network ports, host setup, controller URL).
- [ ] Define 3-5 focused feedback prompts (confusion, flow, reliability, fun).
- [ ] Timebox fixes to only blockers discovered during prep.

Outcome:
- External test is structured and comparable to internal run.

### Day 13 - External Alpha Run 2 and Debrief
- [ ] Run external test with protocol checklist.
- [ ] Capture confusion points verbatim from players.
- [ ] Categorize findings: blocker, annoying, polish-only.
- [ ] Apply only blocker fixes today.

Outcome:
- Real-user confidence signal grounded in repeatable notes.

### Day 14 - Ship Gate Decision Day
- [ ] Compare Day 10 and Day 13 results against Stability Done checklist.
- [ ] Decide one path: ship candidate, short hardening extension, or rollback risky polish.
- [ ] Freeze near-term backlog to top post-alpha tasks only.
- [ ] Write short handoff summary: what is stable, what is known risk, what is next.

Outcome:
- Clear go or no-go decision with documented rationale.

## Daily Log Template (Use Every Day)

Date:  
Top 3 tasks:
1. 
2. 
3. 

Completed:
- 

Problems found:
- 

Evidence links:
- 

Next first task:
- 

## Reference Files

- [tiled-docs/04-sprint/V1 Ship Plan.md](tiled-docs/04-sprint/V1%20Ship%20Plan.md)
- [tiled-docs/04-sprint/2026-04-16 Linux Handover.md](tiled-docs/04-sprint/2026-04-16%20Linux%20Handover.md)
- [tiled-docs/04-sprint/2026-04-14 Playtest Log - Simon-complete.md](tiled-docs/04-sprint/2026-04-14%20Playtest%20Log%20-%20Simon-complete.md)
- [tiled-docs/02-technical/Game Flow.md](tiled-docs/02-technical/Game%20Flow.md)
- [tiled-docs/02-technical/Game Rules.md](tiled-docs/02-technical/Game%20Rules.md)
- [tiled/scenes/tests/vote_multiplayer_headless_scaffold.gd](tiled/scenes/tests/vote_multiplayer_headless_scaffold.gd)
- [tiled/tests/e2e/controller-multi.spec.js](tiled/tests/e2e/controller-multi.spec.js)
- [tiled/scripts/autoload/GameManager.gd](tiled/scripts/autoload/GameManager.gd)
- [tiled/controller/js/state.js](tiled/controller/js/state.js)
