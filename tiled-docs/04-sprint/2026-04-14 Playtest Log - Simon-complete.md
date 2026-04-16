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

- Date: 14/04/2026
- Build checked on: 
- Test device(s): PC – Asus Laptop
- Number of players simulated: 3
- Network setup: LAN
- Overall feel after first run:

## Quick Pass Checklist

Mark each as `OK`, `ISSUE`, or `NOT TESTED`.

- App launches cleanly - OK
- Main menu text and buttons feel intentional enough: OK
- Host can start a session without confusion: OK
- QR / join flow works quickly: OK
- Phones connect reliably: OK
- Player naming works and feels sensible: OK
- Lobby state matches connected players: OK
- Round starts cleanly: OK
- Turn flow is understandable: OK
- Answer submission works first time: OK
- Scoring feels understandable: OK
- Reveal / transition pacing feels right: OK
- End-of-round state is clear: OK
- Next round starts without weird carry-over state: OK
- Session can survive a player dropping or reconnecting: OK
- No obvious soft-locks or dead buttons: OK
- No unreadable text / broken layout on controller: OK
- No placeholder text that damages trust: OK

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
- ~~Hide the score in the corner (short fix)~~
- ~~change the game end background.~~ 

## Leave For Later

- The highlight circles cover part of the text.
		- consider - resizing or just replace with an underline - hand drawn squiggle.
		- game length - change from short medium long, to numeric values? 200 350 500? Impact on code?
		- Confirm overlay needs attention. Also, disable controls behind when overlay is on, *I can change the length!*
- ~~Splash screen needs some love.~~  *Updated - could still do with some work but ok for now.*
- Home screen: credits button - consider change of colour. Add an animation. **LATER**
- Settings and exit buttons: . maybe add a small bounce effect, see what it looks like.
- Game Setup: the highlight circles cover part of the text.
	- consider - resizing, transparency, behind the text (odd!), or just replace with an underline - hand drawn squiggle.
	- game length - change from short medium long, to numeric values? 200 350 500? Impact on code?
	- Confirm overlay needs attention. Also, disable controls behind when overlay is on, i can change the length!
- The controller UI is a bit clunky:
	- Connect and name can be seen. Connect must be clicked first (it then hides!)
		- TO join player must enter a name, pick avatar click join and then ready
		- Could the connect include the 'join' command. Player is then given the name/avatar selection with the update profile button and ready. They appear as a default name to start with. 
- Messages in transitions:
	- Correct message is a bit "meh". You scored 78 points (75 + 3 bonus). Got to be changed! (short/later)pre question trianstion: "Give this one a go for n points!" (make a few to make it different)
-  Current player icon on the player bar, maybe make it flash. maybe bin it and make the whole badge bigger/wobble/glow/something.  - (later)
- Turn message at the top - jazz it up. (basic style - short. Animation/backgrounds - later)
- Tiles - get some variety in there. Definitely between questions, even in the grid.
- Slides are numbered, consider allowing keyboard to do the slides (1 - 9) (later)
- 

## Tester Hand-Off Notes

When this pass is done, write one sentence for each:

- What felt fun:

- What felt confusing:

- What felt broken:

- What I am explicitly choosing not to fix yet:

- What I want external testers to pay attention to:

