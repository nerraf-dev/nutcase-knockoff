# Tiled Playtest Log (2026-04-14)

## Build Under Test

- Build: `tiled/\_builds/windows/tiled.exe`

- Purpose: pre-share playtest before handing build to a couple of external testers

- Focus: gameplay stability, controller flow, clarity, and obvious friction

- Explicitly not a priority in this pass: music variety, deep visual polish, placeholder copy unless quick to fix

## Triage Rule

Use these labels while testing:

- `BIG` = blocks play, breaks trust, confuses the round flow, or makes the game feel unstable

- `SHORT` = small fix with clear scope, worth doing now

- `LATER` = cosmetic, content, polish, nice-to-have, or anything that risks a rabbit hole

If an issue is not clearly `BIG` or `SHORT`, mark it `LATER` and keep moving.

## Session Notes

- Date:

- Build checked on:

- Test device(s):

- Number of players simulated:

- Network setup:

- Overall feel after first run:

## Quick Pass Checklist

Mark each as `OK`, `ISSUE`, or `NOT TESTED`.

- App launches cleanly

- Main menu text and buttons feel intentional enough

- Host can start a session without confusion

- QR / join flow works quickly

- Phones connect reliably

- Player naming works and feels sensible

- Lobby state matches connected players

- Round starts cleanly

- Turn flow is understandable

- Answer submission works first time

- Scoring feels understandable

- Reveal / transition pacing feels right

- End-of-round state is clear

- Next round starts without weird carry-over state

- Session can survive a player dropping or reconnecting

- No obvious soft-locks or dead buttons

- No unreadable text / broken layout on controller

- No placeholder text that damages trust

## Issue Log

| ID | Area | Priority | What happened | Repro steps | Expected | Actual | Fix now? |
| - | - | - | - | - | - | - | - |
| 1 |  |  |  |  |  |  |  |
| 2 |  |  |  |  |  |  |  |
| 3 |  |  |  |  |  |  |  |
| 4 |  |  |  |  |  |  |  |
| 5 |  |  |  |  |  |  |  |
| 6 |  |  |  |  |  |  |  |
| 7 |  |  |  |  |  |  |  |
| 8 |  |  |  |  |  |  |  |


## High-Risk Things To Watch Closely

### Connection and controller state

- phone joins but host UI does not update

- host advances but one controller remains on an old state

- reconnect creates duplicate player state

- controller appears connected but input does nothing

### Round flow

- a submit, skip, reveal, timeout, or next-round action leaves the game in a stuck state

- a player can act when they should not be allowed to

- a round resolves but score / winner / next state is unclear

### Trust breakers

- scoring looks wrong even if technically correct

- fuzzy answer acceptance feels unfair or inconsistent

- placeholder text/images make the game feel unfinished in a distracting way

- visual overlap or clipped UI makes players unsure what is happening

## Must-Fix Before External Testers


## Short Fixes Worth Doing Before External Testers


## Leave For Later


## Tester Hand-Off Notes

When this pass is done, write one sentence for each:

- What felt fun:

- What felt confusing:

- What felt broken:

- What I am explicitly choosing not to fix yet:

- What I want external testers to pay attention to:

